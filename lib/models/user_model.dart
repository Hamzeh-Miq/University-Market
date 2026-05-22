import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a UniTrade user profile document stored in Firestore.
class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String phoneNumber;
  final String university;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final String role;

  /// Whether the user has an active semester subscription.
  final bool isSubscribed;

  /// The date/time when the current subscription expires.
  final DateTime? subscriptionExpiresAt;

  /// The date/time when the current subscription was activated by admin.
  final DateTime? subscriptionActivatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    required this.phoneNumber,
    required this.university,
    required this.isVerified,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.role = 'user',
    this.isSubscribed = false,
    this.subscriptionExpiresAt,
    this.subscriptionActivatedAt,
  });

  /// The user's display name (first name only).
  String get displayName => firstName;

  /// The user's full name assembled from the three parts.
  String get fullName {
    if (middleName.trim().isEmpty) {
      return '$firstName $lastName'.trim();
    }
    return '$firstName $middleName $lastName'.trim();
  }

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    // Support documents that still use the legacy 'fullName' field by splitting
    // it into parts when the new fields are absent.
    final storedFirst = json['firstName'] as String?;
    final storedMiddle = (json['middleName'] as String?) ?? '';
    final storedLast = json['lastName'] as String?;

    String firstName;
    String middleName;
    String lastName;

    if (storedFirst != null && storedFirst.isNotEmpty) {
      firstName = storedFirst;
      middleName = storedMiddle;
      lastName = storedLast ?? '';
    } else {
      // Fallback: split legacy 'fullName' into parts
      final parts = ((json['fullName'] as String?) ?? '').trim().split(' ');
      firstName = parts.isNotEmpty ? parts.first : '';
      lastName = parts.length > 1 ? parts.last : '';
      middleName = parts.length > 2 ? parts.sublist(1, parts.length - 1).join(' ') : '';
    }

    return UserModel(
      uid: documentId,
      email: json['email'] ?? '',
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      phoneNumber: json['phoneNumber'] ?? '',
      university: json['university'] ?? '',
      isVerified: json['isVerified'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      role: json['role'] ?? 'user',
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      subscriptionExpiresAt:
          (json['subscriptionExpiresAt'] as Timestamp?)?.toDate(),
      subscriptionActivatedAt:
          (json['subscriptionActivatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      // Keep fullName for any existing queries / display code that reads it
      'fullName': fullName,
      // Keep displayName field in sync
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'university': university,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': role,
      'isSubscribed': isSubscribed,
      'subscriptionExpiresAt': subscriptionExpiresAt != null
          ? Timestamp.fromDate(subscriptionExpiresAt!)
          : null,
      'subscriptionActivatedAt': subscriptionActivatedAt != null
          ? Timestamp.fromDate(subscriptionActivatedAt!)
          : null,
    };
  }
}
