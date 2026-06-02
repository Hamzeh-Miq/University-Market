import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_text_styles.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/subscription_gate.dart';

/// Shows the current user's favourite listings.
class FavouriteListingsScreen extends ConsumerWidget {
  const FavouriteListingsScreen({super.key});

  Future<void> _contactSeller(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null || product.sellerId == currentUser.uid) return;

    final isAdmin = ref.read(isAdminProvider);
    final isSubscribed = ref.read(hasActiveSubscriptionProvider);
    if (!isAdmin && !isSubscribed) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SubscriptionGate(
          featureLabel: 'messaging sellers',
          child: SizedBox.shrink(),
        ),
      );
      return;
    }

    try {
      final conversationId = await ref
          .read(chatServiceProvider)
          .getOrCreateConversation(
            buyerId: currentUser.uid,
            sellerId: product.sellerId,
            productId: product.productId,
            productTitle: product.title,
          );
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamed(AppRoutes.chatDetail, arguments: conversationId);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open chat. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(favoriteProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Favourite Posts', style: AppTextStyles.heading3),
      ),
      body: productsAsync.when(
        loading: () => const _FavouriteLoadingList(),
        error: (_, __) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load favourites',
          subtitle: 'Please try again in a moment.',
          action: FilledButton(
            onPressed: () => ref.invalidate(favoriteProductsProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No favourite posts yet',
              subtitle: 'Save items you want to buy and they will appear here.',
              action: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.allListings),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Browse listings'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return _FavouriteListingTile(
                product: product,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.listingDetail,
                  arguments: product.productId,
                ),
                onRemove: () {
                  ref
                      .read(watchlistProvider.notifier)
                      .toggleItem(product.productId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from favourites.')),
                  );
                },
                onContact: () => _contactSeller(context, ref, product),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavouriteListingTile extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onContact;

  const _FavouriteListingTile({
    required this.product,
    required this.onTap,
    required this.onRemove,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final isOwner = product.sellerId == currentUser?.uid;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _FavouriteThumbnail(product: product),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'JD ${product.effectivePrice.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(
                          color: product.hasDiscount
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove from favourites',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isOwner ? null : onContact,
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(isOwner ? 'Your post' : 'Contact'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteThumbnail extends StatelessWidget {
  final ProductModel product;

  const _FavouriteThumbnail({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: product.images.isNotEmpty
          ? Image.network(
              product.images.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textHint,
              ),
            )
          : const Icon(
              Icons.image_outlined,
              color: AppColors.primary,
              size: 34,
            ),
    );
  }
}

class _FavouriteLoadingList extends StatelessWidget {
  const _FavouriteLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            LoadingPlaceholder(height: 82, width: 82, borderRadius: 14),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingPlaceholder(height: 16, borderRadius: 6),
                  SizedBox(height: 10),
                  LoadingPlaceholder(height: 12, width: 140, borderRadius: 6),
                  SizedBox(height: 10),
                  LoadingPlaceholder(height: 18, width: 90, borderRadius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
