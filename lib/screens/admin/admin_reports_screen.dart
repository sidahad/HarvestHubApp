import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final DataService _dataService = DataService();
  String _selectedPeriod = 'All Time';
  DateTime _startDate = DateTime(2020);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _startDate = lastMonth;
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case 'This Year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case 'All Time':
        _startDate = DateTime(2020);
        _endDate = now;
        break;
    }
  }

  List<OrderModel> get _filteredOrders {
    return _dataService.orders.where((order) {
      final orderDate = order.orderDate;
      return orderDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          orderDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, dynamic> get _platformAnalytics {
    final orders = _filteredOrders;
    final completedOrders = orders.where((o) => o.status == 'Delivered').toList();
    
    double totalRevenue = 0;
    int totalItems = 0;
    Set<String> uniqueCustomers = {};
    Set<String> uniqueFarmers = {};
    Map<String, double> farmerRevenue = {};
    Map<String, int> farmerOrders = {};
    Map<String, double> customerSpending = {};
    
    for (var order in completedOrders) {
      totalRevenue += order.totalAmount;
      uniqueCustomers.add(order.customerId ?? order.customerName);
      uniqueFarmers.add(order.farmerId);
      
      // Farmer stats
      farmerRevenue[order.farmerName] = 
          (farmerRevenue[order.farmerName] ?? 0) + order.totalAmount;
      farmerOrders[order.farmerName] = 
          (farmerOrders[order.farmerName] ?? 0) + 1;
      
      // Customer stats
      final customerKey = order.customerName.isEmpty ? 'Unknown' : order.customerName;
      customerSpending[customerKey] = 
          (customerSpending[customerKey] ?? 0) + order.totalAmount;
      
      // Count items
      for (var item in order.items) {
        totalItems += item.quantity;
      }
    }
    
    // Sort farmers by revenue
    final topFarmers = farmerRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Sort customers by spending
    final topCustomers = customerSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': orders.length,
      'completedOrders': completedOrders.length,
      'pendingOrders': orders.where((o) => o.status == 'Pending').length,
      'cancelledOrders': orders.where((o) => o.status == 'Cancelled').length,
      'totalItems': totalItems,
      'uniqueCustomers': uniqueCustomers.length,
      'uniqueFarmers': uniqueFarmers.length,
      'avgOrderValue': completedOrders.isNotEmpty ? totalRevenue / completedOrders.length : 0,
      'topFarmers': topFarmers.take(5).toList(),
      'topCustomers': topCustomers.take(5).toList(),
      'farmerOrders': farmerOrders,
    };
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _platformAnalytics;
    final totalProducts = _dataService.products.length;
    final totalFarmers = _dataService.farmers.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Platform Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFA1C68A),
          onRefresh: () async {
            await _dataService.loadCatalog();
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
                  child: Row(
                    children: ['All Time', 'This Year', 'This Month', 'Last Month']
                        .map((period) {
                      final isSel = _selectedPeriod == period;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPeriod = period;
                              _updateDateRange();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF88AB75) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              period,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? const Color(0xFF0D1A13) : const Color(0xFF8FA497),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Platform Overview Card
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF88AB75).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.analytics_rounded,
                              color: Color(0xFFA1C68A),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Platform Revenue',
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
                      const SizedBox(height: 18),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMiniStat(
                              'Pending',
                              '${analytics['pendingOrders']}',
                              Icons.pending_outlined,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMiniStat(
                              'Cancelled',
                              '${analytics['cancelledOrders']}',
                              Icons.cancel_outlined,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Platform Statistics Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _buildStatCard(
                      'Total Farmers',
                      '$totalFarmers',
                      Icons.agriculture_rounded,
                      const Color(0xFF88AB75),
                    ),
                    _buildStatCard(
                      'Active Customers',
                      '${analytics['uniqueCustomers']}',
                      Icons.people_rounded,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Total Products',
                      '$totalProducts',
                      Icons.inventory_2_rounded,
                      Colors.teal,
                    ),
                    _buildStatCard(
                      'Items Sold',
                      '${analytics['totalItems']}',
                      Icons.shopping_cart_rounded,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Top Performing Farmers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Performing Farmers',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    if (analytics['topFarmers'].isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF88AB75).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Top ${analytics['topFarmers'].length}',
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

                if (analytics['topFarmers'].isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15281E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Center(
                      child: Text(
                        'No farmer data for this period',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8FA497),
                        ),
                      ),
                    ),
                  )
                else
                  ...analytics['topFarmers'].asMap().entries.map((entry) {
                    final index = entry.key;
                    final farmer = entry.value;
                    final farmerName = farmer.key;
                    final revenue = farmer.value;
                    final orderCount = analytics['farmerOrders'][farmerName] ?? 0;

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
                                  farmerName,
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
                                  '$orderCount orders completed',
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
                const SizedBox(height: 24),

                // Top Customers
                Text(
                  'Top Customers',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF0F5F1),
                  ),
                ),
                const SizedBox(height: 12),

                if (analytics['topCustomers'].isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15281E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Center(
                      child: Text(
                        'No customer data for this period',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8FA497),
                        ),
                      ),
                    ),
                  )
                else
                  ...analytics['topCustomers'].take(3).map((customer) {
                    final customerName = customer.key;
                    final spending = customer.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15281E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue.withAlpha(30),
                            child: Text(
                              customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              customerName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFF0F5F1),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Rs. ${spending.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF88AB75),
                            ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF0F5F1),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF8FA497),
            ),
          ),
        ],
      ),
    );
  }
}
