import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../services/auth_service.dart';

/// Premium multi-page onboarding welcome screen for UniSooq.
///
/// Fully responsive from 360 dp (small Android) up to 428 dp+ (large phones).
/// All sizes are derived from [_WelcomeLayout], which reads the real available
/// height after safe-area insets — so nothing overflows on any device.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

// ── Responsive size bundle ─────────────────────────────────────────────────────

/// Computes every size token from the real available height/width so that
/// the layout is pixel-perfect on both compact (360 dp) and large (428 dp+)
/// Android phones.
class _WelcomeLayout {
  /// Available height inside SafeArea (already excludes status/nav bars).
  final double h;

  /// Screen width.
  final double w;

  const _WelcomeLayout(this.h, this.w);

  // ── Spacing ──────────────────────────────────────────────────────────────
  double get topGap => h * 0.015;
  double get brandToPageGap => h * 0.008;
  double get pageTopGap => h * 0.02;
  double get iconToTextGap => h * 0.035;
  double get badgeToTitleGap => h * 0.012;
  double get titleToCardGap => h * 0.014;
  double get cardBottomGap => h * 0.025;
  double get dotsToCtaGap => h * 0.018;
  double get ctaBottomGap => h * 0.022;
  double get betweenButtons => h * 0.012;

  // ── Icon ring sizes ──────────────────────────────────────────────────────
  /// Outer ring diameter — 30 % of height, capped for large screens.
  double get outerRing => (h * 0.20).clamp(100.0, 150.0);
  double get middleRing => outerRing * 0.78;
  double get iconBox => outerRing * 0.57;
  double get iconSize => iconBox * 0.46;

  // ── Typography ───────────────────────────────────────────────────────────
  double get titleFontSize => (w * 0.083).clamp(26.0, 34.0);
  double get subtitleFontSize => (w * 0.038).clamp(13.0, 15.5);
  double get brandFontSize => (w * 0.055).clamp(18.0, 23.0);
  double get badgeFontSize => (w * 0.027).clamp(9.5, 11.5);

  // ── Button heights ───────────────────────────────────────────────────────
  double get buttonPaddingV => h < 620 ? 14.0 : 17.0;

  // ── Glass card padding ───────────────────────────────────────────────────
  double get cardPaddingH => w * 0.055;
  double get cardPaddingV => h < 620 ? 13.0 : 17.0;

  // ── Horizontal page padding ──────────────────────────────────────────────
  double get hPad => w * 0.07;
}

