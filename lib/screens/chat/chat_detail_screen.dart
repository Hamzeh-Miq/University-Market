import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

/// Full messaging thread for a single conversation.
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatDetailScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markRead() {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      ref.read(chatServiceProvider).markAsRead(widget.conversationId, uid);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String currentUid) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await ref
          .read(chatServiceProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            senderId: currentUid,
            text: text,
          );
      _scrollToBottom();
      _markRead();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
          ),
        );
      }
    }
  }

  // ── Delete a single message ────────────────────────────────────────────────

  void _onLongPressMessage(BuildContext context, String messageId, bool isMe) {
    if (!isMe) return; // Only allow deleting own messages
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Delete Message',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(chatServiceProvider)
                      .deleteMessage(
                        conversationId: widget.conversationId,
                        messageId: messageId,
                      );
                } catch (e) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Failed to delete message.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.textSecondary),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete entire conversation ─────────────────────────────────────────────

  Future<void> _deleteConversation() async {
    final currentUid = ref.read(authStateProvider).value?.uid;
    if (currentUid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Chat'),
        content: const Text(
          'This conversation will be removed from your inbox. '
          'The other user will still see it, and it will reappear '
          'if they send you a new message.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(chatServiceProvider)
          .softDeleteConversation(widget.conversationId, currentUid);
      if (mounted) Navigator.of(context).pop(); // Go back to chat list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete chat.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final isAdmin = ref.watch(isAdminProvider);
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final conversationAsync = ref.watch(
      singleConversationProvider(widget.conversationId),
    );

    return conversationAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Failed to load conversation details.')),
      ),
      data: (conversation) {
        if (conversation == null) {
          return const Scaffold(
            body: Center(child: Text('Conversation not found.')),
          );
        }

        final participants = conversation.participants;
        final otherUid = participants.firstWhere(
          (id) => id != (currentUser?.uid ?? ''),
          orElse: () => '',
        );
        final productTitle = conversation.productTitle;

        final userInfoAsync = otherUid.isNotEmpty
            ? ref.watch(otherUserInfoProvider((otherUid, isAdmin)))
            : const AsyncData<Map<String, String>>({'name': 'Chat'});
        final canViewOtherProfiles = ref.watch(canViewOtherProfilesProvider);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            // Tappable title → other user's profile
            title: GestureDetector(
              onTap: otherUid.isNotEmpty && canViewOtherProfiles
                  ? () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.sellerProfile, arguments: otherUid)
                  : null,
              child: userInfoAsync.when(
                data: (info) => Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info['name'] ?? 'Chat',
                            style: AppTextStyles.heading3,
                          ),
                          if (isAdmin && (info['email']?.isNotEmpty ?? false))
                            Text(
                              '${info['email']} · ${info['phone'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else if (productTitle.isNotEmpty)
                            Text(
                              productTitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (otherUid.isNotEmpty && canViewOtherProfiles)
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                  ],
                ),
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text('Chat'),
              ),
            ),
            // ── Actions: delete chat ───────────────────────────────
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                onSelected: (value) {
                  if (value == 'delete_chat') _deleteConversation();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete_chat',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        SizedBox(width: 10),
                        Text(
                          'Delete Chat',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Messages list ─────────────────────────────────────
              Expanded(
                child: messagesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text(
                      'Failed to load messages.',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet.\nSay hello!',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    _markRead();
                    _scrollToBottom();
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUser?.uid;
                        return _MessageBubble(
                          text: msg.text,
                          isMe: isMe,
                          timestamp: msg.timestamp,
                          onLongPress: () =>
                              _onLongPressMessage(context, msg.messageId, isMe),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Input bar ─────────────────────────────────────────
              _InputBar(
                controller: _controller,
                onSend: currentUser != null
                    ? () => _sendMessage(currentUser.uid)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: isMe
                ? null
                : const Border.fromBorderSide(
                    BorderSide(color: AppColors.border),
                  ),
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${timestamp.hour.toString().padLeft(2, '0')}:'
                '${timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppColors.textHint,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              onSubmitted: (_) => onSend?.call(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: onSend != null ? AppColors.primary : AppColors.textHint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
