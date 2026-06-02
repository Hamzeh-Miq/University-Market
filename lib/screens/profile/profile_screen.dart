import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/product_status.dart';
import '../../constants/subscription_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/review_provider.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/report_model.dart';
import '../../widgets/app_bottom_nav.dart';

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
      final profile = await ref.read(userServiceProvider).getUserProfile(uid);
      if (mounted) {
        setState(() {
          _userModel = profile;
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _signOut() async {
    // Capture before any async gap
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        // Clear the entire navigation stack — no back route remains
        nav.pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = ref.watch(authStateProvider).value;
    final isAdmin = ref.watch(isAdminProvider);

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
      bottomNavigationBar: const AppBottomNav(currentRoute: AppRoutes.profile),
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
                    // Name + admin badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _userModel?.fullName.isNotEmpty == true
                                ? _userModel!.fullName
                                : firebaseUser?.email ?? 'User',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firebaseUser?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
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
                        value: '${_userModel?.reviewCount ?? 0}',
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
                            : '—',
                      ),
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: firebaseUser?.email ?? '—',
                      ),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: _userModel?.phoneNumber.isNotEmpty == true
                            ? _userModel!.phoneNumber
                            : '—',
                      ),
                      _InfoRow(
                        icon: Icons.school_outlined,
                        label: 'University',
                        value: _userModel?.university ?? '—',
                      ),
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

                  // ── Subscription status card ──────────────────────
                  const SizedBox(height: 24),
                  _SubscriptionStatusCard(
                    userModel: _userModel,
                    isAdmin: isAdmin,
                  ),

                  // ── Admin: Post Requests ─────────────────────────
                  if (isAdmin) ...[
                    const SizedBox(height: 28),
                    _AdminApprovalsSection(),
                    const SizedBox(height: 28),
                    _AdminSubscriptionSection(),
                    const SizedBox(height: 28),
                    _AdminReportsSection(),
                  ],
                  const SizedBox(height: 16),
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
      error: (e, _) => Text(
        'Failed to load your listings.',
        style: const TextStyle(color: AppColors.error),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: const Border.fromBorderSide(
                BorderSide(color: AppColors.border),
              ),
            ),
            child: const Center(
              child: Text(
                "You haven't posted any listings yet.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Column(
          children: listings.map((p) => _MyListingTile(product: p)).toList(),
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
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.listingDetail, arguments: product.productId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border),
          ),
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
              child: const Icon(
                Icons.image_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JD ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ProductStatus.color(
                  product.status,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ProductStatus.label(product.status),
                style: TextStyle(
                  color: ProductStatus.color(product.status),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
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
          BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: items
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(row.icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          row.value,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

// ── Admin Approvals Section ──────────────────────────────────────────────────

/// Embedded admin queue — renders inside the profile for admin users only.
class _AdminApprovalsSection extends ConsumerWidget {
  const _AdminApprovalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingListingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFFF59E0B),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Post Requests',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              pendingAsync.maybeWhen(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${list.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Pending list ────────────────────────────────────────────
        pendingAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to load: $e',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          data: (listings) {
            if (listings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 40,
                        color: AppColors.success,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'All caught up!\nNo posts pending review.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: listings
                  .map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdminPendingCard(
                        product: product,
                        onRefresh: () => ref.refresh(pendingListingsProvider),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Admin pending card ────────────────────────────────────────────────────────

/// A single pending listing card with Approve / Reject actions.
class _AdminPendingCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final VoidCallback onRefresh;

  const _AdminPendingCard({required this.product, required this.onRefresh});

  @override
  ConsumerState<_AdminPendingCard> createState() => _AdminPendingCardState();
}

class _AdminPendingCardState extends ConsumerState<_AdminPendingCard> {
  bool _isActing = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isActing = true);
    try {
      await ref
          .read(productServiceProvider)
          .updateProductStatus(widget.product.productId, newStatus);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ProductStatus.isPublished(newStatus)
                  ? 'Listing approved.'
                  : 'Listing rejected.',
            ),
            backgroundColor: ProductStatus.isPublished(newStatus)
                ? AppColors.success
                : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the listing status.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final sellerAsync = ref.watch(sellerProfileProvider(product.sellerId));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Seller info row ───────────────────────────────────────
          InkWell(
            onTap: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.sellerProfile, arguments: product.sellerId),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: sellerAsync.when(
                loading: () => const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading seller…',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                error: (_, __) => const Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Unknown seller',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ],
                ),
                data: (seller) {
                  final name = seller?.fullName.isNotEmpty == true
                      ? seller!.fullName
                      : 'Unknown User';
                  final initials = name
                      .trim()
                      .split(' ')
                      .where((p) => p.isNotEmpty)
                      .map((p) => p[0].toUpperCase())
                      .take(2)
                      .join();

                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              seller?.email ?? '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // ── Listing info ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.error,
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _AdminBadge(
                            label: product.category,
                            color: AppColors.primary,
                          ),
                          _AdminBadge(
                            label: 'JD ${product.price.toStringAsFixed(2)}',
                            color: AppColors.accent,
                          ),
                          if (product.courseCode != null &&
                              product.courseCode!.isNotEmpty)
                            _AdminBadge(
                              label: product.courseCode!,
                              color: AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Preview button
                IconButton(
                  tooltip: 'Preview',
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.listingDetail,
                    arguments: product.productId,
                  ),
                ),
              ],
            ),
          ),

          if (product.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),

          // ── Action buttons ────────────────────────────────────────
          _isActing
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _confirmAction(
                          context,
                          title: 'Reject Listing',
                          message:
                              'This listing will be hidden from the marketplace.',
                          confirmLabel: 'Reject',
                          confirmColor: AppColors.error,
                          onConfirm: () =>
                              _updateStatus(ProductStatus.legacyRejected),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 17,
                        ),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.divider),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _confirmAction(
                          context,
                          title: 'Approve Listing',
                          message:
                              'This listing will become visible to all students.',
                          confirmLabel: 'Approve',
                          confirmColor: AppColors.success,
                          onConfirm: () =>
                              _updateStatus(ProductStatus.published),
                        ),
                        icon: const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 17,
                        ),
                        label: const Text(
                          'Approve',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

// ── Badge helper ──────────────────────────────────────────────────────────────

class _AdminBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _AdminBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Subscription Status Card ───────────────────────────────────────────────────

/// Shows the current user's subscription status on their profile page.
class _SubscriptionStatusCard extends ConsumerWidget {
  final UserModel? userModel;
  final bool isAdmin;

  const _SubscriptionStatusCard({
    required this.userModel,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isAdmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFFF59E0B),
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Admin — Full Access Granted',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isSubscribed = userModel?.isSubscribed ?? false;
    final expiry = userModel?.subscriptionExpiresAt;
    final isActive =
        isSubscribed && expiry != null && expiry.isAfter(DateTime.now());

    if (isActive) {
      final daysLeft = expiry.difference(DateTime.now()).inDays;
      final formatted = '${expiry.day}/${expiry.month}/${expiry.year}';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Annual Subscription',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Expires $formatted · $daysLeft day${daysLeft == 1 ? '' : 's'} remaining',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Subscribe to unlock the full marketplace',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.payment),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.credit_card_rounded, size: 16),
              label: const Text(
                'Subscribe Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Admin Subscription Management Section ────────────────────────────────────

/// Allows admins to search a user by email and activate or revoke a subscription.
class _AdminSubscriptionSection extends ConsumerStatefulWidget {
  const _AdminSubscriptionSection();

  @override
  ConsumerState<_AdminSubscriptionSection> createState() =>
      _AdminSubscriptionSectionState();
}

class _AdminSubscriptionSectionState
    extends ConsumerState<_AdminSubscriptionSection> {
  final _emailController = TextEditingController();
  UserModel? _foundUser;
  bool _searching = false;
  bool _acting = false;
  String? _searchError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _searching = true;
      _foundUser = null;
      _searchError = null;
    });
    try {
      final user = await ref.read(userServiceProvider).searchUserByEmail(email);
      setState(() {
        _foundUser = user;
        _searching = false;
        if (user == null) _searchError = 'No user found with that email.';
      });
    } catch (e) {
      setState(() {
        _searching = false;
        _searchError = 'Search failed. Please try again.';
      });
    }
  }

  Future<void> _activate() async {
    if (_foundUser == null) return;
    setState(() => _acting = true);
    try {
      await ref.read(userServiceProvider).activateSubscription(_foundUser!.uid);
      final updated = await ref
          .read(userServiceProvider)
          .getUserProfile(_foundUser!.uid);
      if (mounted) {
        setState(() {
          _foundUser = updated;
          _acting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Subscription activated for ${_foundUser?.fullName ?? _foundUser?.email}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not activate the subscription.')),
        );
      }
    }
  }

  Future<void> _revoke() async {
    if (_foundUser == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Subscription'),
        content: Text('Revoke the subscription for ${_foundUser!.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _acting = true);
    try {
      await ref.read(userServiceProvider).revokeSubscription(_foundUser!.uid);
      final updated = await ref
          .read(userServiceProvider)
          .getUserProfile(_foundUser!.uid);
      if (mounted) {
        setState(() {
          _foundUser = updated;
          _acting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription revoked.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not revoke the subscription.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final found = _foundUser;
    final hasActiveSub =
        (found?.isSubscribed ?? false) &&
        (found?.subscriptionExpiresAt?.isAfter(DateTime.now()) ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.card_membership_rounded,
                color: AppColors.success,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Manage Subscriptions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.subscribedUsers),
                icon: const Icon(
                  Icons.people_alt_outlined,
                  color: AppColors.success,
                  size: 16,
                ),
                label: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Search user by email...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _searching ? null : _search,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _searching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Find'),
            ),
          ],
        ),

        if (_searchError != null) ...[
          const SizedBox(height: 10),
          Text(
            _searchError!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],

        if (found != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        found.fullName.isNotEmpty
                            ? found.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            found.fullName.isNotEmpty
                                ? found.fullName
                                : found.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            found.email,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: hasActiveSub
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasActiveSub
                            ? Icons.verified_rounded
                            : Icons.lock_rounded,
                        color: hasActiveSub
                            ? AppColors.success
                            : AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasActiveSub
                              ? 'Subscribed · expires ${found.subscriptionExpiresAt!.day}/${found.subscriptionExpiresAt!.month}/${found.subscriptionExpiresAt!.year} · ${SubscriptionConstants.subscriptionDurationLabel} plan'
                              : 'No active subscription',
                          style: TextStyle(
                            color: hasActiveSub
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_acting)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _activate,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add_card_rounded, size: 18),
                          label: Text(
                            hasActiveSub
                                ? 'Renew (+${SubscriptionConstants.subscriptionDurationLabel})'
                                : 'Activate',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (hasActiveSub) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _revoke,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: AppColors.error,
                              size: 18,
                            ),
                            label: const Text(
                              'Revoke',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Admin Reports Section ─────────────────────────────────────────────────────

/// Embedded admin panel showing pending user/product reports.
class _AdminReportsSection extends ConsumerWidget {
  const _AdminReportsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(pendingReportsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pending Reports',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7F1D1D),
                  ),
                ),
              ),
              reportsAsync.maybeWhen(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${list.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        reportsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to load reports: $e',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          data: (reports) {
            if (reports.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 40,
                        color: AppColors.success,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No pending reports.\nAll clear!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: reports
                  .map(
                    (report) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdminReportCard(
                        report: report,
                        onRefresh: () => ref.refresh(pendingReportsProvider),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Admin report card ─────────────────────────────────────────────────────────

class _AdminReportCard extends ConsumerStatefulWidget {
  final ReportModel report;
  final VoidCallback onRefresh;

  const _AdminReportCard({required this.report, required this.onRefresh});

  @override
  ConsumerState<_AdminReportCard> createState() => _AdminReportCardState();
}

class _AdminReportCardState extends ConsumerState<_AdminReportCard> {
  bool _isActing = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isActing = true);
    try {
      await ref
          .read(reportServiceProvider)
          .updateReportStatus(widget.report.reportId, newStatus);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'reviewed'
                  ? 'Report marked as reviewed ✓'
                  : 'Report dismissed',
            ),
            backgroundColor: newStatus == 'reviewed'
                ? AppColors.success
                : AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the report status.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _deleteReportedReview() async {
    setState(() => _isActing = true);
    try {
      await ref
          .read(reviewServiceProvider)
          .deleteReview(reviewId: widget.report.targetId);
      await ref
          .read(reportServiceProvider)
          .updateReportStatus(widget.report.reportId, 'reviewed');
      widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted and report marked reviewed.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the reported review.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isUser = report.targetType == 'user';
    final isReview = report.targetType == 'review';
    final chipColor = isUser
        ? AppColors.error
        : isReview
        ? AppColors.primary
        : AppColors.warning;
    final chipLabel = isUser
        ? 'USER'
        : isReview
        ? 'REVIEW'
        : 'PRODUCT';
    final reporterAsync = report.reporterId.isEmpty
        ? null
        : ref.watch(sellerProfileProvider(report.reporterId));
    final targetUserAsync = isUser && report.targetId.isNotEmpty
        ? ref.watch(sellerProfileProvider(report.targetId))
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type chip + target name ──────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: chipColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                      color: chipColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.targetName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Reason ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.report_outlined,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    report.reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            // ── Description ─────────────────────────────────────────
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                report.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 10),

            _ReportPartyDetails(
              report: report,
              reporterAsync: reporterAsync,
              targetUserAsync: targetUserAsync,
            ),

            const SizedBox(height: 8),

            // ── Reporter ref + date ──────────────────────────────────
            Text(
              'Reporter: ${report.reporterId.length > 12 ? '${report.reporterId.substring(0, 12)}…' : report.reporterId}'
              ' · ${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),

            const SizedBox(height: 12),

            // ── Action buttons ───────────────────────────────────────
            if (_isActing)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('dismissed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: isReview
                          ? _deleteReportedReview
                          : () => _updateStatus('reviewed'),
                      style: FilledButton.styleFrom(
                        backgroundColor: isReview
                            ? AppColors.error
                            : AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(isReview ? 'Delete Review' : 'Mark Reviewed'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportPartyDetails extends StatelessWidget {
  final ReportModel report;
  final AsyncValue<UserModel?>? reporterAsync;
  final AsyncValue<UserModel?>? targetUserAsync;

  const _ReportPartyDetails({
    required this.report,
    required this.reporterAsync,
    required this.targetUserAsync,
  });

  @override
  Widget build(BuildContext context) {
    final targetLabel = switch (report.targetType) {
      'user' => 'Reported user',
      'review' => 'Reported review',
      _ => 'Reported product',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportPartyRow(
            icon: Icons.person_search_outlined,
            label: 'Reported by',
            value: _userValue(reporterAsync, report.reporterId),
          ),
          const SizedBox(height: 8),
          _ReportPartyRow(
            icon: Icons.flag_outlined,
            label: targetLabel,
            value: report.targetType == 'user'
                ? _userValue(targetUserAsync, report.targetId)
                : _targetValue(report),
          ),
        ],
      ),
    );
  }

  String _targetValue(ReportModel report) {
    final name = report.targetName.isEmpty
        ? 'Unknown target'
        : report.targetName;
    if (report.targetId.isEmpty) return name;
    return '$name (${report.targetId})';
  }

  String _userValue(AsyncValue<UserModel?>? userAsync, String fallbackId) {
    final fallback = fallbackId.isEmpty ? 'Unknown user' : fallbackId;
    final user = userAsync?.valueOrNull;
    if (user == null) return fallback;

    final name = user.fullName.isEmpty ? 'Unknown user' : user.fullName;
    if (user.email.isEmpty) return '$name ($fallback)';
    return '$name - ${user.email} ($fallback)';
  }
}

class _ReportPartyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReportPartyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
