import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_text_styles.dart';
import '../../data/dummy_categories.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/product_card.dart';
import '../../widgets/subscription_gate.dart';

/// Premium home dashboard for discovery, quick actions, and campus deals.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final unreadAsync = currentUser != null
        ? ref.watch(unreadCountProvider(currentUser.uid))
        : const AsyncData<int>(0);
    final unreadCount = unreadAsync.valueOrNull ?? 0;
    final favouriteCount = ref.watch(favoriteCountProvider);
    final isSubscribed = ref.watch(hasActiveSubscriptionProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final hasAccess = isSubscribed || isAdmin;
    final productsAsync = ref.watch(productListProvider);
    final dealsAsync = ref.watch(discountedListingsProvider);
    final favouriteIds = ref.watch(watchlistProvider);

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentRoute: AppRoutes.home),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productListProvider);
            ref.invalidate(discountedListingsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HomeHeader(
                        favouriteCount: favouriteCount,
                        unreadCount: unreadCount,
                      ),
                      const SizedBox(height: 18),
                      PremiumSearchField(
                        hintText: 'Search textbooks, laptops, desks...',
                        onFilterTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.allListings),
                      ),
                      const SizedBox(height: 22),
                      _CategoryStrip(hasAccess: hasAccess),
                      const SizedBox(height: 24),
                      _DealsCarousel(dealsAsync: dealsAsync),
                      const SizedBox(height: 24),
                      _NewListingsBanner(hasAccess: hasAccess),
                      const SizedBox(height: 24),
                      PremiumSectionHeader(
                        title: 'Trending on Campus',
                        actionLabel: 'See All',
                        onActionTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.allListings),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              productsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: _ProductGridSkeleton(),
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: PremiumEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Could not load listings',
                    subtitle: 'Pull down to refresh and try again.',
                    action: GradientActionButton(
                      label: 'Retry',
                      icon: Icons.refresh_rounded,
                      onPressed: () => ref.invalidate(productListProvider),
                    ),
                  ),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: PremiumEmptyState(
                        icon: Icons.storefront_rounded,
                        title: 'No campus listings yet',
                        subtitle:
                            'Be the first student to post something useful.',
                        action: GradientActionButton(
                          label: hasAccess ? 'Post an Item' : 'Browse Listings',
                          icon: hasAccess
                              ? Icons.add_a_photo_outlined
                              : Icons.search_rounded,
                          onPressed: () => hasAccess
                              ? Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.addListing)
                              : Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.allListings),
                        ),
                      ),
                    );
                  }

                  final visibleProducts = products.take(6).toList();
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    sliver: SliverGrid.builder(
                      itemCount: visibleProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.57,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                          ),
                      itemBuilder: (context, index) {
                        final product = visibleProducts[index];
                        final isWatched = favouriteIds.contains(
                          product.productId,
                        );
                        return ProductCard(
                          product: product,
                          isWatched: isWatched,
                          onWatchlistToggle: () => ref
                              .read(watchlistProvider.notifier)
                              .toggleItem(product.productId),
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.listingDetail,
                            arguments: product.productId,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppColors.primary,
        elevation: 3,
        tooltip: 'Settings',
        child: const Icon(Icons.settings_rounded),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final int favouriteCount;
  final int unreadCount;

  const _HomeHeader({required this.favouriteCount, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UniSooq',
                style: AppTextStyles.appTitle.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 5),
              Text(
                'Premium finds from students around campus',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        PremiumIconButton(
          icon: Icons.favorite_border_rounded,
          tooltip: 'Favourite Posts',
          badgeCount: favouriteCount,
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.favouriteListings),
        ),
        const SizedBox(width: 10),
        PremiumIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          tooltip: 'Messages',
          badgeCount: unreadCount,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.chatList),
        ),
      ],
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final bool hasAccess;

  const _CategoryStrip({required this.hasAccess});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dummyCategories.length + 2,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index < dummyCategories.length) {
            final category = dummyCategories[index];
            return CategoryBadge(
              icon: category.icon,
              label: category.name,
              color: category.color,
              onTap: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.allListings, arguments: category.name),
            );
          }

          if (index == dummyCategories.length) {
            return CategoryBadge(
              icon: Icons.grid_view_rounded,
              label: 'All',
              color: AppColors.primary,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.allListings),
            );
          }

          return CategoryBadge(
            icon: hasAccess ? Icons.camera_alt_outlined : Icons.lock_rounded,
            label: 'Sell',
            color: hasAccess ? AppColors.favourite : AppColors.textHint,
            onTap: () => hasAccess
                ? Navigator.of(context).pushNamed(AppRoutes.addListing)
                : showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const SubscriptionGate(
                      featureLabel: 'posting listings',
                      child: SizedBox.shrink(),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _DealsCarousel extends StatelessWidget {
  final AsyncValue<List<ProductModel>> dealsAsync;

  const _DealsCarousel({required this.dealsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumSectionHeader(
          title: 'Leaving Campus Soon?',
          actionLabel: 'More',
          onActionTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.offersListings),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 146,
          child: dealsAsync.when(
            loading: () => const Row(
              children: [
                Expanded(
                  child: LoadingPlaceholder(height: 146, borderRadius: 16),
                ),
              ],
            ),
            error: (_, __) => const _StaticDealCard(),
            data: (deals) {
              final visibleDeals = deals.take(5).toList();
              if (visibleDeals.isEmpty) {
                return const _StaticDealCard();
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleDeals.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _DealCard(product: visibleDeals[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DealCard extends StatelessWidget {
  final ProductModel product;

  const _DealCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.listingDetail, arguments: product.productId),
      borderRadius: BorderRadius.circular(AppColors.radius),
      child: Container(
        width: 248,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppColors.radius),
          color: AppColors.primaryDark,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (product.images.isNotEmpty)
              Image.network(
                product.images.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.16),
                    AppColors.primaryDark.withValues(alpha: 0.86),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'JD ${product.effectivePrice.toStringAsFixed(2)}',
                    style: AppTextStyles.priceLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticDealCard extends StatelessWidget {
  const _StaticDealCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerLow : null,
        gradient: isDark ? null : AppColors.softBlueGradient,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Fast campus deals',
                  style: AppTextStyles.heading3.copyWith(color: cs.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discounted listings will appear here as students add offers.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.favourite,
            size: 48,
          ),
        ],
      ),
    );
  }
}

class _NewListingsBanner extends StatelessWidget {
  final bool hasAccess;

  const _NewListingsBanner({required this.hasAccess});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        final artWidth = isCompact ? 92.0 : 126.0;

        return Container(
          constraints: const BoxConstraints(minHeight: 156),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerLow : null,
            gradient: isDark ? null : AppColors.softBlueGradient,
            borderRadius: BorderRadius.circular(AppColors.radius),
            border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: isCompact ? -30 : -18,
                top: isCompact ? 28 : 18,
                child: _PeekingStack(scale: isCompact ? 0.78 : 1),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18, 18, artWidth, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Find Newly Listed Items',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Fresh posts from your favourite departments, updated as students list.',
                      maxLines: isCompact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        height: 1.28,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.allListings),
                        icon: const Icon(Icons.search_rounded, size: 16),
                        label: const Text('Browse now'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppColors.primary,
                          textStyle: AppTextStyles.actionLink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PeekingStack extends StatelessWidget {
  final double scale;

  const _PeekingStack({this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      alignment: Alignment.topRight,
      child: SizedBox(
        width: 140,
        height: 112,
        child: Stack(
          children: [
            _MiniProductTile(
              left: 42,
              top: 0,
              color: AppColors.amber.withValues(alpha: 0.25),
              icon: Icons.menu_book_rounded,
            ),
            _MiniProductTile(
              left: 0,
              top: 28,
              color: AppColors.favourite.withValues(alpha: 0.18),
              icon: Icons.headphones_rounded,
            ),
            _MiniProductTile(
              left: 62,
              top: 52,
              color: AppColors.primary.withValues(alpha: 0.18),
              icon: Icons.laptop_mac_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniProductTile extends StatelessWidget {
  final double left;
  final double top;
  final Color color;
  final IconData icon;

  const _MiniProductTile({
    required this.left,
    required this.top,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.surface, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 30),
      ),
    );
  }
}

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.57,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, __) =>
          const LoadingPlaceholder(height: double.infinity, borderRadius: 16),
    );
  }
}
