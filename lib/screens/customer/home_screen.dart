import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import 'product_details_screen.dart';
import 'product_list_screen.dart';
import 'farmer_profile_screen.dart';
import 'farmer_market_map_screen.dart';
import 'notifications_screen.dart';
import 'search_filter_dialog.dart';
import '../auth/role_selection_screen.dart';
import '../../widgets/hero_card_video_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  int _getActiveFilterCount() {
    int count = 0;
    if (_dataService.selectedCategory != 'All') count++;
    if (_dataService.maxDistanceKm < 50.0) count++;
    if (_dataService.selectedMarket != 'All Markets') count++;
    if (_dataService.priceLimit != null &&
        _dataService.priceFilter != 'Any price')
      count++;
    if (_dataService.productNameFilter != null &&
        _dataService.productNameFilter!.isNotEmpty)
      count++;
    if (_dataService.farmerNameFilter != null &&
        _dataService.farmerNameFilter!.isNotEmpty)
      count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = _dataService.notifications
        .where((n) => !n.isRead)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row (Leafora Style)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RoleSelectionScreen(),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF15281E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha(25)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFFF0F5F1),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Color(0xFFA1C68A),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  _dataService.selectedDeliveryAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF8FA497),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Live Map Icon Button
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF15281E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Live Farmers Map',
                        icon: const Icon(
                          Icons.map_outlined,
                          size: 20,
                          color: Color(0xFFA1C68A),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FarmerMarketMapScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notification Button
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF15281E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Badge(
                          isLabelVisible: unreadNotifs > 0,
                          label: Text('$unreadNotifs'),
                          backgroundColor: const Color(0xFF88AB75),
                          textColor: const Color(0xFF0D1A13),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: Color(0xFFF0F5F1),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search Bar + Filter Trigger (Frosted Dark Glass)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProductListScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15281E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF8FA497),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Search fresh produce, veggies...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF6F8578),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF182D22),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withAlpha(30),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFFA1C68A),
                              size: 20,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const SearchFilterDialog(),
                              );
                            },
                          ),
                        ),
                        // Active filter count badge
                        if (_getActiveFilterCount() > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF88AB75),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                '${_getActiveFilterCount()}',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0D1A13),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero Banner Card (Leafora "Bring Greenery to Life" Style)
                HeroCardVideoBackground(
                  videoAsset: 'video/customer_home_hero.mp4',
                  borderRadius: BorderRadius.circular(26),
                  padding: const EdgeInsets.all(22),
                  fallbackDecoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3326), Color(0xFF12241A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withAlpha(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  overlayGradient: LinearGradient(
                    colors: [
                      const Color(0xFF0D1A13).withValues(alpha: 0.65),
                      const Color(0xFF0D1A13).withValues(alpha: 0.78),
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
                              'Bring Freshness\nto Life',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFF0F5F1),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Curated organic harvest direct from verified local farmers.',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8FA497),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ProductListScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF88AB75),
                                  foregroundColor: const Color(0xFF0D1A13),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  'Shop Now',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0D1A13),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF88AB75).withAlpha(25),
                          border: Border.all(
                            color: const Color(0xFF88AB75).withAlpha(60),
                          ),
                        ),
                        child: const Icon(
                          Icons.local_florist_rounded,
                          color: Color(0xFFA1C68A),
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Categories Row (Leafora rounded square chips)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dataService.categories.length,
                    itemBuilder: (context, index) {
                      final cat = _dataService.categories[index];
                      final isSelected =
                          _dataService.selectedCategory == cat.name;

                      return GestureDetector(
                        onTap: () {
                          _dataService.setCategory(
                            isSelected ? 'All' : cat.name,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          width: 72,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF88AB75)
                                : const Color(0xFF15281E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFA1C68A)
                                  : Colors.white.withAlpha(20),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat.iconData,
                                size: 24,
                                color: isSelected
                                    ? const Color(0xFF0D1A13)
                                    : const Color(0xFFA1C68A),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF0D1A13)
                                      : const Color(0xFFF0F5F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Nearby Farmers Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Farmers',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    Text(
                      'Within 20 km',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Farmers Carousel
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dataService.farmers.length,
                    itemBuilder: (context, index) {
                      final farmer = _dataService.farmers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FarmerProfileScreen(farmer: farmer),
                            ),
                          );
                        },
                        child: Container(
                          width: 240,
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15281E),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withAlpha(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(farmer.avatarUrl),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            farmer.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFF0F5F1),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (farmer.isVerified)
                                          const Icon(
                                            Icons.verified,
                                            size: 15,
                                            color: Color(0xFFA1C68A),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      farmer.farmName,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF8FA497),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 15,
                                          color: Colors.amber,
                                        ),
                                        Text(
                                          ' ${farmer.rating}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFF0F5F1),
                                          ),
                                        ),
                                        Text(
                                          ' (${farmer.distanceKm}km)',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF8FA497),
                                          ),
                                        ),
                                      ],
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
                ),
                const SizedBox(height: 24),

                // Best Sellers Header (Matching Leafora)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Best Sellers',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProductListScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA1C68A),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFFA1C68A),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Products Grid (Adaptive & Responsive)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 900
                        ? 4
                        : (width > 560 ? 3 : 2);
                    final childAspectRatio = width < 360
                        ? 0.65
                        : (width > 600 ? 0.78 : 0.72);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _dataService.filteredProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final product = _dataService.filteredProducts[index];
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
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withAlpha(20),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Flexible Product Image Container
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(22),
                                              ),
                                          child: Image.network(
                                            product.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: const Color(
                                                        0xFF0F1E16,
                                                      ),
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.eco_outlined,
                                                          color: Color(
                                                            0xFFA1C68A,
                                                          ),
                                                          size: 36,
                                                        ),
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      // Wishlist Heart Toggle
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withAlpha(80),
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              product.isFavorite
                                                  ? Icons.favorite
                                                  : Icons
                                                        .favorite_border_rounded,
                                              color: product.isFavorite
                                                  ? const Color(0xFFE76F51)
                                                  : Colors.white70,
                                              size: 17,
                                            ),
                                            onPressed: () {
                                              _dataService.toggleFavorite(
                                                product.id,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFF0F5F1),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Rs.${product.price.toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFA1C68A),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _dataService.addToCart(product);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${product.name} added to cart',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 1,
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFF1E3A2B,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF88AB75),
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                color: Color(0xFF0D1A13),
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
