import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches filtered listings using Firestore compound queries
  Future<List<ProductModel>> fetchFilteredListings({
    String? courseCode,
    double? maxPrice,
    String? category,
  }) async {
    Query query = _db.collection('products').where('status', isEqualTo: 'Available');

    // Filter by Category
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    // Exact match for course code (e.g., "CS101")
    if (courseCode != null && courseCode.isNotEmpty) {
      query = query.where('courseCode', isEqualTo: courseCode.toUpperCase().trim());
    }

    // Range filter for price
    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
      // NOTE: Range filter on 'price' requires ordering by 'price' first
      query = query.orderBy('price', descending: false);
    } else {
      // Default sorting: Newest first
      query = query.orderBy('createdAt', descending: true);
    }

    try {
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => 
        ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  /// Add a new product to Firestore
  Future<void> addProduct(ProductModel product) async {
    await _db.collection('products').add(product.toJson());
  }
}
