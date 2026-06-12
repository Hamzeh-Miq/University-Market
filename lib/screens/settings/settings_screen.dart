import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

/// App-wide settings screen: dark mode, optional 2FA, and sign-out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final secondFactorAsync = ref.watch(secondFactorEnrolledProvider);
    final is2FAEnrolled = secondFactorAsync.valueOrNull ?? false;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Settings',
          style: AppTextStyles.heading2.copyWith(color: cs.onSurface),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Appearance ──────────────────────────────────────────────
          _SectionHeader(label: 'Appearance'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: isDark ? AppColors.amber : AppColors.primary,
            title: 'Dark Mode',
            subtitle: isDark ? 'Dark theme is on' : 'Light theme is on',
            trailing: Switch.adaptive(
              value: isDark,
              activeColor: AppColors.primary,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).state = value
                    ? ThemeMode.dark
                    : ThemeMode.light;
              },
            ),
          ),

          const SizedBox(height: 24),

          // ── Security ────────────────────────────────────────────────
          _SectionHeader(label: 'Security'),
          const SizedBox(height: 8),
          secondFactorAsync.when(
            loading: () => const _SettingsLoadingTile(),
            error: (_, __) => _SettingsTile(
              icon: Icons.shield_outlined,
              iconColor: AppColors.textSecondary,
              title: 'SMS Two-Factor Authentication',
              subtitle: 'Could not load 2FA status',
              trailing: const SizedBox.shrink(),
            ),
            data: (_) => _SettingsTile(
              icon: is2FAEnrolled
                  ? Icons.verified_user_rounded
                  : Icons.shield_outlined,
              iconColor: is2FAEnrolled ? AppColors.success : AppColors.warning,
              title: 'SMS Two-Factor Authentication',
              subtitle: is2FAEnrolled
                  ? 'Enabled — tap to disable'
                  : 'Not enabled — tap to set up for extra security',
              trailing: is2FAEnrolled
                  ? const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.error,
                    )
                  : const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textHint,
                    ),
              onTap: is2FAEnrolled
                  ? () => _confirmDisable2FA(context, ref)
                  : () => _show2FASetup(context, ref),
            ),
          ),

          const SizedBox(height: 24),

          // ── Account ─────────────────────────────────────────────────
          _SectionHeader(label: 'Account'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Sign Out',
            subtitle: 'You will be taken back to the login screen',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
            ),
            onTap: () => _confirmSignOut(context, ref),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog then disables SMS 2FA on the account.
  Future<void> _confirmDisable2FA(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable two-factor authentication?'),
        content: const Text(
          'Your account will be less secure without SMS verification. Are you sure you want to remove it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disable 2FA'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authServiceProvider).unenrollSecondFactor();
      ref.invalidate(secondFactorEnrolledProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication has been disabled.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Opens a bottom sheet that guides the user through enrolling SMS 2FA.
  Future<void> _show2FASetup(BuildContext context, WidgetRef ref) async {
    ref.read(twoFactorFlowProvider.notifier).reset();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TwoFASetupSheet(widgetRef: ref),
    );
    ref.invalidate(secondFactorEnrolledProvider);
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      }
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading skeleton tile ─────────────────────────────────────────────────────

class _SettingsLoadingTile extends StatelessWidget {
  const _SettingsLoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ── 2FA Setup Bottom Sheet ────────────────────────────────────────────────────

/// Self-contained bottom sheet that guides the user through enrolling
/// SMS 2FA without any sign-out or navigation side-effects.
class _TwoFASetupSheet extends StatefulWidget {
  /// The parent [WidgetRef] — passed in so we can use the same Riverpod
  /// providers without wrapping the sheet in a new [ProviderScope].
  final WidgetRef widgetRef;

  const _TwoFASetupSheet({required this.widgetRef});

  @override
  State<_TwoFASetupSheet> createState() => _TwoFASetupSheetState();
}

class _TwoFASetupSheetState extends State<_TwoFASetupSheet> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _errorMsg;
  bool _codeSent = false;

  WidgetRef get _ref => widget.widgetRef;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _errorMsg = null);
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMsg = 'Please enter your mobile number.');
      return;
    }

    final completed = await _ref
        .read(twoFactorFlowProvider.notifier)
        .startEnrollment(phone);

    if (!mounted) return;

    if (completed) {
      // Instantly enrolled (e.g. test environment) — just close.
      Navigator.of(context).pop();
      return;
    }

    final flowState = _ref.read(twoFactorFlowProvider);
    if (flowState.errorMessage != null) {
      setState(() => _errorMsg = flowState.errorMessage);
    } else {
      setState(() => _codeSent = true);
    }
  }

  Future<void> _confirmCode() async {
    setState(() => _errorMsg = null);
    if (_codeCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Enter the 6-digit code.');
      return;
    }

    final completed = await _ref
        .read(twoFactorFlowProvider.notifier)
        .submitCode(_codeCtrl.text.trim());

    if (!mounted) return;

    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-factor authentication enabled successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final flowState = _ref.read(twoFactorFlowProvider);
      setState(
        () =>
            _errorMsg =
                flowState.errorMessage ?? 'Invalid code. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final flowState = _ref.watch(twoFactorFlowProvider);
    final isLoading = flowState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _codeSent
                            ? 'Enter verification code'
                            : 'Enable SMS 2-Factor Auth',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        _codeSent
                            ? 'Code sent to ${flowState.maskedPhoneNumber}'
                            : 'A one-time code will be sent to your phone',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Error banner
            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Input field
            if (!_codeSent)
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '07XXXXXXXX or +9627XXXXXXXX',
                  prefixIcon: Icon(Icons.phone_android_rounded),
                ),
              )
            else
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                enabled: !isLoading,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: '6-digit verification code',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.lock_clock_outlined),
                  counterText: '',
                ),
              ),
            const SizedBox(height: 20),

            // Primary action button
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : (_codeSent ? _confirmCode : _sendCode),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_codeSent ? Icons.verified_outlined : Icons.sms_outlined),
                label: Text(
                  isLoading
                      ? 'Please wait…'
                      : (_codeSent ? 'Confirm Code' : 'Send SMS Code'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // Secondary actions
            if (_codeSent) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: isLoading ? null : () {
                  _ref.read(twoFactorFlowProvider.notifier).reset();
                  setState(() {
                    _codeSent = false;
                    _codeCtrl.clear();
                    _errorMsg = null;
                  });
                },
                child: Text(
                  'Change phone number',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
