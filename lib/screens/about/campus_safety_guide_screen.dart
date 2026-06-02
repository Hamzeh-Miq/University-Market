import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';

/// Informational guide for safer student-to-student campus exchanges.
class CampusSafetyGuideScreen extends StatelessWidget {
  const CampusSafetyGuideScreen({super.key});

  static const List<_ExchangeZone> _zones = [
    _ExchangeZone(
      title: 'Main Library Lounge',
      description:
          'A visible, well-lit indoor space with steady student traffic and nearby staff desks.',
      icon: Icons.local_library_rounded,
      tint: Color(0xFFEAF2FF),
    ),
    _ExchangeZone(
      title: 'Student Union Cafeteria',
      description:
          'Busy throughout the day, close to service counters, and easy to find for both students.',
      icon: Icons.restaurant_rounded,
      tint: Color(0xFFEAF8F4),
    ),
    _ExchangeZone(
      title: 'Engineering Faculty Courtyard',
      description:
          'Open, high-traffic outdoor area with clear sightlines and frequent campus security rounds.',
      icon: Icons.architecture_rounded,
      tint: Color(0xFFFFF7E8),
    ),
  ];

  static const List<String> _tips = [
    'Verify item condition before paying.',
    'Keep transactions within campus grounds.',
    'Meet during active daytime campus hours.',
    'Use in-app chat history for agreement details.',
    'Avoid sharing passwords, banking codes, or private accounts.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(currentRoute: AppRoutes.aboutUs),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SafetyHeader(onBack: () => Navigator.of(context).pop()),
                    const SizedBox(height: 18),
                    const _GuidelineCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Safe Campus Exchange Zones 📍',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose visible, familiar places where other students and staff are nearby.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: _zones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _ExchangeZoneTile(zone: _zones[index]);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Safety Checks',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 12),
                    _SafetyTipList(tips: _tips),
                    const SizedBox(height: 18),
                    const _TrustFooterCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _SafetyHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.softBlueGradient,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Trust Guide',
                      style: AppTextStyles.metadata.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Campus Safety Guide', style: AppTextStyles.appTitle),
          const SizedBox(height: 8),
          Text(
            'Trade with confidence by meeting in visible campus zones and following a few quick checks before every exchange.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _GuidelineCard extends StatelessWidget {
  const _GuidelineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Official Trading Guidelines',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 6),
                Text(
                  'Use public spaces, inspect items calmly, and keep communication inside UniTrade until the exchange is complete.',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExchangeZoneTile extends StatelessWidget {
  final _ExchangeZone zone;

  const _ExchangeZoneTile({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zone.tint,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(zone.icon, color: AppColors.primary, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.title, style: AppTextStyles.heading3),
                const SizedBox(height: 6),
                Text(zone.description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SafetyTipList extends StatelessWidget {
  final List<String> tips;

  const _SafetyTipList({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < tips.length; index++) ...[
            _SafetyTipRow(index: index + 1, text: tips[index]),
            if (index != tips.length - 1)
              Divider(
                height: 18,
                color: AppColors.divider.withValues(alpha: 0.9),
              ),
          ],
        ],
      ),
    );
  }
}

class _SafetyTipRow extends StatelessWidget {
  final int index;
  final String text;

  const _SafetyTipRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: AppTextStyles.metadata.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: AppTextStyles.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _TrustFooterCard extends StatelessWidget {
  const _TrustFooterCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radius),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'When in doubt, pause the trade and choose a busier exchange zone.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExchangeZone {
  final String title;
  final String description;
  final IconData icon;
  final Color tint;

  const _ExchangeZone({
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
  });
}
