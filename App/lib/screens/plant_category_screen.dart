import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant.dart';
import '../models/plant_data.dart'; // Though plantsData is passed, good for context
import '../providers/plant_provider.dart';

class PlantCategoryScreen extends StatelessWidget {
  final String category;
  final List<Map<String, String>> plantsData;

  const PlantCategoryScreen({
    Key? key,
    required this.category,
    required this.plantsData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.green[50],
      body: ListView.builder(
        itemCount: plantsData.length,
        itemBuilder: (BuildContext context, int index) {
          final entry = plantsData[index];
          final String? imagePath = entry['imagePath'];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            child: ListTile(
              leading: imagePath != null && imagePath.isNotEmpty
                  ? Image.asset(
                      imagePath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback for asset not found
                        return Icon(Icons.local_florist, size: 40, color: Colors.grey[400]);
                      },
                    )
                  : Icon(Icons.local_florist, size: 40, color: Colors.grey[400]),
              title: Text(entry['name'] ?? 'Unknown Plant'),
              subtitle: Text(entry['description'] ?? 'No description available.'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final plantProvider = Provider.of<PlantProvider>(context, listen: false);
                  
                  final newPlant = Plant(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: entry['name'] ?? 'Unknown Plant',
                    category: category, // Use the category passed to the screen
                    idealPH: 6.5, // Default value
                    waterNeed: 500, // Default value in ml
                    imageUrl: entry['imagePath'] ?? '', // Placeholder, assuming assets not network
                    description: entry['description'] ?? '',
                    zone: "Unassigned", // Default value
                  );

                  plantProvider.addPlant(newPlant);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${newPlant.name} added to your garden!'),
                      backgroundColor: Colors.green[800],
                    ),
                  );
                },
                child: const Text('Add to My Garden'),
              ),
            ),
          );
        },
      ),
    );
  }
}
