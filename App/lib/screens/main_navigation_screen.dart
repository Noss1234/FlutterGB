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
  final PageController _pageController = PageController();
  double _backgroundOffset = 0.0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ZoneOverviewScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        setState(() {
          // Offset calculation: As page goes from 0 to 2, offset goes from 0 to -screenWidth.
          // Background width is screenWidth * 2.
          // Max offset should be -screenWidth to show the entire background.
          _backgroundOffset = -(_pageController.page!) * (MediaQuery.of(context).size.width / (_screens.length -1));
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(() {}); // Important to remove listener
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final backgroundWidth = screenWidth * 2; // Background is twice the screen width

    return Scaffold(
      // The Scaffold's own background can be plain or transparent if the gradient covers all.
      // backgroundColor: Colors.transparent, // Or a base color
      body: Stack(
        children: [
          Positioned(
            left: _backgroundOffset,
            top: 0,
            bottom: 0,
            width: backgroundWidth,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.lightBlue.shade200, 
                    Colors.green.shade200, 
                    Colors.orange.shade200, 
                    Colors.pink.shade200,
                    Colors.purple.shade200, // Added more colors for a 2x width gradient
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          PageView(
            controller: _pageController,
            children: _screens,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
