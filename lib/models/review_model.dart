import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a profile review left by one user for another.
class ReviewModel {
  /// Firestore document id of the review.
  final String reviewId;

  /// UID of the user who wrote the review.
  final String reviewerId;

  /// Display name of the reviewer saved for easier rendering.
  final String reviewerName;

  /// UID of the user being reviewed.
  final String revieweeId;

  /// Optional product id related to the review.
  final String productId;

  /// Rating value from 1 to 5.
  final int rating;

  /// Required free-text review body.
  final String comment;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last edit timestamp, when the review has been updated.
  final DateTime? updatedAt;

  ReviewModel({
    required this.reviewId,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  /// Builds a [ReviewModel] from Firestore json.
  factory ReviewModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ReviewModel(
      reviewId: documentId,
      reviewerId: json['reviewerId'] ?? '',
      reviewerName: json['reviewerName'] ?? '',
      revieweeId: json['revieweeId'] ?? '',
      productId: json['productId'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Serializes the review for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'revieweeId': revieweeId,
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Returns true when this review has been edited after creation.
  bool get isEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  /// Creates a copy of this review with selected fields changed.
  ReviewModel copyWith({
    String? reviewId,
    String? reviewerId,
    String? reviewerName,
    String? revieweeId,
    String? productId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      revieweeId: revieweeId ?? this.revieweeId,
      productId: productId ?? this.productId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
