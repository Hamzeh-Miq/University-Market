/// Subscription-related constants for UniSooq.
class SubscriptionConstants {
  SubscriptionConstants._();

  /// Duration of the annual subscription in days.
  static const int subscriptionDays = 365;

  /// Short user-facing label for the subscription duration.
  static const String subscriptionDurationLabel = '1 year';

  /// Number of listings shown to non-subscribed users as a free preview.
  static const int freePreviewLimit = 6;

  /// Display price of the annual subscription (shown in UI only — not real).
  static const String subscriptionPriceDisplay = 'JD 5.00';

  /// Numeric price for display purposes.
  static const double subscriptionPrice = 5.00;
}
