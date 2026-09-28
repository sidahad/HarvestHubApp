import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import 'add_edit_product_screen.dart';

class FarmerProductsScreen extends StatefulWidget {
  const FarmerProductsScreen({super.key});

  @override
  State<FarmerProductsScreen> createState() => _FarmerProductsScreenState();
}

class _FarmerProductsScreenState extends State<FarmerProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final data = DataService();
    final currentUser = AuthService().currentUser;

    // Filter: Show only products added by THIS farmer
    final products = data.products
        .where((p) => p.farmerId == currentUser?.uid)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          'My Farm Produce',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: products.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No produce listed yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start adding your fresh harvest to the market',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = products[index];
                  final isOutOfStock = p.stockKg <= 0;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15281E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            p.imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 70,
                                  height: 70,
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFF0F5F1),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (p.isOrganic)
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF88AB75,
                                          ).withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Organic',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: const Color(0xFFA1C68A),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${p.price.toStringAsFixed(0)} / ${p.unit} • ${p.category}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF8FA497),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOutOfStock
                                            ? const Color(
                                                0xFFE76F51,
                                              ).withAlpha(30)
                                            : const Color(
                                                0xFF88AB75,
                                              ).withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isOutOfStock
                                            ? '0 ${p.unit} (Out of Stock)'
                                            : '${p.stockKg} ${p.unit} available',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isOutOfStock
                                              ? const Color(0xFFE76F51)
                                              : const Color(0xFFA1C68A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    flex: 1,
                                    child: Text(
                                      '${p.freshnessScore}% Fresh',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFFA1C68A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: AppTheme.primary,
                              ),
                              onPressed: () async {
                                // Double-check: Only allow editing own products
                                if (p.farmerId != currentUser?.uid) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You can only edit your own products',
                                      ),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                  return;
                                }
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddEditProductScreen(product: p),
                                  ),
                                );
                                setState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: AppTheme.error,
                              ),
                              onPressed: () {
                                // Double-check: Only allow deleting own products
                                if (p.farmerId != currentUser?.uid) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You can only delete your own products',
                                      ),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                  return;
                                }
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Produce?'),
                                    content: Text(
                                      'Are you sure you want to remove ${p.name} from the marketplace?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.error,
                                        ),
                                        onPressed: () {
                                          data.deleteProduct(p.id);
                                          Navigator.pop(ctx);
                                          setState(() {});
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
          );
          setState(() {});
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Produce',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
