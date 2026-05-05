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
