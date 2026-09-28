import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../models/pickup_slot_model.dart';
import 'pickup_schedule_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final double finalTotal;
  const CheckoutScreen({super.key, required this.finalTotal});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final DataService _dataService = DataService();
  final GamificationService _gs = GamificationService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  PickupSlotModel? _selectedPickupSlot;
  late String _pickupSlot;
  String _selectedPayment = 'Cash on Delivery / Pickup';
  bool _placingOrder = false;

  // ── Loyalty redemption state ─────────────────────────────────────────────
  CustomerGamificationProfile? _gamProfile;
  int _pointsToRedeem = 0;
  double get _redeemDiscount =>
      GamificationService.calculateDiscount(_pointsToRedeem);
  double get _finalTotal =>
      (widget.finalTotal - _redeemDiscount).clamp(0, widget.finalTotal);

  @override
  void initState() {
    super.initState();
    final profile = AuthService().userModel;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _addressController = TextEditingController(
      text: profile?.address.isNotEmpty == true ? profile!.address : '',
    );
    _pickupSlot = _dataService.selectedPickupSlot;
    _loadGamProfile();
  }

  Future<void> _loadGamProfile() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final p = await _gs.getCustomerProfile(uid);
    if (mounted) setState(() => _gamProfile = p);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onPlaceOrder() async {
    if (_placingOrder) return;
    if (!_formKey.currentState!.validate()) return;
    // Zero-stock validation: verify live stock in Firestore
    final outOfStockItems = <String>[];
    final insufficientItems = <String>[];

    for (final item in _dataService.cart) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('products')
            .doc(item.product.id)
            .get();
        if (doc.exists) {
          final latestStock = (doc.data()?['stock'] as num?)?.toInt() ?? 0;
          if (latestStock <= 0) {
            outOfStockItems.add(item.product.name);
          } else if (item.quantity > latestStock) {
            insufficientItems.add('${item.product.name} (only $latestStock available)');
          }
        }
      } catch (_) {}
    }

    if (outOfStockItems.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Out of stock: ${outOfStockItems.join(', ')}. Please remove from cart.'),
            backgroundColor: const Color(0xFFD9534F),
          ),
        );
      }
      return;
    }

    if (insufficientItems.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient stock: ${insufficientItems.join(', ')}'),
            backgroundColor: const Color(0xFFD9534F),
          ),
        );
      }
      return;
    }

    setState(() => _placingOrder = true);
    try {
      // Book pickup slot if selected
      if (_selectedPickupSlot != null) {
        await _dataService.bookPickupSlot(_selectedPickupSlot!.id);
      }
      
      final orders = await _dataService.createOrders(
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        slot: _pickupSlot,
        paymentMethod: _selectedPayment,
      );

      // ── Redeem loyalty points if applied ──────────────────────────────────
      if (_pointsToRedeem > 0) {
        final uid = AuthService().currentUser?.uid;
        if (uid != null && orders.isNotEmpty) {
          // Use the first sub-order ID as the redemption key
          await _gs.redeemPoints(
            customerId: uid,
            orderId: orders.first.id,
            pointsUsed: _pointsToRedeem,
          );
        }
      }
      // ── end redemption ───────────────────────────────────────────────────
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(orders: orders)),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFD9534F),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _dataService.cart;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFFF0F5F1)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Checkout',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF0F5F1),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Customer Details'),
                const SizedBox(height: 10),
                _buildRequiredField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildRequiredField(
                  controller: _phoneController,
                  label: 'Mobile Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 22),

                // Delivery Address Box
                _buildSectionHeader('Delivery Address'),
                const SizedBox(height: 10),
                _buildRequiredField(
                  controller: _addressController,
                  label: 'Complete Delivery Address',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 22),

                // Pickup Scheduling Box
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Pickup / Delivery Slot'),
                    TextButton(
                      onPressed: () async {
                        final slot = await Navigator.of(context).push<PickupSlotModel>(
                          MaterialPageRoute(
                            builder: (_) => const PickupScheduleScreen(),
                          ),
                        );
                        if (slot != null && mounted) {
                          setState(() {
                            _selectedPickupSlot = slot;
                            _pickupSlot = '${slot.farmerName} - ${slot.dateString}, ${slot.timeRange}';
                          });
                        }
                      },
                      child: Text(
                        'Change',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF88AB75),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15281E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F3A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFF88AB75),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scheduled Slot',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF0F5F1),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _pickupSlot,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF8EAA95),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Method
                _buildSectionHeader('Payment Method'),
                const SizedBox(height: 10),
                _buildPaymentOption('Cash on Delivery / Pickup', Icons.payments_outlined),
                _buildPaymentOption('Google Pay / Mobile Wallet', Icons.account_balance_wallet_outlined),
                _buildPaymentOption('Credit / Debit Card', Icons.credit_card_outlined),
                const SizedBox(height: 24),

                // Items Summary Box
                _buildSectionHeader('Order Items (${items.length})'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15281E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Column(
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.product.title}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFF0F5F1),
                                ),
                              ),
                            ),
                            Text(
                              'Rs. ${item.totalPrice.toInt()}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF88AB75),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),

                // ── Loyalty Points Redemption ─────────────────────────────
                if (_gamProfile != null &&
                    _gamProfile!.currentPoints >=
                        GamificationConfig.minRedeemPoints)
                  _LoyaltyRedeemWidget(
                    profile: _gamProfile!,
                    orderTotal: widget.finalTotal,
                    pointsToRedeem: _pointsToRedeem,
                    onChanged: (pts) =>
                        setState(() => _pointsToRedeem = pts),
                  ),
                if (_gamProfile != null &&
                    _gamProfile!.currentPoints >=
                        GamificationConfig.minRedeemPoints)
                  const SizedBox(height: 16),

                // Final Place Order Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _placingOrder ? null : _onPlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF88AB75),
                      foregroundColor: const Color(0xFF0D1A13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: _placingOrder
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF0D1A13),
                            ),
                          )
                        : Text(
                            _redeemDiscount > 0
                                ? 'Place Order • Rs. ${_finalTotal.toInt()}  (-${_redeemDiscount.toInt()})'
                                : 'Place Order • Rs. ${widget.finalTotal.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFF0F5F1),
      ),
    );
  }

  Widget _buildRequiredField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: const Color(0xFFF0F5F1), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: const Color(0xFF8EAA95), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF88AB75), size: 20),
        filled: true,
        fillColor: const Color(0xFF15281E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF88AB75), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '$label is required';
        if (label == 'Mobile Phone Number' && value.trim().length < 7) {
          return 'Enter a valid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSel = _selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1B3526) : const Color(0xFF15281E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? const Color(0xFF88AB75) : Colors.white.withAlpha(20),
            width: isSel ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSel ? const Color(0xFFA1C68A) : const Color(0xFF8EAA95),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSel ? const Color(0xFF88AB75) : Colors.white.withAlpha(40),
                  width: isSel ? 5.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LOYALTY REDEEM WIDGET — shown on checkout when user has enough points
// ═══════════════════════════════════════════════════════════════════════════

class _LoyaltyRedeemWidget extends StatelessWidget {
  final CustomerGamificationProfile profile;
  final double orderTotal;
  final int pointsToRedeem;
  final ValueChanged<int> onChanged;

  const _LoyaltyRedeemWidget({
    required this.profile,
    required this.orderTotal,
    required this.pointsToRedeem,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Max redeemable = min(currentPoints, points worth 20% of order)
    final maxByPercent =
        (orderTotal * GamificationConfig.maxRedeemPercent *
                GamificationConfig.pointsPerRupee)
            .floor();
    final maxRedeemable = maxByPercent.clamp(0, profile.currentPoints);
    final discount = GamificationService.calculateDiscount(pointsToRedeem);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3526),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: pointsToRedeem > 0
              ? const Color(0xFF52B788)
              : const Color(0xFF88AB75).withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Color(0xFF52B788), size: 18),
              const SizedBox(width: 8),
              Text(
                'Use Loyalty Points',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF0F5F1),
                ),
              ),
              const Spacer(),
              Text(
                '${profile.currentPoints} pts available',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF8FA497),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Slider for point selection
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF52B788),
              inactiveTrackColor: const Color(0xFF1F3A2A),
              thumbColor: const Color(0xFF88AB75),
              overlayColor: const Color(0xFF88AB75).withAlpha(30),
              valueIndicatorColor: const Color(0xFF52B788),
              valueIndicatorTextStyle: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            child: Slider(
              min: 0,
              max: maxRedeemable.toDouble(),
              divisions: maxRedeemable > 0 ? maxRedeemable ~/ 10 : 1,
              value: pointsToRedeem.clamp(0, maxRedeemable).toDouble(),
              label: '$pointsToRedeem pts',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 pts',
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF657A6E)),
              ),
              if (pointsToRedeem > 0)
                Text(
                  '$pointsToRedeem pts  →  Rs ${discount.toStringAsFixed(0)} OFF',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF52B788),
                  ),
                ),
              Text(
                '$maxRedeemable pts',
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF657A6E)),
              ),
            ],
          ),
          if (maxRedeemable < profile.currentPoints)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Max ${GamificationConfig.maxRedeemPercent * 100 ~/ 1}% discount per order',
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF8FA497)),
              ),
            ),
        ],
      ),
    );
  }
}
