// lib/widgets/plant_tile.dart

import 'package:flutter/material.dart';
import '../models/plant.dart';

/// Eine Kachel, die eine Pflanze in der Grid-Übersicht darstellt.
/// Zeigt Bild, Namen und einen Zahnrad-Button für Einstellungen.
class PlantTile extends StatelessWidget {
  final Plant plant;
  final VoidCallback onEdit;
  final VoidCallback? onTap;

  const PlantTile({
    Key? key,
    required this.plant,
    required this.onEdit,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Bild-Widget: Asset-Bild oder Standard-Icon
    final Widget imageWidget = plant.imagePath.isNotEmpty
        ? Image.asset(
            plant.imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
          )
        : const Icon(
            Icons.local_florist,
            size: 50,
            color: Colors.grey,
          );

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Quadrat-Container für das Bild
            AspectRatio(
              aspectRatio: 1.0,
              child: imageWidget,
            ),
            // Name und Einstellungs-Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      plant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Einstellungen bearbeiten',
                    onPressed: onEdit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
