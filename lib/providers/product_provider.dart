import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'watchlist_provider.dart';

// ── Service provider ──────────────────────────────────────────────────────────

/// Exposes [ProductService] as a singleton.
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

// ── Sort option ───────────────────────────────────────────────────────────────

/// Available sort orders for product listings.
enum ProductSortOption { newest, priceAsc, priceDesc }

/// Human-readable labels for each sort option.
extension ProductSortOptionLabel on ProductSortOption {
  String get label {
    switch (this) {
      case ProductSortOption.newest:
        return 'Newest';
      case ProductSortOption.priceAsc:
        return 'Price ↑';
      case ProductSortOption.priceDesc:
        return 'Price ↓';
    }
  }
}

// ── Filter state ──────────────────────────────────────────────────────────────

/// Holds current search/filter criteria for product listings.
class ProductFilter {
  final String? category;
  final String? courseCode;
  final double? maxPrice;
  final ProductSortOption sortOption;

  const ProductFilter({
    this.category,
    this.courseCode,
    this.maxPrice,
    this.sortOption = ProductSortOption.newest,
  });

  ProductFilter copyWith({
    String? category,
    String? courseCode,
    double? maxPrice,
    ProductSortOption? sortOption,
  }) {
    return ProductFilter(
      category: category ?? this.category,
      courseCode: courseCode ?? this.courseCode,
      maxPrice: maxPrice ?? this.maxPrice,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

// ── Filter notifier ───────────────────────────────────────────────────────────

/// Notifier for mutable filter/sort state the user controls.
class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  /// Replaces the entire filter state.
  void updateFilter(ProductFilter filter) => state = filter;

  /// Convenience: change only the sort option.
  void setSort(ProductSortOption sort) =>
      state = state.copyWith(sortOption: sort);

  /// Convenience: change only the category.
  void setCategory(String? category) =>
      state = state.copyWith(category: category);
}

/// Mutable filter state the user controls.
final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(
      ProductFilterNotifier.new,
    );

// ── Product list provider ─────────────────────────────────────────────────────

/// Fetches products reactively whenever the filter/sort changes.
final productListProvider = FutureProvider.autoDispose<List<ProductModel>>((
  ref,
) async {
  final filter = ref.watch(productFilterProvider);
  final service = ref.read(productServiceProvider);

  String sortField;
  bool descending;

  switch (filter.sortOption) {
    case ProductSortOption.priceAsc:
      sortField = 'price';
      descending = false;
      break;
    case ProductSortOption.priceDesc:
      sortField = 'price';
      descending = true;
      break;
    case ProductSortOption.newest:
      sortField = 'createdAt';
      descending = true;
      break;
  }

  return service.fetchFilteredListings(
    category: filter.category,
    courseCode: filter.courseCode,
    maxPrice: filter.maxPrice,
    sortBy: sortField,
    descending: descending,
  );
});

// ── My listings provider ──────────────────────────────────────────────────────

/// Fetches all listings posted by [sellerId]. Auto-disposes when screen exits.
final myListingsProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, String>((ref, sellerId) async {
      final service = ref.read(productServiceProvider);
      return service.fetchMyListings(sellerId);
    });

// ── Single product provider ───────────────────────────────────────────────────

/// Fetches a single product by its document ID.
final singleProductProvider = FutureProvider.autoDispose
    .family<ProductModel?, String>((ref, productId) async {
      final service = ref.read(productServiceProvider);
      return service.fetchProduct(productId);
    });

/// Fetches the user's current favourite public listings.
final favoriteProductsProvider = FutureProvider.autoDispose<List<ProductModel>>(
  (ref) async {
    final favoriteIds = ref.watch(watchlistProvider);
    if (favoriteIds.isEmpty) return [];

    final service = ref.read(productServiceProvider);
    return service.fetchProductsByIds(favoriteIds);
  },
);

// ── Pending listings provider ─────────────────────────────────────────────────

/// Fetches products that are pending approval (Admin Only)
final pendingListingsProvider = FutureProvider.autoDispose<List<ProductModel>>((
  ref,
) async {
  final service = ref.read(productServiceProvider);
  return service.fetchPendingListings();
});

// ── Discounted listings provider ──────────────────────────────────────────────

/// Fetches all published listings that have an active discount applied.
/// Used by the Offers section on the home screen.
final discountedListingsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
      final service = ref.read(productServiceProvider);
      return service.fetchDiscountedListings();
    });

// ── Sold statistics provider ──────────────────────────────────────────────────

/// Holds aggregated statistics and rankings of sold products.
class SoldStats {
  final int totalSold;
  final int soldToday;
  final int soldThisMonth;
  final int soldThisYear;
  final List<MapEntry<String, int>> dailyRanking;
  final List<MapEntry<String, int>> monthlyRanking;
  final List<MapEntry<String, int>> yearlyRanking;

  SoldStats({
    required this.totalSold,
    required this.soldToday,
    required this.soldThisMonth,
    required this.soldThisYear,
    required this.dailyRanking,
    required this.monthlyRanking,
    required this.yearlyRanking,
  });
}

/// Computes sold product stats and leaderboards by university.
final soldStatisticsProvider = FutureProvider.autoDispose<SoldStats>((
  ref,
) async {
  final service = ref.read(productServiceProvider);
  final products = await service.fetchSoldListings();

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final monthStart = DateTime(now.year, now.month, 1);
  final yearStart = DateTime(now.year, 1, 1);

  int totalSold = 0;
  int soldToday = 0;
  int soldThisMonth = 0;
  int soldThisYear = 0;

  final Map<String, int> dailyUniRank = {};
  final Map<String, int> monthlyUniRank = {};
  final Map<String, int> yearlyUniRank = {};

  for (final product in products) {
    totalSold++;

    final soldAt = product.soldAt;
    if (soldAt == null) continue;

    final uni = product.sellerUniversity ?? 'University of Jordan';

    if (soldAt.isAfter(todayStart)) {
      soldToday++;
      dailyUniRank[uni] = (dailyUniRank[uni] ?? 0) + 1;
    }
    if (soldAt.isAfter(monthStart)) {
      soldThisMonth++;
      monthlyUniRank[uni] = (monthlyUniRank[uni] ?? 0) + 1;
    }
    if (soldAt.isAfter(yearStart)) {
      soldThisYear++;
      yearlyUniRank[uni] = (yearlyUniRank[uni] ?? 0) + 1;
    }
  }

  List<MapEntry<String, int>> sortRanking(Map<String, int> map) {
    final list = map.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  return SoldStats(
    totalSold: totalSold,
    soldToday: soldToday,
    soldThisMonth: soldThisMonth,
    soldThisYear: soldThisYear,
    dailyRanking: sortRanking(dailyUniRank),
    monthlyRanking: sortRanking(monthlyUniRank),
    yearlyRanking: sortRanking(yearlyUniRank),
  );
});
