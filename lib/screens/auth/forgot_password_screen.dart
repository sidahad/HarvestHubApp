import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'email_otp_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final debugOtp = await AuthService().sendEmailOtp(
        email: email,
        purpose: OtpPurpose.resetPassword,
      );
      if (!mounted) return;
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(
            email: email,
            purpose: OtpPurpose.resetPassword,
            debugOtp: debugOtp,
          ),
        ),
      );
      if (!mounted) return;
      if (verified == true) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFD9534F)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendDirectResetLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService().sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to $email. Please check your inbox.'),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
                decoration: BoxDecoration(
                  color: const Color(0xFF13241A),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withAlpha(25), width: 1.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D3526),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(20)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF0F5F1), size: 16),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Icon(Icons.lock_reset_rounded, color: Color(0xFF88AB75), size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Reset Password',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We will email a 6-digit OTP code to verify your identity',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF8EAA95),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Email Address',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _sendOtp(),
                      style: GoogleFonts.inter(color: const Color(0xFFF0F5F1), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'name@domain.com',
                        hintStyle: GoogleFonts.inter(color: const Color(0xFF6B8A74), fontSize: 13),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF88AB75), size: 20),
                        filled: true,
                        fillColor: const Color(0xFF15281E),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF88AB75), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Enter your registered email address. We will securely deliver a 6-digit verification OTP.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8EAA95), height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF88AB75),
                          foregroundColor: const Color(0xFF0D1A13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Color(0xFF0D1A13), strokeWidth: 2.5),
                              )
                            : Text('Send OTP', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _loading ? null : _sendDirectResetLink,
                        icon: const Icon(Icons.mark_email_read_outlined, size: 18, color: Color(0xFF88AB75)),
                        label: Text(
                          'Or send 1-click reset link to email',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF88AB75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
