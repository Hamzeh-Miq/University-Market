import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../models/category_model.dart';
import '../../data/dummy_categories.dart';
import '../../providers/auth_provider.dart';

/// Main home screen showing department category cards.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModel = ref.watch(currentUserModelProvider).value;
    final isAdmin = userModel?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'UniTrade',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 22,
          ),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: AppColors.textPrimary),
              tooltip: 'Pending Approvals',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.pendingListings),
            ),
          // About Us
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: AppColors.textPrimary),
            tooltip: 'About Us',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.aboutUs),
          ),
          // Profile
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textPrimary),
            tooltip: 'My Profile',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Text(
              'Browse by Department',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              'Find textbooks, equipment and more for your faculty.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 4),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.05,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: dummyCategories.length,
              itemBuilder: (context, index) {
                final category = dummyCategories[index];
                return _CategoryCard(category: category);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.departmentListings,
        arguments: category.name,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: category.color.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                size: 30,
                color: category.color,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
