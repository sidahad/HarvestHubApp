import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../models/order_model.dart';

class FarmerReportsScreen extends StatefulWidget {
  const FarmerReportsScreen({super.key});

  @override
  State<FarmerReportsScreen> createState() => _FarmerReportsScreenState();
}

class _FarmerReportsScreenState extends State<FarmerReportsScreen> {
  final DataService _dataService = DataService();
  String _selectedPeriod = 'This Week';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'This Week':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _startDate = lastMonth;
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case 'Custom':
        // Keep existing dates
        break;
    }
  }

  List<OrderModel> get _filteredOrders {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    return _dataService.orders.where((order) {
      // Filter by farmer ID
      if (order.farmerId != currentUser.uid) return false;
      
      // Filter by date range
      final orderDate = order.orderDate;
      return orderDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          orderDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, dynamic> get _analytics {
    final orders = _filteredOrders;
    final completedOrders = orders.where((o) => o.status == 'Delivered' || o.status == 'Completed').toList();
    
    double totalRevenue = 0;
    int totalItems = 0;
    Map<String, int> productSales = {};
    Map<String, double> productRevenue = {};

    for (var order in completedOrders) {
      totalRevenue += order.totalAmount;
      
      for (var item in order.items) {
        totalItems += item.quantity;
        
        // Track product sales
        final productName = item.product.name;
        productSales[productName] = (productSales[productName] ?? 0) + item.quantity;
        productRevenue[productName] = 
            (productRevenue[productName] ?? 0) + (item.product.price * item.quantity);
      }
    }

    // Sort products by revenue
    final sortedProducts = productRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalOrders': orders.length,
      'completedOrders': completedOrders.length,
      'pendingOrders': orders.where((o) => o.status == 'Pending').length,
      'cancelledOrders': orders.where((o) => o.status == 'Cancelled').length,
      'totalRevenue': totalRevenue,
      'totalItems': totalItems,
      'avgOrderValue': completedOrders.isNotEmpty ? totalRevenue / completedOrders.length : 0,
      'topProducts': sortedProducts.take(5).toList(),
      'productSales': productSales,
    };
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFA1C68A),
              onPrimary: Color(0xFF0D1A13),
              surface: Color(0xFF15281E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _analytics;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Sales & Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: _selectCustomDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFA1C68A),
          onRefresh: () async {
            await _dataService.loadOrdersForStaff();
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15281E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Today', 'This Week', 'This Month', 'Last Month', 'Custom']
                          .map((period) {
                        final isSel = _selectedPeriod == period;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPeriod = period;
                              if (period != 'Custom') {
                                _updateDateRange();
                              } else {
                                _selectCustomDateRange();
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF88AB75) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              period,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? const Color(0xFF0D1A13) : const Color(0xFF8FA497),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date Range Display
                if (_selectedPeriod == 'Custom')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF88AB75).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF88AB75).withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range, color: Color(0xFFA1C68A), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFA1C68A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Revenue Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A2B), Color(0xFF12241A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF88AB75).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.monetization_on_rounded,
                              color: Color(0xFFA1C68A),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Revenue',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF8FA497),
                                  ),
                                ),
                                Text(
                                  'Rs. ${analytics['totalRevenue'].toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF0F5F1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              'Completed',
                              '${analytics['completedOrders']}',
                              Icons.check_circle_outline,
                              const Color(0xFF88AB75),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniStat(
                              'Pending',
                              '${analytics['pendingOrders']}',
                              Icons.pending_outlined,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniStat(
                              'Avg Value',
                              'Rs. ${analytics['avgOrderValue'].toStringAsFixed(0)}',
                              Icons.trending_up_rounded,
                              const Color(0xFFA1C68A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Order Statistics
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Orders',
                        '${analytics['totalOrders']}',
                        Icons.receipt_long_rounded,
                        const Color(0xFF88AB75),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Items Sold',
                        '${analytics['totalItems']}',
                        Icons.inventory_2_outlined,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Top Selling Products
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Selling Products',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    if (analytics['topProducts'].isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF88AB75).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Top ${analytics['topProducts'].length}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFA1C68A),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (analytics['topProducts'].isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15281E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.show_chart_rounded,
                            size: 48,
                            color: Color(0xFF8FA497),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No sales data for this period',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8FA497),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...analytics['topProducts'].asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    final productName = product.key;
                    final revenue = product.value;
                    final quantity = analytics['productSales'][productName] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15281E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Row(
                        children: [
                          // Rank badge
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? Colors.amber.withAlpha(30)
                                  : index == 1
                                      ? Colors.grey.withAlpha(30)
                                      : Colors.brown.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '#${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: index == 0
                                      ? Colors.amber
                                      : index == 1
                                          ? Colors.grey.shade400
                                          : Colors.brown.shade300,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF0F5F1),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$quantity units sold',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF8FA497),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. ${revenue.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF88AB75),
                                ),
                              ),
                              Text(
                                'Revenue',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF8FA497),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF8FA497),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF0F5F1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8FA497),
            ),
          ),
        ],
      ),
    );
  }
}
