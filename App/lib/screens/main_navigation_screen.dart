// screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:irrigation_control_app/widgets/main_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'zone_overview_screen.dart';
import 'settings_screen.dart';

// 🌿 Haupt-Navigation mit drei Tabs (Home, Zonen, Einstellungen)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    ZoneOverviewScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
