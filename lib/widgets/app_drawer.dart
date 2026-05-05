import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../data/dummy_categories.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModel = ref.watch(currentUserModelProvider).value;
    final isAdmin = userModel?.role == 'admin';

    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'UniTrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Campus Marketplace',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.category_outlined, color: AppColors.primary),
            title: const Text('Departments', style: TextStyle(fontWeight: FontWeight.w600)),
            children: dummyCategories.map((cat) {
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 54, right: 16),
                leading: Icon(cat.icon, color: cat.color, size: 20),
                title: Text(cat.name, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.of(context).pushNamed(
                    AppRoutes.departmentListings,
                    arguments: cat.name,
                  );
                },
              );
            }).toList(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.textPrimary),
            title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.textPrimary),
            title: const Text('About Us', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.aboutUs);
            },
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
              title: const Text('Pending Approvals', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.pendingListings);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
            onTap: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
    );
  }
}
