import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/review_provider.dart';
import '../../services/review_service.dart';
import '../../widgets/report_dialog.dart';

/// Public profile view — shows any user's info, listings, and reviews.
/// Also allows the logged-in user to leave a review (once per person).
class SellerProfileScreen extends ConsumerWidget {
  final String uid;

  const SellerProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProfileProvider(uid));
    final listingsAsync = ref.watch(myListingsProvider(uid));
    final reviewsAsync = ref.watch(reviewsProvider(uid));
    final currentUser = ref.watch(authStateProvider).value;
    final isOwnProfile = currentUser?.uid == uid;

    return sellerAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text('Error loading profile: $e')),
      ),
      data: (seller) {
        final name = seller?.fullName.isNotEmpty == true
            ? seller!.fullName
            : 'Unknown User';
        final email = seller?.email ?? '—';
        final phone = seller?.phoneNumber ?? '—';
        final university = seller?.university ?? '—';
        final isAdmin = seller?.role == 'admin';
        final rating = seller?.rating ?? 0.0;
        final reviewCount = seller?.reviewCount ?? 0;

        final initials = name
            .trim()
            .split(' ')
            .where((p) => p.isNotEmpty)
            .map((p) => p[0].toUpperCase())
            .take(2)
            .join();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── Hero Header ───────────────────────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (!isOwnProfile && currentUser != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'report') {
                          showReportDialog(
                            context,
                            ref,
                            reporterId: currentUser.uid,
                            targetType: 'user',
                            targetId: uid,
                            targetName: name,
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
                              Text('Report this user',
                                  style:
                                      TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 56),
                        // Avatar
                        CircleAvatar(
                          radius: 44,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.25),
                          child: Text(
                            initials.isEmpty ? '?' : initials,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Name + admin badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shield_rounded,
                                        size: 11, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        // Rating row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFF59E0B), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($reviewCount review${reviewCount == 1 ? '' : 's'})',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Contact Info ──────────────────────────────
                      _InfoCard(items: [
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: phone.isNotEmpty && phone != '—'
                              ? phone
                              : 'Not provided',
                        ),
                        _InfoRow(
                          icon: Icons.school_outlined,
                          label: 'University',
                          value: university,
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // ── Leave a Review ────────────────────────────
                      if (!isOwnProfile && currentUser != null)
                        _ReviewSection(
                          revieweeId: uid,
                          revieweeName: name,
                          reviewerId: currentUser.uid,
                        ),

                      // ── Reviews list ──────────────────────────────
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      reviewsAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
                        error: (e, _) => Text('Error loading reviews: $e',
                            style: const TextStyle(
                                color: AppColors.error)),
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return _EmptyCard(
                                message: 'No reviews yet.');
                          }
                          return Column(
                            children: reviews
                                .map((r) => _ReviewTile(review: r))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Listings ──────────────────────────────────
                      const Text(
                        "Seller's Listings",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      listingsAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
                        error: (e, _) => Text('Error: $e',
                            style: const TextStyle(
                                color: AppColors.error)),
                        data: (listings) {
                          if (listings.isEmpty) {
                            return _EmptyCard(
                                message: 'No listings posted yet.');
                          }
                          return Column(
                            children: listings
                                .map((p) => _ListingTile(product: p))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Review submission section ─────────────────────────────────────────────────

class _ReviewSection extends ConsumerStatefulWidget {
  final String revieweeId;
  final String revieweeName;
  final String reviewerId;

  const _ReviewSection({
    required this.revieweeId,
    required this.revieweeName,
    required this.reviewerId,
  });

  @override
  ConsumerState<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<_ReviewSection> {
  int _selectedStars = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final review = ReviewModel(
        reviewId: '',
        reviewerId: widget.reviewerId,
        revieweeId: widget.revieweeId,
        productId: '',
        rating: _selectedStars,
        comment: _commentCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await ReviewService().submitReview(review);

      // Refresh both the reviews list and the seller profile
      ref.invalidate(reviewsProvider(widget.revieweeId));
      ref.invalidate(sellerProfileProvider(widget.revieweeId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted! ✓'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedStars = 0;
          _commentCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReviewedAsync = ref.watch(
        hasReviewedProvider((widget.reviewerId, widget.revieweeId)));

    return hasReviewedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (alreadyReviewed) {
        if (alreadyReviewed) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'You have already reviewed this user.',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave a Review',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Star picker
                  Row(
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedStars = star),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            star <= _selectedStars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: star <= _selectedStars
                                ? const Color(0xFFF59E0B)
                                : AppColors.textHint,
                            size: 34,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Comment field
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText:
                          'Share your experience with ${widget.revieweeName.split(' ').first}…',
                      hintStyle:
                          const TextStyle(color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Submit Review',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ── Review tile ───────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < review.rating
                        ? const Color(0xFFF59E0B)
                        : AppColors.textHint,
                    size: 16,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items
            .map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(row.icon, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.label,
                              style: const TextStyle(
                                  color: AppColors.textHint, fontSize: 11)),
                          Text(row.value,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
}

// ── Empty state card ─────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

// ── Listing tile ──────────────────────────────────────────────────────────────

class _ListingTile extends StatelessWidget {
  final ProductModel product;
  const _ListingTile({required this.product});

  Color get _statusColor {
    switch (product.status) {
      case 'Available':
        return AppColors.success;
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRoutes.listingDetail, arguments: product.productId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: product.images.isNotEmpty
                  ? Image.network(product.images.first, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.error,
                          ))
                  : const Icon(Icons.image_outlined,
                      color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    'JD ${product.price.toStringAsFixed(2)} · ${product.category}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.status,
                style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
