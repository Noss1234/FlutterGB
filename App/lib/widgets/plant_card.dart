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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      plant.category,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.water_drop_outlined, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Wasser: ${plant.waterNeed}ml',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.thermostat_outlined, size: 14, color: Colors.orange[700]), // Example icon for pH
                        const SizedBox(width: 4),
                        Text(
                          'pH: ${plant.idealPH}',
                          style: TextStyle(fontSize: 12, color: Colors.orange[700]),
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
