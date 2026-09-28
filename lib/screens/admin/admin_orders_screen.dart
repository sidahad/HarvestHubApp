import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final List<String> _allStatuses = [
    'All',
    'Processing',
    'Pending',
    'Confirmed',
    'Ready for Pickup',
    'In Transit',
    'Delivered',
    'Cancelled',
  ];
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Firestore stream: all orders, newest first ─────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() =>
      FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots();

  // ── Status color helper ───────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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
      case 'pending':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  // ── Update order status ───────────────────────────────────────────────
  Future<void> _updateStatus(
      String orderId, String currentStatus, String farmerName) async {
    final statuses = [
      'Processing',
      'Pending',
      'Confirmed',
      'Ready for Pickup',
      'In Transit',
      'Delivered',
      'Cancelled',
    ];
    String selected = currentStatus;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Order Status',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Order from $farmerName',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses.map((s) {
                  final isSelected = selected == s;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selected = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _statusColor(s).withValues(alpha: 0.15)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _statusColor(s)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? _statusColor(s)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (selected == currentStatus) return;
                    try {
                      await DataService()
                          .updateOrderStatus(orderId, selected);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Order updated to "$selected"'),
                        backgroundColor: AppTheme.primary,
                      ));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Update failed: $e'),
                        backgroundColor: AppTheme.error,
                      ));
                    }
                  },
                  child: Text('Confirm Update',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter logic ──────────────────────────────────────────────────────
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilters(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.where((doc) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      final customer =
          (data['customerName'] as String? ?? '').toLowerCase();
      final farmer =
          (data['farmerName'] as String? ?? '').toLowerCase();
      final id = doc.id.toLowerCase();

      final matchesStatus =
          _selectedStatus == 'All' || status == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          customer.contains(_searchQuery.toLowerCase()) ||
          farmer.contains(_searchQuery.toLowerCase()) ||
          id.contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Orders Management',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        bottom: true,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: GoogleFonts.poppins(color: AppTheme.error)),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          final filtered = _applyFilters(allDocs);

          // Tabs: All / Active / Completed
          final activeDocs = filtered
              .where((d) =>
                  d.data()['status'] != 'Delivered' &&
                  d.data()['status'] != 'Cancelled')
              .toList();
          final completedDocs = filtered
              .where((d) =>
                  d.data()['status'] == 'Delivered' ||
                  d.data()['status'] == 'Cancelled')
              .toList();

          // Summary stats
          final totalRevenue = allDocs.fold<double>(
              0,
              (total, d) =>
                  total +
                  ((d.data()['totalAmount'] as num?)?.toDouble() ?? 0));

          return Column(
            children: [
              // ── Summary Banner ─────────────────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _summaryTile('Total Orders', '${allDocs.length}'),
                    _divider(),
                    _summaryTile('Active', '${activeDocs.length}'),
                    _divider(),
                    _summaryTile('Revenue',
                        'Rs.${totalRevenue.toStringAsFixed(0)}'),
                  ],
                ),
              ),

              // ── Search + Status Filter ────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      onChanged: (v) =>
                          setState(() => _searchQuery = v),
                      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by customer, farmer, order ID...',
                        hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                        prefixIcon:
                            const Icon(Icons.search, color: AppTheme.primary),
                        filled: true,
                        fillColor: AppTheme.cardColor,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status filter chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allStatuses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final s = _allStatuses[i];
                          final isSel = _selectedStatus == s;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedStatus = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppTheme.primary
                                    : AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel
                                      ? AppTheme.primary
                                      : AppTheme.border,
                                ),
                              ),
                              child: Text(
                                s,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSel
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tabs ──────────────────────────────────────────────
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                labelStyle:
                    GoogleFonts.poppins(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'All (${filtered.length})'),
                  Tab(text: 'Active (${activeDocs.length})'),
                  Tab(text: 'Done (${completedDocs.length})'),
                ],
              ),

              // ── Order Lists ────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(filtered),
                    _buildOrderList(activeDocs),
                    _buildOrderList(completedDocs),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildOrderList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 60, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text('No orders found.',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();
        final status = data['status'] as String? ?? 'Processing';
        final customerName =
            data['customerName'] as String? ?? 'Unknown Customer';
        final customerPhone =
            data['customerPhone'] as String? ?? '';
        final farmerName =
            data['farmerName'] as String? ?? 'Unknown Farmer';
        final total =
            (data['totalAmount'] as num?)?.toDouble() ?? 0;
        final address = data['deliveryAddress'] as String? ?? '';
        final pickupSlot = data['pickupSlot'] as String? ?? '';
        final createdAt = data['createdAt'];
        String dateStr = '';
        if (createdAt is Timestamp) {
          dateStr = DateFormat('dd MMM yyyy, hh:mm a')
              .format(createdAt.toDate());
        }

        final items = data['items'];
        final itemCount = items is List ? items.length : 0;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _statusColor(status).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${doc.id.length > 10 ? doc.id.substring(doc.id.length - 10).toUpperCase() : doc.id}',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(dateStr,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer & Farmer
                    Row(
                      children: [
                        Expanded(
                          child: _infoTile(
                            Icons.person_outline,
                            'Customer',
                            customerName,
                            customerPhone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoTile(
                            Icons.agriculture_outlined,
                            'Farmer',
                            farmerName,
                            '',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Address
                    if (address.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ),
                        ],
                      ),

                    // Pickup slot
                    if (pickupSlot.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(pickupSlot,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 20),

                    // Footer: items + total + action
                    Row(
                      children: [
                        const Icon(Icons.shopping_basket_outlined,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$itemCount item${itemCount != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          'Rs. ${total.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => _updateStatus(
                              doc.id, status, farmerName),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            side: const BorderSide(
                                color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Update',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(
      IconData icon, String label, String name, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (sub.isNotEmpty)
          Text(sub,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _summaryTile(String label, String val) => Expanded(
        child: Column(
          children: [
            Text(val,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
      );

  Widget _divider() => Container(
      width: 1, height: 30, color: Colors.white.withValues(alpha: 0.3));
}
