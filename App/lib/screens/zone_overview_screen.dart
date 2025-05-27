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
      backgroundColor: Colors.transparent, // Make background transparent
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: zoneCount,
        itemBuilder: (ctx, index) {
          final bool isCurrentlyWatering = _isWatering[index] ?? false;
          final theme = Theme.of(context); // Access theme

          return Card(
            // Card properties will be inherited from cardTheme
            child: Padding( 
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // const added
              child: ListTile(
                contentPadding: EdgeInsets.zero, 
                leading: Icon(
                  Icons.water_drop_outlined,
                  color: isCurrentlyWatering ? Colors.green[700] : theme.iconTheme.color, 
                  size: 32, 
                ),
                title: Text(
                  "Zone $index", 
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [ 
                  Row( 
                    children: [
                      Text("Menge: ", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14)),
                      SizedBox(
                        width: 70, 
                        child: TextField(
                          controller: controllers[index],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration( // const added
                            hintText: "ml",
                          ),
                          enabled: !isCurrentlyWatering,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14), 
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text("ml", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14)),
                    ],
                  ), 
                  if (isCurrentlyWatering)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0), // const added
                      child: Text(
                        'Bewässerung aktiv...',
                        style: TextStyle(color: Colors.green[700], fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                ], 
              ), 
              trailing: ElevatedButton.icon(
                  onPressed: () => _toggleZoneWatering(index),
                  icon: Icon( // This Icon cannot be const due to conditional icon
                    isCurrentlyWatering ? Icons.stop_circle_outlined : Icons.play_circle_fill_outlined,
                    size: 20, 
                  ),
                  label: Text(isCurrentlyWatering ? "Stop" : "Start"), // This Text cannot be const due to conditional text
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentlyWatering ? Colors.red[500] : Colors.green[500],
                  ), 
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
