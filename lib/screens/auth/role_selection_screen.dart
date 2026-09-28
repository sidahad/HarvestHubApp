import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'Customer';

  final List<_RoleItem> _roles = const [
    _RoleItem(
      role: 'Customer',
      icon: Icons.shopping_bag_outlined,
      title: 'Customer',
      subtitle: 'Buy fresh organic produce directly from verified local farmers',
      color: Color(0xFF88AB75),
    ),
    _RoleItem(
      role: 'Farmer',
      icon: Icons.eco_outlined,
      title: 'Farmer',
      subtitle: 'List your crops, manage harvest & receive direct payments',
      color: Color(0xFFA1C68A),
    ),
    _RoleItem(
      role: 'Admin',
      icon: Icons.admin_panel_settings_outlined,
      title: 'Admin',
      subtitle: 'Manage platform, verify farmers & monitor all transactions',
      color: Color(0xFF6B9B7E),
    ),
  ];

  void _onContinue() {
    AuthService().setSelectedRole(_selectedRole);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Logo + Header (Leafora Style)
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15281E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withAlpha(25)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.eco_rounded,
                                    color: Color(0xFF88AB75),
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HarvestHub',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFF0F5F1),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Farm to Table, Direct',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF8EAA95),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          Text(
                            'Choose Your Role',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF0F5F1),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select how you want to experience the botanical market',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF8EAA95),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Role Cards
                          ..._roles.map((r) {
                            final selected = _selectedRole == r.role;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedRole = r.role),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF1B3526)
                                        : const Color(0xFF15281E),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF88AB75)
                                          : Colors.white.withAlpha(20),
                                      width: selected ? 1.8 : 1,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF88AB75).withAlpha(40),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? const Color(0xFF88AB75).withAlpha(50)
                                              : const Color(0xFF0F1E16),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withAlpha(15)),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            r.icon,
                                            color: selected
                                                ? const Color(0xFFA1C68A)
                                                : const Color(0xFF8EAA95),
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.title,
                                              style: GoogleFonts.playfairDisplay(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFF0F5F1),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              r.subtitle,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: const Color(0xFF8EAA95),
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? const Color(0xFF88AB75)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: selected
                                                ? const Color(0xFF88AB75)
                                                : const Color(0xFF4C6A57),
                                            width: 2,
                                          ),
                                        ),
                                        child: selected
                                            ? const Icon(
                                                Icons.check,
                                                color: Color(0xFF0D1A13),
                                                size: 15,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          const Spacer(),
                          const SizedBox(height: 16),

                          // Continue Pill Button (Leafora Style)
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _onContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF88AB75),
                                foregroundColor: const Color(0xFF0D1A13),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Continue as $_selectedRole',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleItem {
  final String role, title, subtitle;
  final IconData icon;
  final Color color;
  const _RoleItem({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
