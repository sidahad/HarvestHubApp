import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/language_service.dart';
import '../../models/farmer_model.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/role_router.dart';
import '../common/language_selection_screen.dart';
import '../common/trust_safety_screen.dart';
import '../common/chatbot_screen.dart';
import 'farmer_market_location_screen.dart';
import 'farmer_pickup_slots_screen.dart';
import 'farmer_rewards_screen.dart';

class FarmerOwnProfileScreen extends StatefulWidget {
  const FarmerOwnProfileScreen({super.key});

  @override
  State<FarmerOwnProfileScreen> createState() => _FarmerOwnProfileScreenState();
}

class _FarmerOwnProfileScreenState extends State<FarmerOwnProfileScreen> {
  final AuthService _auth = AuthService();
  final DataService _data = DataService();
  final LanguageService _langService = LanguageService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _langService.addListener(_onLangChange);
    _data.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _langService.removeListener(_onLangChange);
    _data.removeListener(_onDataChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  FarmerModel? _getFarmerData() {
    final uid = _auth.currentUser?.uid;
    for (final f in _data.farmers) {
      if (f.id == uid) return f;
    }
    return null;
  }

  void _showEditProfileDialog(FarmerModel? farmer) {
    final nameCtrl = TextEditingController(
      text: _auth.userModel?.fullName ?? farmer?.name ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: _auth.userModel?.phone ?? '',
    );
    final farmNameCtrl = TextEditingController(
      text: farmer?.farmName ?? '${nameCtrl.text} Farm',
    );
    final bioCtrl = TextEditingController(
      text: farmer?.bio ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1A13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Edit Farmer Profile',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF0F5F1),
                  ),
                ),
                const SizedBox(height: 18),
                _buildSheetTextField('Full Name', nameCtrl, Icons.person_outline),
                const SizedBox(height: 14),
                _buildSheetTextField('Phone Number', phoneCtrl, Icons.phone_outlined, isPhone: true),
                const SizedBox(height: 14),
                _buildSheetTextField('Farm Name', farmNameCtrl, Icons.agriculture_outlined),
                const SizedBox(height: 14),
                _buildSheetTextField('About Farm / Bio', bioCtrl, Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF88AB75),
                      foregroundColor: const Color(0xFF0D1A13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final uid = _auth.currentUser?.uid;
                      if (uid == null) return;
                      Navigator.pop(ctx);
                      setState(() => _loading = true);
                      try {
                        final batch = FirebaseFirestore.instance.batch();
                        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
                        final farmerRef = FirebaseFirestore.instance.collection('farmers').doc(uid);

                        batch.set(userRef, {
                          'fullName': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                        }, SetOptions(merge: true));

                        batch.set(farmerRef, {
                          'name': nameCtrl.text.trim(),
                          'farmName': farmNameCtrl.text.trim(),
                          'bio': bioCtrl.text.trim(),
                        }, SetOptions(merge: true));

                        await batch.commit();
                        await _auth.fetchUserProfile(uid);
                        await _data.loadCatalog();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Farmer profile updated successfully!'),
                              backgroundColor: Color(0xFF1E3827),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Update failed: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8EAA95),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          style: GoogleFonts.inter(color: const Color(0xFFF0F5F1), fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF88AB75), size: 18),
            filled: true,
            fillColor: const Color(0xFF15281E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withAlpha(25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withAlpha(25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF88AB75)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = _auth.userModel;
    final farmer = _getFarmerData();
    final farmerProducts = _data.products.where(
      (p) => p.farmerId == user?.uid,
    ).toList();
    final farmerOrders = _data.orders.where(
      (o) => o.farmerId == user?.uid,
    ).toList();

    final farmerName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : (farmer?.name.isNotEmpty == true ? farmer!.name : 'Farmer');
    final farmName = farmer?.farmName.isNotEmpty == true
        ? farmer!.farmName
        : '$farmerName Farm';
    final marketName = farmer?.marketName.isNotEmpty == true
        ? farmer!.marketName
        : 'Fresh Farm Stall';
    final marketHours = farmer?.marketHours.isNotEmpty == true
        ? farmer!.marketHours
        : 'Mon-Sat: 8:00 AM - 6:00 PM';
    final location = farmer?.location.isNotEmpty == true
        ? farmer!.location
        : (user?.address.isNotEmpty == true ? user!.address : 'Local Farm Location');

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        title: Text(
          l10n.farmerProfile,
          style: GoogleFonts.playfairDisplay(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF0F5F1),
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.language,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF15281E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(25)),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: Color(0xFF88AB75),
                size: 18,
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LanguageSelectionScreen(isFullPage: true),
                ),
              );
            },
          ),
          IconButton(
            tooltip: l10n.editProfile,
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF88AB75), size: 20),
            onPressed: () => _showEditProfileDialog(farmer),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF88AB75)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  children: [
                    // Farmer Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF15281E), Color(0xFF0F1E16)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: const Color(0xFF1F3A2B),
                                backgroundImage: (user?.profilePic != null && user!.profilePic!.isNotEmpty)
                                    ? NetworkImage(user.profilePic!)
                                    : (farmer?.avatarUrl.isNotEmpty == true
                                        ? NetworkImage(farmer!.avatarUrl)
                                        : null),
                                child: (user?.profilePic == null || user!.profilePic!.isEmpty) &&
                                        (farmer?.avatarUrl.isEmpty ?? true)
                                    ? const Icon(Icons.agriculture_rounded, size: 44, color: Color(0xFF88AB75))
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF88AB75),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Color(0xFF0D1A13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                farmerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF0F5F1),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF88AB75).withAlpha(40),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF88AB75).withAlpha(100)),
                                ),
                                child: Text(
                                  l10n.verifiedBadge,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF88AB75),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            farmName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF88AB75),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF8EAA95)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF8EAA95),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (user?.phone.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF8EAA95)),
                                const SizedBox(width: 4),
                                Text(
                                  user!.phone,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF8EAA95),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Stats Row
                    Row(
                      children: [
                        _buildStatBox(
                          '${farmerProducts.length}',
                          l10n.liveProducts,
                          Icons.inventory_2_outlined,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          '${farmerOrders.length}',
                          l10n.orders,
                          Icons.receipt_long_outlined,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          farmer?.rating != null ? farmer!.rating.toStringAsFixed(1) : '4.9',
                          l10n.rating,
                          Icons.star_outline_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Farm & Market Information Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15281E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.farmDetails,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF0F5F1),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const FarmerMarketLocationScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n.edit,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF88AB75),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(Icons.store_outlined, l10n.marketName, marketName),
                          const Divider(height: 18, color: Color(0xFF1E3427)),
                          _buildDetailRow(Icons.access_time_outlined, l10n.marketHours, marketHours),
                          const Divider(height: 18, color: Color(0xFF1E3427)),
                          _buildDetailRow(Icons.location_city_outlined, l10n.location, location),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Settings & Actions Group
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF15281E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Column(
                        children: [
                          // Language Switch
                          _buildActionTile(
                            icon: Icons.language_rounded,
                            title: l10n.language,
                            subtitle: _langService.currentLanguageName,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF88AB75).withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _langService.currentLanguageName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF88AB75),
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LanguageSelectionScreen(isFullPage: true),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFF1E3427)),
                          // Market Location & Hours
                          _buildActionTile(
                            icon: Icons.map_outlined,
                            title: l10n.marketLocationHours,
                            subtitle: marketName,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FarmerMarketLocationScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFF1E3427)),
                          // Pickup Slots
                          _buildActionTile(
                            icon: Icons.schedule_rounded,
                            title: 'Pickup Slots & Hours',
                            subtitle: 'Manage pickup time intervals',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FarmerPickupSlotsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFF1E3427)),
                          // Farmer Rewards
                          _buildActionTile(
                            icon: Icons.emoji_events_outlined,
                            title: 'Farmer Rewards & Badges',
                            subtitle: 'View achievements and seller score',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FarmerRewardsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFF1E3427)),
                          // Assistant / Chatbot
                          _buildActionTile(
                            icon: Icons.smart_toy_outlined,
                            title: 'Farm Assistant AI',
                            subtitle: 'Farming and produce queries',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ChatbotScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFF1E3427)),
                          // Trust & Safety
                          _buildActionTile(
                            icon: Icons.shield_outlined,
                            title: l10n.trustSafety,
                            subtitle: 'Safe transactions & farmer badges',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TrustSafetyScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFF1E3427)),
                          // Switch Role
                          _buildActionTile(
                            icon: Icons.swap_horiz_rounded,
                            title: l10n.switchRole,
                            subtitle: 'Change portal to Customer or Admin',
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/roles');
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFF1E3427)),
                          // Logout
                          _buildActionTile(
                            icon: Icons.logout_rounded,
                            title: l10n.logout,
                            subtitle: l10n.logoutAccount,
                            iconColor: AppTheme.error,
                            onTap: () => logoutAndGoToRoles(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF15281E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF88AB75), size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF0F5F1),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF8EAA95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF88AB75)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF8EAA95),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF88AB75)).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor ?? const Color(0xFF88AB75)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF0F5F1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8EAA95),
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF8EAA95)),
          ],
        ),
      ),
    );
  }
}
