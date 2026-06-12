import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// Form to edit the current user's full name and phone number.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profile = await ref.read(userServiceProvider).getUserProfile(uid);
      if (mounted && profile != null) {
        _firstNameCtrl.text = profile.firstName;
        _middleNameCtrl.text = profile.middleName;
        _lastNameCtrl.text = profile.lastName;
        _phoneCtrl.text = profile.phoneNumber;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      setState(() => _saving = false);
      return;
    }

    final firstName = _firstNameCtrl.text.trim();
    final middleName = _middleNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();

    // Rebuild the legacy composite fields so nothing breaks on other screens
    final fullName = [
      firstName,
      middleName,
      lastName,
    ].where((s) => s.isNotEmpty).join(' ');

    try {
      await ref.read(userServiceProvider).updateUserProfile(uid, {
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'fullName': fullName,
        'displayName': firstName,
        'phoneNumber': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your profile. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (!_loading && !_saving)
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar placeholder ────────────────────────────
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Name section ──────────────────────────────────
                    _SectionLabel(label: 'Full Name'),
                    const SizedBox(height: 10),
                    _FieldBox(
                      controller: _firstNameCtrl,
                      label: 'First Name',
                      hint: 'e.g. Ahmad',
                      icon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'First name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _FieldBox(
                      controller: _middleNameCtrl,
                      label: 'Middle Name (optional)',
                      hint: 'e.g. Khalid',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _FieldBox(
                      controller: _lastNameCtrl,
                      label: 'Last Name',
                      hint: 'e.g. Al-Hassan',
                      icon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Last name is required'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Contact section ───────────────────────────────
                    _SectionLabel(label: 'Contact'),
                    const SizedBox(height: 10),
                    _FieldBox(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      hint: 'e.g. 079 000 0000',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (v.trim().length < 9) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // ── Save button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: AppTextStyles.buttonText,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FieldBox({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        // fillColor and borders are inherited from InputDecorationTheme
        // in main.dart — which correctly adapts to light/dark mode.
      ),
    );
  }
}
