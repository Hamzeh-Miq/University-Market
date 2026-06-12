    import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// Serializable result returned when Firebase has sent or auto-resolved an SMS
/// challenge for second-factor enrollment or sign-in.
class PhoneVerificationResult {
  final bool completedInstantly;
  final String? verificationId;
  final int? resendToken;
  final String? maskedPhoneNumber;
  final String? phoneNumber;

  const PhoneVerificationResult._({
    required this.completedInstantly,
    this.verificationId,
    this.resendToken,
    this.maskedPhoneNumber,
    this.phoneNumber,
  });

  /// Returned when Firebase completes the phone challenge without manual code
  /// entry, such as instant verification on Android.
  const PhoneVerificationResult.completed() : this._(completedInstantly: true);

  /// Returned when the app needs the user to enter the SMS code manually.
  const PhoneVerificationResult.codeSent({
    required String verificationId,
    required int? resendToken,
    required String maskedPhoneNumber,
    required String phoneNumber,
  }) : this._(
         completedInstantly: false,
         verificationId: verificationId,
         resendToken: resendToken,
         maskedPhoneNumber: maskedPhoneNumber,
         phoneNumber: phoneNumber,
       );
}

/// Handles Firebase Authentication operations for UniSooq.
class AuthService {
  static const String studentEmailDomain = '@students.asu.edu.jo';
  static const String adminEmail = '202120554@students.asu.edu.jo';
  static const String _pendingProfilePrefix = 'unisooq_pending_profile:';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  /// Pure helper so the student email rule can be tested without Firebase.
  static bool isStudentEmail(String email) {
    return email.trim().toLowerCase().endsWith(studentEmailDomain);
  }

  /// Validates if the email belongs to Applied Science Private University students.
  bool isValidEduEmail(String email) {
    return isStudentEmail(email);
  }

  /// Returns a stream of the current user's authentication state.
  Stream<User?> get authStateChanges => _auth.userChanges();

  /// Returns the currently signed-in Firebase user, if any.
  User? get currentUser => _auth.currentUser;

