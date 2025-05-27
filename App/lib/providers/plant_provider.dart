// providers/plant_provider.dart
import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/esp_service.dart';

class PlantProvider with ChangeNotifier {
  List<Plant> _plants = [];

  List<Plant> get plants => _plants;

  Future<void> fetchPlants() async {
    try {
      _plants = await EspService.getPlantsFromESP();
      notifyListeners();
    } catch (e) {
      debugPrint('Fehler beim Laden der Pflanzen: $e');
    }
  }

  void addPlant(Plant plant) {
    _plants.add(plant);
    notifyListeners();
    // Hier ggf. auch an ESP senden
  }

  void updatePlant(Plant updatedPlant) {
    final index = _plants.indexWhere((p) => p.id == updatedPlant.id);
    if (index >= 0) {
      _plants[index] = updatedPlant;
      notifyListeners();
      // Optional: update to ESP
    }
  }

  void removePlant(String id) {
    _plants.removeWhere((p) => p.id == id);
    notifyListeners();
    // Optional: remove from ESP
  }

  Plant? getPlantById(String id) {
    // Using firstWhere with orElse returning null directly.
    // This avoids the 'null as Plant' cast which causes the error.
    // The return type of the method is already Plant? so this is safe.
    return _plants.firstWhere((p) => p.id == id, orElse: () => null);
  }
}
