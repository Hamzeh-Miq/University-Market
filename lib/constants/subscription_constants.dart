/// Subscription-related constants for UniTrade.
class SubscriptionConstants {
  SubscriptionConstants._();

  /// Duration of the annual subscription in days.
  static const int subscriptionDays = 365;

  /// Number of listings shown to non-subscribed users as a free preview.
  static const int freePreviewLimit = 6;

  /// Display price of the annual subscription (shown in UI only — not real).
  static const String subscriptionPriceDisplay = 'JD 5.00';

  /// Numeric price for display purposes.
  static const double subscriptionPrice = 5.00;
}
