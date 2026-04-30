import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

/// Exposes [ProductService] as a singleton.
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

/// Filter state — holds current search/filter criteria.
class ProductFilter {
  final String? category;
  final String? courseCode;
  final double? maxPrice;

  const ProductFilter({this.category, this.courseCode, this.maxPrice});

  ProductFilter copyWith({
    String? category,
    String? courseCode,
    double? maxPrice,
  }) {
    return ProductFilter(
      category: category ?? this.category,
      courseCode: courseCode ?? this.courseCode,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

/// Notifier for mutable filter state the user controls.
class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  void updateFilter(ProductFilter filter) => state = filter;
}

/// Mutable filter state the user controls.
final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(ProductFilterNotifier.new);

/// Fetches products reactively whenever the filter changes.
final productListProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final filter = ref.watch(productFilterProvider);
  final service = ref.read(productServiceProvider);

  return service.fetchFilteredListings(
    category: filter.category,
    courseCode: filter.courseCode,
    maxPrice: filter.maxPrice,
  );
});
