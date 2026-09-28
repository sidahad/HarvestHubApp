import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import 'product_details_screen.dart';
import 'search_filter_dialog.dart';
import 'farmer_market_map_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = _dataService.searchQuery;
    _dataService.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchFilterDialog(),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_dataService.selectedCategory != 'All') count++;
    if (_dataService.maxDistanceKm < 50.0) count++;
    if (_dataService.selectedMarket != 'All Markets') count++;
    if (_dataService.locationFilter.isNotEmpty) count++;
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
    final products = _dataService.filteredProducts;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Product Listing'),
        actions: [
          IconButton(
            tooltip: 'Farmer market map',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FarmerMarketMapScreen()),
            ),
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: _showFilters,
              ),
              // Active filter count badge
              if (_getActiveFilterCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF88AB75),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_getActiveFilterCount()}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0D1A13),
                        fontSize: 9,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            children: [
              // Search Input Field
              TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: const Color(0xFFF0F5F1)),
                decoration: InputDecoration(
                  hintText: 'Search by product name, farmer, market...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF6F8578)),
                  filled: true,
                  fillColor: const Color(0xFF15281E),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFA1C68A),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFF88AB75)),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF8FA497),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _dataService.setSearchQuery('');
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  _dataService.setSearchQuery(val);
                },
              ),
              const SizedBox(height: 12),

              // Active Filters chips bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_dataService.productNameFilter != null &&
                        _dataService.productNameFilter!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(
                            Icons.search,
                            size: 14,
                            color: Color(0xFFA1C68A),
                          ),
                          label: Text(
                            'Name: ${_dataService.productNameFilter}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFF0F5F1),
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: const Color(0xFF182D22),
                          side: BorderSide(color: Colors.white.withAlpha(25)),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF8FA497),
                          ),
                          // Name chip ka onDeleted
                          onDeleted: () {
                            _dataService.updateFilters(
                              distance: _dataService.maxDistanceKm,
                              market: _dataService.selectedMarket,
                              category: _dataService.selectedCategory,
                              price: _dataService.priceLimit,
                              priceMode: _dataService.priceFilter,
                              productName: '',
                              farmerName:
                                  _dataService.farmerNameFilter,
                              location:
                                  _dataService.locationFilter,
                            );
                          },
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(
                        Icons.category,
                        size: 14,
                        color: Color(0xFFA1C68A),
                      ),
                      label: Text(
                        'Cat: ${_dataService.selectedCategory}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF0F5F1),
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: const Color(0xFF182D22),
                      side: BorderSide(color: Colors.white.withAlpha(25)),
                      onPressed: _showFilters,
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(
                        Icons.near_me,
                        size: 14,
                        color: Color(0xFFA1C68A),
                      ),
                      label: Text(
                        'Dist: <${_dataService.maxDistanceKm.toInt()}km',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF0F5F1),
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: const Color(0xFF182D22),
                      side: BorderSide(color: Colors.white.withAlpha(25)),
                      onPressed: _showFilters,
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(
                        Icons.store,
                        size: 14,
                        color: Color(0xFFA1C68A),
                      ),
                      label: Text(
                        _dataService.selectedMarket,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF0F5F1),
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: const Color(0xFF182D22),
                      side: BorderSide(color: Colors.white.withAlpha(25)),
                      onPressed: _showFilters,
                    ),
                    if (_dataService.locationFilter.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Chip(
                        avatar: const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFFA1C68A),
                        ),
                        label: Text(
                          _dataService.locationFilter,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF0F5F1),
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: const Color(0xFF182D22),
                        side: BorderSide(color: Colors.white.withAlpha(25)),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF8FA497),
                        ),
                        onDeleted: () {
                          _dataService.updateFilters(
                            distance: _dataService.maxDistanceKm,
                            market: _dataService.selectedMarket,
                            category: _dataService.selectedCategory,
                            price: _dataService.priceLimit,
                            priceMode: _dataService.priceFilter,
                            productName: _dataService.productNameFilter,
                            farmerName: _dataService.farmerNameFilter,
                            location: '',
                          );
                        },
                      ),
                    ],
                    if (_dataService.priceLimit != null &&
                        _dataService.priceFilter != 'Any price') ...[
                      const SizedBox(width: 8),
                      Chip(
                        avatar: const Icon(
                          Icons.attach_money,
                          size: 14,
                          color: Color(0xFFA1C68A),
                        ),
                        label: Text(
                          '${_dataService.priceFilter}: Rs.${_dataService.priceLimit!.toInt()}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF0F5F1),
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: const Color(0xFF182D22),
                        side: BorderSide(color: Colors.white.withAlpha(25)),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF8FA497),
                        ),
                        // Price chip ka onDeleted
                        onDeleted: () {
                          _dataService.updateFilters(
                            distance: _dataService.maxDistanceKm,
                            market: _dataService.selectedMarket,
                            category: _dataService.selectedCategory,
                            price: null,
                            priceMode: 'Any price',
                            productName: _dataService.productNameFilter,
                            farmerName:
                                _dataService.farmerNameFilter,
                            location:
                                _dataService.locationFilter,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Results Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${products.length} fresh products',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8FA497),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Product Listing Grid or List
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 60,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No products match your search',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try adjusting filters or searching for another keyword.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _isGridView
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width > 900
                              ? 4
                              : (width > 560 ? 3 : 2);
                          final childAspectRatio = width < 360
                              ? 0.65
                              : (width > 600 ? 0.78 : 0.72);
                          return GridView.builder(
                            itemCount: products.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemBuilder: (context, index) {
                              final item = products[index];
                              return _buildGridCard(item);
                            },
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final item = products[index];
                          return _buildListCard(item);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(dynamic product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF15281E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFF0F1E16),
                          child: const Center(
                            child: Icon(
                              Icons.eco_outlined,
                              color: Color(0xFFA1C68A),
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withAlpha(90),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          product.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border_rounded,
                          color: product.isFavorite
                              ? const Color(0xFFE76F51)
                              : Colors.white70,
                          size: 16,
                        ),
                        onPressed: () =>
                            _dataService.toggleFavorite(product.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 2),
                  Text(
                    product.farmerName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF8FA497),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs.${product.price.toInt()}/${product.unit}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFA1C68A),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _dataService.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.title} added to cart'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF1E3A2B),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF88AB75),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF0D1A13),
                            size: 16,
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
  }

  Widget _buildListCard(dynamic product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF15281E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                product.imageUrl,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 68,
                  height: 68,
                  color: const Color(0xFF0F1E16),
                  child: const Center(
                    child: Icon(
                      Icons.eco_outlined,
                      color: Color(0xFFA1C68A),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF0F5F1),
                    ),
                  ),
                  Text(
                    'by ${product.farmerName} • ${product.farmerFarm}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8FA497),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Text(
                        'Rs.${product.price.toInt()} / ${product.unit}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFA1C68A),
                        ),
                      ),
                      Text(
                        'Stock: ${product.stock}',
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
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              icon: Icon(
                product.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border_rounded,
                color: product.isFavorite
                    ? const Color(0xFFE76F51)
                    : const Color(0xFF8FA497),
              ),
              onPressed: () => _dataService.toggleFavorite(product.id),
            ),
            IconButton(
              tooltip: 'Add to cart',
              onPressed: () {
                _dataService.addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.title} added to cart'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFF1E3A2B),
                  ),
                );
              },
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF88AB75),
                foregroundColor: const Color(0xFF0D1A13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
