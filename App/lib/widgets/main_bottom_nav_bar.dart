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
          icon: const Icon(Icons.home_outlined), // const added
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.water_drop_outlined), // const added
          label: 'Zones',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined), // const added
          label: 'Settings',
        ),
      ],
    );
  }
}
