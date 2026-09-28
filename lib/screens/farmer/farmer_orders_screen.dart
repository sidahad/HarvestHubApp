import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  final List<String> _statuses = [
    'Processing',
    'Pending',
    'Confirmed',
    'Ready for Pickup',
    'In Transit',
    'Delivered',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      await DataService().loadOrdersForStaff();
      final currentUser = AuthService().currentUser;
      final farmerOrders = DataService().orders
          .where((order) => order.farmerId == currentUser?.uid)
          .toList();
      debugPrint('Loaded ${DataService().orders.length} total orders');
      debugPrint('Farmer ID: ${currentUser?.uid}');
      debugPrint('Farmer-specific orders: ${farmerOrders.length}');
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    try {
      await DataService().updateOrderStatus(order.id, newStatus);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order #${order.id.substring(order.id.length - 4)} updated to $newStatus',
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update order: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = DataService();
    final currentUser = AuthService().currentUser;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back button
          title: Text(
            'Customer Orders',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }
    
    final allOrders = data.orders
        .where((order) => order.farmerId == currentUser?.uid)
        .toList();
    final activeOrders = allOrders
        .where((o) => o.status != 'Delivered' && o.status != 'Completed' && o.status != 'Cancelled')
        .toList();
    final completedOrders = allOrders
        .where((o) => o.status == 'Delivered' || o.status == 'Completed')
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          'Customer Orders',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(text: 'Active (${activeOrders.length})'),
            Tab(text: 'Completed (${completedOrders.length})'),
            Tab(text: 'All (${allOrders.length})'),
          ],
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOrderList(activeOrders, isRefreshable: true),
            _buildOrderList(completedOrders, isRefreshable: true),
            _buildOrderList(allOrders, isRefreshable: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, {bool isRefreshable = false}) {
    final content = orders.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 60,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No orders in this category',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Orders from customers will appear here',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _buildOrderCard(orders[index]),
          );

    if (isRefreshable) {
      return RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadOrders,
        child: content,
      );
    }
    return content;
  }

  Widget _buildOrderCard(OrderModel order) {
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(order.orderDate);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8FA497),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getStatusColor(order.status).withAlpha(100),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    order.status,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(order.status),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          
          Divider(height: 24, color: Colors.white.withAlpha(15)),

          // Customer Details Section
          Text(
            'Customer Details',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF0F5F1),
            ),
          ),
          const SizedBox(height: 10),
          _buildCustomerRow(
            Icons.person_outline,
            order.customerName.isEmpty
                ? 'Customer name unavailable'
                : order.customerName,
          ),
          const SizedBox(height: 6),
          _buildCustomerRow(
            Icons.phone_outlined,
            order.customerPhone.isEmpty
                ? 'Phone number unavailable'
                : order.customerPhone,
          ),
          const SizedBox(height: 6),
          _buildCustomerRow(
            Icons.location_on_outlined,
            order.deliveryAddress,
          ),
          
          Divider(height: 24, color: Colors.white.withAlpha(15)),

          // Items Section
          Text(
            'Order Items',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF0F5F1),
            ),
          ),
          const SizedBox(height: 8),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.name} × ${item.quantity}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFD0DDD4),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rs. ${(item.product.price * item.quantity).toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFFA1C68A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 24, color: Colors.white.withAlpha(15)),
          
          // Pickup Slot & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup Slot',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF8FA497),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.pickupSlot,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFA1C68A),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF8FA497),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFA1C68A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.white.withAlpha(15)),
          const SizedBox(height: 16),

          // Status Update Dropdown
          Row(
            children: [
              Text(
                'Update Status:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8FA497),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1A13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statuses.contains(order.status)
                          ? order.status
                          : (_statuses.contains('Completed') ? 'Completed' : _statuses.first),
                      dropdownColor: const Color(0xFF182D22),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFA1C68A),
                      ),
                      items: _statuses
                          .toSet()
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFF0F5F1),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) _updateStatus(order, val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFA1C68A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8FA497)),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      case 'confirmed':
        return Colors.blue;
      case 'ready for pickup':
        return AppTheme.accent;
      case 'in transit':
        return Colors.purple;
      case 'delivered':
        return AppTheme.primary;
      case 'cancelled':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }
}
