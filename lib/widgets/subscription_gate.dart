import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../providers/auth_provider.dart';

/// Wraps [child] behind a subscription paywall.
///
/// If the current user has an active subscription the [child] is rendered
/// normally.  Otherwise a locked placeholder is shown.  The optional
/// [fullPage] flag makes the gate fill the entire screen (useful for screens
/// like Add Listing where the whole page should be gated).
class SubscriptionGate extends ConsumerWidget {
  /// The widget to show when the user IS subscribed.
  final Widget child;

  /// Short label for the locked feature, e.g. "filters" or "messaging".
  final String featureLabel;

  /// When true the gate placeholder fills available space rather than being
  /// an inline card.
  final bool fullPage;

  const SubscriptionGate({
    super.key,
    required this.child,
    required this.featureLabel,
    this.fullPage = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubscribed = ref.watch(hasActiveSubscriptionProvider);

    if (isSubscribed) return child;

    return fullPage
        ? _FullPageGate(featureLabel: featureLabel)
        : _InlineGate(featureLabel: featureLabel);
  }
}

/// Inline locked card — replaces a specific widget in a layout.
class _InlineGate extends StatelessWidget {
  final String featureLabel;
  const _InlineGate({required this.featureLabel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSubscriptionSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Subscribe to unlock $featureLabel',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Full-page gate — used when an entire screen is locked.
class _FullPageGate extends StatelessWidget {
  final String featureLabel;
  const _FullPageGate({required this.featureLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 28),
            const Text(
              'Subscription Required',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Unlock $featureLabel and everything UniTrade has to offer with a semester subscription.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.payment),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.credit_card_rounded),
                label: const Text(
                  'Subscribe Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the subscription detail bottom sheet.
void _showSubscriptionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SubscriptionSheet(),
  );
}

class _SubscriptionSheet extends StatelessWidget {
  const _SubscriptionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon + title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'UniTrade Semester Pass',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '4 months · Full access to the campus marketplace',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Feature list
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    f,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // CTA
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.payment);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.credit_card_rounded),
              label: const Text(
                'Subscribe Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Maybe Later'),
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _features = [
  'Browse the full listings catalogue',
  'Filter by category, price & course code',
  'Message sellers directly',
  'Post your own listings',
  'Access your watchlist',
];