// ── Screen state ───────────────────────────────────────────────────────────────

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _pageValue = 0;

  late AnimationController _entranceCtrl;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;

  late AnimationController _orbCtrl;
  late Animation<double> _orbFloat;

  static const List<_OnboardPage> _pages = [
    _OnboardPage(
      icon: Icons.storefront_rounded,
      gradient: [Color(0xFF1E78FF), Color(0xFF4FA3FF)],
      orbColor: Color(0xFF1E78FF),
      title: 'Your Campus\nMarketplace',
      subtitle:
          'Buy and sell textbooks, electronics, clothing & more — all within your university community.',
      badge: 'BUY & SELL',
      badgeIcon: Icons.sell_rounded,
    ),
    _OnboardPage(
      icon: Icons.verified_user_rounded,
      gradient: [Color(0xFF00BFA5), Color(0xFF26D6BB)],
      orbColor: Color(0xFF00BFA5),
      title: 'Students\nOnly Space',
      subtitle:
          'Exclusively for verified ${AuthService.studentEmailDomain} accounts. Safe, trusted, campus-exclusive.',
      badge: 'VERIFIED',
      badgeIcon: Icons.shield_rounded,
    ),
    _OnboardPage(
      icon: Icons.chat_bubble_rounded,
      gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
      orbColor: Color(0xFF8B5CF6),
      title: 'Chat & Close\nDeals Fast',
      subtitle:
          'Message sellers directly, negotiate prices, and close deals safely — all in one place.',
      badge: 'REAL-TIME',
      badgeIcon: Icons.bolt_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _orbFloat = Tween<double>(
      begin: -12,
      end: 12,
    ).animate(CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut));

    _pageController.addListener(() {
      setState(() => _pageValue = _pageController.page ?? 0);
    });
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _orbCtrl.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goRegister() =>
      Navigator.of(context).pushNamed(AppRoutes.login, arguments: 'register');
  void _goLogin() => Navigator.of(context).pushNamed(AppRoutes.login);

  Color _lerpColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  List<Color> _currentGradient() {
    final int l = _pageValue.floor().clamp(0, _pages.length - 1);
    final int r = _pageValue.ceil().clamp(0, _pages.length - 1);
    final double t = _pageValue - l;
    return [
      _lerpColor(_pages[l].gradient[0], _pages[r].gradient[0], t),
      _lerpColor(_pages[l].gradient[1], _pages[r].gradient[1], t),
    ];
  }

  Color _currentOrbColor() {
    final int l = _pageValue.floor().clamp(0, _pages.length - 1);
    final int r = _pageValue.ceil().clamp(0, _pages.length - 1);
    return _lerpColor(_pages[l].orbColor, _pages[r].orbColor, _pageValue - l);
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final gradientColors = _currentGradient();
    final orbColor = _currentOrbColor();

    return Scaffold(
      backgroundColor: AppColors.authNavyDeep,
      // Prevent system keyboard from pushing content (not relevant here but
      // avoids overflow if device shows nav bar).
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _entranceFade,
        child: SlideTransition(
          position: _entranceSlide,
          child: Stack(
            children: [
              // ── Animated radial background ────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.5),
                    radius: 1.4,
                    colors: [
                      gradientColors[0].withValues(alpha: 0.35),
                      AppColors.authNavyDeep,
                    ],
                  ),
                ),
              ),

              // ── Orb top-right ─────────────────────────────────────────────
              AnimatedBuilder(
                animation: _orbFloat,
                builder: (_, __) => Positioned(
                  top: -80 + _orbFloat.value,
                  right: -80,
                  child: _Orb(
                    size: mq.size.width * 0.72,
                    color: orbColor.withValues(alpha: 0.22),
                  ),
                ),
              ),

              // ── Orb bottom-left ───────────────────────────────────────────
              AnimatedBuilder(
                animation: _orbFloat,
                builder: (_, __) => Positioned(
                  bottom: -60 - _orbFloat.value * 0.6,
                  left: -60,
                  child: _Orb(
                    size: mq.size.width * 0.58,
                    color: gradientColors[1].withValues(alpha: 0.18),
                  ),
                ),
              ),

              // ── Dot-grid texture ──────────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _DotGridPainter(
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),

              // ── Safe-area content ─────────────────────────────────────────
              SafeArea(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final layout = _WelcomeLayout(
                      constraints.maxHeight,
                      mq.size.width,
                    );

                    return Column(
                      children: [
                        SizedBox(height: layout.topGap),

                        // Brand strip
                        _BrandStrip(
                          gradientColors: gradientColors,
                          layout: layout,
                        ),

                        SizedBox(height: layout.brandToPageGap),

                        // Page carousel
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _pages.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, i) => _OnboardingPage(
                              page: _pages[i],
                              pulseScale: _pulseScale,
                              layout: layout,
                            ),
                          ),
                        ),

                        // Dots + CTA pinned at bottom
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.hPad,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PageDots(
                                count: _pages.length,
                                current: _currentPage,
                                activeColor: gradientColors[0],
                              ),
                              SizedBox(height: layout.dotsToCtaGap),
                              _isLastPage
                                  ? _FinalCTA(
                                      gradientColors: gradientColors,
                                      layout: layout,
                                      onRegister: _goRegister,
                                      onLogin: _goLogin,
                                    )
                                  : _NextButton(
                                      gradientColors: gradientColors,
                                      layout: layout,
                                      onTap: _nextPage,
                                    ),
                              SizedBox(height: layout.ctaBottomGap),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _OnboardPage {
  final IconData icon;
  final List<Color> gradient;
  final Color orbColor;
  final String title;
  final String subtitle;
  final String badge;
  final IconData badgeIcon;

  const _OnboardPage({
    required this.icon,
    required this.gradient,
    required this.orbColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeIcon,
  });
}

// ── Orb helper ─────────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

// ── Brand strip ────────────────────────────────────────────────────────────────

class _BrandStrip extends StatelessWidget {
  final List<Color> gradientColors;
  final _WelcomeLayout layout;
  const _BrandStrip({required this.gradientColors, required this.layout});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (b) =>
              LinearGradient(colors: gradientColors).createShader(b),
          child: Text(
            'UniSooq',
            style: TextStyle(
              fontSize: layout.brandFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Text(
            'BETA',
            style: TextStyle(
              fontSize: layout.badgeFontSize * 0.9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Onboarding page ────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardPage page;
  final Animation<double> pulseScale;
  final _WelcomeLayout layout;

  const _OnboardingPage({
    required this.page,
    required this.pulseScale,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.hPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: layout.pageTopGap),

          // Pulsing icon
          _PulsingIcon(page: page, pulseScale: pulseScale, layout: layout),

          SizedBox(height: layout.iconToTextGap),

          // Badge
          _BadgeChip(page: page, layout: layout),

          SizedBox(height: layout.badgeToTitleGap),

          // Title with gradient mask
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: [Colors.white, Colors.white.withValues(alpha: 0.85)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(b),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: layout.titleFontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
          ),

          SizedBox(height: layout.titleToCardGap),

          // Glass subtitle card
          _GlassCard(
            text: page.subtitle,
            accentColor: page.gradient[0],
            layout: layout,
          ),

          SizedBox(height: layout.cardBottomGap),
        ],
      ),
    );
  }
}

// ── Pulsing icon ───────────────────────────────────────────────────────────────

class _PulsingIcon extends StatelessWidget {
  final _OnboardPage page;
  final Animation<double> pulseScale;
  final _WelcomeLayout layout;

  const _PulsingIcon({
    required this.page,
    required this.pulseScale,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final double outer = layout.outerRing;
    final double mid = layout.middleRing;
    final double box = layout.iconBox;

    return AnimatedBuilder(
      animation: pulseScale,
      builder: (_, __) {
        return SizedBox(
          width: outer,
          height: outer,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Transform.scale(
                scale: pulseScale.value,
                child: Container(
                  width: outer,
                  height: outer,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: page.gradient[0].withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Middle ring
              Transform.scale(
                scale: 1 + (pulseScale.value - 1) * 0.6,
                child: Container(
                  width: mid,
                  height: mid,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: page.gradient[0].withValues(alpha: 0.28),
                      width: 1.5,
                    ),
                    color: page.gradient[0].withValues(alpha: 0.06),
                  ),
                ),
              ),
              // Icon box
              Container(
                width: box,
                height: box,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: page.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.gradient[0].withValues(alpha: 0.5),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: page.gradient[1].withValues(alpha: 0.2),
                      blurRadius: 50,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  page.icon,
                  color: Colors.white,
                  size: layout.iconSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Badge chip ─────────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final _OnboardPage page;
  final _WelcomeLayout layout;
  const _BadgeChip({required this.page, required this.layout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.hPad * 0.55,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            page.gradient[0].withValues(alpha: 0.25),
            page.gradient[1].withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: page.gradient[0].withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            page.badgeIcon,
            size: layout.badgeFontSize,
            color: page.gradient[0],
          ),
          const SizedBox(width: 6),
          Text(
            page.badge,
            style: TextStyle(
              fontSize: layout.badgeFontSize,
              fontWeight: FontWeight.bold,
              color: page.gradient[0],
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass card ─────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final String text;
  final Color accentColor;
  final _WelcomeLayout layout;
  const _GlassCard({
    required this.text,
    required this.accentColor,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.cardPaddingH,
        vertical: layout.cardPaddingV,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.08), blurRadius: 20),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: layout.subtitleFontSize,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.78),
          height: 1.6,
        ),
      ),
    );
  }
}

// ── Page dots ──────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final Color activeColor;

  const _PageDots({
    required this.count,
    required this.current,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final bool active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Next button ────────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final List<Color> gradientColors;
  final _WelcomeLayout layout;
  final VoidCallback onTap;

  const _NextButton({
    required this.gradientColors,
    required this.layout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: layout.buttonPaddingV),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Final CTA ──────────────────────────────────────────────────────────────────

class _FinalCTA extends StatelessWidget {
  final List<Color> gradientColors;
  final _WelcomeLayout layout;
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  const _FinalCTA({
    required this.gradientColors,
    required this.layout,
    required this.onRegister,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary — Register
        GestureDetector(
          onTap: onRegister,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: layout.buttonPaddingV),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.42),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Text(
              'Create Free Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),

        SizedBox(height: layout.betweenButtons),

        // Ghost — Login
        GestureDetector(
          onTap: onLogin,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: layout.buttonPaddingV),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Text(
              'Sign In',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),

        SizedBox(height: layout.betweenButtons),

        // Terms
        Text(
          'By continuing you agree to our Terms of Use',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

// ── Dot-grid background painter ────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  final Color color;
  const _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 28.0;
    const radius = 1.2;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

// ignore: unused_element
double _sin(double x) => math.sin(x);
