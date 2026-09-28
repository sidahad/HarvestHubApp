import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import 'customer_main_layout.dart';
import 'order_details_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final List<OrderModel> orders;
  const OrderSuccessScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final totalAmount = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final firstOrder = orders.first;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFFF0F5F1)),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CustomerMainLayout()),
            (route) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glowing Emerald Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF15281E),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF88AB75).withAlpha(80), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF88AB75).withAlpha(40),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 58,
                      color: Color(0xFF88AB75),
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                Text(
                  'Order Placed Successfully',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF0F5F1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your botanical produce order has been delivered to the farm.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF8EAA95),
                  ),
                ),
                const SizedBox(height: 26),

                // Order Details Card (Frosted Glass)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15281E),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Farmer Orders', '${orders.length}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Color(0xFF223A2A), height: 1),
                      ),
                      _buildRow('Total Amount', 'Rs. ${totalAmount.toInt()}', isTotal: true),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Color(0xFF223A2A), height: 1),
                      ),
                      ...orders.map(
                        (order) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _buildRow(
                            order.farmerName,
                            '#${order.id} • Rs. ${order.totalAmount.toInt()}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Track Order Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(order: firstOrder),
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
                    icon: const Icon(Icons.local_shipping_outlined, size: 20),
                    label: Text(
                      'Track Order Status',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const CustomerMainLayout(),
                        ),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF15281E),
                      side: BorderSide(color: Colors.white.withAlpha(20)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF0F5F1),
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

  Widget _buildRow(String title, String val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8EAA95)),
        ),
        Expanded(
          child: Text(
            val,
            textAlign: TextAlign.right,
            style: isTotal
                ? GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF88AB75),
                  )
                : GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF0F5F1),
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
