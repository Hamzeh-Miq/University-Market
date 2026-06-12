import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/subscription_constants.dart';
import '../../data/dummy_categories.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/subscription_gate.dart';

/// Listings browser with combined category filter + sort — both work at once.
class AllListingsScreen extends ConsumerStatefulWidget {
  /// Optional pre-selected category passed from the home screen.
  final String? initialCategory;
  final bool offersOnly;

  const AllListingsScreen({
    super.key,
    this.initialCategory,
    this.offersOnly = false,
  });

  @override
  ConsumerState<AllListingsScreen> createState() => _AllListingsScreenState();
}

class _AllListingsScreenState extends ConsumerState<AllListingsScreen> {
  String? _selectedCategory;
  ProductSortOption _selectedSort = ProductSortOption.newest;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilter());
  }

  void _applyFilter() {
    ref
        .read(productFilterProvider.notifier)
        .updateFilter(
          ProductFilter(category: _selectedCategory, sortOption: _selectedSort),
        );
  }

  void _onCategoryChanged(String? category) {
    setState(() => _selectedCategory = category);
    _applyFilter();
  }

  void _onSortChanged(ProductSortOption sort) {
    setState(() => _selectedSort = sort);
    _applyFilter();
  }

  Future<void> _delete(BuildContext ctx, String productId) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(productServiceProvider).deleteProduct(productId);
        // ignore: unused_result
        ref.refresh(productListProvider);
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Could not delete the listing. Please try again.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = widget.offersOnly
        ? ref.watch(discountedListingsProvider)
        : ref.watch(productListProvider);
    final authState = ref.watch(authStateProvider);
    final currentUid = authState.value?.uid;
    final isSubscribed = ref.watch(hasActiveSubscriptionProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final favouriteIds = ref.watch(watchlistProvider);
    // Admins always have full access regardless of subscription.
    final hasAccess = isSubscribed || isAdmin;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: widget.offersOnly,
        title: Text(
          widget.offersOnly ? 'Special Offers' : 'Departments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      bottomNavigationBar: const AppBottomNav(
        currentRoute: AppRoutes.allListings,
      ),
      floatingActionButton: hasAccess
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.addListing),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Listing',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SubscriptionGate(
                  featureLabel: 'posting listings',
                  child: SizedBox.shrink(),
                ),
              ),
              backgroundColor: AppColors.textHint,
              icon: const Icon(Icons.lock_rounded, color: Colors.white),
              label: const Text(
                'Subscribe to Post',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: Column(
        children: [
          // ── Filter bar (gated for non-subscribers) ───────────────────────
          if (!widget.offersOnly && hasAccess)
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chips row
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: 'All',
                            selected: _selectedCategory == null,
                            onTap: () => _onCategoryChanged(null),
                          ),
                        ),
                        ...dummyCategories.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: cat.name,
                              selected: _selectedCategory == cat.name,
                              onTap: () => _onCategoryChanged(cat.name),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sort by',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: ProductSortOption.values.map((opt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: opt.label,
                          selected: _selectedSort == opt,
                          onTap: () => _onSortChanged(opt),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            )
          else if (!widget.offersOnly)
            // Locked filter bar placeholder
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SubscriptionGate(
                  featureLabel: 'filters',
                  child: SizedBox.shrink(),
                ),
              ),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Subscribe to filter & sort listings',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          if (!widget.offersOnly)
            const Divider(height: 1, color: AppColors.divider),

          // ── Active filter summary ─────────────────────────────────────
          if (!widget.offersOnly && _selectedCategory != null)
            Container(
              color: AppColors.primary.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_selectedCategory · ${_selectedSort.label}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _onCategoryChanged(null),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          // ── Listings ─────────────────────────────────────────────────
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load listings.\n$err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppColors.textHint.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No listings found.\nTry a different filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Non-subscribers see only the first kFreePreviewLimit items.
                final visibleProducts = hasAccess
                    ? products
                    : products
                          .take(SubscriptionConstants.freePreviewLimit)
                          .toList();
                final isLimited =
                    !hasAccess &&
                    products.length > SubscriptionConstants.freePreviewLimit;

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: visibleProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final product = visibleProducts[i];
                          final isOwner = product.sellerId == currentUid;
                          return _ProductListTile(
                            product: product,
                            isOwner: isOwner,
                            isFavourite: favouriteIds.contains(
                              product.productId,
                            ),
                            onFavouriteToggle: () => ref
                                .read(watchlistProvider.notifier)
                                .toggleItem(product.productId),
                            onDelete: () => _delete(ctx, product.productId),
                          );
                        },
                      ),
                    ),
                    if (isLimited)
                      GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SubscriptionGate(
                            featureLabel: 'the full catalogue',
                            child: SizedBox.shrink(),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: AppColors.primary.withValues(alpha: 0.07),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Showing ${SubscriptionConstants.freePreviewLimit} of ${products.length} listings · Subscribe for full access',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared filter chip ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : cs.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Product list tile (same as DepartmentListingsScreen) ─────────────────────

class _ProductListTile extends StatelessWidget {
  final ProductModel product;
  final bool isOwner;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onDelete;

  const _ProductListTile({
    required this.product,
    required this.isOwner,
    required this.isFavourite,
    required this.onFavouriteToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key(product.productId),
      direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.listingDetail, arguments: product.productId),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                            ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        color: AppColors.primary,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (product.courseCode != null &&
                        product.courseCode!.isNotEmpty)
                      Text(
                        product.courseCode!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (product.hasDiscount) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'JD ${product.discountedPrice!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            'JD ${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${product.discountPercent}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'JD ${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                )
              else
                IconButton(
                  tooltip: isFavourite
                      ? 'Remove from favourites'
                      : 'Add to favourites',
                  icon: Icon(
                    isFavourite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavourite ? AppColors.error : AppColors.textHint,
                  ),
                  onPressed: onFavouriteToggle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
