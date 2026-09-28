import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';

class MarketplaceViewScreen extends StatefulWidget {
  const MarketplaceViewScreen({super.key});

  @override
  State<MarketplaceViewScreen> createState() => _MarketplaceViewScreenState();
}

class _MarketplaceViewScreenState extends State<MarketplaceViewScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final data = DataService();
    final currentUser = AuthService().currentUser;
    
    // Show ONLY other farmers' products (not own products)
    final otherFarmersProducts = data.products
        .where((p) => p.farmerId != currentUser?.uid)
        .toList();

    // Apply filters
    final filteredProducts = otherFarmersProducts.where((p) {
      final matchesCategory = _selectedCategory == 'All' || 
                             p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
                          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          p.farmerName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    // Get unique categories from other farmers' products
    final categories = ['All', ...otherFarmersProducts
        .map((p) => p.category)
        .toSet()
        .toList()..sort()];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button for bottom nav screen
        title: Text(
          'Marketplace - Other Farmers',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
              decoration: InputDecoration(
                hintText: 'Search products or farmer name...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF8FA497)),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                filled: true,
                fillColor: const Color(0xFF15281E),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: true, // Add safe area for bottom navigation
        child: Column(
          children: [
          // Category Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: const Color(0xFF15281E),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.white.withAlpha(20),
                  ),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF0D1A13)
                        : const Color(0xFFF0F5F1),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              },
            ),
          ),

          // Info Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF15281E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'View other farmers\' products for price comparison and market insights',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8FA497),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredProducts.length} products from other farmers',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          otherFarmersProducts.isEmpty
                              ? 'No other farmers have listed products yet'
                              : 'No products match your search',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (otherFarmersProducts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Try adjusting your filters',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildProductCard(filteredProducts[index]);
                    },
                  ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isOutOfStock = product.stockKg <= 0;
    final isPriceLow = product.price < 200;
    final isPriceHigh = product.price > 1000;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFF182D22),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppTheme.primary,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF0F5F1),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isOrganic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Organic',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFFA1C68A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Category
                    Text(
                      product.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Price with indicator
                    Row(
                      children: [
                        Text(
                          'Rs. ${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFA1C68A),
                          ),
                        ),
                        Text(
                          ' / ${product.unit}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF8FA497),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isPriceLow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A2B),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFA1C68A).withAlpha(50),
                              ),
                            ),
                            child: Text(
                              'Budget',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: const Color(0xFFA1C68A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (isPriceHigh)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF332A15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFE5B94C).withAlpha(50),
                              ),
                            ),
                            child: Text(
                              'Premium',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: const Color(0xFFE5B94C),
                                fontWeight: FontWeight.w600,
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

          Divider(height: 20, color: Colors.white.withAlpha(15)),

          // Farmer Info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1E3A2B),
                child: Text(
                  product.farmerName.isNotEmpty
                      ? product.farmerName[0].toUpperCase()
                      : 'F',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFA1C68A),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.farmerName.isEmpty
                          ? 'Unknown Farmer'
                          : product.farmerName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    if (product.distanceKm > 0)
                      Text(
                        '${product.distanceKm.toStringAsFixed(1)} km away',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF8FA497),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Stock and Freshness
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? const Color(0xFF3A1818)
                        : const Color(0xFF1E3A2B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOutOfStock
                          ? const Color(0xFFEF5350).withAlpha(60)
                          : const Color(0xFFA1C68A).withAlpha(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOutOfStock ? Icons.close : Icons.check_circle,
                        size: 14,
                        color: isOutOfStock
                            ? const Color(0xFFEF5350)
                            : const Color(0xFFA1C68A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOutOfStock
                            ? 'Out of Stock'
                            : '${product.stockKg} ${product.unit} available',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOutOfStock
                              ? const Color(0xFFEF5350)
                              : const Color(0xFFA1C68A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF182D22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.eco,
                      size: 14,
                      color: Color(0xFFA1C68A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.freshnessScore}% Fresh',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA1C68A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Market Info
          if (product.marketName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.store,
                  size: 14,
                  color: Color(0xFF8FA497),
                ),
                const SizedBox(width: 6),
                Text(
                  product.marketName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF8FA497),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