  /// Resends the Firebase verification link to the current user.
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }
    await user.sendEmailVerification();
  }

  /// Reloads and returns the latest signed-in Firebase user.
  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    await user.reload();
    return _auth.currentUser;
  }

  /// Reloads the current user and returns whether the email is verified.
  Future<bool> reloadAndCheckVerified() async {
    final user = await reloadCurrentUser();
    return user?.emailVerified ?? false;
  }

  /// Returns true when the provided or current user has at least one enrolled
  /// phone second factor.
  Future<bool> hasEnrolledSecondFactor([User? user]) async {
    final targetUser = user ?? _auth.currentUser;
    if (targetUser == null) {
      return false;
    }

    final factors = await targetUser.multiFactor.getEnrolledFactors();
    return factors.whereType<PhoneMultiFactorInfo>().isNotEmpty;
  }

  /// Returns true when the provided or current user has completed the full
  /// email + SMS second-factor requirements.
  Future<bool> isFullyVerified([User? user]) async {
    final targetUser = user ?? _auth.currentUser;
    if (targetUser == null) {
      return false;
    }
    return targetUser.emailVerified &&
        await hasEnrolledSecondFactor(targetUser);
  }

  /// Converts student-entered phone numbers into Firebase-friendly E.164
  /// format for Jordanian mobile numbers.
  String normalizePhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (digitsOnly.startsWith('+')) {
      return digitsOnly;
    }
    if (digitsOnly.startsWith('00962')) {
      return '+${digitsOnly.substring(2)}';
    }
    if (digitsOnly.startsWith('962')) {
      return '+$digitsOnly';
    }
    if (digitsOnly.startsWith('07')) {
      return '+962${digitsOnly.substring(1)}';
    }
    if (digitsOnly.startsWith('7')) {
      return '+962$digitsOnly';
    }
    throw Exception(
      'Enter a valid Jordanian mobile number, for example 07XXXXXXXX or +9627XXXXXXXX.',
    );
  }

  /// Masks a phone number for display inside verification prompts.
  String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 4) {
      return phoneNumber;
    }

    final visibleStart = phoneNumber.substring(0, 4);
    final visibleEnd = phoneNumber.substring(phoneNumber.length - 2);
    final hiddenLength = phoneNumber.length - 6;
    return '$visibleStart${List.filled(hiddenLength, '*').join()}$visibleEnd';
  }

  /// Registers a student user in Firebase Auth and stores their profile details
  /// temporarily until the email is verified.
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

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase did not return a registered user.');
      }

      final pendingProfile = _PendingRegistrationProfile(
        email: email,
        firstName: firstName.trim(),
        middleName: middleName.trim(),
        lastName: lastName.trim(),
        phoneNumber: phoneNumber.trim(),
      );

      try {
        await _storePendingRegistrationProfile(user, pendingProfile);
        await user.sendEmailVerification();
      } catch (e, st) {
        try {
          await user.delete();
        } catch (deleteError) {
          debugPrint(
            'Failed to roll back Firebase Auth user after pending profile setup failed: $deleteError',
          );
        }
        Error.throwWithStackTrace(e, st);
      }

      return userCredential;
    } catch (e, st) {
      Error.throwWithStackTrace(
        Exception('Failed to register: ${e.toString()}'),
        st,
      );
    }
  }

  /// Sign in an existing user.
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Creates the Firestore user profile for the signed-in user if it does not
  /// already exist. Email verification is not required.
  Future<UserModel> ensureVerifiedUserProfileExists({
    String? phoneNumberOverride,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You need to sign in before continuing registration.');
    }

    final existingProfile = await _userService.getUserProfile(user.uid);
    if (existingProfile != null) {
      return existingProfile;
    }

    final pendingProfile = _decodePendingRegistrationProfile(user.displayName);
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw Exception('Your account is missing an email address.');
    }

    final localPart = email.split('@').first.trim();
    final fallbackFirstName = localPart.isEmpty ? 'Student' : localPart;
    final fallbackPhone = phoneNumberOverride?.trim() ?? '';
    final resolvedPhoneNumber =
        pendingProfile?.phoneNumber.trim().isNotEmpty == true
        ? pendingProfile!.phoneNumber.trim()
        : fallbackPhone;

    final userModel = UserModel(
      uid: user.uid,
      email: email,
      firstName: pendingProfile?.firstName.trim().isNotEmpty == true
          ? pendingProfile!.firstName.trim()
          : fallbackFirstName,
      middleName: pendingProfile?.middleName.trim() ?? '',
      lastName: pendingProfile?.lastName.trim() ?? '',
      phoneNumber: resolvedPhoneNumber,
      university: 'Applied Science Private University',
      isVerified: true,
      createdAt: DateTime.now(),
      role: email.toLowerCase() == adminEmail ? 'admin' : 'user',
    );

    await _userService.createUserProfile(userModel);

    // Once the profile is persisted, replace the temporary encoded payload
    // with a readable display name for the Auth user.
    await user.updateDisplayName(userModel.fullName);

    return userModel;
  }

  /// Starts phone enrollment for the current signed-in user.
  Future<PhoneVerificationResult> beginSecondFactorEnrollment(
    String phoneNumber,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You need to sign in before setting up 2FA.');
    }
    if (!user.emailVerified) {
      throw Exception('Verify your university email before setting up 2FA.');
    }

    final normalizedPhone = normalizePhoneNumber(phoneNumber);
    final session = await user.multiFactor.getSession();
    final completer = Completer<PhoneVerificationResult>();

    await _auth.verifyPhoneNumber(
      multiFactorSession: session,
      phoneNumber: normalizedPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        if (completer.isCompleted) {
          return;
        }

        try {
          await user.multiFactor.enroll(
            PhoneMultiFactorGenerator.getAssertion(credential),
          );
          await reloadCurrentUser();
          completer.complete(const PhoneVerificationResult.completed());
        } catch (e, st) {
          completer.completeError(
            Exception('Failed to automatically enroll 2FA: $e'),
            st,
          );
        }
      },
      verificationFailed: (e) {
        if (completer.isCompleted) {
          return;
        }
        completer.completeError(Exception(_mapPhoneAuthError(e)));
      },
      codeSent: (verificationId, resendToken) {
        if (completer.isCompleted) {
          return;
        }
        completer.complete(
          PhoneVerificationResult.codeSent(
            verificationId: verificationId,
            resendToken: resendToken,
            maskedPhoneNumber: maskPhoneNumber(normalizedPhone),
            phoneNumber: normalizedPhone,
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  /// Completes second-factor enrollment using the SMS code entered by the user.
  Future<void> completeSecondFactorEnrollment({
    required String verificationId,
    required String smsCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You need to sign in before confirming 2FA.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    await user.multiFactor.enroll(
      PhoneMultiFactorGenerator.getAssertion(credential),
    );
    await reloadCurrentUser();
  }

  /// Removes the first enrolled SMS phone second factor from the current user.
  ///
  /// Throws [Exception] if the user is not signed in, has no enrolled factor,
  /// or if Firebase requires re-authentication (stale session).
  Future<void> unenrollSecondFactor() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You need to sign in before changing 2FA settings.');
    }
    final factors = await user.multiFactor.getEnrolledFactors();
    final phoneFactor = factors.whereType<PhoneMultiFactorInfo>().firstOrNull;
    if (phoneFactor == null) {
      throw Exception('No SMS second factor is enrolled on this account.');
    }
    await user.multiFactor.unenroll(multiFactorInfo: phoneFactor);
    await reloadCurrentUser();
  }

  /// Sends the SMS challenge for a pending multi-factor sign-in flow.
  Future<PhoneVerificationResult> beginSecondFactorSignInChallenge(
    MultiFactorResolver resolver,
  ) async {
    final hint = resolver.hints.whereType<PhoneMultiFactorInfo>().firstOrNull;
    if (hint == null) {
      throw Exception('No SMS second factor is available for this account.');
    }

    final completer = Completer<PhoneVerificationResult>();

    await _auth.verifyPhoneNumber(
      multiFactorSession: resolver.session,
      multiFactorInfo: hint,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        if (completer.isCompleted) {
          return;
        }

        try {
          await resolver.resolveSignIn(
            PhoneMultiFactorGenerator.getAssertion(credential),
          );
          completer.complete(const PhoneVerificationResult.completed());
        } catch (e, st) {
          completer.completeError(
            Exception('Failed to automatically complete 2FA sign-in: $e'),
            st,
          );
        }
      },
      verificationFailed: (e) {
        if (completer.isCompleted) {
          return;
        }
        completer.completeError(Exception(_mapPhoneAuthError(e)));
      },
      codeSent: (verificationId, resendToken) {
        if (completer.isCompleted) {
          return;
        }
        completer.complete(
          PhoneVerificationResult.codeSent(
            verificationId: verificationId,
            resendToken: resendToken,
            maskedPhoneNumber: hint.phoneNumber,
            phoneNumber: hint.phoneNumber,
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  /// Resolves a pending multi-factor sign-in after the user enters the SMS
  /// verification code.
  Future<void> completeSecondFactorSignIn({
    required MultiFactorResolver resolver,
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    await resolver.resolveSignIn(
      PhoneMultiFactorGenerator.getAssertion(credential),
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapPhoneAuthError(FirebaseAuthException exception) {
    final message = exception.message?.toLowerCase() ?? '';

    if (message.contains('sms based mfa not enabled') ||
        message.contains('sms-based mfa not enabled') ||
        message.contains('multi-factor') && message.contains('not enabled')) {
      return 'SMS 2FA is not enabled for this Firebase project yet. Open Firebase Console > Authentication > Sign-in method, enable Phone and SMS multi-factor authentication, then try again.';
    }

    if (message.contains('given sign-in provider is disabled') ||
        message.contains('sign-in provider is disabled')) {
      return 'Phone authentication is disabled in Firebase right now. Open Firebase Console > Authentication > Sign-in method and enable the Phone provider before setting up SMS 2FA.';
    }

    switch (exception.code) {
      case 'invalid-phone-number':
        return 'Enter a valid phone number before requesting a code.';
      case 'invalid-verification-code':
        return 'The verification code is incorrect. Please try again.';
      case 'session-expired':
        return 'This verification session expired. Please request a new code.';
      case 'too-many-requests':
        return 'Too many attempts were made. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return exception.message ??
            'Phone verification failed. Please try again.';
    }
  }

  Future<void> _storePendingRegistrationProfile(
    User user,
    _PendingRegistrationProfile profile,
  ) async {
    final encoded = base64Url.encode(utf8.encode(jsonEncode(profile.toJson())));
    await user.updateDisplayName('$_pendingProfilePrefix$encoded');
  }

  _PendingRegistrationProfile? _decodePendingRegistrationProfile(
    String? displayName,
  ) {
    if (displayName == null || !displayName.startsWith(_pendingProfilePrefix)) {
      return null;
    }

    try {
      final encoded = displayName.substring(_pendingProfilePrefix.length);
      final decodedJson = utf8.decode(base64Url.decode(encoded));
      final data = jsonDecode(decodedJson) as Map<String, dynamic>;
      return _PendingRegistrationProfile.fromJson(data);
    } catch (e) {
      debugPrint('Failed to decode pending registration profile: $e');
      return null;
    }
  }
}

class _PendingRegistrationProfile {
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String phoneNumber;

  const _PendingRegistrationProfile({
    required this.email,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.phoneNumber,
  });

  factory _PendingRegistrationProfile.fromJson(Map<String, dynamic> json) {
    return _PendingRegistrationProfile(
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
    };
  }
}
