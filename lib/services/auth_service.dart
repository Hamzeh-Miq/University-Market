import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// Handles Firebase Authentication operations for UniTrade.
class AuthService {
  static const String studentEmailDomain = '@students.asu.edu.jo';
  static const String adminEmail = '202120554@students.asu.edu.jo';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  /// Pure helper so the student email rule can be tested without Firebase.
  static bool isStudentEmail(String email) {
    return email.trim().toLowerCase().endsWith(studentEmailDomain);
  }

  /// Validates if the email belongs to Applied Science University students.
  bool isValidEduEmail(String email) {
    return isStudentEmail(email);
  }

  /// Returns a stream of the current user's authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Resends the Firebase email-verification link to the current signed-in user.
  /// Throws if no user is signed in.
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');
    await user.sendEmailVerification();
  }

  /// Reloads the current Firebase user to get the latest [emailVerified] status.
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Registers a student user and creates their Firestore profile.
  Future<UserCredential?> registerStudent(
    String email,
    String password, {
    required String firstName,
    String middleName = '',
    required String lastName,
    required String phoneNumber,
  }) async {
    if (!isValidEduEmail(email)) {
      throw Exception(
        'Access restricted. Only $studentEmailDomain email addresses are allowed.',
      );
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      final String role = email.trim().toLowerCase() == adminEmail
          ? 'admin'
          : 'user';

      // Build and store the user profile in Firestore
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        firstName: firstName.trim(),
        middleName: middleName.trim(),
        lastName: lastName.trim(),
        phoneNumber: phoneNumber.trim(),
        university: 'Applied Science Private University',
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
