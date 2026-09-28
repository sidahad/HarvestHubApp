import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Simulate auto SMS detection & auto-fill after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _simulateAutoFill('482910');
      }
    });
  }

  void _startCountdown() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  void _simulateAutoFill(String code) {
    for (int i = 0; i < code.length && i < _controllers.length; i++) {
      _controllers[i].text = code[i];
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.sms_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('SMS Auto-Detected: OTP 482910 verified!'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    // Auto-verify after short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _verifyOTP();
    });
  }

  Future<void> _verifyOTP() async {
    final enteredCode = _controllers.map((c) => c.text).join();
    if (enteredCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isVerifying = false);

    // Show verification success bottom sheet and navigate to Login
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 50),
            ),
            const SizedBox(height: 16),
            Text('Phone Verified!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your phone number has been verified successfully. Please login to your account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Phone Verification', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A2B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: const Center(
                  child: Icon(Icons.phone_android_rounded, size: 48, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Phone Number',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFF0F5F1)),
              ),
              const SizedBox(height: 8),
              Text(
                'We have sent a 6-digit OTP code to\n${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF8FA497), height: 1.4),
              ),
              const SizedBox(height: 32),

              // Responsive OTP 6-Digit input boxes
              LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = constraints.maxWidth < 340 ? 4.0 : 8.0;
                  final boxWidth = ((constraints.maxWidth - (5 * spacing)) / 6).clamp(36.0, 52.0);
                  final boxHeight = (boxWidth * 1.18).clamp(46.0, 58.0);
                  final fontSize = boxWidth < 40 ? 17.0 : 20.0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: boxWidth,
                        height: boxHeight,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFA1C68A),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFF15281E),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(boxWidth < 40 ? 10 : 12),
                              borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(boxWidth < 40 ? 10 : 12),
                              borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(boxWidth < 40 ? 10 : 12),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (val.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            if (_controllers.every((c) => c.text.isNotEmpty)) {
                              _verifyOTP();
                            }
                          },
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 24),

              if (_isVerifying)
                const CircularProgressIndicator(color: AppTheme.primary)
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyOTP,
                    child: const Text('Verify & Continue'),
                  ),
                ),
              const SizedBox(height: 24),

              // Resend Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the code? ", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        _startCountdown();
                        _simulateAutoFill('482910');
                      },
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
