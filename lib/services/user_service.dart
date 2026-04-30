import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

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
}

