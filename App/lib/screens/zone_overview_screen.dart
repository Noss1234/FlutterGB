// screens/zone_overview_screen.dart
import 'package:flutter/material.dart';
import '../services/esp_service.dart';

class ZoneOverviewScreen extends StatefulWidget {
  const ZoneOverviewScreen({super.key});

  @override
  State<ZoneOverviewScreen> createState() => _ZoneOverviewScreenState();
}

// 💧 Bildschirm zur manuellen Steuerung einzelner Bewässerungszonen
class _ZoneOverviewScreenState extends State<ZoneOverviewScreen> {
  final int zoneCount = 8; // Anzahl der verfügbaren Zonen (anpassbar)
  final Map<int, TextEditingController> controllers = {};
  final Map<int, bool> _isWatering = {}; // Track watering status

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < zoneCount; i++) {
      controllers[i] = TextEditingController(text: '300'); // Standard: 300 ml
      _isWatering[i] = false; // Initialize status
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleZoneWatering(int zone) async {
    final bool currentWateringState = _isWatering[zone] ?? false;
    
    if (currentWateringState) {
      // Stop watering
      try {
        await EspService.stopManualWatering(zone); // Assuming this method exists
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Zone $zone gestoppt')),
          );
          setState(() {
            _isWatering[zone] = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Stoppen von Zone $zone: $e')),
          );
        }
      }
    } else {
      // Start watering
      final amount = int.tryParse(controllers[zone]?.text ?? '0') ?? 0;
      if (amount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bitte eine gültige Menge eingeben.')),
          );
        }
        return;
      }

      try {
        await EspService.startManualWatering(zone, amount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Zone $zone gestartet für $amount ml')),
          );
          setState(() {
            _isWatering[zone] = true;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Starten von Zone $zone: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Zonensteuerung"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.green[50],
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: zoneCount,
        itemBuilder: (ctx, index) {
          final bool isCurrentlyWatering = _isWatering[index] ?? false;
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.water_drop_outlined, // Changed to outlined
                color: isCurrentlyWatering ? Colors.green[600] : Colors.blue[600],
                size: 30,
              ),
              title: Text("Zone $index", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Menge: ", style: TextStyle(fontSize: 13)),
                      SizedBox(
                        width: 70, // Slightly reduced width
                        child: TextField(
                          controller: controllers[index],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          ),
                          enabled: !isCurrentlyWatering, // Disable input if watering
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text("ml", style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (isCurrentlyWatering)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Bewässerung aktiv...',
                        style: TextStyle(color: Colors.green[700], fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
              trailing: TextButton.icon(
                onPressed: () => _toggleZoneWatering(index),
                icon: Icon(isCurrentlyWatering ? Icons.stop_circle_outlined : Icons.play_circle_filled_outlined),
                label: Text(isCurrentlyWatering ? "Stop" : "Start"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: isCurrentlyWatering ? Colors.red[600] : Colors.green[600],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
