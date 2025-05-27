import 'package:flutter/material.dart';
import 'plant_category_screen.dart';
import '../models/plant_data.dart';

class PlantLibraryScreen extends StatelessWidget {
  const PlantLibraryScreen({super.key}) : super(); // use_super_parameters

  Widget _buildCategoryTile(BuildContext context, String title, IconData icon, List<Map<String, String>> plantsData) {
    final theme = Theme.of(context);
    return Card( // Wrap ListTile in a Card
      // Card properties will be inherited from cardTheme
      child: ListTile(
        leading: Icon(icon, color: theme.iconTheme.color, size: 28),
        title: Text(title, style: theme.textTheme.titleLarge),
        trailing: Icon(Icons.chevron_right, color: theme.iconTheme.color?.withAlpha((0.6 * 255).round())),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlantCategoryScreen(
                category: title,
                plantsData: plantsData, // Ensure this matches the parameter name in PlantCategoryScreen
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // Will use appBarTheme from main.dart
        title: const Text('Pflanzenbibliothek'),
      ),
      backgroundColor: Colors.transparent, // For shared background
      body: ListView(
        padding: const EdgeInsets.all(12.0), // Adjusted padding for better spacing with card margins
        children: [
          _buildCategoryTile(context, 'Obst', Icons.apple_outlined, PlantData.fruits),
          _buildCategoryTile(context, 'Gemüse', Icons.local_florist_outlined, PlantData.vegetables), // Using a generic icon
          _buildCategoryTile(context, 'Blumen', Icons.local_florist_outlined, PlantData.flowers), // Using a generic icon
        ],
      ),
    );
  }
}
