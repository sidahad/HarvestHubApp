import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/farmer_model.dart';
import '../../services/data_service.dart';
import '../customer/farmer_market_map_screen.dart';

class AdminFarmersScreen extends StatefulWidget {
  const AdminFarmersScreen({super.key});

  @override
  State<AdminFarmersScreen> createState() => _AdminFarmersScreenState();
}

class _AdminFarmersScreenState extends State<AdminFarmersScreen> {
  final DataService _data = DataService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Sort: pending first, then verified
    final allFarmers = [..._data.farmers]
      ..sort((a, b) {
        if (a.isVerified == b.isVerified) return 0;
        return a.isVerified ? 1 : -1; // pending first
      });

    final farmers = _searchQuery.isEmpty
        ? allFarmers
        : allFarmers
            .where((f) =>
                f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                f.farmName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                f.location.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Farmer Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(
                  color: const Color(0xFFF0F5F1), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search farmers...',
                hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF6B8A74), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF8FA497), size: 20),
                filled: true,
                fillColor: const Color(0xFF15281E),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: farmers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.agriculture_rounded,
                        size: 64, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      _data.farmers.isEmpty
                          ? 'Loading farmers...'
                          : 'No farmers match your search',
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () => _data.loadCatalog(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: farmers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final f = farmers[index];
                    return _buildFarmerCard(context, f);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildFarmerCard(BuildContext context, FarmerModel f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: f.isVerified
              ? Colors.white.withAlpha(20)
              : const Color(0xFFE5B94C).withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1E3A2B),
                backgroundImage:
                    f.imageUrl.isNotEmpty ? NetworkImage(f.imageUrl) : null,
                onBackgroundImageError: f.imageUrl.isNotEmpty
                    ? (_, __) {}
                    : null,
                child: f.imageUrl.isEmpty
                    ? const Icon(Icons.person,
                        color: Color(0xFFA1C68A), size: 24)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            f.name,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF0F5F1),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Verified / Pending badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: f.isVerified
                                ? const Color(0xFF1A3B28)
                                : const Color(0xFF332A15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: f.isVerified
                                  ? const Color(0xFFA1C68A).withAlpha(80)
                                  : const Color(0xFFE5B94C).withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                f.isVerified
                                    ? Icons.verified_rounded
                                    : Icons.pending_actions_rounded,
                                size: 12,
                                color: f.isVerified
                                    ? const Color(0xFFA1C68A)
                                    : const Color(0xFFE5B94C),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                f.isVerified ? 'Verified' : 'Pending',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: f.isVerified
                                      ? const Color(0xFFA1C68A)
                                      : const Color(0xFFE5B94C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      f.farmName,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF8FA497)),
                    ),
                    Text(
                      f.location.isNotEmpty
                          ? '${f.location} • ${f.totalProducts} products'
                          : '${f.totalProducts} products listed',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF8FA497)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (f.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              f.description,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF8FA497)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          Divider(height: 20, color: Colors.white.withAlpha(15)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${f.rating.toStringAsFixed(1)}  •  ${f.reviewsCount} reviews',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF0F5F1),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color:
                        f.isVerified ? AppTheme.error : AppTheme.primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  f.isVerified
                      ? Icons.remove_circle_outline
                      : Icons.verified_user_outlined,
                  size: 14,
                  color: f.isVerified ? AppTheme.error : AppTheme.primary,
                ),
                onPressed: () async {
                  await _toggleVerification(context, f);
                },
                label: Text(
                  f.isVerified ? 'Revoke' : 'Verify',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: f.isVerified ? AppTheme.error : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVerification(
      BuildContext context, FarmerModel f) async {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
      return;
    }

    // Update in-memory model then notify listeners → rebuilds dashboard too
    final idx = _data.farmers.indexWhere((x) => x.id == f.id);
    if (idx != -1) {
      _data.farmers[idx] = FarmerModel(
        id: f.id,
        name: f.name,
        farmName: f.farmName,
        location: f.location,
        distanceKm: f.distanceKm,
        rating: f.rating,
        reviewCount: f.reviewCount,
        avatarUrl: f.avatarUrl,
        bio: f.bio,
        isVerified: newVerified,
        followerCount: f.followerCount,
        totalProducts: f.totalProducts,
        joinedDate: f.joinedDate,
        isFollowing: f.isFollowing,
      );
      // notifyListeners so AdminDashboard also reflects the change
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      _data.notifyListeners();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newVerified
            ? '${f.name} verified'
            : '${f.name} badge revoked'),
        backgroundColor:
            newVerified ? AppTheme.primary : AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
