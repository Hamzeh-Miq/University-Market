import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Exposes the [AuthService] as a singleton across the app.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Exposes the [UserService] as a singleton across the app.
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

/// Exposes a real-time stream of the current Firebase [User].
/// Widgets can watch this to react to login/logout instantly.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Convenience provider: true when a user is signed in AND has a verified
/// email. SMS 2FA is optional — it is not a gate for app access.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(authStateProvider);
  return userAsync.maybeWhen(
    data: (user) => user != null && user.emailVerified,
    orElse: () => false,
  );
});

/// Exposes the current user's profile model, which includes their role
final currentUserModelProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final userAsync = ref.watch(authStateProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userServiceProvider).watchUserProfile(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Convenience provider: true when the current user has the 'admin' role.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserModelProvider).value?.role == 'admin';
});

/// Exposes any user's public profile by their UID.
/// Used to display seller info on listing/admin screens.
final sellerProfileProvider = FutureProvider.autoDispose
    .family<UserModel?, String>((ref, uid) async {
      return ref.read(userServiceProvider).getUserProfile(uid);
    });

/// Exposes all currently active subscribed users for admin dashboards.
final subscribedUsersProvider = StreamProvider.autoDispose<List<UserModel>>((
  ref,
) {
  return ref.watch(userServiceProvider).watchSubscribedUsers();
});

/// True when the current user has a paid, non-expired annual subscription.
/// Checks both the [isSubscribed] flag and [subscriptionExpiresAt] against now.
final hasActiveSubscriptionProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserModelProvider).value;
  if (user == null || !user.isSubscribed) return false;
  final expiry = user.subscriptionExpiresAt;
  if (expiry == null) return false;
  return expiry.isAfter(DateTime.now());
});

/// True when the current user is allowed to view other users' profiles.
/// Admins always have access; regular users need an active subscription.
final canViewOtherProfilesProvider = Provider<bool>((ref) {
  return ref.watch(isAdminProvider) || ref.watch(hasActiveSubscriptionProvider);
});

/// Reports whether the currently signed-in Firebase user has enrolled an SMS
/// second factor.
///
/// We intentionally do NOT pass the [User] object from the auth stream
/// because stream emission caches the user snapshot. Instead we call
/// [hasEnrolledSecondFactor] with no argument so it reads
/// `FirebaseAuth.instance.currentUser` — which always reflects the latest
/// server state after a [reload] call.
final secondFactorEnrolledProvider = FutureProvider<bool>((ref) async {
  // Watch auth state only to re-run this provider whenever sign-in changes.
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return false;
  return ref.read(authServiceProvider).hasEnrolledSecondFactor();
});

/// Distinguishes whether the verification screen is handling initial MFA
/// enrollment or the second step of a sign-in challenge.
enum TwoFactorFlowMode { idle, enrollment, signInChallenge }

/// Holds transient second-factor verification state between the login screen
/// and the dedicated verification UI.
class TwoFactorFlowState {
  final TwoFactorFlowMode mode;
  final bool isLoading;
  final String phoneNumber;
  final String maskedPhoneNumber;
  final String verificationId;
  final int? resendToken;
  final String? errorMessage;
  final MultiFactorResolver? resolver;

  const TwoFactorFlowState({
    this.mode = TwoFactorFlowMode.idle,
    this.isLoading = false,
    this.phoneNumber = '',
    this.maskedPhoneNumber = '',
    this.verificationId = '',
    this.resendToken,
    this.errorMessage,
    this.resolver,
  });

  /// True when the current flow is waiting for the user to enter the SMS code.
  bool get isAwaitingCode => verificationId.isNotEmpty;

  /// Creates a copy with selected fields overridden.
  TwoFactorFlowState copyWith({
    TwoFactorFlowMode? mode,
    bool? isLoading,
    String? phoneNumber,
    String? maskedPhoneNumber,
    String? verificationId,
    int? resendToken,
    Object? errorMessage = _sentinel,
    Object? resolver = _sentinel,
  }) {
    return TwoFactorFlowState(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      maskedPhoneNumber: maskedPhoneNumber ?? this.maskedPhoneNumber,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      resolver: identical(resolver, _sentinel)
          ? this.resolver
          : resolver as MultiFactorResolver?,
    );
  }

  /// Returns a cleared state.
  static const TwoFactorFlowState initial = TwoFactorFlowState();
}

