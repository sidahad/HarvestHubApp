import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import 'customer_main_layout.dart';
import 'review_screen.dart';

Future<void> _callFarmer(BuildContext context, String phoneNumber) async {
  final uri = Uri(scheme: 'tel', path: phoneNumber);
  final canLaunch = await canLaunchUrl(uri);
  if (canLaunch) {
    await launchUrl(uri);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open dialer for $phoneNumber',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1F3A2B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back to Home',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Color(0xFFF0F5F1),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CustomerMainLayout()),
                (route) => false,
              );
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Order Tracking #${order.id.length > 8 ? order.id.substring(order.id.length - 8).toUpperCase() : order.id}',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F5F1),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(order),
                  const SizedBox(height: 22),
                  _sectionTitle('Order Progress'),
                  const SizedBox(height: 10),
                  _OrderTimeline(status: order.status),
                  const SizedBox(height: 22),
                  _sectionTitle('Farmer Contact'),
                  const SizedBox(height: 10),
                  _buildContactCard(context),
                  const SizedBox(height: 22),
                  _sectionTitle('Items Ordered'),
                  const SizedBox(height: 10),
                  _buildItemsCard(),
                  const SizedBox(height: 20),
                  _buildMetaCard(),
                  if (order.status.toLowerCase() == 'delivered' ||
                      order.status.toLowerCase() == 'completed') ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF88AB75),
                          foregroundColor: const Color(0xFF0D1A13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReviewScreen(
                                orderId: order.id,
                                items: order.items,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_rounded, size: 22),
                        label: Text(
                          'Rate & Review Products',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFF0F5F1),
      ),
    );
  }

  Widget _buildHeader(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(order.status).withAlpha(100),
                    ),
                  ),
                  child: Text(
                    order.status,
                    style: GoogleFonts.poppins(
                      color: _getStatusColor(order.status),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3A2B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF88AB75).withAlpha(60),
                    ),
                  ),
                  child: Text(
                    'Order #${order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF0F5F1),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'From: ${order.farmerName}',
            style: GoogleFonts.inter(
              color: const Color(0xFF8EAA95),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return const Color(0xFFFFB74D);
      case 'pending':
        return const Color(0xFFFFA726);
      case 'confirmed':
        return const Color(0xFF42A5F5);
      case 'ready for pickup':
      case 'in transit':
        return const Color(0xFFAB47BC);
      case 'delivered':
      case 'completed':
        return const Color(0xFF66BB6A);
      case 'cancelled':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF88AB75);
    }
  }

  Color _getStatusBackgroundColor(String status) {
    return _getStatusColor(status).withAlpha(30);
  }

  Widget _buildContactCard(BuildContext context) {
    final hasPhone = order.farmerPhone.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1F3A2B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Color(0xFF88AB75),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.farmerName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF0F5F1),
                    fontSize: 14,
                  ),
                ),
                Text(
                  hasPhone ? order.farmerPhone : 'Phone number unavailable',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8EAA95),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: hasPhone ? 'Call farmer' : 'Phone number unavailable',
            onPressed: hasPhone
                ? () => _callFarmer(context, order.farmerPhone)
                : null,
            icon: Icon(
              Icons.phone_rounded,
              color: hasPhone
                  ? const Color(0xFF88AB75)
                  : const Color(0xFF8EAA95).withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        children: order.items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF0F5F1),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${item.quantity} x Rs. ${item.product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8EAA95),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF88AB75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMetaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        children: [
          _metaRow('Customer', order.customerName),
          _metaRow('Delivery Address', order.deliveryAddress),
          _metaRow('Pickup Slot', order.pickupSlot),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: Color(0xFF223A2B), height: 1),
          ),
          _metaRow(
            'Total',
            'Rs. ${order.totalAmount.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF8EAA95),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: isTotal
                  ? GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF88AB75),
                    )
                  : GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF0F5F1),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated horizontal order-progress timeline:
/// Placed → Confirmed → Ready → Completed
/// Falls back to a "Cancelled" banner when the order was cancelled.
class _OrderTimeline extends StatefulWidget {
  final String status;

  const _OrderTimeline({required this.status});

  @override
  State<_OrderTimeline> createState() => _OrderTimelineState();
}

class _OrderTimelineState extends State<_OrderTimeline>
    with SingleTickerProviderStateMixin {
  static const List<String> _steps = [
    'Placed',
    'Confirmed',
    'Ready',
    'Completed',
  ];

  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _currentStep {
    switch (widget.status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
      case 'processing':
        return 1;
      case 'ready for pickup':
      case 'in transit':
        return 2;
      case 'delivered':
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  bool get _isCancelled => widget.status.toLowerCase() == 'cancelled';

  @override
  Widget build(BuildContext context) {
    if (_isCancelled) return _buildCancelledBanner();

    final currentStep = _currentStep;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final animatedStep = currentStep * _progress.value;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_steps.length * 2 - 1, (i) {
                  if (i.isEven) {
                    final stepIndex = i ~/ 2;
                    final isDone = stepIndex <= animatedStep + 0.001;
                    final isCurrent = stepIndex == currentStep;
                    return _buildDot(isDone, isCurrent);
                  } else {
                    final segmentIndex = i ~/ 2;
                    final segmentProgress = (animatedStep - segmentIndex).clamp(
                      0.0,
                      1.0,
                    );
                    return Expanded(child: _buildConnector(segmentProgress));
                  }
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(_steps.length, (index) {
                  final isDone = index <= animatedStep + 0.001;
                  return Expanded(
                    child: Text(
                      _steps[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                        color: isDone
                            ? const Color(0xFFF0F5F1)
                            : const Color(0xFF8EAA95),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDot(bool isDone, bool isCurrent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: isCurrent ? 26 : 20,
      height: isCurrent ? 26 : 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? const Color(0xFF88AB75) : const Color(0xFF233B2C),
        border: isCurrent
            ? Border.all(
                color: const Color(0xFF88AB75).withAlpha(130),
                width: 3,
              )
            : null,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFF88AB75).withAlpha(90),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: isDone
          ? Icon(
              isCurrent ? Icons.radio_button_checked : Icons.check_rounded,
              size: isCurrent ? 14 : 13,
              color: const Color(0xFF0D1A13),
            )
          : null,
    );
  }

  Widget _buildConnector(double progress) {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF233B2C),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF88AB75)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350).withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF5350).withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_rounded, color: Color(0xFFEF5350), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This order was cancelled',
              style: GoogleFonts.poppins(
                color: const Color(0xFFEF5350),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
