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

/// Convenience provider: true when a user is signed in AND verified.
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
