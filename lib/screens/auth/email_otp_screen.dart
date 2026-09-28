import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;
  final String? debugOtp;

  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.purpose,
    this.debugOtp,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _timer;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    if (widget.debugOtp != null && widget.debugOtp!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo OTP: ${widget.debugOtp} (debug only)'),
            backgroundColor: const Color(0xFF1E3827),
          ),
        );
      });
    }
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

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final otp = await AuthService().sendEmailOtp(
        email: widget.email,
        purpose: widget.purpose,
      );
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otp != null ? 'New OTP sent. Demo code: $otp' : 'A new OTP was sent to your email.'),
          backgroundColor: const Color(0xFF1E3827),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFD9534F)),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOTP() async {
    final enteredCode = _controllers.map((c) => c.text).join();
    if (enteredCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code'), backgroundColor: Color(0xFFD9534F)),
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await AuthService().verifyEmailOtp(
        email: widget.email,
        otp: enteredCode,
        purpose: widget.purpose,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFD9534F)),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
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
    final isReset = widget.purpose == OtpPurpose.resetPassword;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFFF0F5F1)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Email Verification',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F5F1),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFF15281E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(25)),
                ),
                child: const Center(
                  child: Icon(Icons.mark_email_unread_rounded, size: 40, color: Color(0xFF88AB75)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isReset ? 'Reset with OTP' : 'Verify your email',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n${widget.email}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF8EAA95),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
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
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF0F5F1),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFF15281E),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(boxWidth < 40 ? 10 : 14),
                              borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(boxWidth < 40 ? 10 : 14),
                              borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(boxWidth < 40 ? 10 : 14),
                              borderSide: const BorderSide(color: Color(0xFF88AB75), width: 1.8),
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
              const SizedBox(height: 32),
              if (_isVerifying)
                const CircularProgressIndicator(color: Color(0xFF88AB75))
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF88AB75),
                      foregroundColor: const Color(0xFF0D1A13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Text(
                      'Verify OTP',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't get the code? ",
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8EAA95)),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF88AB75)),
                    )
                  else
                    GestureDetector(
                      onTap: _isResending ? null : _resend,
                      child: Text(
                        _isResending ? 'Sending…' : 'Resend OTP',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF88AB75),
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
    ),
  ),
);
}
}
