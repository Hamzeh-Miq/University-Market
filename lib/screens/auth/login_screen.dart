import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../constants/app_routes.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Controls which tab the LoginScreen opens in.
enum LoginMode { login, register }

/// Authentication screen handling both Login and Register flows.
class LoginScreen extends ConsumerStatefulWidget {
  final LoginMode initialMode;

  const LoginScreen({super.key, this.initialMode = LoginMode.login});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _email = '';
  String _password = '';
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String? _message;
  bool _messageIsSuccess = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialMode == LoginMode.login;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final authService = ref.read(authServiceProvider);

    try {
      if (_isLogin) {
        final credential = await authService.signIn(_email, _password);
        if (mounted && credential.user != null) {
          // Ensure the Firestore profile document exists (creates it on first login).
          await authService.ensureVerifiedUserProfileExists();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          }
        }
      } else {
        await authService.registerStudent(
          _email,
          _password,
          firstName: _firstName,
          middleName: _middleName,
          lastName: _lastName,
          phoneNumber: _phoneNumber,
        );
        if (mounted) {
          setState(() {
            _isLogin = true;
            _messageIsSuccess = true;
            _message =
                'Account created! Please verify your university email before logging in.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messageIsSuccess = false;
          _message = _mapFirebaseError(e);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirebaseError(dynamic e) {
    final message = e.toString().toLowerCase();
    if (message.contains('invalid-credential') ||
        message.contains('invalid-email') ||
        message.contains('wrong-password') ||
        message.contains('user-not-found')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (message.contains('email-already-in-use')) {
      return 'This email is already registered. Try logging in.';
    }
    if (message.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    if (message.contains('user-disabled')) {
      return 'This account has been disabled.';
    }
    if (message.contains('requires an index')) {
      return 'Database setup in progress. Please click the link in your console to create the index.';
    }
    return e.toString().replaceAll('Exception: ', '').split(']').last.trim();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _message = null;
    });
    _animController
      ..reset()
      ..forward();
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'UniTrade',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The exclusive campus marketplace',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Form Card ────────────────────────────────────────
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? 'Welcome back 👋' : 'Create account',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name fields — only in register mode
                            if (!_isLogin) ...[
                              // First Name
                              TextFormField(
                                decoration: _fieldDecoration(
                                  'First Name',
                                  Icons.badge_outlined,
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter your first name.';
                                  }
                                  return null;
                                },
                                onSaved: (v) => _firstName = v!.trim(),
                              ),
                              const SizedBox(height: 14),

                              // Middle Name (optional)
                              TextFormField(
                                decoration: _fieldDecoration(
                                  'Middle Name (optional)',
                                  Icons.person_outline,
                                ),
                                textCapitalization: TextCapitalization.words,
                                onSaved: (v) => _middleName = v?.trim() ?? '',
                              ),
                              const SizedBox(height: 14),

                              // Last Name
                              TextFormField(
                                decoration: _fieldDecoration(
                                  'Last Name',
                                  Icons.badge_outlined,
                                ),
                                textCapitalization: TextCapitalization.words,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter your last name.';
                                  }
                                  return null;
                                },
                                onSaved: (v) => _lastName = v!.trim(),
                              ),
                              const SizedBox(height: 14),

                              // Phone Number
                              TextFormField(
                                decoration: _fieldDecoration(
                                  'Phone Number',
                                  Icons.phone_outlined,
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter your phone number.';
                                  }
                                  if (v.trim().length < 7) {
                                    return 'Enter a valid phone number.';
                                  }
                                  return null;
                                },
                                onSaved: (v) => _phoneNumber = v!.trim(),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Email
                            TextFormField(
                              decoration:
                                  _fieldDecoration(
                                    'University Email',
                                    Icons.email_outlined,
                                  ).copyWith(
                                    hintText: _isLogin
                                        ? null
                                        : 'student@students.asu.edu.jo',
                                  ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter your email.';
                                }
                                if (!_isLogin &&
                                    !ref
                                        .read(authServiceProvider)
                                        .isValidEduEmail(v)) {
                                  return 'Only ${AuthService.studentEmailDomain} email addresses are allowed.';
                                }
                                return null;
                              },
                              onSaved: (v) => _email = v!.trim(),
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              decoration:
                                  _fieldDecoration(
                                    'Password',
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                              obscureText: _obscurePassword,
                              validator: (v) {
                                if (v == null || v.length < 10) {
                                  return 'Password must be at least 10 characters.';
                                }
                                return null;
                              },
                              onSaved: (v) => _password = v!,
                            ),
                            const SizedBox(height: 20),

                            // Message banner
                            if (_message != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: _messageIsSuccess
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _messageIsSuccess
                                        ? AppColors.success
                                        : AppColors.error,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  _message!,
                                  style: TextStyle(
                                    color: _messageIsSuccess
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            // Submit button
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : FilledButton(
                                    onPressed: _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      _isLogin ? 'Login' : 'Register',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Toggle mode
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Register"
                          : 'Already have an account? Login',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
