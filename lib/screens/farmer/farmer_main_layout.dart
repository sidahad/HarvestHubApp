import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'farmer_dashboard_screen.dart';
import 'farmer_products_screen.dart';
import 'farmer_orders_screen.dart';
import 'farmer_reports_screen.dart';
import 'farmer_notifications_screen.dart';
import 'farmer_own_profile_screen.dart';
import 'marketplace_view_screen.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../common/chatbot_screen.dart';

class FarmerMainLayout extends StatefulWidget {
  const FarmerMainLayout({super.key});

  @override
  State<FarmerMainLayout> createState() => _FarmerMainLayoutState();
}

class _FarmerMainLayoutState extends State<FarmerMainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    DataService().loadCatalog().catchError((error) {
      debugPrint('Could not load farmer catalog: $error');
    });
    DataService().loadOrdersForStaff().catchError((error) {
      debugPrint('Could not load farmer orders: $error');
    });
  }

  final List<Widget> _screens = const [
    FarmerDashboardScreen(),
    FarmerProductsScreen(),
    FarmerOrdersScreen(),
    FarmerNotificationsScreen(),
    FarmerReportsScreen(),
    MarketplaceViewScreen(),
    FarmerOwnProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
        ),
        tooltip: 'Farm Assistant',
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1912),
          border: Border(
            top: BorderSide(
              color: Colors.white.withAlpha(20),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: uid == null
                  ? const Stream.empty()
                  : FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
              builder: (context, snapshot) {
                final unreadAlerts = snapshot.data?.docs.length ?? 0;

                return BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  backgroundColor: Colors.transparent,
                  selectedItemColor: AppTheme.primary,
                  unselectedItemColor: AppTheme.textSecondary,
                  selectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.dashboard_outlined),
                      activeIcon: const Icon(Icons.dashboard_rounded),
                      label: l10n.overview,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.inventory_2_outlined),
                      activeIcon: const Icon(Icons.inventory_2_rounded),
                      label: l10n.produce,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.receipt_long_outlined),
                      activeIcon: const Icon(Icons.receipt_long_rounded),
                      label: l10n.orders,
                    ),
                    BottomNavigationBarItem(
                      icon: Badge(
                        isLabelVisible: unreadAlerts > 0,
                        label: Text('$unreadAlerts'),
                        backgroundColor: AppTheme.error,
                        textColor: Colors.white,
                        child: const Icon(Icons.notifications_outlined),
                      ),
                      activeIcon: Badge(
                        isLabelVisible: unreadAlerts > 0,
                        label: Text('$unreadAlerts'),
                        backgroundColor: AppTheme.error,
                        textColor: Colors.white,
                        child: const Icon(Icons.notifications_rounded),
                      ),
                      label: l10n.alerts,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.bar_chart_outlined),
                      activeIcon: const Icon(Icons.bar_chart_rounded),
                      label: l10n.reports,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.store_outlined),
                      activeIcon: const Icon(Icons.store_rounded),
                      label: l10n.market,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person_outline),
                      activeIcon: const Icon(Icons.person_rounded),
                      label: l10n.profile,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
