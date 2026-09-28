import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/data_service.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MyOrdersScreen({super.key, this.onBack});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dataService.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _dataService.orders
        .where(
          (o) =>
              o.status != 'Delivered' &&
              o.status != 'Completed' &&
              o.status != 'Cancelled',
        )
        .toList();
    final pastOrders = _dataService.orders
        .where(
          (o) =>
              o.status == 'Delivered' ||
              o.status == 'Completed' ||
              o.status == 'Cancelled',
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        leading: (Navigator.of(context).canPop() || widget.onBack != null)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFF0F5F1),
                  size: 18,
                ),
                tooltip: 'Back',
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              )
            : null,
        centerTitle: true,
        title: Text(
          'My Orders',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F5F1),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF88AB75),
          indicatorWeight: 3,
          labelColor: const Color(0xFFF0F5F1),
          unselectedLabelColor: const Color(0xFF8EAA95),
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: 'Active (${activeOrders.length})'),
            Tab(text: 'Completed (${pastOrders.length})'),
          ],
        ),
      ),
      body: SafeArea(
        bottom: true, // Add bottom safe area
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOrderList(
              activeOrders,
              emptyMsg: 'No active orders right now.',
            ),
            _buildOrderList(pastOrders, emptyMsg: 'No completed orders yet.'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, {required String emptyMsg}) {
    if (orders.isEmpty) {
      return Center(
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
                Icons.receipt_long_outlined,
                size: 38,
                color: Color(0xFF88AB75),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF0F5F1),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final dateStr =
                '${order.orderDate.day.toString().padLeft(2, '0')} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][order.orderDate.month - 1]} ${order.orderDate.year}';

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(order: order),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF15281E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Order #${order.id}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF0F5F1),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBg(order.status),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _statusColor(order.status).withAlpha(80),
                            ),
                          ),
                          child: Text(
                            order.status,
                            style: GoogleFonts.inter(
                              color: _statusColor(order.status),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Placed on $dateStr • by ${order.farmerName}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8EAA95),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Color(0xFF223A2B), height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${order.items.length} item(s)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF8EAA95),
                          ),
                        ),
                        Text(
                          'Rs. ${order.totalAmount.toInt()}',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF88AB75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF1E3827);
      case 'cancelled':
        return const Color(0xFF381E1E);
      default:
        return const Color(0xFF2E2C1A);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFFA1C68A);
      case 'cancelled':
        return const Color(0xFFE76F51);
      default:
        return const Color(0xFFE9C46A);
    }
  }
}
