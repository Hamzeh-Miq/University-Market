import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation_model.dart';

/// Handles all Firestore operations for the chat feature.
class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns a real-time stream of all conversations for [userId],
  /// ordered by most recent message first.
  Stream<List<ConversationModel>> watchConversations(String userId) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ConversationModel.fromJson(d.data(), d.id))
            // Hide conversations this user has soft-deleted
            .where((c) => !c.deletedBy.contains(userId))
            .toList());
  }

  /// Returns a real-time stream of messages in a conversation,
  /// ordered chronologically (oldest first).
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => MessageModel.fromJson(d.data(), d.id))
            .toList());
  }

  /// Sends a message and atomically updates the conversation's lastMessage.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    try {
      final now = DateTime.now();
      final msgRef = _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      final message = MessageModel(
        messageId: msgRef.id,
        senderId: senderId,
        text: text,
        timestamp: now,
      );

      final batch = _db.batch();
      batch.set(msgRef, message.toJson());
      batch.update(
        _db.collection('conversations').doc(conversationId),
        {
          'lastMessage': text,
          'lastMessageTime': Timestamp.fromDate(now),
          'lastSenderId': senderId,
          // Restore the conversation for both users when a new message arrives
          'deletedBy': [],
        },
      );
      await batch.commit();
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to send message: $e'), st);
    }
  }

  /// Returns the existing conversation ID for this buyer+seller pair,
  /// or creates a new one and returns its ID.
  /// One thread exists per person pair — multiple products share the same thread.
  /// [productTitle] is stored only when creating a brand-new conversation.
  Future<String> getOrCreateConversation({
    required String buyerId,
    required String sellerId,
    required String productId,
    required String productTitle,
  }) async {
    try {
      // Firestore can't query "array contains ALL of [a, b]" in one step,
      // so fetch all conversations the buyer is in, then filter client-side
      // for the ones where the seller is also a participant.
      final snapshot = await _db
          .collection('conversations')
          .where('participants', arrayContains: buyerId)
          .get();

      final existing = snapshot.docs.where((doc) {
        final participants =
            List<String>.from(doc.data()['participants'] ?? []);
        return participants.contains(sellerId);
      }).toList();

      if (existing.isNotEmpty) {
        // Return the existing thread — no duplicate created
        return existing.first.id;
      }

      // No existing conversation — create one
      final newConv = ConversationModel(
        conversationId: '',
        participants: [buyerId, sellerId],
        productId: productId,
        productTitle: productTitle,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      );

      final ref =
          await _db.collection('conversations').add(newConv.toJson());
      return ref.id;
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to create conversation: $e'), st);
    }
  }

  /// Returns display info for [uid].
  /// Regular users receive only the name.
  /// Admins (isAdmin=true) additionally receive email and phone.
  Future<Map<String, String>> getOtherUserInfo(
    String uid, {
    bool isAdmin = false,
  }) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return {'name': 'Unknown User'};
      final data = doc.data()!;

      final parts = [
        (data['firstName'] as String?) ?? '',
        (data['middleName'] as String?) ?? '',
        (data['lastName'] as String?) ?? '',
      ].where((s) => s.isNotEmpty);

      final fullName = parts.join(' ');
      final result = <String, String>{
        'name': fullName.isEmpty ? 'Unknown User' : fullName,
      };

      if (isAdmin) {
        result['email'] = (data['email'] as String?) ?? '';
        result['phone'] = (data['phoneNumber'] as String?) ?? '';
      }

      return result;
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to fetch user info: $e'), st);
    }
  }

  /// Returns a real-time count of conversations where the last message
  /// was sent by someone other than [userId] AND after they last read it.
  Stream<int> watchUnreadCount(String userId) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lastMessage = (data['lastMessage'] as String?) ?? '';
        final lastSenderId = (data['lastSenderId'] as String?) ?? '';
        if (lastMessage.isEmpty || lastSenderId == userId) continue;

        // Check if user has read this conversation after the last message
        final readAtMap =
            (data['readAt'] as Map<String, dynamic>?) ?? {};
        final readAtTs = readAtMap[userId] as Timestamp?;
        final lastMsgTs = data['lastMessageTime'] as Timestamp?;

        if (readAtTs == null || lastMsgTs == null) {
          count++;
        } else if (lastMsgTs.compareTo(readAtTs) > 0) {
          // Last message arrived after the user's last read
          count++;
        }
      }
      return count;
    });
  }

  /// Marks all messages in [conversationId] as read for [userId] by
  /// writing the current server timestamp to readAt.{userId}.
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _db.collection('conversations').doc(conversationId).update({
        'readAt.$userId': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-critical — silently ignore
    }
  }

  /// Deletes a single message from a conversation.
  /// Only the sender should be allowed to call this in the UI.
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to delete message: $e'), st);
    }
  }

  /// Soft-deletes a conversation for [userId] only.
  /// The conversation remains in Firestore and the other participant can still
  /// see it. The chat is restored for both users when a new message is sent.
  Future<void> softDeleteConversation(
      String conversationId, String userId) async {
    try {
      await _db.collection('conversations').doc(conversationId).update({
        'deletedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to delete conversation: $e'), st);
    }
  }
}
