// screens/plant_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/plant.dart';

class PlantDetailScreen extends StatelessWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.green[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📷 Pflanzenbild
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                plant.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // 🌿 Kategorien & Beschreibung
            Text(
              plant.category,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54),
            ),
            const SizedBox(height: 8),

            Text(
              plant.description,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),

            // 💧 Wasserbedarf
            _buildInfoTile(
              icon: Icons.opacity,
              title: "Wasserbedarf",
              value: "${plant.waterNeed} ml pro Tag",
            ),

            // 🌡️ pH-Wert
            _buildInfoTile(
              icon: Icons.science,
              title: "Optimaler pH-Wert",
              value: plant.idealPH.toStringAsFixed(1),
            ),

            // 🌍 Zugeordnete Zone
            _buildInfoTile(
              icon: Icons.place,
              title: "Bewässerungszone",
              value: "Zone ${plant.zone}",
            ),

            // (Zukünftige Buttons z. B. Bearbeiten, Zeitplan ändern etc.)
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: edit feature
                },
                icon: const Icon(Icons.edit),
                label: const Text("Bearbeiten"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      {required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
