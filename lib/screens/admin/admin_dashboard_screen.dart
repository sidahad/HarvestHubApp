import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/farmer_model.dart';
import '../../services/data_service.dart';
import '../../utils/role_router.dart';
import '../../l10n/app_localizations.dart';
import 'admin_farmer_products_screen.dart';
import '../customer/farmer_market_map_screen.dart';
import '../common/language_selection_screen.dart';
import '../../widgets/hero_card_video_background.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DataService _data = DataService();

  // Firestore-sourced counts (loaded once on init)
  int _totalUsers = 0;
  int _totalActiveOrders = 0;

  @override
  void initState() {
    super.initState();
    // Listen to DataService so dashboard rebuilds when loadCatalog /
    // loadOrdersForStaff complete and call notifyListeners().
    _data.addListener(_onDataChanged);
    _loadFirestoreCounts();
  }

  @override
  void dispose() {
    _data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  /// Fetch user count and active-order count directly from Firestore.
  /// These are independent of DataService's in-memory lists.
  Future<void> _loadFirestoreCounts() async {
    try {
      // Total registered users (all roles)
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();

      // Active orders = orders that are NOT delivered/cancelled
      final activeOrdersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', whereNotIn: ['Delivered', 'Cancelled', 'Completed'])
          .get();

      if (mounted) {
        setState(() {
          _totalUsers = usersSnap.docs.length;
          _totalActiveOrders = activeOrdersSnap.docs.length;
        });
      }
    } catch (e) {
      debugPrint('AdminDashboard: failed to load Firestore counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final farmers = _data.farmers;
    final products = _data.products;
    final orders = _data.orders;

    // Approved (verified) farmers
    final approvedFarmers = farmers.where((f) => f.isVerified).length;
    // Pending farmers
    final pendingFarmers = farmers.where((f) => !f.isVerified).length;

    final totalMarketVolume = orders.fold<double>(
      0,
      (acc, o) => acc + o.totalAmount,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminCenter,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'HarvestHub Platform Management',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher
          IconButton(
            icon: const Icon(Icons.language_rounded, color: Color(0xFFE76F51)),
            tooltip: l10n.language,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LanguageSelectionScreen(isFullPage: true),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Live Farmers Map',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FarmerMarketMapScreen(),
              ),
            ),
          ),
          // Refresh button — re-fetches everything
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: () {
              _data.loadCatalog().catchError(
                    (e) => debugPrint('Reload catalog: $e'),
                  );
              _data.loadOrdersForStaff().catchError(
                    (e) => debugPrint('Reload orders: $e'),
                  );
              _loadFirestoreCounts();
            },
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
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _data.loadCatalog(),
              _data.loadOrdersForStaff(),
              _loadFirestoreCounts(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Admin Banner ──────────────────────────────────────────
                HeroCardVideoBackground(
                  videoAsset: 'video/admin_home_hero.mp4',
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(20),
                  fallbackDecoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.secondary, Color(0xFF0D47A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  overlayGradient: LinearGradient(
                    colors: [
                      const Color(0xFF081C38).withValues(alpha: 0.72),
                      const Color(0xFF061426).withValues(alpha: 0.84),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform Metrics & Moderation',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Live platform monitoring and moderation',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Use Wrap so stats never overflow on small screens
                      Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          _buildHeaderStat(
                            'Total GMV',
                            'Rs. ${totalMarketVolume.toStringAsFixed(0)}',
                          ),
                          _buildHeaderStat(
                            'Approved',
                            '$approvedFarmers Verified',
                          ),
                          _buildHeaderStat(
                            'Pending',
                            '$pendingFarmers Waiting',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Platform KPIs ─────────────────────────────────────────
                Text(
                  'Platform Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 700 ? 3 : 2;
                    final childAspectRatio =
                        width < 360 ? 1.1 : (width > 600 ? 1.5 : 1.25);

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildMetricCard(
                          'Total Users',
                          '$_totalUsers Registered',
                          Icons.people_alt_rounded,
                          Colors.blue,
                        ),
                        _buildMetricCard(
                          'Registered Farmers',
                          '${farmers.length} Farms',
                          Icons.agriculture_rounded,
                          AppTheme.primary,
                        ),
                        _buildMetricCard(
                          'Listed Produce',
                          '${products.length} Products',
                          Icons.inventory_2_rounded,
                          AppTheme.accent,
                        ),
                        _buildMetricCard(
                          'Total Orders',
                          '${orders.length} Orders',
                          Icons.receipt_rounded,
                          Colors.purple,
                        ),
                        _buildMetricCard(
                          'Active Orders',
                          '$_totalActiveOrders In Progress',
                          Icons.local_shipping_rounded,
                          Colors.orange,
                        ),
                        _buildMetricCard(
                          'Pending Farmers',
                          '$pendingFarmers Awaiting',
                          Icons.pending_actions_rounded,
                          Colors.amber,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Farmer Approvals ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Farmer Approvals & Moderation',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Show pending count badge
                    if (pendingFarmers > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5B94C).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE5B94C).withAlpha(80)),
                        ),
                        child: Text(
                          '$pendingFarmers pending',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE5B94C),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (farmers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Loading farmers...',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ),
                  )
                else
                  // Show pending farmers first, then verified
                  ...[
                    ...farmers
                        .where((f) => !f.isVerified)
                        .map((f) => _buildFarmerTile(context, f)),
                    ...farmers
                        .where((f) => f.isVerified)
                        .map((f) => _buildFarmerTile(context, f)),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFarmerApproval(FarmerModel f) async {
    final newVerified = !f.isVerified;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final farmersRef =
          FirebaseFirestore.instance.collection('farmers').doc(f.id);
      final usersRef =
          FirebaseFirestore.instance.collection('users').doc(f.id);

      batch.set(farmersRef, {'isVerified': newVerified}, SetOptions(merge: true));
      batch.set(usersRef, {'isVerified': newVerified}, SetOptions(merge: true));
      await batch.commit();

      final idx = _data.farmers.indexWhere((x) => x.id == f.id);
      if (idx != -1) {
        _data.farmers[idx] = FarmerModel(
          id: f.id,
          name: f.name,
          farmName: f.farmName,
          location: f.location,
          latitude: f.latitude,
          longitude: f.longitude,
          marketName: f.marketName,
          marketHours: f.marketHours,
          distanceKm: f.distanceKm,
          rating: f.rating,
          reviewCount: f.reviewCount,
          avatarUrl: f.avatarUrl,
          bio: f.bio,
          isVerified: newVerified,
          followerCount: f.followerCount,
          totalProducts: f.totalProducts,
        );
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        _data.notifyListeners();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newVerified
              ? '${f.name} approved & verified'
              : '${f.name} marked as pending'),
          backgroundColor: newVerified ? AppTheme.primary : AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Widget _buildFarmerTile(BuildContext context, farmer) {
    final f = farmer as FarmerModel;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: f.isVerified
              ? Colors.white.withAlpha(20)
              : const Color(0xFFE5B94C).withAlpha(40),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminFarmerProductsScreen(farmer: f),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: f.imageUrl.isNotEmpty
                    ? Image.network(
                        f.imageUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => _farmerAvatarPlaceholder(),
                      )
                    : _farmerAvatarPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    Text(
                      '${f.location.isNotEmpty ? f.location : "No location"} • ${f.totalProducts} products listed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!f.isVerified)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF88AB75),
                    foregroundColor: const Color(0xFF0D1A13),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: Text(
                    'Approve',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _toggleFarmerApproval(f),
                )
              else
                InkWell(
                  onTap: () => _toggleFarmerApproval(f),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A2B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFA1C68A).withAlpha(50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Color(0xFFA1C68A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFA1C68A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios,
                size: 13,
                color: Color(0xFF8FA497),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _farmerAvatarPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      color: const Color(0xFF1E3A2B),
      child: const Icon(Icons.person, color: Color(0xFFA1C68A), size: 24),
    );
  }

  Widget _buildHeaderStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
        ),
        Text(
          val,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
