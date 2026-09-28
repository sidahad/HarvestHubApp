import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/data_service.dart';
import 'product_list_screen.dart';

class CategoriesScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const CategoriesScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          'Produce Categories',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F5F1),
          ),
        ),
      ),
      body: SafeArea(
        bottom: true, // Add bottom safe area
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore Harvest Categories',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a category to browse botanical farm selections',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF8EAA95),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: GridView.builder(
                  itemCount: dataService.categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final cat = dataService.categories[index];
                    return GestureDetector(
                      onTap: () {
                        dataService.setCategory(cat.name);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProductListScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15281E),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withAlpha(20)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA1C68A).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                cat.iconData,
                                size: 30,
                                color: const Color(0xFFA1C68A),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              cat.name,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF0F5F1),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${cat.itemCount}+ Products',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF88AB75),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
