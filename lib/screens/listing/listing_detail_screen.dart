import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/product_status.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/subscription_gate.dart';
import '../../widgets/report_dialog.dart';

/// Detailed view of a single product listing.
class ListingDetailScreen extends ConsumerWidget {
  final String productId;

  const ListingDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(singleProductProvider(productId));
    final currentUser = ref.watch(authStateProvider).value;
    final userModel = ref.watch(currentUserModelProvider).value;
    final isAdmin = userModel?.role == 'admin';
    final isSubscribed = ref.watch(hasActiveSubscriptionProvider);

    return Scaffold(
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text(
            'Failed to load listing.',
            style: TextStyle(color: AppColors.error),
          ),
        ),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Listing not found.'));
          }

          final isOwner = product.sellerId == currentUser?.uid;
          final isFavourite = ref.watch(
            watchlistProvider.select((ids) => ids.contains(product.productId)),
          );

          Future<void> markSold() async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Mark as Sold'),
                content: const Text(
                  'This will remove the listing from public posts and count it in sold item rankings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Mark Sold'),
                  ),
                ],
              ),
            );

            if (confirmed != true || !context.mounted) return;

            try {
              await ref
                  .read(productServiceProvider)
                  .markProductAsSold(
                    product.productId,
                    sellerUniversity: product.sellerUniversity,
                  );
              ref.invalidate(singleProductProvider(productId));
              ref.invalidate(productListProvider);
              ref.invalidate(soldStatisticsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Listing marked as sold.'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.of(context).pop();
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not mark listing sold.')),
                );
              }
            }
          }

          return CustomScrollView(
            slivers: [
              // ── Image header ─────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (!isOwner && currentUser != null)
                    IconButton(
                      tooltip: isFavourite
                          ? 'Remove from favourites'
                          : 'Add to favourites',
                      onPressed: () => ref
                          .read(watchlistProvider.notifier)
                          .toggleItem(product.productId),
                      icon: Icon(
                        isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: Colors.white,
                      ),
                    ),
                  if (!isOwner && !isAdmin && currentUser != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'report') {
                          showReportDialog(
                            context,
                            ref,
                            reporterId: currentUser.uid,
                            targetType: 'product',
                            targetId: product.productId,
                            targetName: product.title,
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                color: AppColors.error,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Report this listing',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: product.images.isEmpty
                      ? Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 80,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : PageView.builder(
                          itemCount: product.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              product.images[index],
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    child: const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                            );
                          },
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Chips row ──────────────────────────────────
                      Row(
                        children: [
                          _Chip(
                            label: product.category,
                            color: AppColors.primary,
                          ),
                          if (product.courseCode != null &&
                              product.courseCode!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _Chip(
                              label: product.courseCode!,
                              color: AppColors.accent,
                            ),
                          ],
                          const Spacer(),
                          _Chip(
                            label: ProductStatus.label(product.status),
                            color: ProductStatus.color(product.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Title ──────────────────────────────────────
                      Text(
                        product.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Price ──────────────────────────────────────────────
                      if (product.hasDiscount) ...[
                        // Discounted price row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'JD ${product.discountedPrice!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'JD ${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textHint,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.textHint,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${product.discountPercent}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          'JD ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      const SizedBox(height: 18),

                      // ── Description ────────────────────────────────
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Seller info ────────────────────────────────
                      _SellerCard(sellerId: product.sellerId),
                      const SizedBox(height: 28),

                      // ── CTA ────────────────────────────────────────
                      if (isAdmin && !isOwner) ...[
                        if (ProductStatus.isPending(product.status)) ...[
                          FilledButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(productServiceProvider)
                                  .updateProductStatus(
                                    product.productId,
                                    ProductStatus.published,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Listing approved'),
                                  ),
                                );
                              }
                              ref.invalidate(singleProductProvider(productId));
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Approve Listing',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (!ProductStatus.isSold(product.status)) ...[
                          FilledButton.icon(
                            onPressed: markSold,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.sell_outlined,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Mark as Sold',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text('Delete Listing'),
                                content: const Text(
                                  'Are you sure you want to permanently delete this listing?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              await ref
                                  .read(productServiceProvider)
                                  .deleteProduct(product.productId);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          label: const Text(
                            'Delete Listing',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Admin can also open a chat with the seller
                        FilledButton.icon(
                          onPressed: () async {
                            if (currentUser == null) return;
                            try {
                              final convId = await ref
                                  .read(chatServiceProvider)
                                  .getOrCreateConversation(
                                    buyerId: currentUser.uid,
                                    sellerId: product.sellerId,
                                    productId: product.productId,
                                    productTitle: product.title,
                                  );
                              if (context.mounted) {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.chatDetail,
                                  arguments: convId,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Failed to open chat. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Contact Seller',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (!isOwner)
                        // Non-owner: gate messaging behind subscription
                        if (isAdmin || isSubscribed)
                          FilledButton.icon(
                            onPressed: () async {
                              if (currentUser == null) return;
                              try {
                                final convId = await ref
                                    .read(chatServiceProvider)
                                    .getOrCreateConversation(
                                      buyerId: currentUser.uid,
                                      sellerId: product.sellerId,
                                      productId: product.productId,
                                      productTitle: product.title,
                                    );
                                if (context.mounted) {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.chatDetail,
                                    arguments: convId,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to open chat. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Contact Seller',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const SubscriptionGate(
                            featureLabel: 'messaging sellers',
                            child: SizedBox.shrink(),
                          )
                      else
                        // ── Owner CTAs: Edit + Delete ───────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!ProductStatus.isSold(product.status)) ...[
                              FilledButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.editListing,
                                      arguments: product,
                                    ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Edit Listing',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: markSold,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.sell_outlined,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Mark as Sold',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Delete Listing'),
                                    content: const Text(
                                      'Are you sure you want to delete this listing? This cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && context.mounted) {
                                  try {
                                    await ref
                                        .read(productServiceProvider)
                                        .deleteProduct(product.productId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Listing deleted.'),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not delete the listing.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              label: const Text(
                                'Delete Listing',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Small colored chip label.
class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Fetches and displays seller info from providers.
class _SellerCard extends ConsumerWidget {
  final String sellerId;
  const _SellerCard({required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final canViewOtherProfiles = ref.watch(canViewOtherProfilesProvider);
    final canAccessSellerProfile =
        currentUser?.uid == sellerId || canViewOtherProfiles;

    if (!canAccessSellerProfile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: const SubscriptionGate(
          featureLabel: 'seller details',
          child: SizedBox.shrink(),
        ),
      );
    }

    final sellerAsync = ref.watch(sellerProfileProvider(sellerId));

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.sellerProfile, arguments: sellerId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: sellerAsync.when(
          loading: () => const Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 14),
              Text(
                'Loading seller...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          error: (_, __) => const Row(
            children: [
              CircleAvatar(
                radius: 26,

                child: Text(
                  '?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Unknown seller',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
          data: (seller) {
            final name = seller?.fullName ?? 'Unknown Seller';
            final rating = seller?.rating.toStringAsFixed(1) ?? '0.0';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

            return Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              '· Tap to view profile & review',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            );
          },
        ),
      ),
    );
  }
}
