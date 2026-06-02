import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/product_status.dart';

/// Data model for a product listing in the UniTrade marketplace.
class ProductModel {
  final String productId;
  final String sellerId;
  final String title;
  final String description;
  final double price;

  /// Optional discounted price set by the seller without admin approval.
  /// When non-null and less than [price], the listing is considered on offer.
  final double? discountedPrice;

  final String category;
  final String? courseCode;
  final List<String> images;
  final String status;
  final DateTime createdAt;
  final String? sellerUniversity;
  final DateTime? soldAt;

  ProductModel({
    required this.productId,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    this.discountedPrice,
    required this.category,
    this.courseCode,
    required this.images,
    required this.status,
    required this.createdAt,
    this.sellerUniversity,
    this.soldAt,
  });

  // ── Computed discount helpers ───────────────────────────────────────────────

  /// Returns `true` when an active discount is applied (discountedPrice < price).
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  /// The effective selling price — discounted price when available, else [price].
  double get effectivePrice => discountedPrice ?? price;

  /// Discount as an integer percentage (e.g. 25 for 25% off). Returns 0 when
  /// there is no active discount.
  int get discountPercent =>
      hasDiscount ? (((price - discountedPrice!) / price) * 100).round() : 0;

  // ── Serialisation ───────────────────────────────────────────────────────────

  factory ProductModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ProductModel(
      // Prefer the stored productId field; fall back to the Firestore doc ID.
      productId: (json['productId'] as String?)?.isNotEmpty == true
          ? json['productId'] as String
          : documentId,
      sellerId: json['sellerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      category: json['category'] ?? '',
      courseCode: json['courseCode'],
      images: List<String>.from(json['images'] ?? []),
      status: ProductStatus.normalize(
        json['status'] ?? ProductStatus.published,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      sellerUniversity: json['sellerUniversity'] as String?,
      soldAt: (json['soldAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      if (discountedPrice != null) 'discountedPrice': discountedPrice,
      'category': category,
      'courseCode': courseCode,
      'images': images,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (sellerUniversity != null) 'sellerUniversity': sellerUniversity,
      if (soldAt != null) 'soldAt': Timestamp.fromDate(soldAt!),
    };
  }
}
