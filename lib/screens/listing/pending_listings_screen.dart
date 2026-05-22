import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/product_service.dart';

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
              Text('Admin access required.',
                  style: TextStyle(
                      fontSize: 16, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Post Requests',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load: $e',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
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
                  Icon(Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.success.withValues(alpha: 0.7)),
                  const SizedBox(height: 16),
                  const Text(
                    'All caught up!\nNo posts pending review.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 15),
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
      await ProductService()
          .updateProductStatus(widget.product.productId, newStatus);
      widget.onRefresh();
      if (mounted) {
        final label =
            newStatus == 'Available' ? 'Approved ✓' : 'Rejected ✗';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Listing "$label"'),
          backgroundColor: newStatus == 'Available'
              ? AppColors.success
              : AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: confirmColor),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Seller row ─────────────────────────────────────────────
          _SellerRow(
            sellerId: product.sellerId,
            sellerAsync: sellerAsync,
          ),

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
                              color: AppColors.error),
                        )
                      : const Icon(Icons.image_outlined,
                          color: AppColors.primary, size: 32),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _Badge(
                              label: product.category,
                              color: AppColors.primary),
                          _Badge(
                            label:
                                'JD ${product.price.toStringAsFixed(2)}',
                            color: AppColors.accent,
                          ),
                          if (product.courseCode != null &&
                              product.courseCode!.isNotEmpty)
                            _Badge(
                                label: product.courseCode!,
                                color: AppColors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
                // Preview button
                IconButton(
                  tooltip: 'Preview post',
                  icon: const Icon(Icons.open_in_new_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.listingDetail,
                      arguments: product.productId),
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
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
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
                          onConfirm: () => _updateStatus('Rejected'),
                        ),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.error, size: 18),
                        label: const Text('Reject',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const VerticalDivider(
                        width: 1, color: AppColors.divider),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _confirmAction(
                          context,
                          title: 'Approve Listing',
                          message:
                              'This listing will become visible to all students.',
                          confirmLabel: 'Approve',
                          confirmColor: AppColors.success,
                          onConfirm: () => _updateStatus('Available'),
                        ),
                        icon: const Icon(Icons.check_rounded,
                            color: AppColors.success, size: 18),
                        label: const Text('Approve',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12)),
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
      onTap: () => Navigator.of(context)
          .pushNamed(AppRoutes.sellerProfile, arguments: sellerId),
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: sellerAsync.when(
          loading: () => const Row(
            children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Loading seller...',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          error: (_, __) => const Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: AppColors.error),
              SizedBox(width: 8),
              Text('Unknown seller',
                  style: TextStyle(color: AppColors.error, fontSize: 13)),
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
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        seller?.email ?? '',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Tap hint
                const Row(
                  children: [
                    Text('View profile',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.primary),
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
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}
