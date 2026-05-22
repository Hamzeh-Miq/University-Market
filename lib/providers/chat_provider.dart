import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';

/// Singleton [ChatService] provider.
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

/// Real-time stream of all conversations for [userId].
final conversationsProvider =
    StreamProvider.autoDispose.family<List<ConversationModel>, String>(
  (ref, userId) =>
      ref.watch(chatServiceProvider).watchConversations(userId),
);

/// Real-time stream of messages in a single conversation.
final messagesProvider =
    StreamProvider.autoDispose.family<List<MessageModel>, String>(
  (ref, conversationId) =>
      ref.watch(chatServiceProvider).watchMessages(conversationId),
);

/// Fetches display info for another user.
/// [args.$1] = uid, [args.$2] = isAdmin flag.
/// Admins receive name + email + phone; regular users receive name only.
final otherUserInfoProvider = FutureProvider.autoDispose
    .family<Map<String, String>, (String, bool)>(
  (ref, args) => ref
      .watch(chatServiceProvider)
      .getOtherUserInfo(args.$1, isAdmin: args.$2),
);

/// Real-time count of conversations where the last message was sent by
/// someone else — drives the AppBar chat badge.
final unreadCountProvider =
    StreamProvider.autoDispose.family<int, String>(
  (ref, userId) =>
      ref.watch(chatServiceProvider).watchUnreadCount(userId),
);
