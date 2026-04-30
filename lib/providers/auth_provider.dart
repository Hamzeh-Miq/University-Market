import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// Exposes a real-time stream of the current Firebase [User].
/// Widgets can watch this to react to login/logout instantly.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Exposes the [AuthService] as a singleton across the app.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Convenience provider: true when a user is signed in AND verified.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(authStateProvider);
  return userAsync.maybeWhen(
    data: (user) => user != null && user.emailVerified,
    orElse: () => false,
  );
});
