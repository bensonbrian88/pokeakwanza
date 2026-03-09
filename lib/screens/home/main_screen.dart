import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/bottom_nav.dart';
import 'home_premium_screen.dart';
import '../shop_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadGuestFlag();
  }

  Future<void> _loadGuestFlag() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  final List<Widget> _screens = [
    const HomePremiumScreen(),
    const ShopScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isGuest,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isGuest) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('is_guest');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
