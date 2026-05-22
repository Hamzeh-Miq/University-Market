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
        .map((s) => s.docs
            .map((d) => ReviewModel.fromJson(d.data(), d.id))
            .toList());
  }

  /// Returns true if [reviewerId] has already reviewed [revieweeId].
  Future<bool> hasReviewed({
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
      return result.docs.isNotEmpty;
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to check review: $e'), st);
    }
  }

  /// Submits a review and updates the reviewee's aggregated rating in their
  /// user document atomically.
  Future<void> submitReview(ReviewModel review) async {
    try {
      // Use a transaction to keep rating + reviewCount consistent
      await _db.runTransaction((tx) async {
        final userRef =
            _db.collection('users').doc(review.revieweeId);
        final userSnap = await tx.get(userRef);

        final currentRating =
            (userSnap.data()?['rating'] ?? 0.0).toDouble();
        final currentCount =
            (userSnap.data()?['reviewCount'] ?? 0) as int;

        final newCount = currentCount + 1;
        final newRating =
            ((currentRating * currentCount) + review.rating) / newCount;

        final reviewRef = _db.collection('reviews').doc();
        tx.set(reviewRef, review.toJson());
        tx.update(userRef, {
          'rating': newRating,
          'reviewCount': newCount,
        });
      });
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to submit review: $e'), st);
    }
  }
}
