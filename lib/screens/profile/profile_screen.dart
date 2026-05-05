import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';

/// Shows the current user's profile, stats, and their posted listings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _userModel;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final profile = await UserService().getUserProfile(uid);
      if (mounted) setState(() { _userModel = profile; _loadingProfile = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _signOut() async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authServiceProvider).signOut();
      nav.pushReplacementNamed(AppRoutes.login);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = ref.watch(authStateProvider).value;

    if (_loadingProfile) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final initials = _userModel?.fullName.isNotEmpty == true
        ? _userModel!.fullName
            .trim()
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
            .take(2)
            .join()
        : (firebaseUser?.email?[0].toUpperCase() ?? '?');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.editProfile),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _signOut,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userModel?.fullName.isNotEmpty == true
                          ? _userModel!.fullName
                          : firebaseUser?.email ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firebaseUser?.email ?? '',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats row ────────────────────────────────────
                  Row(
                    children: [
                      _StatCard(
                        label: 'Rating',
                        value:
                            '${_userModel?.rating.toStringAsFixed(1) ?? "0.0"} ★',
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Reviews',
                        value:
                            '${_userModel?.reviewCount ?? 0}',
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Verified',
                        value: (firebaseUser?.emailVerified ?? false)
                            ? 'Yes ✓'
                            : 'No',
                        color: (firebaseUser?.emailVerified ?? false)
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Info card ────────────────────────────────────
                  _InfoCard(
                    items: [
                      _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: _userModel?.fullName.isNotEmpty == true
                              ? _userModel!.fullName
                              : '—'),
                      _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: firebaseUser?.email ?? '—'),
                      _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _userModel?.phoneNumber.isNotEmpty == true
                              ? _userModel!.phoneNumber
                              : '—'),
                      _InfoRow(
                          icon: Icons.school_outlined,
                          label: 'University',
                          value: _userModel?.university ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── My Listings ──────────────────────────────────
                  const Text(
                    'My Listings',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (firebaseUser != null)
                    _MyListingsSection(uid: firebaseUser.uid),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Listings ──────────────────────────────────────────────────────────────

class _MyListingsSection extends ConsumerWidget {
  final String uid;
  const _MyListingsSection({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider(uid));

    return listingsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Error: $e',
          style: const TextStyle(color: AppColors.error)),
      data: (listings) {
        if (listings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: const Border.fromBorderSide(
                  BorderSide(color: AppColors.border)),
            ),
            child: const Center(
              child: Text("You haven't posted any listings yet.",
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }

        return Column(
          children: listings
              .map((p) => _MyListingTile(product: p))
              .toList(),
        );
      },
    );
  }
}

class _MyListingTile extends StatelessWidget {
  final ProductModel product;
  const _MyListingTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRoutes.listingDetail, arguments: product.productId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
              BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.image_outlined,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('JD ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(product.status,
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
              BorderSide(color: AppColors.border)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: items
            .map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(row.icon,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.label,
                              style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 11)),
                          Text(row.value,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
}
