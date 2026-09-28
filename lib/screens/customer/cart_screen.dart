import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const CartScreen({super.key, this.onBack});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _promoController = TextEditingController();
  bool _discountApplied = false;

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChange);
    _promoController.dispose();
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  void _applyPromo() {
    if (_promoController.text.trim().toUpperCase() == 'HARVEST20') {
      setState(() => _discountApplied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo HARVEST20 applied. 20% discount granted! ðŸŒ¿'),
          backgroundColor: Color(0xFF1E3827),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code. Try "HARVEST20"'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _dataService.cart;
    final subtotal = _dataService.cartSubtotal;
    final discount = _discountApplied ? subtotal * 0.20 : 0.0;
    final deliveryFee = _dataService.deliveryFee;
    final total = (subtotal - discount) + deliveryFee;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          'My Cart',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F5F1),
          ),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () => _dataService.clearCart(),
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  color: const Color(0xFFE76F51),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        bottom: true, // Add bottom safe area
        child: cartItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF15281E),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 40,
                          color: Color(0xFF88AB75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your Cart is Empty',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse our botanical farm fresh harvest\nand add items to your cart.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF8EAA95),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Cart Items List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final product = item.product;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15281E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withAlpha(20)),
                          ),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  product.imageUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 72,
                                    height: 72,
                                    color: const Color(0xFF1D3526),
                                    child: const Center(
                                      child: Icon(Icons.eco_rounded, color: Color(0xFF88AB75)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFF0F5F1),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'by ${product.farmerName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF8EAA95),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rs. ${item.totalPrice.toInt()}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF0F5F1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity Controls & Delete (Matching Screen 4)
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E1C14),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white.withAlpha(20)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.remove, size: 14, color: Color(0xFFF0F5F1)),
                                      onPressed: () {
                                        _dataService.updateCartQuantity(product.id, -1);
                                      },
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFF0F5F1),
                                      ),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.add, size: 14, color: Color(0xFFF0F5F1)),
                                      onPressed: () {
                                        _dataService.updateCartQuantity(product.id, 1);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF8EAA95)),
                                onPressed: () {
                                  _dataService.removeFromCart(item.product.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Summary Card (Matching Screen 4)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13241A),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border(
                        top: BorderSide(color: Colors.white.withAlpha(25), width: 1.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Promo Input Field
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1E15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withAlpha(20)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer_outlined, size: 18, color: Color(0xFF8EAA95)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _promoController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: GoogleFonts.inter(color: const Color(0xFFF0F5F1), fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Promo Code (HARVEST20)',
                                    hintStyle: GoogleFonts.inter(color: const Color(0xFF6B8A74), fontSize: 13),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 34,
                                child: ElevatedButton(
                                  onPressed: _applyPromo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF88AB75),
                                    foregroundColor: const Color(0xFF0D1A13),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Apply',
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtotal Row
                        _buildSummaryRow('Subtotal', 'Rs. ${subtotal.toInt()}'),
                        if (_discountApplied)
                          _buildSummaryRow(
                            'Promo Discount (20%)',
                            '- Rs. ${discount.toInt()}',
                            isDiscount: true,
                          ),
                        _buildSummaryRow('Shipping', 'Rs. ${deliveryFee.toInt()}'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFF233B2B), height: 1),
                        ),
                        _buildSummaryRow(
                          'Total',
                          'Rs. ${total.toInt()}',
                          isTotal: true,
                        ),
                        const SizedBox(height: 16),

                        // Proceed to Checkout Pill Button (Matching Screen 4)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(finalTotal: total),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF88AB75),
                              foregroundColor: const Color(0xFF0D1A13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Proceed to Checkout',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Secure Checkout note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF8EAA95)),
                            const SizedBox(width: 6),
                            Text(
                              'Secure Checkout',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF8EAA95),
                                fontWeight: FontWeight.w500,
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

  Widget _buildSummaryRow(
    String label,
    String amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isTotal ? const Color(0xFFF0F5F1) : const Color(0xFF8EAA95),
            ),
          ),
          Text(
            amount,
            style: isTotal
                ? GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF88AB75),
                  )
                : GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDiscount ? const Color(0xFF88AB75) : const Color(0xFFF0F5F1),
                  ),
          ),
        ],
      ),
    );
  }
}
