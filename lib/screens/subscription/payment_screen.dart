import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/subscription_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

/// Simulated payment screen for the UniTrade annual subscription.
///
/// Presents a realistic card-entry form. On submission it shows a
/// processing animation and then activates the subscription directly
/// in Firestore — no real money is charged.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  _PaymentStep _step = _PaymentStep.form;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  // ── Card number formatter ─────────────────────────────────────────────────

  String _formatCardNumber(String value) {
    final digits = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  // ── Submission ────────────────────────────────────────────────────────────

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // Step 1: show processing
    setState(() => _step = _PaymentStep.processing);
    _spinController.repeat();

    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    _spinController.stop();

    // Step 2: activate subscription in Firestore
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      if (mounted) setState(() => _step = _PaymentStep.form);
      return;
    }
    try {
      await UserService().activateSubscription(uid);
      if (mounted) setState(() => _step = _PaymentStep.success);
    } catch (e) {
      if (mounted) {
        setState(() => _step = _PaymentStep.form);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _step == _PaymentStep.form
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              title: const Text(
                'Subscribe',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 18),
              ),
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (_step) {
          _PaymentStep.form => _FormView(
              formKey: _formKey,
              cardNumberController: _cardNumberController,
              expiryController: _expiryController,
              cvvController: _cvvController,
              nameController: _nameController,
              formatCardNumber: _formatCardNumber,
              onPay: _pay,
            ),
          _PaymentStep.processing => _ProcessingView(spin: _spinAnimation),
          _PaymentStep.success => _SuccessView(
              onDone: () => Navigator.of(context).pop(true),
            ),
        },
      ),
    );
  }
}

enum _PaymentStep { form, processing, success }

// ── Form View ─────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController cardNumberController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final TextEditingController nameController;
  final String Function(String) formatCardNumber;
  final VoidCallback onPay;

  const _FormView({
    required this.formKey,
    required this.cardNumberController,
    required this.expiryController,
    required this.cvvController,
    required this.nameController,
    required this.formatCardNumber,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Order summary card ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UniTrade Annual Pass',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          Text(
                            '1 year full access',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Annual Fee',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(
                        SubscriptionConstants.subscriptionPriceDisplay,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Duration',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        '${SubscriptionConstants.subscriptionDays} days',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── What you get ───────────────────────────────────────────
            const Text(
              "What you'll unlock",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            ..._perks.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: AppColors.success, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Text(p,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14)),
                    ],
                  ),
                )),

            const SizedBox(height: 28),

            // ── Card details section ───────────────────────────────────
            const Text(
              'Card Details',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),

            // Card number
            TextFormField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              decoration: _dec('Card Number', Icons.credit_card_rounded,
                  hint: '0000 0000 0000 0000'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(' ', '');
                if (digits.length != 16) return 'Enter a valid 16-digit card number.';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Expiry + CVV row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: expiryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryFormatter(),
                    ],
                    decoration:
                        _dec('Expiry', Icons.calendar_month_rounded, hint: 'MM/YY'),
                    validator: (v) {
                      if ((v ?? '').length < 5) return 'Enter MM/YY.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: cvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: _dec('CVV', Icons.lock_rounded, hint: '•••'),
                    validator: (v) {
                      if ((v ?? '').length < 3) return 'Enter 3-digit CVV.';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Cardholder name
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _dec(
                  'Cardholder Name', Icons.person_outline_rounded,
                  hint: 'As on card'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
            ),
            const SizedBox(height: 28),

            // Pay button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Pay ${SubscriptionConstants.subscriptionPriceDisplay}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security_rounded,
                    color: AppColors.textHint, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Secured · 256-bit encryption',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static InputDecoration _dec(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2)),
    );
  }
}

const List<String> _perks = [
  'Browse the full listings catalogue',
  'Filter by category, price & course code',
  'Message sellers directly',
  'Post your own listings',
];

// ── Processing View ───────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  final Animation<double> spin;
  const _ProcessingView({required this.spin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: spin,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.credit_card_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Processing Payment…',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait, do not close the app.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Success View ──────────────────────────────────────────────────────────────

class _SuccessView extends StatefulWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 64),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Payment Successful! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your semester subscription is now active for ${SubscriptionConstants.subscriptionDays} days.\nEnjoy full access to UniTrade!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),

              // What's unlocked chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _UnlockChip(label: 'Full Catalogue', icon: Icons.grid_view_rounded),
                  _UnlockChip(label: 'Filters', icon: Icons.filter_list_rounded),
                  _UnlockChip(label: 'Messaging', icon: Icons.chat_bubble_rounded),
                  _UnlockChip(label: 'Post Listings', icon: Icons.add_a_photo_rounded),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Start Exploring',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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

class _UnlockChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _UnlockChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.success, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Input Formatters ──────────────────────────────────────────────────────────

/// Formats card number as XXXX XXXX XXXX XXXX while typing.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats expiry as MM/YY while typing.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) {
      return newValue.copyWith(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    final formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
