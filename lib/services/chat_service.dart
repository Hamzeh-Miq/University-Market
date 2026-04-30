import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns a real-time stream of all conversations for [userId].
  Stream<List<ConversationModel>> watchConversations(String userId) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Returns a real-time stream of messages in a conversation.
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Sends a message and updates the conversation's lastMessage field.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
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
      {'lastMessage': text, 'lastMessageTime': Timestamp.fromDate(now)},
    );
    await batch.commit();
  }

  /// Creates a new conversation between two users about a product.
  /// Returns the conversation ID (existing or newly created).
  Future<String> getOrCreateConversation({
    required String buyerId,
    required String sellerId,
    required String productId,
  }) async {
    // Check if a conversation already exists for this buyer+product
    final existing = await _db
        .collection('conversations')
        .where('productId', isEqualTo: productId)
        .where('participants', arrayContains: buyerId)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    // Create new
    final newConv = ConversationModel(
      conversationId: '',
      participants: [buyerId, sellerId],
      productId: productId,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    );

    final ref = await _db.collection('conversations').add(newConv.toJson());
    return ref.id;
  }
}
