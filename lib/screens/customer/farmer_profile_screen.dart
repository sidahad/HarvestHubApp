import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/farmer_model.dart';
import '../../services/data_service.dart';
import 'product_details_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  final FarmerModel farmer;
  const FarmerProfileScreen({super.key, required this.farmer});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final farmer = _dataService.farmers.firstWhere(
      (f) => f.id == widget.farmer.id,
      orElse: () => widget.farmer,
    );
    final farmerProducts = _dataService.products
        .where((p) => p.farmerId == farmer.id || p.farmerName == farmer.name)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Farmer Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF223E2E),
                  border: Border.all(
                    color: const Color(0xFFA1C68A).withAlpha(120),
                    width: 2.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: (farmer.avatarUrl.isNotEmpty && !farmer.avatarUrl.contains('unsplash.com'))
                    ? Image.network(
                        farmer.avatarUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            farmer.name.isNotEmpty ? farmer.name[0].toUpperCase() : 'F',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFA1C68A),
                              fontWeight: FontWeight.bold,
                              fontSize: 34,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          farmer.name.isNotEmpty ? farmer.name[0].toUpperCase() : 'F',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFA1C68A),
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 14),

              // Name & Verification Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    farmer.name,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (farmer.isVerified)
                    const Icon(
                      Icons.verified,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                farmer.farmName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${farmer.location} (${farmer.distanceKm} km away)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Stats Row in Frosted Glass Container
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('farmers')
                    .doc(farmer.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final rating =
                      (data?['rating'] as num?)?.toDouble() ?? farmer.rating;
                  final reviewCount =
                      (data?['reviewCount'] as num?)?.toInt() ??
                      (data?['reviewsCount'] as num?)?.toInt() ??
                      farmer.reviewCount;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15281E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Rating',
                          rating.toStringAsFixed(1),
                          icon: Icons.star_rounded,
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.white.withAlpha(20),
                        ),
                        _buildStatItem('Reviews', '$reviewCount'),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.white.withAlpha(20),
                        ),
                        _buildStatItem('Followers', '${farmer.followerCount}'),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Follow / Unfollow Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _dataService.toggleFollowFarmer(farmer.id);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: farmer.isFollowing
                        ? const Color(0xFF15281E)
                        : const Color(0xFF88AB75),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: farmer.isFollowing
                          ? const Color(0xFFA1C68A).withAlpha(80)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: farmer.isFollowing
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF88AB75).withAlpha(50),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        farmer.isFollowing
                            ? Icons.check_circle_rounded
                            : Icons.person_add_alt_1_rounded,
                        size: 18,
                        color: farmer.isFollowing
                            ? const Color(0xFFA1C68A)
                            : const Color(0xFF0D1A13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        farmer.isFollowing ? 'Following' : 'Follow Farmer',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: farmer.isFollowing
                              ? const Color(0xFFA1C68A)
                              : const Color(0xFF0D1A13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bio Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF15281E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About the Farm',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      farmer.bio,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF8FA497),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Farmer Products Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Products by ${farmer.name} (${farmerProducts.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF0F5F1),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Products Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: farmerProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final product = farmerProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailsScreen(product: product),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF15281E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              product.imageUrl,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF0F5F1),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Rs. ${product.price.toInt()} / ${product.unit}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFA1C68A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildStatItem(String label, String value, {IconData? icon, Color? iconColor}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor ?? Colors.amber),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
