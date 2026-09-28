import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../models/pickup_slot_model.dart';

class FarmerPickupSlotsScreen extends StatefulWidget {
  const FarmerPickupSlotsScreen({super.key});

  @override
  State<FarmerPickupSlotsScreen> createState() => _FarmerPickupSlotsScreenState();
}

class _FarmerPickupSlotsScreenState extends State<FarmerPickupSlotsScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
    _dataService.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSlots() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _dataService.loadPickupSlotsForFarmer(user.uid);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddSlotDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);
    int totalSlots = 10;
    String location = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0D1A13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Create Pickup Slot',
            style: GoogleFonts.poppins(
              color: const Color(0xFFA1C68A),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker
                Text(
                  'Date',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
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
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15281E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFA1C68A), size: 18),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Range
                Text(
                  'Time Range',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
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
                            setDialogState(() => startTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15281E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withAlpha(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFFA1C68A), size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    startTime.format(context),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('-', style: GoogleFonts.inter(color: Colors.white70)),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
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
                            setDialogState(() => endTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15281E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withAlpha(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFFA1C68A), size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    endTime.format(context),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Total Slots
                Text(
                  'Total Slots Available',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15281E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'e.g., 10',
                      hintStyle: GoogleFonts.inter(color: Colors.white38),
                    ),
                    onChanged: (val) {
                      totalSlots = int.tryParse(val) ?? 10;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Location (optional)
                Text(
                  'Pickup Location (Optional)',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15281E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: TextField(
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'e.g., Farm Gate, Market Entrance',
                      hintStyle: GoogleFonts.inter(color: Colors.white38),
                    ),
                    onChanged: (val) {
                      location = val;
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                // Get current user's farmer data
                final farmer = _dataService.farmers.firstWhere(
                  (f) => f.id == user.uid,
                  orElse: () => _dataService.farmers.first,
                );

                final slot = PickupSlotModel(
                  id: '',
                  farmerId: user.uid,
                  farmerName: farmer.name,
                  farmName: farmer.farmName,
                  date: selectedDate,
                  startTime: startTime.format(context),
                  endTime: endTime.format(context),
                  totalSlots: totalSlots,
                  location: location.isEmpty ? null : location,
                );

                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  await _dataService.createPickupSlot(slot);
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pickup slot created successfully!',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF1E3827),
                    ),
                  );
                } catch (e) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pickup slot saved successfully',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF1E3827),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF88AB75),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF0D1A13),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = _dataService.pickupSlots;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Manage Pickup Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSlots,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA1C68A)))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: slots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.event_busy_rounded,
                              size: 60,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Pickup Slots Created',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create time slots for customers to pick up their orders',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slot = slots[index];
                          return _buildSlotCard(slot);
                        },
                      ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSlotDialog,
        backgroundColor: const Color(0xFF88AB75),
        icon: const Icon(Icons.add_rounded, color: Color(0xFF0D1A13)),
        label: Text(
          'Add Slot',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0D1A13),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(PickupSlotModel slot) {
    final percentBooked = (slot.bookedSlots / slot.totalSlots * 100).clamp(0, 100);
    final isUpcoming = slot.date.isAfter(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: slot.isActive 
              ? const Color(0xFFA1C68A).withAlpha(40)
              : Colors.white.withAlpha(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? const Color(0xFF88AB75).withAlpha(30)
                      : Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isUpcoming ? const Color(0xFFA1C68A) : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      slot.dateString,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isUpcoming ? const Color(0xFFA1C68A) : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Switch(
                value: slot.isActive,
                onChanged: (val) async {
                  await _dataService.togglePickupSlotStatus(slot.id);
                },
                activeThumbColor: const Color(0xFF88AB75),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFFA1C68A), size: 18),
              const SizedBox(width: 8),
              Text(
                slot.timeRange,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          if (slot.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFA1C68A), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slot.location!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${slot.bookedSlots} / ${slot.totalSlots}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: slot.isFull ? Colors.orange : const Color(0xFFA1C68A),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentBooked / 100,
                      backgroundColor: Colors.white.withAlpha(20),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        slot.isFull ? Colors.orange : const Color(0xFF88AB75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentBooked.toStringAsFixed(0)}% booked',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Show bookings for this slot
                  },
                  icon: const Icon(Icons.people_outline_rounded, size: 16),
                  label: Text(
                    'View Bookings',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA1C68A),
                    side: const BorderSide(color: Color(0xFFA1C68A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF0D1A13),
                      title: Text(
                        'Delete Slot?',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      content: Text(
                        'This will permanently delete this pickup slot.',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: GoogleFonts.inter()),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text('Delete', style: GoogleFonts.inter()),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await _dataService.deletePickupSlot(slot.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Slot deleted',
                            style: GoogleFonts.inter(),
                          ),
                          backgroundColor: const Color(0xFF88AB75),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
