import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String? courseCode;
  final List<String> images;
  final String status;
  final DateTime createdAt;

  ProductModel({
    required this.productId,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.courseCode,
    required this.images,
    required this.status,
    required this.createdAt,
  });

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
      category: json['category'] ?? '',
      courseCode: json['courseCode'],
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] ?? 'Available',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'courseCode': courseCode,
      'images': images,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
