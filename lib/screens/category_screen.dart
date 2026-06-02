import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../constants/app_text_styles.dart';
import '../models/category_model.dart';

class CategoryScreen extends StatelessWidget {
  final CategoryModel category;

  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: category.color,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: category.color),
                  Center(
                    child: Icon(
                      category.icon,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items in ${category.name} yet.',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to post something!',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.addListing);
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Post an Item',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: category.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
