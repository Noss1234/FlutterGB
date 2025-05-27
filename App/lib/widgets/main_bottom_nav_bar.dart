import 'package:flutter/material.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key, // use_super_parameters
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.green[800],
      unselectedItemColor: Colors.grey[600],
      backgroundColor: Colors.white,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), // unnecessary const removed
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop_outlined), // unnecessary const removed
          label: 'Zones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined), // unnecessary const removed
          label: 'Settings',
        ),
      ],
    );
  }
}
