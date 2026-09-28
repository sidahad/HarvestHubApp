import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/auth_service.dart';
import '../../utils/role_router.dart';
import 'email_otp_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _role = 'Customer';
  bool _obscure = true;
  bool _loading = false;
  bool _locating = false;

  // Optional: keep lat/lng too, in case you want to save them in Firestore
  double? _latitude;
  double? _longitude;

  static const _roles = [
    {'role': 'Customer'},
    {'role': 'Farmer'},
    {'role': 'Admin'},
  ];

  @override
  void initState() {
    super.initState();
    _role = AuthService().selectedRole;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── NEW: Pick current location and reverse-geocode into an address ──────
  Future<void> _pickCurrentLocation() async {
    setState(() => _locating = true);
    try {
      // 1. Check if location service is on
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Please turn on Location Services.';
      }

      // 2. Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied. Enable it from app settings.';
      }

      // 3. Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      // 4. Reverse geocode lat/lng -> human readable address
      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

        setState(() => _addressCtrl.text = address);
      } else {
        throw 'Could not resolve an address for this location.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFD9534F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final model = await AuthService().signUp(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passCtrl.text,
        address: _addressCtrl.text.trim(),
        role: _role,
        // If AuthService.signUp accepts these, uncomment to save coordinates too:
        // latitude: _latitude,
        // longitude: _longitude,
      );
      if (!mounted) return;
      if (model != null) {
        final email = _emailCtrl.text.trim();
        String? debugOtp;
        try {
          debugOtp = await AuthService().sendEmailOtp(
            email: email,
            purpose: OtpPurpose.verifyEmail,
          );
        } catch (_) {}
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified! Please log in to continue.'),
              backgroundColor: Color(0xFF1E3827),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFD9534F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignup() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => homeForRole(user.role)),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFD9534F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleSignup() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService().signInWithApple();
      if (!mounted) return;
      if (user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => homeForRole(user.role)),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFD9534F),
          ),
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
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
                decoration: BoxDecoration(
                  color: const Color(0xFF13241A),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withAlpha(25),
                      width: 1.2,
                    ),
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
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFF0F5F1),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF88AB75),
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create Account',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join HarvestHub — botanical market direct from farms',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF8EAA95),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role chips
                      _label('I am registering as...'),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _roles.map((r) {
                            final sel = _role == r['role'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _role = r['role']!);
                                  AuthService().setSelectedRole(r['role']!);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? const Color(0xFF1B3526)
                                        : const Color(0xFF15281E),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: sel
                                          ? const Color(0xFF88AB75)
                                          : Colors.white.withAlpha(20),
                                      width: sel ? 1.6 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        r['role'] == 'Customer'
                                            ? Icons.shopping_bag_outlined
                                            : r['role'] == 'Farmer'
                                            ? Icons.eco_outlined
                                            : Icons.admin_panel_settings_outlined,
                                        size: 16,
                                        color: sel
                                            ? const Color(0xFFA1C68A)
                                            : const Color(0xFF8EAA95),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        r['role']!,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: sel
                                              ? const Color(0xFFF0F5F1)
                                              : const Color(0xFF8EAA95),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      _label('Full Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF0F5F1),
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Muhammad Ali',
                          prefixIcon: Icons.person_outline,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _label('Email Address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF0F5F1),
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: 'ali@example.com',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _label('Phone Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF0F5F1),
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: '+92 300 1234567',
                          prefixIcon: Icons.phone_outlined,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your phone number'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _label('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF0F5F1),
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Min 6 characters',
                          prefixIcon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF8EAA95),
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter a password';
                          if (v.length < 6)
                            return 'Minimum 6 characters required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address — NOW with "use my location" button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _label('Delivery / Farm Address'),
                          GestureDetector(
                            onTap: _locating ? null : _pickCurrentLocation,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _locating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF88AB75),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.my_location_rounded,
                                        size: 15,
                                        color: Color(0xFF88AB75),
                                      ),
                                const SizedBox(width: 5),
                                Text(
                                  _locating ? 'Locating...' : 'Use my location',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF88AB75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF0F5F1),
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Tap "Use my location" or type manually',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your address'
                            : null,
                      ),
                      const SizedBox(height: 26),

                      // Submit Pill Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF88AB75),
                            foregroundColor: const Color(0xFF0D1A13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF0D1A13),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.white.withAlpha(20)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8EAA95),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.white.withAlpha(20)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _loading ? null : _googleSignup,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF15281E),
                            side: BorderSide(color: Colors.white.withAlpha(20)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.account_circle_outlined,
                                color: Color(0xFF4285F4),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF0F5F1),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _loading ? null : _appleSignup,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF15281E),
                            side: BorderSide(color: Colors.white.withAlpha(20)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.apple,
                                color: Color(0xFFF0F5F1),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Continue with Apple',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF0F5F1),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8EAA95),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                            child: Text(
                              'Login',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF88AB75),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF6B8A74),
        fontSize: 13,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF88AB75), size: 20),
      suffixIcon: suffix,
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
    );
  }

  Widget _label(String t) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFF0F5F1),
    ),
  );
}
