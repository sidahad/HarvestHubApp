import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';
import '../common/chatbot_screen.dart';

class CustomerMainLayout extends StatefulWidget {
  final int initialIndex;
  const CustomerMainLayout({super.key, this.initialIndex = 0});

  @override
  State<CustomerMainLayout> createState() => _CustomerMainLayoutState();
}

class _CustomerMainLayoutState extends State<CustomerMainLayout> {
  late int _currentIndex;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _dataService.addListener(_onDataChanged);
    _dataService.loadCartForCurrentUser().catchError((error) {
      debugPrint('Could not load cart initial: $error');
    });
    _dataService.loadWishlistForCurrentUser().catchError((error) {
      debugPrint('Could not load wishlist initial: $error');
    });
    _dataService
        .loadCatalog()
        .then((_) {
          _dataService.loadCartForCurrentUser().catchError((error) {
            debugPrint('Could not load cart: $error');
          });
          _dataService.loadWishlistForCurrentUser().catchError((error) {
            debugPrint('Could not load wishlist: $error');
          });
          _dataService.loadFollowedFarmersForCurrentUser().catchError((error) {
            debugPrint('Could not load followed farmers: $error');
          });
        })
        .catchError((error) {
          debugPrint('Could not load catalog: $error');
        });
    _dataService
        .loadOrdersForCurrentUser()
        .then((_) {
          _dataService.loadNotificationsForCurrentUser().catchError((error) {
            debugPrint('Could not load notifications: $error');
          });
        })
        .catchError((error) {
          debugPrint('Could not load orders: $error');
          _dataService.loadNotificationsForCurrentUser().catchError((err) {
            debugPrint('Could not load notifications fallback: $err');
          });
        });
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  List<Widget> get _screens => [
    const HomeScreen(),
    CategoriesScreen(onBack: () => setState(() => _currentIndex = 0)),
    CartScreen(onBack: () => setState(() => _currentIndex = 0)),
    MyOrdersScreen(onBack: () => setState(() => _currentIndex = 0)),
    ProfileScreen(onBack: () => setState(() => _currentIndex = 0)),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cartCount = _dataService.cart.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatbot_fab',
        tooltip: 'ChatBot Assistant',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1912),
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha(20), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFFA1C68A),
              unselectedItemColor: const Color(0xFF6F8578),
              selectedLabelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: l10n.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.grid_view_outlined),
                  activeIcon: const Icon(Icons.grid_view_rounded),
                  label: l10n.products,
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    backgroundColor: const Color(0xFF88AB75),
                    textColor: const Color(0xFF0D1A13),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text('$cartCount'),
                    backgroundColor: const Color(0xFF88AB75),
                    textColor: const Color(0xFF0D1A13),
                    child: const Icon(Icons.shopping_bag_rounded),
                  ),
                  label: l10n.cart,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long_outlined),
                  activeIcon: const Icon(Icons.receipt_long_rounded),
                  label: l10n.orders,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person_rounded),
                  label: l10n.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
