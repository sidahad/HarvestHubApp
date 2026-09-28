import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../models/farmer_model.dart';
import '../../l10n/app_localizations.dart';
import 'add_edit_product_screen.dart';
import 'marketplace_view_screen.dart';
import 'farmer_pickup_slots_screen.dart';
import 'farmer_market_location_screen.dart';
import 'farmer_rewards_screen.dart';
import 'farmer_own_profile_screen.dart';
import 'farmer_notifications_screen.dart';
import '../common/chat_list_screen.dart';
import '../common/language_selection_screen.dart';
import '../../utils/role_router.dart';
import '../../widgets/hero_card_video_background.dart';

class FarmerDashboardScreen extends StatelessWidget {
  const FarmerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = DataService();
    final uid = AuthService().currentUser?.uid;
    final farmerName = AuthService().userModel?.fullName ?? 'Farmer';
    final products = data.products;
    
    FarmerModel? currentFarmer;
    for (final f in data.farmers) {
      if (f.id == uid) {
        currentFarmer = f;
        break;
      }
    }
    final currentMarket = (currentFarmer?.marketName.isNotEmpty == true)
        ? currentFarmer!.marketName
        : ((currentFarmer?.location.isNotEmpty == true)
            ? currentFarmer!.location
            : (AuthService().userModel?.address.isNotEmpty == true
                ? AuthService().userModel!.address
                : 'Local Fresh'));

