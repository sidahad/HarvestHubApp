import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/data_service.dart';
import '../../models/notification_model.dart';
import 'my_orders_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DataService _dataService = DataService();
  String _selectedFilter = 'All'; // 'All', 'Unread', 'order', 'promo', 'restock'

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChange);
    _dataService.loadNotificationsForCurrentUser();
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  List<NotificationModel> _getFilteredNotifications() {
    final all = _dataService.notifications;
    if (_selectedFilter == 'All') return all;
    if (_selectedFilter == 'Unread') {
      return all.where((n) => !n.isRead).toList();
    }
    return all.where((n) => n.type == _selectedFilter).toList();
  }

  int _countFor(String filter) {
    final all = _dataService.notifications;
    if (filter == 'All') return all.length;
    if (filter == 'Unread') return all.where((n) => !n.isRead).length;
    return all.where((n) => n.type == filter).length;
  }

  void _handleNotificationTap(NotificationModel notif) {
    if (!notif.isRead) {
      _dataService.markNotificationRead(notif.id);
    }

    if (notif.type == 'order') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
      );
    } else if (notif.type == 'promo') {
      // Extract code if present
      final match = RegExp(r'code\s+([A-Z0-9]+)', caseSensitive: false).firstMatch(notif.message);
      final code = match != null ? match.group(1) : 'HARVEST20';
      if (code != null) {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF88AB75), size: 20),
                const SizedBox(width: 10),
                Text('Promo code "$code" copied to clipboard!'),
              ],
            ),
            backgroundColor: const Color(0xFF15281E),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15281E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        title: Text(
          'Clear All Notifications?',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFF0F5F1),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all notifications? This action cannot be undone.',
          style: GoogleFonts.inter(
            color: const Color(0xFF8EAA95),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF8EAA95)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _dataService.clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Color(0xFF15281E),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredNotifications();
    final unreadCount = _dataService.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFFF0F5F1)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF0F5F1),
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF88AB75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D1A13),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_dataService.notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFFF0F5F1)),
              color: const Color(0xFF15281E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withAlpha(20)),
              ),
              onSelected: (val) {
                if (val == 'mark_all_read') {
                  _dataService.markAllNotificationsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: Color(0xFF15281E),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else if (val == 'clear_all') {
                  _confirmClearAll();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all_rounded, color: Color(0xFF88AB75), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Mark all read',
                        style: GoogleFonts.inter(color: const Color(0xFFF0F5F1), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_outlined, color: Color(0xFFE76F51), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Clear all',
                        style: GoogleFonts.inter(color: const Color(0xFFE76F51), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive width container for tablets and large phones
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  children: [
                    // Filter Chips Bar (Horizontally scrollable and responsive)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip('All', Icons.all_inclusive_rounded, _countFor('All')),
                            _buildFilterChip('Unread', Icons.mark_email_unread_outlined, _countFor('Unread')),
                            _buildFilterChip('order', Icons.local_shipping_outlined, _countFor('order'), label: 'Orders'),
                            _buildFilterChip('restock', Icons.eco_outlined, _countFor('restock'), label: 'Harvests'),
                            _buildFilterChip('promo', Icons.discount_outlined, _countFor('promo'), label: 'Deals'),
                            _buildFilterChip('system', Icons.notifications_none_rounded, _countFor('system'), label: 'System'),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Color(0xFF1E3527), height: 1),

                    // Notification List or Empty State
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF88AB75),
                        backgroundColor: const Color(0xFF15281E),
                        onRefresh: () async {
                          await _dataService.loadNotificationsForCurrentUser();
                        },
                        child: filtered.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: _buildEmptyState(),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final notif = filtered[index];
                                  return _buildNotificationCard(notif);
                                },
                              ),
                      ),
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

  Widget _buildFilterChip(String filterKey, IconData icon, int count, {String? label}) {
    final isSelected = _selectedFilter == filterKey;
    final displayLabel = label ?? filterKey;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 15,
          color: isSelected ? const Color(0xFF0D1A13) : const Color(0xFF8EAA95),
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0D1A13) : const Color(0xFFF0F5F1),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0D1A13).withAlpha(40)
                      : const Color(0xFF244431),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF0D1A13) : const Color(0xFFA1C68A),
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF15281E),
        selectedColor: const Color(0xFF88AB75),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isSelected ? const Color(0xFF88AB75) : Colors.white.withAlpha(15),
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filterKey;
          });
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final visual = _getVisuals(notif.type);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFD9534F).withAlpha(180),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (_) {
        final removed = notif;
        _dataService.deleteNotification(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification removed'),
            backgroundColor: const Color(0xFF15281E),
            action: SnackBarAction(
              label: 'Undo',
              textColor: const Color(0xFF88AB75),
              onPressed: () {
                _dataService.restoreNotification(removed);
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notif),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead ? const Color(0xFF14241B) : const Color(0xFF193324),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notif.isRead
                  ? Colors.white.withAlpha(18)
                  : const Color(0xFF88AB75).withAlpha(80),
              width: notif.isRead ? 1 : 1.4,
            ),
            boxShadow: notif.isRead
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF88AB75).withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge with distinct gradient per notification type
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: visual.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: visual.gradient.first.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  visual.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Content Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Tag Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: visual.badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            visual.label.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: visual.badgeTextColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Time Ago
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: Color(0xFF8EAA95),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notif.displayTime,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF8EAA95),
                              ),
                            ),
                          ],
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF88AB75),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFFB0C4B5),
                        height: 1.4,
                      ),
                    ),

                    // Quick Action Link
                    if (notif.type == 'order') ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Order Tracking',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFA1C68A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFA1C68A)),
                        ],
                      ),
                    ] else if (notif.type == 'promo') ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tap to copy promo code',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF4A261),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 13, color: Color(0xFFF4A261)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF15281E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF88AB75).withAlpha(40), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF88AB75).withAlpha(20),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 42,
                  color: Color(0xFF88AB75),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedFilter == 'All'
                  ? 'All Caught Up!'
                  : 'No ${_selectedFilter.capitalize()} Notifications',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF0F5F1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'You don\'t have any notifications right now. Fresh deals and harvest updates will appear here.'
                  : 'There are currently no notifications matching this filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF8EAA95),
                height: 1.5,
              ),
            ),
            if (_selectedFilter != 'All') ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedFilter = 'All'),
                icon: const Icon(Icons.filter_list_off_rounded, size: 16),
                label: const Text('View All Notifications'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF88AB75),
                  side: const BorderSide(color: Color(0xFF88AB75)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _Visuals _getVisuals(String type) {
    switch (type) {
      case 'order':
        return _Visuals(
          icon: Icons.local_shipping_rounded,
          gradient: const [Color(0xFF2A9D8F), Color(0xFF1E6F5C)],
          badgeBg: const Color(0xFF2A9D8F).withAlpha(40),
          badgeTextColor: const Color(0xFF52B788),
          label: 'Order Update',
        );
      case 'promo':
        return _Visuals(
          icon: Icons.local_offer_rounded,
          gradient: const [Color(0xFFE76F51), Color(0xFFF4A261)],
          badgeBg: const Color(0xFFE76F51).withAlpha(40),
          badgeTextColor: const Color(0xFFF4A261),
          label: 'Exclusive Deal',
        );
      case 'restock':
        return _Visuals(
          icon: Icons.eco_rounded,
          gradient: const [Color(0xFF52B788), Color(0xFF2D6A4F)],
          badgeBg: const Color(0xFF52B788).withAlpha(40),
          badgeTextColor: const Color(0xFF74C69D),
          label: 'Fresh Harvest',
        );
      case 'system':
      default:
        return _Visuals(
          icon: Icons.notifications_active_rounded,
          gradient: const [Color(0xFF4361EE), Color(0xFF3A0CA3)],
          badgeBg: const Color(0xFF4361EE).withAlpha(40),
          badgeTextColor: const Color(0xFF90E0EF),
          label: 'Platform Notice',
        );
    }
  }
}

class _Visuals {
  final IconData icon;
  final List<Color> gradient;
  final Color badgeBg;
  final Color badgeTextColor;
  final String label;

  _Visuals({
    required this.icon,
    required this.gradient,
    required this.badgeBg,
    required this.badgeTextColor,
    required this.label,
  });
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
