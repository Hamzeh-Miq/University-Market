import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_routes.dart';
import '../../services/auth_service.dart';

/// Welcome / splash screen shown to new users before login or registration.
///
/// Design: dark navy gradient background, app icon, headline, feature
/// highlights, and CTA buttons — matching the reference design style.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    // Lock status bar to light icons on the dark background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    // Restore default overlay style when leaving
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _goRegister() =>
      Navigator.of(context).pushNamed(AppRoutes.login, arguments: 'register');

  void _goLogin() => Navigator.of(context).pushNamed(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.authNavyDeep,
      body: Stack(
        children: [
          // ── Gradient background ────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.authNavyDeep,
                    AppColors.authNavyMid,
                    AppColors.authNavyBright,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Decorative blurred circle top-right ───────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),

          // ── Decorative blurred circle bottom-left ─────────────────
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.authHighlight.withValues(alpha: 0.08),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.07),

                      // ── App icon ─────────────────────────────────
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.authHighlight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.onPrimary,
                          size: 44,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── App name ─────────────────────────────────
                      const Text(
                        'UniTrade',
                        style: AppTextStyles.authBrandTitle,
                      ),

                      const SizedBox(height: 8),

                      // ── Tagline ───────────────────────────────────
                      Text(
                        'The exclusive campus marketplace\nfor university students',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.onPrimarySoft,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: size.height * 0.055),

                      // ── Feature highlights ────────────────────────
                      _FeatureRow(
                        icon: Icons.sell_rounded,
                        title: 'Buy & Sell on Campus',
                        subtitle:
                            'Textbooks, electronics, clothing & more — all in one place.',
                        accentColor: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      _FeatureRow(
                        icon: Icons.verified_user_rounded,
                        title: 'Students Only',
                        subtitle:
                            'Exclusive to verified ${AuthService.studentEmailDomain} inboxes.',
                        accentColor: AppColors.accent,
                      ),
                      const SizedBox(height: 16),
                      _FeatureRow(
                        icon: Icons.chat_bubble_rounded,
                        title: 'Chat with Sellers',
                        subtitle:
                            'Message sellers directly and close deals safely.',
                        accentColor: AppColors.successLight,
                      ),

                      const Spacer(),

                      // ── Register button ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _goRegister,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Register',
                            style: AppTextStyles.primaryButtonLarge,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Login link ────────────────────────────────
                      GestureDetector(
                        onTap: _goLogin,
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account?  ',
                            style: AppTextStyles.onPrimaryPrompt,
                            children: const [
                              TextSpan(
                                text: 'LOGIN',
                                style: AppTextStyles.onPrimaryLink,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature row ───────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon circle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        const SizedBox(width: 14),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.onPrimaryFeatureTitle),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTextStyles.onPrimaryFeatureBody),
            ],
          ),
        ),
      ],
    );
  }
}