    final totalRevenue = data.orders.fold<double>(
      0,
      (sum, o) => sum + o.totalAmount,
    );
    final activeOrders = data.orders
        .where(
          (o) =>
              o.status != 'Delivered' &&
              o.status != 'Completed' &&
              o.status != 'Cancelled',
        )
        .length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Remove back button for bottom nav screen
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.farmerPortal,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currentFarmer?.farmName.isNotEmpty == true
                  ? currentFarmer!.farmName
                  : '$farmerName Farm',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Language Switch Button
          IconButton(
            icon: const Icon(Icons.language_rounded, color: Color(0xFF88AB75)),
            tooltip: l10n.language,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LanguageSelectionScreen(isFullPage: true),
              ),
            ),
          ),
          // Order Alerts with live unread badge
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: uid == null
                ? const Stream.empty()
                : FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: uid)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  backgroundColor: AppTheme.error,
                  textColor: Colors.white,
                  child: const Icon(Icons.notifications_outlined),
                ),
                tooltip: l10n.alerts,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FarmerNotificationsScreen(),
                  ),
                ),
              );
            },
          ),
          // Farmer Profile Button
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: l10n.farmerProfile,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FarmerOwnProfileScreen(),
              ),
            ),
          ),
          // Chat / Messages
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: l10n.messages,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChatListScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.logout,
            onPressed: () => logoutAndGoToRoles(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              HeroCardVideoBackground(
                videoAsset: 'video/farmer_home_hero.mp4',
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(20),
                fallbackDecoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                overlayGradient: LinearGradient(
                  colors: [
                    const Color(0xFF0C2B14).withValues(alpha: 0.72),
                    const Color(0xFF081F0E).withValues(alpha: 0.84),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $farmerName!',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your fresh produce is live in $currentMarket.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddEditProductScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                            ),
                            label: Text(l10n.addNewProduct),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Material(
                color: const Color(0xFF15281E),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(
                    Icons.add_location_alt_outlined,
                    color: AppTheme.primary,
                  ),
                  title: Text(
                    'Set Market Location & Hours',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Add your GPS pin so nearby customers can find you',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FarmerMarketLocationScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Marketplace View Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarketplaceViewScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A2B), Color(0xFF12241A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withAlpha(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF88AB75).withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          color: Color(0xFFA1C68A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'View Marketplace',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF0F5F1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Compare prices from other farmers',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8FA497),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFA1C68A),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pickup Slots Management Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FarmerPickupSlotsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A2B), Color(0xFF12241A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withAlpha(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF88AB75).withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.access_time_filled_rounded,
                          color: Color(0xFFA1C68A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Pickup Slots',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF0F5F1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create time slots for order pickups',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8FA497),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFA1C68A),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Farmer Rewards Banner ────────────────────────────────────
              _FarmerRewardsBanner(
                farmerId: AuthService().currentUser?.uid ?? '',
              ),
              const SizedBox(height: 20),

              // Metrics Grid
              Text(
                'Overview & Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 700 ? 4 : 2;
                  final childAspectRatio = width < 360
                      ? 1.15
                      : (width > 600 ? 1.5 : 1.3);

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _buildMetricCard(
                        'Total Revenue',
                        'Rs. ${totalRevenue.toStringAsFixed(0)}',
                        Icons.monetization_on_rounded,
                        AppTheme.primary,
                      ),
                      _buildMetricCard(
                        'Active Orders',
                        '$activeOrders',
                        Icons.local_shipping_rounded,
                        AppTheme.accent,
                      ),
                      _buildMetricCard(
                        'Produce Listed',
                        '${products.length} Items',
                        Icons.eco_rounded,
                        Colors.teal,
                      ),
                      _buildMetricCard(
                        'Customer Rating',
                        '4.9',
                        Icons.star_rounded,
                        Colors.amber.shade800,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Inventory Monitoring Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A2B), Color(0xFF12241A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inventory Status',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF0F5F1),
                                ),
                              ),
                              Text(
                                'Monitor your stock levels',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF8FA497),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInventoryMetric(
                            'Out of Stock',
                            products
                                .where((p) => p.stockKg <= 0)
                                .length
                                .toString(),
                            Icons.remove_circle_outline,
                            const Color(0xFFE76F51),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInventoryMetric(
                            'Low Stock',
                            products
                                .where((p) => p.stockKg > 0 && p.stockKg < 10)
                                .length
                                .toString(),
                            Icons.warning_rounded,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInventoryMetric(
                            'In Stock',
                            products
                                .where((p) => p.stockKg >= 10)
                                .length
                                .toString(),
                            Icons.check_circle_outline,
                            const Color(0xFF88AB75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Live Stock Alert
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Produce Stock',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('View All')),
                ],
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.take(4).length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = products[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15281E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            p.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF0F5F1),
                                ),
                              ),
                              Text(
                                'Rs. ${p.price.toStringAsFixed(0)} / ${p.unit} • ${p.category}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF8FA497),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: p.stockKg > 0
                                ? const Color(0xFF88AB75).withAlpha(30)
                                : const Color(0xFFE76F51).withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.stockKg > 0
                                ? '${p.stockKg} kg in stock'
                                : 'Out of Stock',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.stockKg > 0
                                  ? const Color(0xFFA1C68A)
                                  : const Color(0xFFE76F51),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF0F5F1),
                  ),
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF8FA497),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildInventoryMetric(
  String label,
  String value,
  IconData icon,
  Color color,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withAlpha(40)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF8FA497),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  FARMER REWARDS BANNER — shown on dashboard above analytics grid
// ═══════════════════════════════════════════════════════════════════════════

class _FarmerRewardsBanner extends StatelessWidget {
  final String farmerId;
  const _FarmerRewardsBanner({required this.farmerId});

  @override
  Widget build(BuildContext context) {
    if (farmerId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<FarmerGamificationProfile>(
      stream: GamificationService().farmerProfileStream(farmerId),
      builder: (context, snap) {
        final profile = snap.data ??
            FarmerGamificationProfile.empty(farmerId);
        final badgeColor =
            GamificationService.farmerBadgeColor(profile.badge);
        final badgeIcon =
            GamificationService.farmerBadgeIcon(profile.badge);
        final badgeLabel =
            GamificationService.farmerBadgeLabel(profile.badge);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const FarmerRewardsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  badgeColor.withOpacity(0.20),
                  const Color(0xFF15281E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: badgeColor.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                // Points circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor.withOpacity(0.15),
                    border: Border.all(
                        color: badgeColor.withOpacity(0.5),
                        width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${profile.totalPoints}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text('pts',
                          style: GoogleFonts.inter(
                              fontSize: 8,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(badgeIcon, size: 14, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(badgeLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: badgeColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: profile.tierProgress,
                          minHeight: 5,
                          backgroundColor:
                              const Color(0xFF1F3A2A),
                          valueColor: AlwaysStoppedAnimation(
                              badgeColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.pointsToNextTier > 0
                            ? '${profile.pointsToNextTier} pts to next tier'
                            : 'Max tier reached',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Stats mini
                Column(
                  children: [
                    _MiniStat(
                        icon: Icons.check_circle_outline_rounded,
                        value: '${profile.completedOrders}',
                        color: AppTheme.primary),
                    const SizedBox(height: 4),
                    _MiniStat(
                        icon: Icons.star_rounded,
                        value: '${profile.fiveStarRatings}',
                        color: AppTheme.warning),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: badgeColor),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
      ],
    );
  }
}
