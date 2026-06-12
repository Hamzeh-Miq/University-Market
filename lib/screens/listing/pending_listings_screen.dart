import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/product_status.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';

/// Admin-only screen: review pending listings, view publisher, approve or reject.
class PendingListingsScreen extends ConsumerWidget {
  const PendingListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final pendingAsync = ref.watch(pendingListingsProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.error),
              SizedBox(height: 16),
              Text('Admin access required.', style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Post Requests', style: AppTextStyles.heading3),
      ),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load pending listings.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppColors.success.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All caught up!\nNo posts pending review.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _PendingCard(
              product: listings[i],
              onRefresh: () => ref.refresh(pendingListingsProvider),
            ),
          );
        },
      ),
    );
  }
}

// ── Pending card ──────────────────────────────────────────────────────────────

class _PendingCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final VoidCallback onRefresh;

  const _PendingCard({required this.product, required this.onRefresh});

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _isActing = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isActing = true);
    try {
      await ref
          .read(productServiceProvider)
          .updateProductStatus(widget.product.productId, newStatus);
      widget.onRefresh();
      if (mounted) {
        final label = ProductStatus.isPublished(newStatus)
            ? 'Listing approved.'
            : 'Listing rejected.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(label),
            backgroundColor: ProductStatus.isPublished(newStatus)
                ? AppColors.success
                : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the listing status.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final sellerAsync = ref.watch(sellerProfileProvider(product.sellerId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.subtleBlackShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Seller row ─────────────────────────────────────────────
          _SellerRow(sellerId: product.sellerId, sellerAsync: sellerAsync),

          const Divider(height: 1, color: AppColors.divider),

          // ── Listing info ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.error,
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _Badge(
                            label: product.category,
                            color: AppColors.primary,
                          ),
                          _Badge(
                            label: 'JD ${product.price.toStringAsFixed(2)}',
                            color: AppColors.accent,
                          ),
                          if (product.courseCode != null &&
                              product.courseCode!.isNotEmpty)
                            _Badge(
                              label: product.courseCode!,
                              color: AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Preview button
                IconButton(
                  tooltip: 'Preview post',
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.listingDetail,
                    arguments: product.productId,
                  ),
                ),
              ],
            ),
          ),

          // Description preview
          if (product.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),

          // ── Action buttons ──────────────────────────────────────────
          _isActing
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _confirmAction(
                          context,
                          title: 'Reject Listing',
                          message:
                              'This listing will be hidden from the marketplace.',
                          confirmLabel: 'Reject',
                          confirmColor: AppColors.error,
                          onConfirm: () =>
                              _updateStatus(ProductStatus.legacyRejected),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        label: Text(
                          'Reject',
                          style: AppTextStyles.actionLink.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.divider),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _confirmAction(
                          context,
                          title: 'Approve Listing',
                          message:
                              'This listing will become visible to all students.',
                          confirmLabel: 'Approve',
                          confirmColor: AppColors.success,
                          onConfirm: () =>
                              _updateStatus(ProductStatus.published),
                        ),
                        icon: const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        label: Text(
                          'Approve',
                          style: AppTextStyles.actionLink.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

// ── Seller row (tappable) ─────────────────────────────────────────────────────

class _SellerRow extends StatelessWidget {
  final String sellerId;
  final AsyncValue<UserModel?> sellerAsync;

  const _SellerRow({required this.sellerId, required this.sellerAsync});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.sellerProfile, arguments: sellerId),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: sellerAsync.when(
          loading: () => Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Loading seller...',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 20,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Unknown seller',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ),
          data: (seller) {
            final name = seller?.fullName.isNotEmpty == true
                ? seller!.fullName
                : 'Unknown User';
            final isAdmin = seller?.role == 'admin';

            final initials = name
                .trim()
                .split(' ')
                .where((p) => p.isNotEmpty)
                .map((p) => p[0].toUpperCase())
                .take(2)
                .join();

            return Row(
              children: [
                // Mini avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: AppTextStyles.metadata.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: AppTextStyles.labelLarge),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: AppTextStyles.adminBadge,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(seller?.email ?? '', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                // Tap hint
                const Row(
                  children: [
                    Text('View profile', style: AppTextStyles.actionLink),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.metadata.copyWith(color: color)),
    );
  }
}
