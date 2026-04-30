import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Validates if the email belongs to a university (.edu domain)
  bool isValidEduEmail(String email) {
    // Allows subdomains (e.g., students.asu) and optional country codes (e.g., .jo, .uk)
    final RegExp eduRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.edu(\.[a-zA-Z]{2,})?$');
    return eduRegex.hasMatch(email.trim().toLowerCase());
  }

  /// Registers a student user
  Future<UserCredential?> registerStudent(String email, String password) async {
    if (!isValidEduEmail(email)) {
      throw Exception('Access restricted. Please use a valid university .edu email.');
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();
      
      return userCredential;
    } catch (e) {
      // Re-throw the error so the UI can catch and display it
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  /// Sign in
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
