import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/data_service.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChange);
    _dataService.loadWishlistForCurrentUser();
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
    final wishlist = _dataService.wishlistProducts;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFFF0F5F1)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'My Wishlist',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F5F1),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF88AB75),
          backgroundColor: const Color(0xFF15281E),
          onRefresh: () async {
            await _dataService.loadCatalog();
            await _dataService.loadWishlistForCurrentUser();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
            child: wishlist.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15281E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withAlpha(20)),
                                ),
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  size: 38,
                                  color: Color(0xFFE76F51),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Your Wishlist is Empty',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF0F5F1),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Save your favorite farm produce by tapping the heart icon on any product.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF8EAA95),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final childAspectRatio = width < 360 ? 0.64 : 0.68;

                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: wishlist.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemBuilder: (context, index) {
                          final item = wishlist[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsScreen(product: item),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF15281E),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.white.withAlpha(20)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Flexible Image
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(22),
                                            ),
                                            child: Image.network(
                                              item.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => Container(
                                                color: const Color(0xFF0F1E16),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.eco_rounded,
                                                    color: Color(0xFF88AB75),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
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
                                              icon: const Icon(
                                                Icons.favorite,
                                                color: Color(0xFFE76F51),
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _dataService.toggleFavorite(item.id);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Card Info
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFF0F5F1),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'by ${item.farmerName}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF8EAA95),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // Stock status indicator
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: item.stockKg <= 0
                                                ? const Color(0xFFE76F51).withAlpha(30)
                                                : item.stockKg < 10
                                                    ? Colors.orange.withAlpha(30)
                                                    : const Color(0xFF88AB75).withAlpha(30),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                item.stockKg <= 0
                                                    ? Icons.remove_circle_outline
                                                    : item.stockKg < 10
                                                        ? Icons.warning_rounded
                                                        : Icons.check_circle_outline,
                                                size: 10,
                                                color: item.stockKg <= 0
                                                    ? const Color(0xFFE76F51)
                                                    : item.stockKg < 10
                                                        ? Colors.orange
                                                        : const Color(0xFF88AB75),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                item.stockKg <= 0
                                                    ? 'Out of Stock'
                                                    : item.stockKg < 10
                                                        ? 'Low Stock'
                                                        : 'In Stock',
                                                style: GoogleFonts.inter(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: item.stockKg <= 0
                                                      ? const Color(0xFFE76F51)
                                                      : item.stockKg < 10
                                                          ? Colors.orange
                                                          : const Color(0xFF88AB75),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Rs.${item.price.toInt()}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFA1C68A),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                _dataService.addToCart(item);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${item.title} added to cart!'),
                                                    duration: const Duration(seconds: 1),
                                                    backgroundColor: const Color(0xFF1E3827),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF88AB75),
                                                  borderRadius: BorderRadius.circular(9),
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
          ),
        ),
      ),
    );
  }
}
