import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/category_model.dart';

const List<CategoryModel> dummyCategories = [
  CategoryModel(
    id: 'c1',
    name: 'Law',
    icon: Icons.gavel_rounded,
    color: AppColors.primaryDark,
  ),
  CategoryModel(
    id: 'c2',
    name: 'IT',
    icon: Icons.computer_rounded,
    color: AppColors.primary,
  ),
  CategoryModel(
    id: 'c3',
    name: 'Engineering',
    icon: Icons.architecture_rounded,
    color: AppColors.warning,
  ),
  CategoryModel(
    id: 'c4',
    name: 'Arts',
    icon: Icons.palette_rounded,
    color: AppColors.error,
  ),
  CategoryModel(
    id: 'c5',
    name: 'Business',
    icon: Icons.business_center_rounded,
    color: AppColors.success,
  ),
  CategoryModel(
    id: 'c6',
    name: 'Nursing',
    icon: Icons.medical_services_rounded,
    color: AppColors.accent,
  ),
  CategoryModel(
    id: 'c7',
    name: 'Pharmaceutics',
    icon: Icons.medication_rounded,
    color: AppColors.accent,
  ),
  CategoryModel(
    id: 'c8',
    name: 'Dentistry',
    icon: Icons.health_and_safety_rounded,
    color: AppColors.primaryLight,
  ),
  CategoryModel(
    id: 'c9',
    name: 'Sports',
    icon: Icons.sports_basketball_rounded,
    color: AppColors.warning,
  ),
  CategoryModel(
    id: 'c10',
    name: 'Languages',
    icon: Icons.translate_rounded,
    color: AppColors.primaryDark,
  ),
  CategoryModel(
    id: 'c11',
    name: 'Sharia',
    icon: Icons.menu_book_rounded,
    color: AppColors.textSecondary,
  ),
  CategoryModel(
    id: 'c12',
    name: 'Home Stuff',
    icon: Icons.chair_rounded,
    color: AppColors.textHint,
  ),
];
