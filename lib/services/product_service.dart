import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/product_status.dart';
import '../models/product_model.dart';

/// Handles all Firestore CRUD operations for product listings.
class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches filtered and sorted listings from Firestore.
  Future<List<ProductModel>> fetchFilteredListings({
    String? category,
    String? courseCode,
    double? maxPrice,
    String sortBy = 'createdAt',
    bool descending = true,
  }) async {
    Query query = _db
        .collection('products')
        .where('status', whereIn: ProductStatus.publicStatuses);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (courseCode != null && courseCode.isNotEmpty) {
      query = query.where(
        'courseCode',
        isEqualTo: courseCode.toUpperCase().trim(),
      );
    }

    if (maxPrice != null) {
      // Range filter on 'price' — do NOT add orderBy here.
      // Combining category equality + price range + orderBy(price) requires
      // a very specific composite index per field combo. Instead we filter
      // server-side and sort the results client-side to avoid index mismatches.
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    } else {
      query = query.orderBy(sortBy, descending: descending);
    }

    try {
      final snapshot = await query.get();
      final results = snapshot.docs
          .map(
            (doc) => ProductModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // When a price range filter is active, sort client-side by price asc
      // (server-side orderBy was intentionally omitted to avoid index conflicts).
      if (maxPrice != null) {
        results.sort((a, b) => a.price.compareTo(b.price));
      }

      return results;
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  /// Fetches all listings posted by a specific seller.
  Future<List<ProductModel>> fetchMyListings(String sellerId) async {
    try {
      final snapshot = await _db
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch your listings: $e');
    }
  }

  /// Fetches public listings whose document IDs are in [productIds].
  Future<List<ProductModel>> fetchProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    try {
      final uniqueIds = productIds.toSet().toList();
      final products = <ProductModel>[];

      for (var start = 0; start < uniqueIds.length; start += 10) {
        final end = (start + 10) > uniqueIds.length
            ? uniqueIds.length
            : start + 10;
        final chunk = uniqueIds.sublist(start, end);
        final snapshot = await _db
            .collection('products')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        products.addAll(
          snapshot.docs
              .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
              .where((product) => ProductStatus.isPublished(product.status)),
        );
      }

      final byId = {for (final product in products) product.productId: product};
      return uniqueIds
          .where(byId.containsKey)
          .map((productId) => byId[productId]!)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch favourite listings: $e');
    }
  }

  /// Fetches pending listings for admins
  Future<List<ProductModel>> fetchPendingListings() async {
    try {
      final snapshot = await _db
          .collection('products')
          .where('status', whereIn: ProductStatus.pendingStatuses)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending listings: $e');
    }
  }

  /// Fetches all published listings that have an active discount applied.
  ///
  /// Requires a Firestore composite index on `discountedPrice` (ASC) +
  /// `createdAt` (DESC). The Firebase console will print a clickable URL to
  /// create the index automatically on the first run if it is missing.
  Future<List<ProductModel>> fetchDiscountedListings() async {
    try {
      final snapshot = await _db
          .collection('products')
          .where('status', whereIn: ProductStatus.publicStatuses)
          .where('discountedPrice', isNotEqualTo: null)
          .orderBy('discountedPrice')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch discounted listings: $e');
    }
  }

  /// Fetches all listings that have been marked as Sold.
  Future<List<ProductModel>> fetchSoldListings() async {
    try {
      final snapshot = await _db
          .collection('products')
          .where('status', whereIn: ProductStatus.soldStatuses)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch sold listings: $e');
    }
  }

  /// Updates a product's status.
  Future<void> updateProductStatus(String productId, String newStatus) async {
    try {
      final status = ProductStatus.normalize(newStatus);
      final updates = <String, dynamic>{'status': status};
      if (status == ProductStatus.sold) {
        updates['soldAt'] = FieldValue.serverTimestamp();
      }
      await _db.collection('products').doc(productId).update(updates);
    } catch (e) {
      throw Exception('Failed to update product status: $e');
    }
  }

  /// Applies a discount to a listing **without** requiring admin approval.
  ///
  /// Only updates the [discountedPrice] field. The product status remains
  /// unchanged so the listing stays live immediately.
  /// Pass `null` for [discountedPrice] to remove an existing discount.
  Future<void> applyDiscount(
    String productId, {
    required double? discountedPrice,
  }) async {
    try {
      await _db.collection('products').doc(productId).update({
        'discountedPrice': discountedPrice,
      });
    } catch (e) {
      throw Exception('Failed to apply discount: $e');
    }
  }

  /// Edits the main details of a listing (title, description, category,
  /// courseCode, images). Sets status back to pending so the listing is
  /// removed from public view until an admin re-approves it.
  Future<void> editProduct({
    required String productId,
    required String title,
    required String description,
    required String category,
    String? courseCode,
    required List<String> images,
  }) async {
    try {
      await _db.collection('products').doc(productId).update({
        'title': title,
        'description': description,
        'category': category,
        'courseCode': courseCode,
        'images': images,
        'status': ProductStatus.pending, // Requires admin re-approval
      });
    } catch (e) {
      throw Exception('Failed to edit product: $e');
    }
  }

  /// Fetches a single product by its ID.
  Future<ProductModel?> fetchProduct(String productId) async {
    try {
      final doc = await _db.collection('products').doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Adds a new product listing to Firestore.
  /// Uses a pre-allocated document reference so the productId is stored
  /// inside the document data and always matches the Firestore path.
  Future<void> addProduct(ProductModel product) async {
    try {
      // Allocate a real Firestore document ID first.
      final docRef = _db.collection('products').doc();
      await docRef.set({
        ...product.toJson(),
        'productId': docRef.id, // store the real ID inside the doc
      });
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  /// Permanently deletes a product listing by its document ID.
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Marks a product as sold, removing it from public view and recording when.
  Future<void> markProductAsSold(
    String productId, {
    String? sellerUniversity,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': ProductStatus.sold,
        'soldAt': FieldValue.serverTimestamp(),
      };
      if (sellerUniversity != null) {
        updates['sellerUniversity'] = sellerUniversity;
      }
      await _db.collection('products').doc(productId).update(updates);
    } catch (e) {
      throw Exception('Failed to mark product as sold: $e');
    }
  }
}
