import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../models/farmer_model.dart';
import '../../models/review_model.dart';
import '../../services/data_service.dart';
import '../../l10n/app_localizations.dart';
import 'farmer_profile_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final DataService _dataService = DataService();
  int _quantity = 1;
  List<ReviewModel> _reviews = [];
  bool _loadingReviews = true;
  String? _liveFarmerAvatar;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadFarmerLiveProfile();
  }

  Future<void> _loadFarmerLiveProfile() async {
    final fid = widget.product.farmerId;
    if (fid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(fid).get();
      if (doc.exists && mounted) {
        final pic = (doc.data()?['profilePic'] as String? ?? doc.data()?['photoUrl'] as String? ?? doc.data()?['photoURL'] as String? ?? '').trim();
        if (pic.isNotEmpty) {
          setState(() {
            _liveFarmerAvatar = pic;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadReviews() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: widget.product.id)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          _reviews = snapshot.docs.map((doc) => ReviewModel.fromDoc(doc)).toList();
          _loadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) {
        setState(() => _loadingReviews = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final product = widget.product;
    FarmerModel? matchedFarmer;
    for (final f in _dataService.farmers) {
      if (f.id == product.farmerId ||
          (product.farmerName.isNotEmpty && f.name.toLowerCase() == product.farmerName.toLowerCase())) {
        matchedFarmer = f;
        break;
      }
    }

    final rawAvatar = _liveFarmerAvatar ?? matchedFarmer?.avatarUrl ?? '';
    final farmer = matchedFarmer ??
        FarmerModel(
          id: product.farmerId,
          name: product.farmerName.isNotEmpty ? product.farmerName : 'Local Farmer',
          farmName: product.farmerFarm.isNotEmpty ? product.farmerFarm : 'Local Farm',
          location: product.marketName.isNotEmpty && !product.marketName.toLowerCase().contains('model town')
              ? product.marketName
              : 'Local Market',
          distanceKm: product.distanceKm,
          rating: product.rating,
          reviewCount: product.reviewsCount,
          avatarUrl: rawAvatar,
          bio: 'Fresh organic produce directly from farm to table.',
          followerCount: 50,
          marketName: product.marketName.isNotEmpty && !product.marketName.toLowerCase().contains('model town')
              ? product.marketName
              : '',
        );

    final String effectiveAvatar = (_liveFarmerAvatar?.isNotEmpty == true)
        ? _liveFarmerAvatar!
        : ((farmer.avatarUrl.isNotEmpty && !farmer.avatarUrl.contains('unsplash.com'))
            ? farmer.avatarUrl
            : '');

    String displayLocation = '';
    if (farmer.marketName.isNotEmpty && farmer.location.isNotEmpty) {
      displayLocation = '${farmer.marketName}, ${farmer.location}';
    } else if (farmer.marketName.isNotEmpty) {
      displayLocation = farmer.marketName;
    } else if (farmer.location.isNotEmpty) {
      displayLocation = farmer.location;
    } else if (product.marketName.isNotEmpty && !product.marketName.toLowerCase().contains('model town')) {
      displayLocation = product.marketName;
    } else if (farmer.farmName.isNotEmpty) {
      displayLocation = farmer.farmName;
    } else {
      displayLocation = l10n.market;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image (Image extends fully without dark solid cutoff)
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: const Color(0xFF0D1A13),
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF15281E).withAlpha(200),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFFF0F5F1)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF15281E).withAlpha(200),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    product.isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                    color: product.isFavorite ? const Color(0xFFE76F51) : const Color(0xFFF0F5F1),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _dataService.toggleFavorite(product.id);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF15281E).withAlpha(200),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.share_outlined, color: Color(0xFFF0F5F1), size: 18),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF122218),
                      child: const Center(
                        child: Icon(Icons.eco_rounded, size: 60, color: Color(0xFF88AB75)),
                      ),
                    ),
                  ),
                  // Top subtle gradient for buttons visibility
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 110,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(140),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom prominent elegant curve overlay directly over the image
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF13241A),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                      ),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details Body: Connected seamlessly to the prominent curved top
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF13241A),
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Title and Price Tag
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF0F5F1),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.category}  •  $displayLocation',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF8EAA95),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3324),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF88AB75).withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE9C46A)),
                            const SizedBox(width: 4),
                            Text(
                              '${product.rating}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF0F5F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Botanical Attributes Row (Water, Light, Origin, Stock)
                  Row(
                    children: [
                      _buildMetricCard(Icons.water_drop_outlined, l10n.freshness, l10n.dailyPick),
                      const SizedBox(width: 10),
                      _buildMetricCard(Icons.wb_sunny_outlined, l10n.sunlight, l10n.natural),
                      const SizedBox(width: 10),
                      _buildMetricCard(Icons.eco_outlined, l10n.produce, product.unit),
                      const SizedBox(width: 10),
                      _buildMetricCard(
                        Icons.inventory_2_outlined,
                        l10n.inStock,
                        product.stock > 0 ? '${product.stock} ${l10n.stockAvailable}' : l10n.outOfStock,
                        isHighlight: product.stock > 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Description Header & Body
                  Text(
                    l10n.aboutProduce,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF0F5F1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isNotEmpty ? product.description : product.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFB0C4B6),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Harvested By Farmer Card
                  Text(
                    l10n.harvestedByFarmer,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF0F5F1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FarmerProfileScreen(
                            farmer: farmer.copyWith(
                              avatarUrl: effectiveAvatar.isNotEmpty ? effectiveAvatar : farmer.avatarUrl,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2E22),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF223E2E),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: (effectiveAvatar.isNotEmpty)
                                ? Image.network(
                                    effectiveAvatar,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        farmer.name.isNotEmpty ? farmer.name[0].toUpperCase() : 'F',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFA1C68A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
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
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      farmer.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFF0F5F1),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, size: 16, color: Color(0xFF88AB75)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${farmer.farmName.isNotEmpty ? farmer.farmName : farmer.name} (${farmer.location.isNotEmpty ? farmer.location : (farmer.marketName.isNotEmpty ? farmer.marketName : "Local")})',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF8EAA95),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF8EAA95)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reviews Section
                  Text(
                    '${l10n.customerReviews} (${_reviews.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF0F5F1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_loadingReviews)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: Color(0xFFA1C68A)),
                      ),
                    )
                  else if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15281E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.rate_review_outlined,
                              size: 40,
                              color: Color(0xFF8FA497),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No reviews yet',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8FA497),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to review this product!',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8FA497),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._reviews.map((review) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15281E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withAlpha(20)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF88AB75),
                                    child: Text(
                                      review.customerName.isNotEmpty
                                          ? review.customerName[0].toUpperCase()
                                          : 'C',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D1A13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review.customerName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFF0F5F1),
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (index) => Icon(
                                              index < review.rating
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              size: 14,
                                              color: const Color(0xFFFFB800),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDate(review.createdAt),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF8FA497),
                                    ),
                                  ),
                                ],
                              ),
                              if (review.comment.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  review.comment,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFFB0C4B6),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )),
                  const SizedBox(height: 80), // Space for bottom sheet
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Floating Bar (Matching Screen 3)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1A13),
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha(25), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Unit Price
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.totalPrice,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8EAA95),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${(product.price * _quantity).toInt()}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Quantity Stepper
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF162A1F),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.remove, size: 16, color: Color(0xFFF0F5F1)),
                        onPressed: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                      ),
                      Text(
                        '$_quantity',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF0F5F1),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFFF0F5F1)),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Add to Cart Pill Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF88AB75),
                        foregroundColor: const Color(0xFF0D1A13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: () {
                        _dataService.addToCart(product, qty: _quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $_quantity ${product.title} to Cart!'),
                            backgroundColor: const Color(0xFF1E3827),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: Text(
                        l10n.addToCart,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String title, String subtitle, {bool isHighlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF182D20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF88AB75)),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF8EAA95),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isHighlight ? const Color(0xFF88AB75) : const Color(0xFFF0F5F1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    } else {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    }
  }
