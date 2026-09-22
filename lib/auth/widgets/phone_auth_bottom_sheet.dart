import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Bottom sheet dialog allowing users to sign in or register with their phone number via SMS OTP.
class PhoneAuthBottomSheet extends ConsumerStatefulWidget {
  final bool isSignUp;
  final AccountRole? initialRole;
  final VoidCallback? onSuccess;

  const PhoneAuthBottomSheet({
    super.key,
    this.isSignUp = false,
    this.initialRole,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    bool isSignUp = false,
    AccountRole? initialRole,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PhoneAuthBottomSheet(
        isSignUp: isSignUp,
        initialRole: initialRole,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<PhoneAuthBottomSheet> createState() => _PhoneAuthBottomSheetState();
}

class _PhoneAuthBottomSheetState extends ConsumerState<PhoneAuthBottomSheet> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedCountryCode = '+256'; // Default Uganda
  final List<Map<String, String>> _countries = [
    {'code': '+256', 'flag': '🇺🇬', 'name': 'Uganda'},
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+255', 'flag': '🇹🇿', 'name': 'Tanzania'},
    {'code': '+250', 'flag': '🇷🇼', 'name': 'Rwanda'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
    {'code': '+27', 'flag': '🇿🇦', 'name': 'South Africa'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'United States'},
  ];

  late AccountRole _selectedRole;
  bool _codeSent = false;
  String? _verificationId;
  int? _resendToken;
  bool _isLoading = false;
  String? _errorMessage;

  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? AccountRole.athlete;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  String get _fullPhoneNumber {
    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    return '$_selectedCountryCode$phone';
  }

  Future<void> _handleSendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      setState(() => _errorMessage = 'Please enter a valid phone number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await ref.read(authProvider.notifier).sendPhoneOtp(
          phoneNumber: _fullPhoneNumber,
          forceResendingToken: _resendToken,
          onCodeSent: (verificationId, resendToken) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _codeSent = true;
              _verificationId = verificationId;
              _resendToken = resendToken;
            });
            _startResendTimer();
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _errorMessage = error;
            });
          },
        );
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit verification code.');
      return;
    }
    if (_verificationId == null) {
      setState(() => _errorMessage = 'Verification session expired. Please request a new code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : null;

    await ref.read(authProvider.notifier).verifyPhoneOtp(
          verificationId: _verificationId!,
          smsCode: code,
          name: name,
          role: widget.isSignUp ? _selectedRole : null,
        );

    final state = ref.read(authProvider);
    if (mounted) {
      setState(() => _isLoading = false);
      if (state is AuthAuthenticated) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      } else if (state is AuthError) {
        setState(() => _errorMessage = state.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_iphone_rounded,
                      color: AppColors.accentPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _codeSent ? 'Enter SMS Code' : (widget.isSignUp ? 'Sign Up with Phone' : 'Sign In with Phone'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _codeSent
                            ? 'Code sent to $_fullPhoneNumber'
                            : 'Fast and secure login via SMS',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (!_codeSent) ...[
              // Optional Full Name for Sign-Up
              if (widget.isSignUp) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Samuel Mukasa',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Role selection chips
                const Text('I am registering as:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Athlete'),
                      selected: _selectedRole == AccountRole.athlete,
                      onSelected: (val) {
                        if (val) setState(() => _selectedRole = AccountRole.athlete);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Recruiter'),
                      selected: _selectedRole == AccountRole.recruiter,
                      onSelected: (val) {
                        if (val) setState(() => _selectedRole = AccountRole.recruiter);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Club'),
                      selected: _selectedRole == AccountRole.club,
                      onSelected: (val) {
                        if (val) setState(() => _selectedRole = AccountRole.club);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Phone Number Input with Country Code Selector
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country dropdown
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        items: _countries.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['code'],
                            child: Row(
                              children: [
                                Text(c['flag']!, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(c['code']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCountryCode = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Number field
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '700 000 000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send Verification Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              // OTP Code Entry
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: '6-digit SMS Code',
                  hintText: '123456',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  if (val.length == 6) {
                    _handleVerifyOtp();
                  }
                },
              ),
              const SizedBox(height: 20),

              // Verify button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // Resend & Back actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _codeSent = false;
                        _otpController.clear();
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Change Number'),
                  ),
                  TextButton(
                    onPressed: _resendCountdown > 0 || _isLoading ? null : _handleSendCode,
                    child: Text(
                      _resendCountdown > 0
                          ? 'Resend in ${_resendCountdown}s'
                          : 'Resend Code',
                      style: TextStyle(
                        color: _resendCountdown > 0 ? Colors.grey : AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
