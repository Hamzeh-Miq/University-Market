import 'package:cloud_firestore/cloud_firestore.dart';
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
    Query query =
        _db.collection('products').where('status', isEqualTo: 'Available');

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (courseCode != null && courseCode.isNotEmpty) {
      query = query.where(
          'courseCode', isEqualTo: courseCode.toUpperCase().trim());
    }

    if (maxPrice != null) {
      // Range filter on 'price' requires orderBy on the same field
      query = query
          .where('price', isLessThanOrEqualTo: maxPrice)
          .orderBy('price', descending: false);
    } else {
      query = query.orderBy(sortBy, descending: descending);
    }

    try {
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) =>
              ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
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
          .map((doc) =>
              ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch your listings: $e');
    }
  }

  /// Fetches pending listings for admins
  Future<List<ProductModel>> fetchPendingListings() async {
    try {
      final snapshot = await _db
          .collection('products')
          .where('status', isEqualTo: 'Pending')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending listings: $e');
    }
  }

  /// Updates a product's status
  Future<void> updateProductStatus(String productId, String newStatus) async {
    try {
      await _db.collection('products').doc(productId).update({
        'status': newStatus,
      });
    } catch (e) {
      throw Exception('Failed to update product status: $e');
    }
  }

  /// Fetches a single product by its ID.
  Future<ProductModel?> fetchProduct(String productId) async {
    try {
      final doc =
          await _db.collection('products').doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Adds a new product listing to Firestore.
  Future<void> addProduct(ProductModel product) async {
    try {
      await _db.collection('products').add(product.toJson());
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
}
