import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'email_otp_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const EmailVerificationScreen({super.key, required this.email, required this.onVerified});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _sending = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startOtp();
  }

  Future<void> _startOtp() async {
    try {
      final email = widget.email.isNotEmpty ? widget.email : (AuthService().userModel?.email ?? '');
      final debugOtp = await AuthService().sendEmailOtp(
        email: email,
        purpose: OtpPurpose.verifyEmail,
      );
      if (!mounted) return;
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(
            email: email,
            purpose: OtpPurpose.verifyEmail,
            debugOtp: debugOtp,
          ),
        ),
      );
      if (!mounted) return;
      if (ok == true) {
        widget.onVerified();
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.toString();
        });
      }
    }
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: _sending
            ? const CircularProgressIndicator(color: AppTheme.primary)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? 'Could not send OTP', style: GoogleFonts.inter(color: AppTheme.error), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () {
                      setState(() {
                        _sending = true;
                        _error = null;
                      });
                      _startOtp();
                    }, child: const Text('Retry')),
                  ],
                ),
              ),
      ),
    );
  }
}
