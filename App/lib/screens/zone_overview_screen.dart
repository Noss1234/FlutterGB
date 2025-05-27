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

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < zoneCount; i++) {
      controllers[i] = TextEditingController(text: '300'); // Standard: 300 ml
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _startZone(int zone) async {
    final amount = int.tryParse(controllers[zone]?.text ?? '0') ?? 0;
    if (amount <= 0) return;

    try {
      await EspService.startManualWatering(zone, amount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zone $zone gestartet für $amount ml')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
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
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.water, color: Colors.blue),
              title: Text("Zone $index"),
              subtitle: Row(
                children: [
                  const Text("Menge: "),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: controllers[index],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("ml"),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _startZone(index),
                child: const Text("Start"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(60, 40),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
