import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
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
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading listing: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Listing not found.'));
          }

          final isOwner = product.sellerId == currentUser?.uid;

          return CustomScrollView(
            slivers: [
              // ── Image header ─────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (!isOwner && !isAdmin && currentUser != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: Colors.white),
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
                              Icon(Icons.flag_outlined,
                                  color: AppColors.error, size: 20),
                              SizedBox(width: 10),
                              Text('Report this listing',
                                  style: TextStyle(
                                      color: AppColors.error)),
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
                              colors: [AppColors.primary, AppColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_outlined, size: 80, color: Colors.white54),
                          ),
                        )
                      : PageView.builder(
                          itemCount: product.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              product.images[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: AppColors.background,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.background,
                                child: const Center(child: Icon(Icons.error, color: AppColors.error)),
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
                            label: product.status,
                            color: product.status == 'Available'
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Title ──────────────────────────────────────
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Price ──────────────────────────────────────
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Seller info ────────────────────────────────
                      _SellerCard(sellerId: product.sellerId),
                      const SizedBox(height: 28),

                      // ── CTA ────────────────────────────────────────
                      if (isAdmin) ...[
                        if (product.status == 'Pending') ...[
                          FilledButton.icon(
                            onPressed: () async {
                              await ref.read(productServiceProvider).updateProductStatus(product.productId, 'Available');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing approved')));
                              }
                              ref.invalidate(singleProductProvider(productId));
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                            label: const Text('Approve Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: const Text('Delete Listing'),
                                content: const Text(
                                    'Are you sure you want to permanently delete this listing?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.error),
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
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          label: const Text('Delete Listing',
                              style: TextStyle(color: AppColors.error)),
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
                                  SnackBar(
                                      content: Text(
                                          'Error opening chat: $e')),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline,
                              color: Colors.white),
                          label: const Text(
                            'Contact Seller',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
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
                                    SnackBar(
                                        content: Text(
                                            'Error opening chat: $e')),
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: Colors.white),
                            label: const Text(
                              'Contact Seller',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          const SubscriptionGate(
                            featureLabel: 'messaging sellers',
                            child: SizedBox.shrink(),
                          )
                      else
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: const Text('Delete Listing'),
                                content: const Text(
                                    'Are you sure you want to delete this listing? This cannot be undone.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.error),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Listing deleted.')),
                                  );
                                  Navigator.of(context).pop();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          label: const Text('Delete Listing',
                              style: TextStyle(color: AppColors.error)),
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
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Fetches and displays seller info from Firestore.
class _SellerCard extends StatefulWidget {
  final String sellerId;
  const _SellerCard({required this.sellerId});

  @override
  State<_SellerCard> createState() => _SellerCardState();
}

class _SellerCardState extends State<_SellerCard> {
  UserModel? _seller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSeller();
  }

  Future<void> _loadSeller() async {
    try {
      final seller = await UserService().getUserProfile(widget.sellerId);
      if (mounted) setState(() { _seller = seller; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.sellerProfile,
        arguments: widget.sellerId,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border.fromBorderSide(
              BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                _seller?.fullName.isNotEmpty == true
                    ? _seller!.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            if (_loading)
              const CircularProgressIndicator(strokeWidth: 2)
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _seller?.fullName ?? 'Unknown Seller',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _seller?.rating.toStringAsFixed(1) ?? '0.0',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '· Tap to view profile & review',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
