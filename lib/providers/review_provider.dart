import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

/// Singleton [ReviewService] provider.
final reviewServiceProvider =
    Provider<ReviewService>((ref) => ReviewService());

/// Real-time stream of all reviews for a given [revieweeId].
final reviewsProvider =
    StreamProvider.autoDispose.family<List<ReviewModel>, String>(
  (ref, revieweeId) =>
      ref.watch(reviewServiceProvider).watchReviews(revieweeId),
);

/// Whether the current reviewer has already reviewed the given reviewee.
/// Args: (reviewerId, revieweeId).
final hasReviewedProvider =
    FutureProvider.autoDispose.family<bool, (String, String)>(
  (ref, args) => ref
      .watch(reviewServiceProvider)
      .hasReviewed(reviewerId: args.$1, revieweeId: args.$2),
);
