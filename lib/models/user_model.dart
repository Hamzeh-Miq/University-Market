import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a UniTrade user profile document stored in Firestore.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String fullName;
  final String phoneNumber;
  final String university;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.fullName,
    required this.phoneNumber,
    required this.university,
    required this.isVerified,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.role = 'user',
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      uid: documentId,
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      university: json['university'] ?? '',
      isVerified: json['isVerified'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'university': university,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': role,
    };
  }
}
