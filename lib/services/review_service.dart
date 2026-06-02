import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

/// Handles all Firestore operations for the reviews feature.
class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches all reviews for a given [revieweeId].
  Stream<List<ReviewModel>> watchReviews(String revieweeId) {
    return _db
        .collection('reviews')
        .where('revieweeId', isEqualTo: revieweeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ReviewModel.fromJson(d.data(), d.id)).toList(),
        );
  }

  /// Returns the review left by [reviewerId] for [revieweeId], if one exists.
  Future<ReviewModel?> getReviewByReviewer({
    required String reviewerId,
    required String revieweeId,
  }) async {
    try {
      final result = await _db
          .collection('reviews')
          .where('reviewerId', isEqualTo: reviewerId)
          .where('revieweeId', isEqualTo: revieweeId)
          .limit(1)
          .get();
      if (result.docs.isEmpty) {
        return null;
      }
      final doc = result.docs.first;
      return ReviewModel.fromJson(doc.data(), doc.id);
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('Failed to fetch review: $e'), st);
    }
  }

  /// Submits a review and updates the reviewee's aggregated rating in their
  /// user document atomically.
  Future<void> submitReview(ReviewModel review) async {
    try {
      await _db.runTransaction((tx) async {
        final reviewRef = _db.collection('reviews').doc();
        tx.set(reviewRef, review.copyWith(reviewId: reviewRef.id).toJson());
        await _updateReviewSummary(
          tx: tx,
          revieweeId: review.revieweeId,
          oldRating: null,
          newRating: review.rating,
        );
      });
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('Failed to submit review: $e'), st);
    }
  }

  /// Updates an existing review and adjusts the reviewee aggregates atomically.
  Future<void> updateReview(ReviewModel review) async {
    try {
      await _db.runTransaction((tx) async {
        final reviewRef = _db.collection('reviews').doc(review.reviewId);
        final reviewSnap = await tx.get(reviewRef);
        if (!reviewSnap.exists) {
          throw Exception('Review not found.');
        }

        final existingReview = ReviewModel.fromJson(
          reviewSnap.data()!,
          reviewSnap.id,
        );

        tx.update(reviewRef, {
          'rating': review.rating,
          'comment': review.comment,
          'reviewerName': review.reviewerName,
          'updatedAt': Timestamp.fromDate(review.updatedAt ?? DateTime.now()),
        });

        await _updateReviewSummary(
          tx: tx,
          revieweeId: existingReview.revieweeId,
          oldRating: existingReview.rating,
          newRating: review.rating,
        );
      });
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('Failed to update review: $e'), st);
    }
  }

  /// Deletes a review and adjusts the reviewee aggregates atomically.
  Future<void> deleteReview({
    required String reviewId,
    String? expectedReviewerId,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final reviewRef = _db.collection('reviews').doc(reviewId);
        final reviewSnap = await tx.get(reviewRef);
        if (!reviewSnap.exists) {
          return;
        }

        final existingReview = ReviewModel.fromJson(
          reviewSnap.data()!,
          reviewSnap.id,
        );

        if (expectedReviewerId != null &&
            existingReview.reviewerId != expectedReviewerId) {
          throw Exception('You can only delete your own review.');
        }

        tx.delete(reviewRef);

        await _updateReviewSummary(
          tx: tx,
          revieweeId: existingReview.revieweeId,
          oldRating: existingReview.rating,
          newRating: null,
        );
      });
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('Failed to delete review: $e'), st);
    }
  }

  Future<void> _updateReviewSummary({
    required Transaction tx,
    required String revieweeId,
    required int? oldRating,
    required int? newRating,
  }) async {
    final userRef = _db.collection('users').doc(revieweeId);
    final userSnap = await tx.get(userRef);

    final currentRating = (userSnap.data()?['rating'] ?? 0.0).toDouble();
    final currentCount = (userSnap.data()?['reviewCount'] ?? 0) as int;
    final currentTotal = currentRating * currentCount;
    final adjustedTotal = currentTotal - (oldRating ?? 0) + (newRating ?? 0);
    final adjustedCount =
        currentCount +
        (oldRating == null ? 1 : 0) -
        (newRating == null ? 1 : 0);

    final safeCount = adjustedCount < 0 ? 0 : adjustedCount;
    final safeTotal = safeCount == 0 ? 0.0 : adjustedTotal;
    final nextRating = safeCount == 0 ? 0.0 : safeTotal / safeCount;

    tx.update(userRef, {'rating': nextRating, 'reviewCount': safeCount});
  }
}
