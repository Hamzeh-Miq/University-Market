# Admin Approval Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use flutter-craft:flutter-executing to implement this plan task-by-task.

**Goal:** Implement role-based access for admins to review, approve, edit, and delete pending listings and user accounts.

**Architecture:** Clean Architecture with Riverpod

**Dependencies:** None

---

## Data Layer

### Task 1: UserModel
**Layer:** Data
**Files:**
- Modify: `lib/models/user_model.dart`

**Implementation:**
```dart
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
  final String role; // <-- NEW FIELD

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
    this.role = 'user', // <-- DEFAULT VALUE
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
      role: json['role'] ?? 'user', // <-- PARSE ROLE
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
      'role': role, // <-- ADD ROLE TO JSON
    };
  }
}
```

**Verification:**
```bash
flutter analyze lib/models/user_model.dart
```

### Task 2: AuthService Admin Logic
**Layer:** Data
**Files:**
- Modify: `lib/services/auth_service.dart`

**Implementation:**
```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// Handles Firebase Authentication operations for UniTrade.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  /// Validates if the email belongs to a university (.edu domain).
  bool isValidEduEmail(String email) {
    final RegExp eduRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.edu(\.[a-zA-Z]{2,})?$');
    return eduRegex.hasMatch(email.trim().toLowerCase());
  }

  /// Registers a student user and creates their Firestore profile.
  Future<UserCredential?> registerStudent(
    String email,
    String password, {
    required String fullName,
    required String phoneNumber,
  }) async {
    if (!isValidEduEmail(email)) {
      throw Exception(
          'Access restricted. Please use a valid university .edu email.');
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      // Check if admin
      final String role = email.trim().toLowerCase() == '202120554@students.asu.edu.jo' ? 'admin' : 'user';

      // Build and store the user profile in Firestore
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: fullName.trim().split(' ').first,
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        university: 'University of Jordan',
        isVerified: false,
        createdAt: DateTime.now(),
        role: role,
      );
      await _userService.createUserProfile(userModel);

      return userCredential;
    } catch (e) {
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  /// Sign in an existing user.
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

**Verification:**
```bash
flutter analyze lib/services/auth_service.dart
```

### Task 3: ProductService Admin Methods
**Layer:** Data
**Files:**
- Modify: `lib/services/product_service.dart`

**Implementation:** Add these two methods inside the class:
```dart
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
```

**Verification:**
```bash
flutter analyze lib/services/product_service.dart
```

---

## Presentation Layer

### Task 4: CurrentUserModelProvider
**Layer:** Presentation
**Files:**
- Modify: `lib/providers/auth_provider.dart`

**Implementation:** Add this provider to the file:
```dart
import '../models/user_model.dart';
import '../services/user_service.dart';

/// Exposes the current user's profile model, which includes their role
final currentUserModelProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final userAsync = ref.watch(authStateProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return UserService().watchUserProfile(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
```

**Verification:**
```bash
flutter analyze lib/providers/auth_provider.dart
```

### Task 5: Pending Listings Provider
**Layer:** Presentation
**Files:**
- Modify: `lib/providers/product_provider.dart`

**Implementation:** Add this provider to the file:
```dart
// ── Pending listings provider ─────────────────────────────────────────────────

/// Fetches products that are pending approval (Admin Only)
final pendingListingsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final service = ref.read(productServiceProvider);
  return service.fetchPendingListings();
});
```

**Verification:**
```bash
flutter analyze lib/providers/product_provider.dart
```

### Task 6: AddListingScreen Default Status
**Layer:** Presentation
**Files:**
- Modify: `lib/screens/listing/add_listing_screen.dart`

**Implementation:**
Around line 79, change:
```dart
        images: const [],
        status: 'Pending', // <-- changed from 'Available'
        createdAt: DateTime.now(),
```

**Verification:**
```bash
flutter analyze lib/screens/listing/add_listing_screen.dart
```

### Task 7: Listing Detail Admin Actions
**Layer:** Presentation
**Files:**
- Modify: `lib/screens/listing/listing_detail_screen.dart`

**Implementation:**
Add this functionality to `ListingDetailScreen`:
1. Read the `currentUserModelProvider`:
`final userModelAsync = ref.watch(currentUserModelProvider);`
`final userModel = userModelAsync.value;`
`final isAdmin = userModel?.role == 'admin';`

2. After `if (!isOwner)` block, conditionally add Admin action buttons for approving the listing if it is pending, or deleting the listing outright.

**Verification:**
```bash
flutter analyze lib/screens/listing/listing_detail_screen.dart
```

---

## Testing

### Task 8: Unit Testing
**Layer:** Test
**Files:**
- Create: `test/services/auth_service_test.dart`
*(We will skip creating the test file for now unless specifically needed for regression).*

**Verification:**
```bash
flutter test
```
