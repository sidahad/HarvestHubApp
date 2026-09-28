import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../models/pickup_slot_model.dart';

class PickupScheduleScreen extends StatefulWidget {
  const PickupScheduleScreen({super.key});

  @override
  State<PickupScheduleScreen> createState() => _PickupScheduleScreenState();
}

class _PickupScheduleScreenState extends State<PickupScheduleScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;
  List<PickupSlotModel> _availableSlots = [];
  PickupSlotModel? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _loadPickupSlots();
  }

  Future<void> _loadPickupSlots() async {
    // Get unique farmer IDs from cart
    final farmerIds = _dataService.cart
        .map((item) => item.product.farmerId)
        .toSet()
        .toList();

    if (farmerIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Load all active pickup slots
    await _dataService.loadAllActivePickupSlots();
    
    // Filter slots for farmers in cart
    _availableSlots = _dataService.pickupSlots
        .where((slot) => farmerIds.contains(slot.farmerId))
        .toList();

    setState(() => _isLoading = false);
  }

  void _confirmSlot() {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a pickup slot',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final slotText = '${_selectedSlot!.farmerName} - ${_selectedSlot!.dateString}, ${_selectedSlot!.timeRange}';
    _dataService.selectedPickupSlot = slotText;
    Navigator.of(context).pop(_selectedSlot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Pickup Scheduling'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA1C68A)),
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _availableSlots.isEmpty
                      ? _buildNoSlotsMessage()
                      : _buildSlotsList(),
                ),
              ),
            ),
      bottomNavigationBar: _availableSlots.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _confirmSlot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF88AB75),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Confirm Pickup Slot',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D1A13),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNoSlotsMessage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy_rounded,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'No Pickup Slots Available',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Farmers in your cart haven\'t created pickup slots yet. You can proceed with checkout and they will contact you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF88AB75),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Continue Checkout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D1A13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Pickup Slots',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose your preferred time slot from farmers in your cart',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Group slots by date
          ..._buildGroupedSlots(),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedSlots() {
    // Group by date
    final groupedByDate = <String, List<PickupSlotModel>>{};
    for (final slot in _availableSlots) {
      final dateKey = slot.dateString;
      groupedByDate.putIfAbsent(dateKey, () => []).add(slot);
    }

    final widgets = <Widget>[];
    groupedByDate.forEach((date, slots) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            date,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFA1C68A),
            ),
          ),
        ),
      );

      for (final slot in slots) {
        widgets.add(_buildSlotCard(slot));
      }

      widgets.add(const SizedBox(height: 16));
    });

    return widgets;
  }

  Widget _buildSlotCard(PickupSlotModel slot) {
    final isSelected = _selectedSlot?.id == slot.id;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSlot = slot);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF15281E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF88AB75)
                : Colors.white.withAlpha(20),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF88AB75).withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF88AB75)
                      : Colors.white.withAlpha(60),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF88AB75)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFF0D1A13),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Slot details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFFA1C68A),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        slot.timeRange,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.agriculture_rounded,
                        color: Color(0xFF88AB75),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${slot.farmerName} (${slot.farmName})',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (slot.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF88AB75),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            slot.location!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: slot.availableSlots > 5
                              ? const Color(0xFF88AB75).withAlpha(30)
                              : Colors.orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${slot.availableSlots} slots left',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: slot.availableSlots > 5
                                ? const Color(0xFFA1C68A)
                                : Colors.orange,
                          ),
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
}