const Object _sentinel = Object();

/// Controls the temporary SMS MFA verification flow across authentication
/// screens without exposing Firebase SDK calls to the UI layer.
class TwoFactorFlowNotifier extends Notifier<TwoFactorFlowState> {
  @override
  TwoFactorFlowState build() => TwoFactorFlowState.initial;

  AuthService get _authService => ref.read(authServiceProvider);

  /// Clears any pending second-factor state.
  void reset() {
    state = TwoFactorFlowState.initial;
  }

  /// Starts a required phone enrollment flow for the currently signed-in user.
  Future<bool> startEnrollment(String phoneNumber) async {
    state = state.copyWith(
      mode: TwoFactorFlowMode.enrollment,
      isLoading: true,
      phoneNumber: phoneNumber,
      errorMessage: null,
      resolver: null,
      verificationId: '',
    );

    try {
      final result = await _authService.beginSecondFactorEnrollment(
        phoneNumber,
      );
      if (result.completedInstantly) {
        reset();
        return true;
      }

      state = state.copyWith(
        mode: TwoFactorFlowMode.enrollment,
        isLoading: false,
        phoneNumber: result.phoneNumber ?? phoneNumber,
        maskedPhoneNumber: result.maskedPhoneNumber ?? '',
        verificationId: result.verificationId ?? '',
        resendToken: result.resendToken,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Sends the SMS second-factor challenge for a pending MFA sign-in.
  Future<bool> startSignInChallenge(
    FirebaseAuthMultiFactorException exception,
  ) async {
    state = state.copyWith(
      mode: TwoFactorFlowMode.signInChallenge,
      isLoading: true,
      errorMessage: null,
      resolver: exception.resolver,
      verificationId: '',
    );

    try {
      final result = await _authService.beginSecondFactorSignInChallenge(
        exception.resolver,
      );
      if (result.completedInstantly) {
        reset();
        return true;
      }

      state = state.copyWith(
        mode: TwoFactorFlowMode.signInChallenge,
        isLoading: false,
        maskedPhoneNumber: result.maskedPhoneNumber ?? '',
        verificationId: result.verificationId ?? '',
        resendToken: result.resendToken,
        phoneNumber: result.phoneNumber ?? '',
        resolver: exception.resolver,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Retries the current SMS step using the previously entered context.
  Future<bool> resendCode() async {
    if (state.mode == TwoFactorFlowMode.signInChallenge &&
        state.resolver != null) {
      final resolver = state.resolver!;
      state = state.copyWith(isLoading: true, errorMessage: null);
      try {
        final result = await _authService.beginSecondFactorSignInChallenge(
          resolver,
        );
        if (result.completedInstantly) {
          reset();
          return true;
        }

        state = state.copyWith(
          isLoading: false,
          maskedPhoneNumber:
              result.maskedPhoneNumber ?? state.maskedPhoneNumber,
          verificationId: result.verificationId ?? state.verificationId,
          resendToken: result.resendToken,
          phoneNumber: result.phoneNumber ?? state.phoneNumber,
        );
        return false;
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
        return false;
      }
    }

    if (state.mode == TwoFactorFlowMode.enrollment &&
        state.phoneNumber.isNotEmpty) {
      return startEnrollment(state.phoneNumber);
    }

    return false;
  }

  /// Confirms the SMS code for either enrollment or sign-in challenge flows.
  Future<bool> submitCode(String smsCode) async {
    if (state.verificationId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Request a verification code before confirming 2FA.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      switch (state.mode) {
        case TwoFactorFlowMode.enrollment:
          await _authService.completeSecondFactorEnrollment(
            verificationId: state.verificationId,
            smsCode: smsCode,
          );
          break;
        case TwoFactorFlowMode.signInChallenge:
          final resolver = state.resolver;
          if (resolver == null) {
            throw Exception(
              'The sign-in session expired. Please log in again.',
            );
          }
          await _authService.completeSecondFactorSignIn(
            resolver: resolver,
            verificationId: state.verificationId,
            smsCode: smsCode,
          );
          break;
        case TwoFactorFlowMode.idle:
          throw Exception('Start 2FA before entering a verification code.');
      }

      reset();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

/// Exposes second-factor flow state to the auth screens.
final twoFactorFlowProvider =
    NotifierProvider<TwoFactorFlowNotifier, TwoFactorFlowState>(
      TwoFactorFlowNotifier.new,
    );
