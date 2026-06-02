import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Canonical product status values stored for listings.
class ProductStatus {
  ProductStatus._();

  /// Waiting for admin approval before becoming public.
  static const String pending = 'pending';

  /// Visible to all marketplace users.
  static const String published = 'published';

  /// Sold by the post owner or admin and removed from public listings.
  static const String sold = 'sold';

  /// Legacy value used by older documents for pending posts.
  static const String legacyPending = 'Pending';

  /// Legacy value used by older documents for public posts.
  static const String legacyAvailable = 'Available';

  /// Legacy value used by older documents for sold posts.
  static const String legacySold = 'Sold';

  /// Legacy value used by older rejected documents.
  static const String legacyRejected = 'Rejected';

  /// Status values that should appear in public listing queries.
  static const List<String> publicStatuses = [published, legacyAvailable];

  /// Status values that should appear in pending approval queries.
  static const List<String> pendingStatuses = [pending, legacyPending];

  /// Status values that should count as sold.
  static const List<String> soldStatuses = [sold, legacySold];

  /// Converts older Firestore values into the canonical values used by UI.
  static String normalize(String status) {
    switch (status) {
      case legacyPending:
        return pending;
      case legacyAvailable:
        return published;
      case legacySold:
        return sold;
      default:
        return status;
    }
  }

  /// Human-readable status label for chips and cards.
  static String label(String status) {
    switch (normalize(status)) {
      case pending:
        return 'Pending';
      case published:
        return 'Published';
      case sold:
        return 'Sold';
      case legacyRejected:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  /// Visual color associated with a product status.
  static Color color(String status) {
    switch (normalize(status)) {
      case pending:
        return AppColors.warning;
      case published:
        return AppColors.success;
      case sold:
        return AppColors.primary;
      case legacyRejected:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Whether this status is waiting for admin review.
  static bool isPending(String status) => normalize(status) == pending;

  /// Whether this status is publicly visible.
  static bool isPublished(String status) => normalize(status) == published;

  /// Whether this status has been marked sold.
  static bool isSold(String status) => normalize(status) == sold;
}
