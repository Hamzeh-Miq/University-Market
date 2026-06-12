import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/product_status.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/report_dialog.dart';
import '../../widgets/subscription_gate.dart';

/// Subscriber-only profile view for other users.
/// Also allows the logged-in user to manage their own review.
class SellerProfileScreen extends ConsumerWidget {
  final String uid;

  const SellerProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final currentUserModel = ref.watch(currentUserModelProvider).value;
    final canViewOtherProfiles = ref.watch(canViewOtherProfilesProvider);
    final isOwnProfile = currentUser?.uid == uid;
    final canAccessProfile = isOwnProfile || canViewOtherProfiles;

    if (!canAccessProfile) {
      return const Scaffold(
        body: SubscriptionGate(
          featureLabel: 'member profiles',
          fullPage: true,
          child: SizedBox.shrink(),
        ),
      );
    }

    final sellerAsync = ref.watch(sellerProfileProvider(uid));
    final listingsAsync = ref.watch(myListingsProvider(uid));
    final reviewsAsync = ref.watch(reviewsProvider(uid));

    return sellerAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Failed to load profile.')),
      ),
      data: (seller) {
        final name = seller?.fullName.isNotEmpty == true
            ? seller!.fullName
            : 'Unknown User';
        final email = seller?.email ?? '-';
        final phone = seller?.phoneNumber ?? '-';
        final university = seller?.university ?? '-';
        final isAdmin = seller?.role == 'admin';
        final rating = seller?.rating ?? 0.0;
        final reviewCount = seller?.reviewCount ?? 0;

        final initials = name
            .trim()
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0].toUpperCase())
            .take(2)
            .join();

        final reviewerName = currentUserModel?.fullName.isNotEmpty == true
            ? currentUserModel!.fullName
            : currentUser?.displayName ??
                  currentUser?.email?.split('@').first ??
                  'Anonymous User';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
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
                              Icon(
                                Icons.flag_outlined,
                                color: AppColors.error,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Report this user',
                                style: TextStyle(color: AppColors.error),
                              ),
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
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
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
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shield_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($reviewCount review${reviewCount == 1 ? '' : 's'})',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
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
                      _InfoCard(
                        items: [
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: phone.isNotEmpty && phone != '-'
                                ? phone
                                : 'Not provided',
                          ),
                          _InfoRow(
                            icon: Icons.school_outlined,
                            label: 'University',
                            value: university,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (!isOwnProfile && currentUser != null)
                        _ReviewSection(
                          revieweeId: uid,
                          revieweeName: name,
                          reviewerId: currentUser.uid,
                          reviewerName: reviewerName,
                        ),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (error, _) => const Text(
                          'Failed to load reviews.',
                          style: TextStyle(color: AppColors.error),
                        ),
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return const _EmptyCard(message: 'No reviews yet.');
                          }

                          return Column(
                            children: reviews
                                .map(
                                  (review) => _ReviewTile(
                                    review: review,
                                    ref: ref,
                                    canReportReview:
                                        isOwnProfile && currentUser != null,
                                    reporterId: currentUser?.uid,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (error, _) => const Text(
                          'Failed to load listings.',
                          style: TextStyle(color: AppColors.error),
                        ),
                        data: (listings) {
                          if (listings.isEmpty) {
                            return const _EmptyCard(
                              message: 'No listings posted yet.',
                            );
                          }

                          return Column(
                            children: listings
                                .map(
                                  (product) => _ListingTile(product: product),
                                )
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

class _ReviewSection extends ConsumerStatefulWidget {
  final String revieweeId;
  final String revieweeName;
  final String reviewerId;
  final String reviewerName;

  const _ReviewSection({
    required this.revieweeId,
    required this.revieweeName,
    required this.reviewerId,
    required this.reviewerName,
  });

  @override
  ConsumerState<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<_ReviewSection> {
  final TextEditingController _commentCtrl = TextEditingController();
  int _selectedStars = 0;
  bool _submitting = false;
  String? _seededReviewId;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _seedFromReview(ReviewModel? review) {
    final nextId = review?.reviewId;
    if (_seededReviewId == nextId) {
      return;
    }

    _seededReviewId = nextId;
    _selectedStars = review?.rating ?? 0;
    _commentCtrl.text = review?.comment ?? '';
  }

  Future<void> _saveReview(ReviewModel? existingReview) async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    final trimmedComment = _commentCtrl.text.trim();
    if (trimmedComment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review text is required.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final review = ReviewModel(
        reviewId: existingReview?.reviewId ?? '',
        reviewerId: widget.reviewerId,
        reviewerName: widget.reviewerName,
        revieweeId: widget.revieweeId,
        productId: existingReview?.productId ?? '',
        rating: _selectedStars,
        comment: trimmedComment,
        createdAt: existingReview?.createdAt ?? DateTime.now(),
        updatedAt: existingReview == null ? null : DateTime.now(),
      );

      if (existingReview == null) {
        await ref.read(reviewServiceProvider).submitReview(review);
      } else {
        await ref.read(reviewServiceProvider).updateReview(review);
      }

      ref.invalidate(reviewsProvider(widget.revieweeId));
      ref.invalidate(
        reviewerReviewProvider((widget.reviewerId, widget.revieweeId)),
      );
      ref.invalidate(sellerProfileProvider(widget.revieweeId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingReview == null ? 'Review submitted.' : 'Review updated.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your review. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(reviewServiceProvider)
          .deleteReview(
            reviewId: review.reviewId,
            expectedReviewerId: widget.reviewerId,
          );

      ref.invalidate(reviewsProvider(widget.revieweeId));
      ref.invalidate(
        reviewerReviewProvider((widget.reviewerId, widget.revieweeId)),
      );
      ref.invalidate(sellerProfileProvider(widget.revieweeId));

      if (mounted) {
        setState(() {
          _seededReviewId = null;
          _selectedStars = 0;
          _commentCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete your review. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingReviewAsync = ref.watch(
      reviewerReviewProvider((widget.reviewerId, widget.revieweeId)),
    );

    return existingReviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (existingReview) {
        _seedFromReview(existingReview);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existingReview == null ? 'Leave a Review' : 'Your Review',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (existingReview != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Text(
                        'You can edit or delete the review you already left for this user.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Row(
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStars = star),
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
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: 'Review text',
                      hintText:
                          'Share your experience with ${widget.revieweeName.split(' ').first}...',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      filled: true,
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
                      onPressed: _submitting
                          ? null
                          : () => _saveReview(existingReview),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              existingReview == null
                                  ? 'Submit Review'
                                  : 'Update Review',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (existingReview != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => _deleteReview(existingReview),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete Review',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
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

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final WidgetRef ref;
  final bool canReportReview;
  final String? reporterId;

  const _ReviewTile({
    required this.review,
    required this.ref,
    required this.canReportReview,
    required this.reporterId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName.isEmpty
                          ? 'Anonymous user'
                          : review.reviewerName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: index < review.rating
                              ? const Color(0xFFF59E0B)
                              : AppColors.textHint,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(review.updatedAt ?? review.createdAt),
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                  if (review.isEdited)
                    const Text(
                      'Edited',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              if (canReportReview && reporterId != null) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'report') {
                      showReportDialog(
                        context,
                        ref,
                        reporterId: reporterId!,
                        targetType: 'review',
                        targetId: review.reviewId,
                        targetName: 'Review by ${review.reviewerName}',
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'report',
                      child: Text('Report review'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: items
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(row.icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            row.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final ProductModel product;

  const _ListingTile({required this.product});

  Color get _statusColor => ProductStatus.color(product.status);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.listingDetail, arguments: product.productId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                      size: 28,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JD ${product.price.toStringAsFixed(2)} · ${product.category}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ProductStatus.label(product.status),
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
