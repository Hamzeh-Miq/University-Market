import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../constants/app_text_styles.dart';
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
                    color: AppColors.onPrimaryFaint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.onPrimary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                // Name row with optional admin badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        userModel?.fullName.isNotEmpty == true
                            ? userModel!.fullName
                            : 'UniTrade',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.onPrimaryTitle,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_rounded,
                              size: 11,
                              color: AppColors.onPrimary,
                            ),
                            SizedBox(width: 3),
                            Text('ADMIN', style: AppTextStyles.adminBadge),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  userModel?.email ?? 'Campus Marketplace',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.onPrimaryBody,
                ),
              ],
            ),
          ),
          ExpansionTile(
            leading: const Icon(
              Icons.category_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Departments', style: AppTextStyles.navLabel),
            children: dummyCategories.map((cat) {
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 54, right: 16),
                leading: Icon(cat.icon, color: cat.color, size: 20),
                title: Text(cat.name, style: AppTextStyles.bodyMedium),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.allListings, arguments: cat.name);
                },
              );
            }).toList(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.person_outline,
              color: AppColors.textPrimary,
            ),
            title: const Text('My Profile', style: AppTextStyles.navLabel),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: AppColors.textPrimary,
            ),
            title: const Text('About Us', style: AppTextStyles.navLabel),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.aboutUs);
            },
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Pending Approvals',
                style: AppTextStyles.actionLink,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.pendingListings);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: AppTextStyles.dangerNavLabel),
            onTap: () async {
              // Show confirm dialog BEFORE closing the drawer so
              // the context is still valid for showDialog.
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              // Close drawer, sign out, clear navigation stack.
              if (context.mounted) Navigator.pop(context);

              await ref.read(authServiceProvider).signOut();

              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
