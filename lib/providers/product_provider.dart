import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

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
final productListProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
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

// ── Pending listings provider ─────────────────────────────────────────────────

/// Fetches products that are pending approval (Admin Only)
final pendingListingsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final service = ref.read(productServiceProvider);
  return service.fetchPendingListings();
});
