import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_farmers_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_contact_messages_screen.dart';
import 'admin_messages_screen.dart';
import '../../services/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../common/chatbot_screen.dart';

class AdminMainLayout extends StatefulWidget {
  const AdminMainLayout({super.key});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    DataService().loadCatalog().catchError((error) {
      debugPrint('Could not load admin catalog: $error');
    });
    DataService().loadOrdersForStaff().catchError((error) {
      debugPrint('Could not load admin orders: $error');
    });
  }

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminOrdersScreen(),
    AdminFarmersScreen(),
    AdminCustomersScreen(),
    AdminCategoriesScreen(),
    AdminReportsScreen(),
    AdminMessagesScreen(),
    AdminContactMessagesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        backgroundColor: AppTheme.secondary,
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
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.secondary,
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
                  icon: const Icon(Icons.analytics_outlined),
                  activeIcon: const Icon(Icons.analytics_rounded),
                  label: AppLocalizations.of(context)?.overview ?? 'Overview',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long_outlined),
                  activeIcon: const Icon(Icons.receipt_long_rounded),
                  label: AppLocalizations.of(context)?.orders ?? 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.agriculture_outlined),
                  activeIcon: const Icon(Icons.agriculture_rounded),
                  label: AppLocalizations.of(context)?.farmers ?? 'Farmers',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.people_outline_rounded),
                  activeIcon: const Icon(Icons.people_rounded),
                  label: AppLocalizations.of(context)?.allCustomers ?? 'Customers',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.category_outlined),
                  activeIcon: const Icon(Icons.category_rounded),
                  label: AppLocalizations.of(context)?.categories ?? 'Categories',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.summarize_outlined),
                  activeIcon: const Icon(Icons.summarize_rounded),
                  label: AppLocalizations.of(context)?.reports ?? 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.forum_outlined),
                  activeIcon: const Icon(Icons.forum_rounded),
                  label: AppLocalizations.of(context)?.messages ?? 'Chats',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.mail_outline_rounded),
                  activeIcon: const Icon(Icons.mail_rounded),
                  label: AppLocalizations.of(context)?.contactUs ?? 'Contact',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
