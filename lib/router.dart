import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants/app_colors.dart';
import 'constants/app_routes.dart';
import 'data/dummy_categories.dart';
import 'models/product_model.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/about/about_us_screen.dart';
import 'screens/about/campus_safety_guide_screen.dart';
import 'screens/listing/listing_detail_screen.dart';
import 'screens/listing/add_listing_screen.dart';
import 'screens/listing/edit_listing_screen.dart';
import 'screens/listing/all_listings_screen.dart';
import 'screens/listing/department_listings_screen.dart';
import 'screens/listing/favourite_listings_screen.dart';
import 'screens/listing/pending_listings_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/seller_profile_screen.dart';
import 'screens/category_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/subscription/payment_screen.dart';
import 'screens/subscription/subscribed_users_screen.dart';

enum _RouteGuard { verified, admin, payment }

/// Central router — all named routes are registered here.
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case AppRoutes.emailVerification:
        return MaterialPageRoute(
          builder: (_) => const EmailVerificationScreen(),
        );

      case AppRoutes.login:
        // Optional argument 'register' opens the form in register mode
        final arg = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(
            initialMode: arg == 'register'
                ? LoginMode.register
                : LoginMode.login,
          ),
        );

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(child: HomeScreen()),
        );

      case AppRoutes.aboutUs:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(child: AboutUsScreen()),
        );

      case AppRoutes.campusSafetyGuide:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(child: CampusSafetyGuideScreen()),
        );

      case AppRoutes.listingDetail:
        final productId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) =>
              _GuardedRoute(child: ListingDetailScreen(productId: productId)),
        );

      case AppRoutes.addListing:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(child: AddListingScreen()),
        );

      case AppRoutes.editListing:
        final product = settings.arguments as ProductModel;
        return MaterialPageRoute(
          builder: (_) =>
              _GuardedRoute(child: EditListingScreen(product: product)),
        );

      case AppRoutes.offersListings:
        return MaterialPageRoute(
          builder: (_) =>
              const _GuardedRoute(child: AllListingsScreen(offersOnly: true)),
        );

      case AppRoutes.departmentListings:
        final category = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => _GuardedRoute(
            child: DepartmentListingsScreen(category: category),
          ),
        );

      case AppRoutes.category:
        final categoryName = settings.arguments as String? ?? '';
        final category = dummyCategories.firstWhere(
          (item) => item.name == categoryName,
          orElse: () => dummyCategories.first,
        );
        return MaterialPageRoute(
          builder: (_) =>
              _GuardedRoute(child: CategoryScreen(category: category)),
        );

      case AppRoutes.allListings:
        final initialCategory = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => _GuardedRoute(
            child: AllListingsScreen(initialCategory: initialCategory),
          ),
        );

      case AppRoutes.pendingListings:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(
            guard: _RouteGuard.admin,
            child: PendingListingsScreen(),
          ),
        );

      case AppRoutes.favouriteListings:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(child: FavouriteListingsScreen()),
        );

      case AppRoutes.chatList:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(child: ChatListScreen()),
        );

      case AppRoutes.chatDetail:
        final conversationId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => _GuardedRoute(
            child: ChatDetailScreen(conversationId: conversationId),
          ),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(child: ProfileScreen()),
        );

      case AppRoutes.editProfile:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(child: EditProfileScreen()),
        );

      case AppRoutes.sellerProfile:
        final uid = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => _GuardedRoute(child: SellerProfileScreen(uid: uid)),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(child: SettingsScreen()),
        );

      case AppRoutes.payment:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(
            guard: _RouteGuard.payment,
            child: PaymentScreen(),
          ),
        );

      case AppRoutes.subscribedUsers:
        return MaterialPageRoute(
          builder: (_) => const _GuardedRoute(
            guard: _RouteGuard.admin,
            child: SubscribedUsersScreen(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

class _GuardedRoute extends ConsumerWidget {
  final Widget child;
  final _RouteGuard guard;

  const _GuardedRoute({required this.child, this.guard = _RouteGuard.verified});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final userAsync = ref.watch(currentUserModelProvider);

    return authAsync.when(
      loading: () => const _RouteLoadingScreen(),
      error: (_, __) => const _RouteRedirectScreen(routeName: AppRoutes.login),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const _RouteRedirectScreen(routeName: AppRoutes.login);
        }

        if (guard == _RouteGuard.verified) return child;

        return userAsync.when(
          loading: () => const _RouteLoadingScreen(),
          error: (_, __) =>
              const _RouteRedirectScreen(routeName: AppRoutes.home),
          data: (user) {
            final isAdmin = user?.role == 'admin';
            final hasActiveSubscription =
                user?.isSubscribed == true &&
                user?.subscriptionExpiresAt?.isAfter(DateTime.now()) == true;

            if (guard == _RouteGuard.admin && !isAdmin) {
              return const _RouteRedirectScreen(routeName: AppRoutes.home);
            }

            if (guard == _RouteGuard.payment && hasActiveSubscription) {
              return const _RouteRedirectScreen(routeName: AppRoutes.home);
            }

            return child;
          },
        );
      },
    );
  }
}

class _RouteRedirectScreen extends StatefulWidget {
  final String routeName;

  const _RouteRedirectScreen({required this.routeName});

  @override
  State<_RouteRedirectScreen> createState() => _RouteRedirectScreenState();
}

class _RouteRedirectScreenState extends State<_RouteRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(widget.routeName, (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) => const _RouteLoadingScreen();
}

class _RouteLoadingScreen extends StatelessWidget {
  const _RouteLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

/// Shown inline inside [_GuardedRoute] when the user is signed in but their
/// email is not yet verified.
///
/// Periodically calls [user.reload()] so that when the user clicks the
/// verification link, the [authStateProvider] stream emits an updated user
/// and [_GuardedRoute] automatically shows the real screen — no Navigator
/// calls are made from this widget.
class _InlineEmailVerificationWall extends ConsumerStatefulWidget {
  const _InlineEmailVerificationWall();

  @override
  ConsumerState<_InlineEmailVerificationWall> createState() =>
      _InlineEmailVerificationWallState();
}

class _InlineEmailVerificationWallState
    extends ConsumerState<_InlineEmailVerificationWall> {
  Timer? _timer;
  bool _isSending = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    // Poll Firebase every 5 s; the stream drives navigation automatically.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.read(authServiceProvider).reloadCurrentUser();
    });
    // Auto-navigate to home after 5 seconds regardless of verification.
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (_) => false,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() {
      _isSending = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).resendVerificationEmail();
      if (mounted) {
        setState(() => _message = 'Verification email sent! Check your inbox.');
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _message = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify your email',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to\n$email\n\nClick the link in your inbox to continue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _message!.contains('sent')
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _isSending ? null : _resend,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(_isSending ? 'Sending…' : 'Resend verification email'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (_) => false,
                      );
                    }
                  },
                  child: const Text(
                    'Sign out',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
