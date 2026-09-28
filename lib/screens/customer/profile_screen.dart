import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/language_service.dart';
import '../../services/gamification_service.dart';
import '../auth/role_selection_screen.dart';
import '../common/language_selection_screen.dart';
import '../common/trust_safety_screen.dart';
import 'customer_rewards_screen.dart';
import 'edit_profile_screen.dart';
import 'wishlist_screen.dart';
import 'my_orders_screen.dart';
import 'favorite_farmers_screen.dart';
import 'notifications_screen.dart';
import '../common/chatbot_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';
import '../common/chat_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DataService _dataService = DataService();
  final LanguageService _languageService = LanguageService();
  CustomerGamificationProfile? _gamProfile;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onStateChange);
    _dataService.addListener(_onStateChange);
    _languageService.addListener(_onStateChange);
    _dataService.loadWishlistForCurrentUser();
    _dataService.loadNotificationsForCurrentUser();
    _loadGamProfile();
  }

  Future<void> _loadGamProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final p = await GamificationService().getCustomerProfile(uid);
    if (mounted) setState(() => _gamProfile = p);
  }

  @override
  void dispose() {
    _authService.removeListener(_onStateChange);
    _dataService.removeListener(_onStateChange);
    _languageService.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.userModel;
    final hasPhoto =
        user?.profilePic != null && user!.profilePic!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          'My Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F5F1),
          ),
        ),
      ),
      body: SafeArea(
        bottom: true, // Add bottom safe area
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
          child: Column(
            children: [
              // User Card Header (Frosted Dark Glass)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF15281E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF88AB75).withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: const Color(0xFF1F3A2B),
                        backgroundImage: hasPhoto
                            ? NetworkImage(user.profilePic!)
                            : null,
                        onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                        child: hasPhoto
                            ? null
                            : (user?.fullName.isNotEmpty == true
                                  ? Text(
                                      user!.fullName.trim()[0].toUpperCase(),
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFF0F5F1),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF88AB75),
                                      size: 36,
                                    )),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Harvest Customer',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? 'customer@harvesthub.com',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8EAA95),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C3626),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF88AB75).withAlpha(60),
                        ),
                      ),
                      child: Text(
                        'Role: ${user?.role ?? "Customer"}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFA1C68A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    'Orders',
                    '${_dataService.orders.length}',
                    Icons.shopping_bag_outlined,
                  ),
                  _buildStatCard(
                    'Wishlist',
                    '${_dataService.wishlistProducts.length}',
                    Icons.favorite_border,
                  ),
                  _buildStatCard(
                    'Following',
                    '${_dataService.followedFarmers.length}',
                    Icons.people_outline,
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Rewards / Loyalty Banner ─────────────────────────────────
              _RewardsBannerCard(
                profile: _gamProfile,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CustomerRewardsScreen()),
                ),
              ),
              const SizedBox(height: 22),

              // Navigation Options List
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF15281E),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    _buildListTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'My Orders',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MyOrdersScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    _buildListTile(
                      icon: Icons.chat_bubble_outline,
                      title: 'Messages',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChatListScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    _buildListTile(
                      icon: Icons.favorite_outline,
                      title: 'Wishlist',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WishlistScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    _buildListTile(
                      icon: Icons.nature_people_outlined,
                      title: 'Following Farmers',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FavoriteFarmersScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    _buildListTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      trailing:
                          _dataService.notifications
                              .where((n) => !n.isRead)
                              .isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE76F51),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_dataService.notifications.where((n) => !n.isRead).length}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Color(0xFF8EAA95),
                                ),
                              ],
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    _buildListTile(
                      icon: Icons.smart_toy_outlined,
                      title: 'ChatBot Assistant',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChatbotScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    _buildListTile(
                      icon: Icons.card_giftcard_rounded,
                      title: 'My Rewards & Points',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CustomerRewardsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    _buildListTile(
                      icon: Icons.info_outline,
                      title: 'About Us',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutUsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    _buildListTile(
                      icon: Icons.support_agent,
                      title: 'Contact Us',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContactUsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    // ── Language Selector ────────────────────────────────
                    _buildListTile(
                      icon: Icons.language_rounded,
                      title: '${AppLocalizations.of(context)!.language}  •  ${_languageService.currentLanguageName}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LanguageSelectionScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                    // ── Trust & Safety ───────────────────────────────────
                    _buildListTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Trust & Safety',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TrustSafetyScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE76F51),
                    side: BorderSide(
                      color: const Color(0xFFE76F51).withAlpha(120),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(
                    'Logout Account',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF15281E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF88AB75), size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF0F5F1),
              ),
            ),
            Text(
              label,
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

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF88AB75), size: 20),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFF0F5F1),
        ),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFF8EAA95),
          ),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  REWARDS BANNER CARD — shown on profile above navigation menu
// ═══════════════════════════════════════════════════════════════════════════

class _RewardsBannerCard extends StatelessWidget {
  final CustomerGamificationProfile? profile;
  final VoidCallback onTap;

  const _RewardsBannerCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pts = profile?.currentPoints ?? 0;
    final badge = profile?.badge ?? CustomerBadge.newBuyer;
    final badgeColor = GamificationService.customerBadgeColor(badge);
    final badgeIcon = GamificationService.customerBadgeIcon(badge);
    final badgeLabel = GamificationService.customerBadgeLabel(badge);
    final progress = profile?.tierProgress ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              badgeColor.withOpacity(0.22),
              const Color(0xFF15281E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: badgeColor.withOpacity(0.45)),
        ),
        child: Row(
          children: [
            // Points circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withOpacity(0.15),
                border: Border.all(
                    color: badgeColor.withOpacity(0.5), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$pts',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF0F5F1),
                    ),
                  ),
                  Text(
                    'pts',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFF8FA497)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Badge + progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(badgeIcon, size: 14, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor:
                          const Color(0xFF1F3A2A),
                      valueColor:
                          AlwaysStoppedAnimation(badgeColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to view rewards & redeem points',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF8FA497)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: badgeColor),
          ],
        ),
      ),
    );
  }
}
