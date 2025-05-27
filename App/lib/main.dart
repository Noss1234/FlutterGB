import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Removed: import 'package:shared_preferences/shared_preferences.dart';

import 'providers/plant_provider.dart';
// Removed: import 'screens/home_screen.dart';
// Removed: import 'screens/zone_overview_screen.dart';
// Removed: import 'screens/settings_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyGardenApp());
}

class MyGardenApp extends StatelessWidget {
  const MyGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlantProvider(),
      child: MaterialApp(
        title: 'MyGarden Controller',
        theme: ThemeData(
          primaryColor: Colors.green[600], // Softer green
          scaffoldBackgroundColor: Colors.grey[200], // Default for non-transparent screens
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green[600], // Consistent AppBar color
            foregroundColor: Colors.white,
            elevation: 1.0,
            titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          cardTheme: CardTheme(
            elevation: 3.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            color: Colors.white, // Default card background
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[500],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // Adjusted padding
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.green[600]!),
            ),
            filled: true,
            fillColor: Colors.white70, // Light fill for TextFields
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          textTheme: TextTheme(
            headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          iconTheme: IconThemeData(
            color: Colors.green[600], // Default icon color
          ),
        ),
        home: const MainNavigationScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
