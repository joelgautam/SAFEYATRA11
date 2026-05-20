import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../services/app_session.dart';

// ── SafeYatra Colors ───────────────────────────────────────────────────────
class SYColors {
  static const pageBg = Color(0xFFF5F3FF);
  static const lavenderPrimary = Color(0xFF7C6FE0);
  static const lavenderDeep = Color(0xFF5A4FCF);
  static const lavenderLight = Color(0xFFE4DEFF);
  static const lavenderSoft = Color(0xFFF0EEFF);
  static const textDark = Color(0xFF2D2757);
  static const textGrey = Color(0xFF9B96B8);
  static const white = Color(0xFFFFFFFF);
  static const roseAccent = Color(0xFFBF4B6B);
}

// ── OTP Login Screen ───────────────────────────────────────────────────────
class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(text: '+977 ');
  final FocusNode _phoneFocusNode = FocusNode();

  int _secondsLeft = 30;
  bool _canResend = false;
  bool _otpRequested = false;
  bool _isRequestingOtp = false;
  bool _isVerifying = false;
  String? _lastDevOtp;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocusNode.requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resend() {
    _requestOtp();
  }

  String get _fullOtp => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _fullOtp.length == 6;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _clearOtpBoxes() {
    for (final controller in _controllers) {
      controller.clear();
    }
  }

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    final fullName = _nameController.text.trim();

    if (phone.length < 8) {
      _showSnack('Please enter a valid phone number.');
      return;
    }

    setState(() => _isRequestingOtp = true);

    try {
      final response = await http.post(
        Uri.parse('${AppSession.apiBaseUrl}/auth/request-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'full_name': fullName,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 201) {
        _showSnack(data['detail']?.toString() ?? 'Could not generate OTP.');
        return;
      }

      _lastDevOtp = data['dev_otp']?.toString();
      _clearOtpBoxes();
      setState(() {
        _otpRequested = true;
        _secondsLeft = 30;
        _canResend = false;
      });
      _startTimer();
      _focusNodes[0].requestFocus();
      _showSnack('Dev OTP: $_lastDevOtp');
    } catch (_) {
      _showSnack(
          'Could not reach backend. Check Django is running on port 8000.');
    } finally {
      if (mounted) setState(() => _isRequestingOtp = false);
    }
  }

  void _verify() async {
    if (!_otpRequested) {
      _showSnack('Request an OTP first.');
      return;
    }
    if (!_isOtpComplete) return;

    setState(() => _isVerifying = true);

    try {
      final response = await http.post(
        Uri.parse('${AppSession.apiBaseUrl}/auth/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text.trim(),
          'code': _fullOtp,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        _showSnack(data['detail']?.toString() ?? 'Invalid OTP.');
        return;
      }

      await AppSession.saveUser(data['user'] as Map<String, dynamic>);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/verified');
      }
    } catch (_) {
      _showSnack('Could not verify OTP. Check backend connection.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SYColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 56),

              // ── Logo ───────────────────────────────────────────────────
              _LogoBadge(),

              const SizedBox(height: 28),

              // ── Title ──────────────────────────────────────────────────
              const Text(
                'Sign Up With Phone',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: SYColors.lavenderDeep,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate a database OTP, then enter it below',
                style: TextStyle(
                  fontSize: 14,
                  color: SYColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ── Main Card ──────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: SYColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: SYColors.lavenderPrimary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Full name',
                        filled: true,
                        fillColor: SYColors.lavenderSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone row
                    _PhoneRow(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isRequestingOtp ? null : _requestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SYColors.lavenderPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isRequestingOtp
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_otpRequested
                                ? 'Generate New OTP'
                                : 'Generate OTP'),
                      ),
                    ),

                    if (_lastDevOtp != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Testing OTP: $_lastDevOtp',
                        style: const TextStyle(
                          color: SYColors.lavenderDeep,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // OTP boxes
                    Row(
                      children: List.generate(
                          6,
                          (i) => Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: i < 5 ? 8 : 0),
                                  child: _OtpBox(
                                    controller: _controllers[i],
                                    focusNode: _focusNodes[i],
                                    onChanged: (val) {
                                      if (val.isNotEmpty && i < 5) {
                                        _focusNodes[i + 1].requestFocus();
                                      } else if (val.isEmpty && i > 0) {
                                        _focusNodes[i - 1].requestFocus();
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                              )),
                    ),

                    const SizedBox(height: 28),

                    // Verify button
                    _VerifyButton(
                      isComplete: _otpRequested && _isOtpComplete,
                      isVerifying: _isVerifying,
                      onTap: _verify,
                    ),

                    const SizedBox(height: 20),

                    // Resend row
                    _canResend
                        ? TextButton(
                            onPressed: _resend,
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: SYColors.lavenderPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : _otpRequested
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.lock_outline,
                                      size: 14, color: SYColors.textGrey),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Resend OTP in ',
                                    style: TextStyle(
                                        fontSize: 13, color: SYColors.textGrey),
                                  ),
                                  Text(
                                    '${_secondsLeft}s',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: SYColors.lavenderPrimary,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'No OTP sent yet',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: SYColors.textGrey,
                                ),
                              ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Info Cards ─────────────────────────────────────────────
              const Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.phone_outlined,
                      title: 'Need help with login?',
                      subtitle: 'Our support team is available 24/7 for you.',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.security,
                      title: '100% Secure Process',
                      subtitle: 'Encrypted connection for your safety.',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Footer
              Text(
                'SAFEYATRA SECURITY PROTOCOLS V2.4',
                style: TextStyle(
                  fontSize: 9,
                  color: SYColors.textGrey.withOpacity(0.6),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logo Badge ─────────────────────────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [
          Color(0xFF8B7EF8),
          Color(0xFF6356D6),
        ]),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C6FE0).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
    );
  }
}

// ── Phone Row ──────────────────────────────────────────────────────────────
class _PhoneRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _PhoneRow({
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SYColors.lavenderSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SYColors.lavenderLight,
            ),
            child: const Icon(Icons.phone_android,
                size: 16, color: SYColors.lavenderPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PHONE NUMBER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: SYColors.textGrey,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: SYColors.textDark,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(
                      color: SYColors.textGrey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => FocusScope.of(context).requestFocus(focusNode),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
            ),
            child: const Text('Edit',
                style: TextStyle(
                  color: SYColors.lavenderPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
          ),
        ],
      ),
    );
  }
}

// ── OTP Single Box ─────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: isFilled ? SYColors.lavenderLight : SYColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFilled ? SYColors.lavenderPrimary : const Color(0xFFDDD9F5),
          width: 2,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: SYColors.lavenderDeep,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ── Verify Button ──────────────────────────────────────────────────────────
class _VerifyButton extends StatefulWidget {
  final bool isComplete;
  final bool isVerifying;
  final VoidCallback onTap;

  const _VerifyButton({
    required this.isComplete,
    required this.isVerifying,
    required this.onTap,
  });

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: widget.isComplete
                  ? [const Color(0xFF8B7EF8), const Color(0xFF6356D6)]
                  : [const Color(0xFFCBC5F0), const Color(0xFFB8B0E8)],
            ),
            boxShadow: widget.isComplete
                ? [
                    BoxShadow(
                      color: SYColors.lavenderPrimary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: widget.isVerifying
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Verify & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Info Card ──────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SYColors.lavenderLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SYColors.lavenderSoft,
            ),
            child: Icon(icon, size: 16, color: SYColors.lavenderPrimary),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: SYColors.textDark,
              )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: SYColors.textGrey,
                height: 1.4,
              )),
        ],
      ),
    );
  }
}
