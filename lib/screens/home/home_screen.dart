import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../models/category_model.dart';
import '../../data/dummy_categories.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/subscription_gate.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final unreadAsync = currentUser != null
        ? ref.watch(unreadCountProvider(currentUser.uid))
        : const AsyncData<int>(0);
    final unreadCount = unreadAsync.valueOrNull ?? 0;
    final isSubscribed = ref.watch(hasActiveSubscriptionProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final hasAccess = isSubscribed || isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(currentRoute: AppRoutes.home),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'UniTrade',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.textPrimary),
                tooltip: 'Messages',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.chatList),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                        minWidth: 17, minHeight: 17),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Categories Grid ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 16,
                ),
                itemCount: dummyCategories.length + 2, // +2 for All Categories and Sell Now
                itemBuilder: (context, index) {
                  if (index < dummyCategories.length) {
                    return _CategoryItem(category: dummyCategories[index]);
                  } else if (index == dummyCategories.length) {
                    return const _SpecialItem(
                      label: 'All Categories',
                      icon: Icons.more_horiz_rounded,
                      color: Colors.blue,
                      route: AppRoutes.allListings,
                    );
                  } else {
                    // "Sell Now" — locked for non-subscribers
                    return _SpecialItem(
                      label: 'Sell Now',
                      icon: hasAccess
                          ? Icons.camera_alt_outlined
                          : Icons.lock_rounded,
                      color: hasAccess ? Colors.purple : AppColors.textHint,
                      route: hasAccess ? AppRoutes.addListing : null,
                      onLockedTap: hasAccess
                          ? null
                          : () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const SubscriptionGate(
                                  featureLabel: 'posting listings',
                                  child: SizedBox.shrink(),
                                ),
                              ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Newly Listed Banner ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Find Newly Listed Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Don't miss fresh ads in your favorite categories",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.allListings),
                            icon: const Text(
                              'Browse now',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            label: const Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      flex: 1,
                      child: Icon(Icons.list_alt_rounded, size: 60, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Offers / Post Your Ad Section ──────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Offers',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Text(
                          'More',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                        label: const Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: hasAccess
                          ? () => Navigator.of(context)
                              .pushNamed(AppRoutes.addListing)
                          : () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const SubscriptionGate(
                                  featureLabel: 'posting listings',
                                  child: SizedBox.shrink(),
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasAccess
                            ? const Color(0xFFF59E0B)
                            : AppColors.textHint,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(hasAccess
                          ? Icons.add_a_photo_outlined
                          : Icons.lock_rounded),
                      label: Text(
                        hasAccess ? 'Post Your Ad' : 'Subscribe to Post',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryModel category;
  const _CategoryItem({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.allListings,
        arguments: category.name,
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                category.icon,
                size: 32,
                color: category.color.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? route;
  final VoidCallback? onLockedTap;

  const _SpecialItem({
    required this.label,
    required this.icon,
    required this.color,
    this.route,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onLockedTap != null) {
          onLockedTap!();
        } else if (route != null) {
          Navigator.of(context).pushNamed(route!);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
