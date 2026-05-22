import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

/// Shown when the user is signed in but their @asu.edu.jo email is not yet
/// verified. Guides them to check their inbox and provides a resend option.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  bool _isSending = false;
  bool _isChecking = false;
  String? _statusMessage;
  bool _statusIsSuccess = false;

  /// Cooldown tracking to prevent spam
  DateTime? _lastSentAt;
  static const _resendCooldownSeconds = 30;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Poll Firebase every 5 seconds to detect when the user clicks
    // the verification link without having to press the button.
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _silentlyCheckVerification();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  /// Silently polls Firebase; navigates to home if verified.
  Future<void> _silentlyCheckVerification() async {
    try {
      final verified = await _authService.reloadAndCheckVerified();
      if (verified && mounted) {
        _autoCheckTimer?.cancel();
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } catch (_) {
      // Silent — user is still on the screen
    }
  }

  /// Manually triggered check shown to the user with feedback.
  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });
    try {
      final verified = await _authService.reloadAndCheckVerified();
      if (!mounted) return;
      if (verified) {
        _autoCheckTimer?.cancel();
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        setState(() {
          _statusIsSuccess = false;
          _statusMessage =
              'Email not verified yet. Please check your inbox and click the link.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusIsSuccess = false;
          _statusMessage = 'Could not check status. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  /// Resends the verification email with a cooldown guard.
  Future<void> _resendEmail() async {
    if (_lastSentAt != null) {
      final elapsed = DateTime.now().difference(_lastSentAt!).inSeconds;
      if (elapsed < _resendCooldownSeconds) {
        setState(() {
          _statusIsSuccess = false;
          _statusMessage =
              'Please wait ${_resendCooldownSeconds - elapsed}s before resending.';
        });
        return;
      }
    }

    setState(() {
      _isSending = true;
      _statusMessage = null;
    });
    try {
      await _authService.resendVerificationEmail();
      _lastSentAt = DateTime.now();
      if (mounted) {
        setState(() {
          _statusIsSuccess = true;
          _statusMessage =
              'Verification email sent! Check your @asu.edu.jo inbox.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusIsSuccess = false;
          _statusMessage = 'Failed to send email. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final email = userAsync.valueOrNull?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated envelope icon ─────────────────────────────
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 58,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Heading ────────────────────────────────────────────
                const Text(
                  'Verify your university email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A verification link was sent to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Open the email and tap the verification link, then come back here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Status banner ──────────────────────────────────────
                if (_statusMessage != null) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _statusIsSuccess
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _statusIsSuccess
                            ? AppColors.success
                            : AppColors.error,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusIsSuccess
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 18,
                          color: _statusIsSuccess
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _statusIsSuccess
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Primary CTA: I've verified ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: _isChecking
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.icon(
                          onPressed: _checkVerification,
                          icon: const Icon(Icons.verified_user_outlined),
                          label: const Text(
                            "I've verified my email",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 14),

                // ── Secondary CTA: Resend email ────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: _isSending
                      ? const Center(child: CircularProgressIndicator())
                      : OutlinedButton.icon(
                          onPressed: _resendEmail,
                          icon: const Icon(Icons.send_outlined,
                              color: AppColors.primary),
                          label: const Text(
                            'Resend verification email',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 28),

                // ── Sign out link ──────────────────────────────────────
                TextButton.icon(
                  onPressed: _signOut,
                  icon: Icon(Icons.logout_rounded,
                      size: 16, color: AppColors.textSecondary),
                  label: Text(
                    'Sign out and use a different account',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
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
