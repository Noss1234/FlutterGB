import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant.dart';
// import '../models/plant_data.dart'; // Removed unused import
import '../providers/plant_provider.dart';

class PlantCategoryScreen extends StatelessWidget {
  final String category;
  final List<Map<String, String>> plantsData;

  const PlantCategoryScreen({
    super.key, // use_super_parameters
    required this.category,
    required this.plantsData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme

    return Scaffold(
      appBar: AppBar( // Will use appBarTheme
        title: Text(category),
      ),
      backgroundColor: Colors.transparent, // For shared background
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0), // Adjusted padding
        itemCount: plantsData.length,
        itemBuilder: (BuildContext context, int index) {
          final entry = plantsData[index];
          final String? imagePath = entry['imagePath'];

          return Card( // Card will use cardTheme
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Adjust ListTile padding
              leading: SizedBox( // Constrain image/icon size
                width: 50,
                height: 50,
                child: imagePath != null && imagePath.isNotEmpty
                    ? ClipRRect( // Clip image to rounded corners
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.local_florist_outlined, size: 30, color: theme.iconTheme.color?.withAlpha((0.7 * 255).round()));
                          },
                        ),
                      )
                    : Icon(Icons.local_florist_outlined, size: 30, color: theme.iconTheme.color?.withAlpha((0.7 * 255).round())),
              ),
              title: Text(
                entry['name'] ?? 'Unknown Plant',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 17),
              ),
              subtitle: Text(
                entry['description'] ?? 'No description available.',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: ElevatedButton( // Button will use elevatedButtonTheme
                // style: ElevatedButton.styleFrom( // Specific overrides if needed
                //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                //   textStyle: const TextStyle(fontSize: 13),
                // ),
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
                      backgroundColor: Colors.green[700], // Consistent SnackBar color
                    ),
                  );
                },
                child: const Text('Add'), // Keep it short, or "Add Plant"
              ),
            ),
          );
        },
      ),
    );
  }
}
