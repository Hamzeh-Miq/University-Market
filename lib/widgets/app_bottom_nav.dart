import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';

/// Bottom navigation bar shared across all main screens.
///
/// Pass [currentRoute] so the correct tab is highlighted.
/// The center "Post Ad" button is always elevated/prominent.
class AppBottomNav extends StatelessWidget {
  /// The route constant for the currently active screen.
  final String currentRoute;

  const AppBottomNav({super.key, required this.currentRoute});

  void _navigate(BuildContext context, String route) {
    if (route == currentRoute) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              // ── Home ────────────────────────────────────────────────
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: currentRoute == AppRoutes.home,
                onTap: () => _navigate(context, AppRoutes.home),
              ),

              // ── Departments ──────────────────────────────────────────
              _NavItem(
                icon: Icons.school_rounded,
                label: 'Departments',
                active: currentRoute == AppRoutes.allListings,
                onTap: () => _navigate(context, AppRoutes.allListings),
              ),

              // ── Post Ad (center, prominent) ──────────────────────────
              _PostAdButton(
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.addListing),
              ),

              // ── About Us ─────────────────────────────────────────────
              _NavItem(
                icon: Icons.info_outline_rounded,
                label: 'About',
                active: currentRoute == AppRoutes.aboutUs,
                onTap: () => _navigate(context, AppRoutes.aboutUs),
              ),

              // ── My Profile ───────────────────────────────────────────
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: currentRoute == AppRoutes.profile,
                onTap: () => _navigate(context, AppRoutes.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Regular nav item ─────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textHint;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Center "Post Ad" floating-style button ────────────────────────────────────

class _PostAdButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PostAdButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x441E88E5),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
