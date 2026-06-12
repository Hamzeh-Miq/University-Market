import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';
import 'constants/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: UniSooqApp()));
}

/// Root application widget. Watches [themeModeProvider] to reactively
/// switch between light and dark mode.
class UniSooqApp extends ConsumerWidget {
  const UniSooqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final lightTheme = ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      textTheme: GoogleFonts.interTextTheme(),
      primaryTextTheme: GoogleFonts.interTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        focusColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      primaryTextTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: const Color(0xFF1C2128),
        onSurface: const Color(0xFFE6EDF3),
        onSurfaceVariant: const Color(0xFF8B949E),
        outline: const Color(0xFF30363D),
        outlineVariant: const Color(0xFF21262D),
        surfaceContainerHighest: const Color(0xFF21262D),
        surfaceContainerLow: const Color(0xFF161B22),
        surfaceContainerHigh: const Color(0xFF262C36),
        inverseSurface: const Color(0xFFE6EDF3),
        onInverseSurface: const Color(0xFF0D1117),
        primaryContainer: AppColors.primary.withValues(alpha: 0.22),
        onPrimaryContainer: const Color(0xFFE6EDF3),
        secondaryContainer: AppColors.accent.withValues(alpha: 0.22),
        onSecondaryContainer: const Color(0xFFE6EDF3),
        tertiaryContainer: AppColors.amber.withValues(alpha: 0.22),
        onTertiaryContainer: const Color(0xFFE6EDF3),
        tertiary: AppColors.amber,
        onTertiary: Colors.white,
        scrim: Colors.black,
        shadow: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2128),
        focusColor: AppColors.primary,
        labelStyle: const TextStyle(color: Color(0xFF8B949E)),
        hintStyle: const TextStyle(color: Color(0xFF6E7681)),
        prefixIconColor: AppColors.primary,
        suffixIconColor: const Color(0xFF8B949E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      cardColor: const Color(0xFF1C2128),
      dividerColor: const Color(0xFF30363D),
    );

    return MaterialApp(
      title: 'UniSooq',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      // _AuthGate determines the first screen based on Firebase Auth state.
      // Named routes are still fully functional for in-app navigation.
      home: const _AuthGate(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

/// Reads Firebase Auth state on startup and routes users to the correct
/// initial screen — no dark welcome screen flash for already-signed-in users.
///
/// - Loading                     → light splash + spinner
/// - Not signed in               → [AppRoutes.welcome] (rendered inline)
/// - Signed in, unverified email → [AppRoutes.emailVerification]
/// - Signed in, email verified   → [AppRoutes.home]
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  /// Ensures we only push a named route once, even if the auth stream
  /// emits multiple times before the frame callback fires.
  bool _navigated = false;

  void _navigateTo(String route) {
    if (_navigated) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _navigated) return;
      setState(() => _navigated = true);
      Navigator.of(context).pushReplacementNamed(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Once we've navigated away, keep showing the neutral splash until the
    // route transition completes and this widget is disposed.
    if (_navigated) {
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),

      error: (_, __) => const WelcomeScreen(),

      data: (user) {
        if (user == null) {
          // Not logged in — render WelcomeScreen directly.
          return const WelcomeScreen();
        }
        // Logged in — go straight to home (email verification not enforced).
        _navigateTo(AppRoutes.home);
        return const Scaffold(backgroundColor: AppColors.background);
      },
    );
  }
}

