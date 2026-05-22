import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/subscription_constants.dart';
import '../models/user_model.dart';

/// Handles all Firestore read/write operations for user profile documents.
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates a new user profile document in Firestore after registration.
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toJson());
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to create user profile: $e'), st);
    }
  }

  /// Fetches a user profile by their UID.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!, doc.id);
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to fetch user profile: $e'), st);
    }
  }

  /// Updates editable fields on a user's profile.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to update user profile: $e'), st);
    }
  }

  /// Returns a real-time stream of the current user's profile.
  Stream<UserModel?> watchUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!, doc.id);
    });
  }

  /// Searches for a user by exact email address.
  /// Returns the first matching [UserModel], or null if not found.
  Future<UserModel?> searchUserByEmail(String email) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return UserModel.fromJson(doc.data(), doc.id);
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to search user by email: $e'), st);
    }
  }

  /// Activates an annual subscription for [uid].
  /// Called by admin or payment screen. Sets isSubscribed, activatedAt, and expiresAt.
  Future<void> activateSubscription(String uid) async {
    try {
      final now = DateTime.now();
      final expiry = now.add(
          const Duration(days: SubscriptionConstants.subscriptionDays));
      await _db.collection('users').doc(uid).update({
        'isSubscribed': true,
        'subscriptionActivatedAt': Timestamp.fromDate(now),
        'subscriptionExpiresAt': Timestamp.fromDate(expiry),
      });
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to activate subscription: $e'), st);
    }
  }

  /// Revokes an active subscription for [uid]. Called by admin only.
  Future<void> revokeSubscription(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isSubscribed': false,
        'subscriptionExpiresAt': null,
        'subscriptionActivatedAt': null,
      });
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to revoke subscription: $e'), st);
    }
  }

  /// Returns a real-time stream of all users with an active subscription
  /// (isSubscribed == true AND subscriptionExpiresAt is in the future).
  Stream<List<UserModel>> watchSubscribedUsers() {
    final now = Timestamp.fromDate(DateTime.now());
    return _db
        .collection('users')
        .where('isSubscribed', isEqualTo: true)
        .where('subscriptionExpiresAt', isGreaterThan: now)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => UserModel.fromJson(d.data(), d.id)).toList());
  }
}
