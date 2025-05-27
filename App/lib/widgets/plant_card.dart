import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../screens/plant_detail_screen.dart'; // Import PlantDetailScreen

class PlantCard extends StatelessWidget {
  final Plant plant;

  const PlantCard({
    Key? key,
    required this.plant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme

    return Card(
      // Card properties will now be mostly inherited from cardTheme in main.dart
      // elevation: 2, // Overridden by cardTheme.elevation if set
      // margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Overridden by cardTheme.margin
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Overridden by cardTheme.shape
      // color: Colors.white, // Overridden by cardTheme.color
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0), // Match card shape for ink splash
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantDetailScreen(plant: plant),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green[100],
                  backgroundImage: plant.imageUrl.isNotEmpty
                      ? plant.imageUrl.startsWith("assets/")
                          ? AssetImage(plant.imageUrl) as ImageProvider
                          : NetworkImage(plant.imageUrl)
                      : null,
                  child: plant.imageUrl.isEmpty
                      ? Icon(Icons.local_florist, size: 30, color: Colors.green[700])
                      : null,
                  // Note: CircleAvatar's onBackgroundImageError is available if more robust error handling for images is needed later.
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      plant.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 17), // Use themed text
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.category,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13), // Use themed text
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.water_drop_outlined, size: 15, color: theme.iconTheme.color?.withOpacity(0.7)),
                        const SizedBox(width: 5),
                        Text(
                          '${plant.waterNeed}ml',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.blueGrey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.thermostat_outlined, size: 15, color: theme.iconTheme.color?.withOpacity(0.7)), // Example icon for pH
                        const SizedBox(width: 5),
                        Text(
                          'pH ${plant.idealPH.toStringAsFixed(1)}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.orange[800]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
