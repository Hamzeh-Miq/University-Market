import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_text_styles.dart';
import '../../models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

/// Shows all active conversations for the current user.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final isAdmin = ref.watch(isAdminProvider);
    final cs = Theme.of(context).colorScheme;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Messages', style: TextStyle(color: cs.onSurface)),
          backgroundColor: cs.surface,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Please sign in to view messages.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final conversationsAsync = ref.watch(
      conversationsProvider(currentUser.uid),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(color: cs.onSurface)),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: conversationsAsync.when(
        loading: () => _buildShimmer(context),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load conversations.',
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 72,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No conversations yet.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Contact Seller" on a listing to start a conversation.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final otherUid = conv.participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => '',
              );
              return Dismissible(
                key: ValueKey(conv.conversationId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Delete Conversation'),
                      content: const Text(
                        'This will be removed from your inbox. '
                        'The other user will still see it.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  try {
                    await ref
                        .read(chatServiceProvider)
                        .softDeleteConversation(
                          conv.conversationId,
                          currentUser.uid,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Conversation removed from inbox'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not remove the conversation.'),
                        ),
                      );
                    }
                  }
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: Colors.white, size: 26),
                      SizedBox(height: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                child: _ConversationTile(
                  conversation: conv,
                  otherUid: otherUid,
                  isAdmin: isAdmin,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF21262D) : Colors.grey.shade200,
        highlightColor: isDark ? const Color(0xFF30363D) : Colors.grey.shade100,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF21262D) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// A single conversation list tile that shows the other user's
/// name (and for admins, email + phone), the product title, and
/// the last message preview.
class _ConversationTile extends ConsumerWidget {
  final ConversationModel conversation;
  final String otherUid;
  final bool isAdmin;

  const _ConversationTile({
    required this.conversation,
    required this.otherUid,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(otherUserInfoProvider((otherUid, isAdmin)));
    final canViewOtherProfiles = ref.watch(canViewOtherProfilesProvider);
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.chatDetail,
          arguments: conversation.conversationId,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar — tap to view profile
              GestureDetector(
                onTap: otherUid.isNotEmpty && canViewOtherProfiles
                    ? () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.sellerProfile, arguments: otherUid)
                    : null,
                child: userInfoAsync.when(
                  data: (info) => CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      (info['name'] ?? 'U').isNotEmpty
                          ? info['name']![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  loading: () => const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primaryLight,
                  ),
                  error: (_, __) =>
                      const CircleAvatar(radius: 26, child: Icon(Icons.person)),
                ),
              ),
              const SizedBox(width: 14),

              // Text content
              Expanded(
                child: userInfoAsync.when(
                  data: (info) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        info['name'] ?? 'Unknown',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Admin-only: email + phone
                      if (isAdmin && (info['email']?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${info['email']} · ${info['phone'] ?? ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Product title
                      if (conversation.productTitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '📦 ${conversation.productTitle}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Last message
                      if (conversation.lastMessage.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          conversation.lastMessage,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  loading: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        color: cs.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 80,
                        color: cs.surfaceContainerHighest,
                      ),
                    ],
                  ),
                  error: (_, __) => const Text('Unknown'),
                ),
              ),

              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
