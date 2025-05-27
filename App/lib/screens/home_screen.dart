import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../services/esp_service.dart';
import '../models/plant.dart';
import '../widgets/plant_card.dart'; // Added import for PlantCard

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  bool isConnected = false;
  Map<String, dynamic>? currentStatus;
  Map<String, dynamic>? waterUsage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      isConnected = false;
    });

    try {
      isConnected = await EspService.ping();
      if (!isConnected) {
        throw Exception("Keine Verbindung zum Bewässerungssystem");
      }

      await Provider.of<PlantProvider>(context, listen: false).fetchPlants();
      currentStatus = await EspService.getStatus();
      waterUsage = await EspService.getWaterUsage();
    } catch (e) {
      if (mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler beim Laden: $e")),
        );
      }
    } finally {
      if (mounted) { // Check if the widget is still in the tree
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plants = Provider.of<PlantProvider>(context).plants;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MyGarden Controller"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.wifi,
              color: isConnected ? Colors.lightGreenAccent : Colors.redAccent,
            ),
            tooltip: isConnected ? "Verbunden" : "Nicht verbunden",
            onPressed: _loadInitialData,
          ),
        ],
      ),
      backgroundColor: Colors.green[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildConnectionInfo(),
                  const SizedBox(height: 16),
                  // Added Weather and Status Card Placeholder
                  Card(
                    elevation: 2,
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(Icons.wb_sunny_outlined, color: Colors.orangeAccent),
                      title: Text('Wetter & Vorhersage'),
                      subtitle: Text('Aktuell sonnig, 23°C. Ideal für die Gartenarbeit.'),
                      onTap: () => print('Weather card tapped'), // Placeholder action
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCurrentStatusCard(),
                  const SizedBox(height: 16),
                  _buildWaterUsageCard(),
                  const SizedBox(height: 16),
                  const Text(
                    "🌱 Deine Pflanzen",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Replaced _buildPlantCard with PlantCard widget
                  ...plants.map((Plant plant) => PlantCard(plant: plant)).toList(),
                  const SizedBox(height: 24), // Added some spacing
                  // Added "Routines" Navigation Placeholder Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    onPressed: () {
                      print('Navigate to Routines Screen');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Routines screen not yet implemented')),
                      );
                    },
                    child: const Text('Zu den Routinen', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16), // Bottom padding
                ],
              ),
            ),
      // Removed FloatingActionButton
    );
  }

  Widget _buildConnectionInfo() {
    return FutureBuilder<String>(
      future: EspService.getBaseUrl(),
      builder: (context, snapshot) {
        final ipText = snapshot.hasData
            ? "IP: ${snapshot.data!.replaceFirst('http://', '')}"
            : "IP: ...";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.cancel,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected
                      ? "Verbindung zum System aktiv"
                      : "Keine Verbindung",
                  style: TextStyle(
                    color: isConnected ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              ipText,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentStatusCard() {
    if (currentStatus == null) return Container(); // Return empty if no status
    return Card(
      color: Colors.white,
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.timer, color: Colors.green),
        title: Text("Status: ${currentStatus!['phase']}"),
        subtitle: Text(
          "Zone: ${currentStatus!['kanal']} • Fortschritt: ${currentStatus!['impulse_gesamt']} / ${currentStatus!['impulse_ziel']} Impulse",
        ),
        trailing: IconButton(
          icon: const Icon(Icons.stop_circle, color: Colors.red),
          onPressed: () {
            EspService.resetWaterUsage().then((_) {
               if (mounted) { // Check if the widget is still in the tree
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bewässerung gestoppt")),
                );
                _loadInitialData(); // neu laden
               }
            });
          },
        ),
      ),
    );
  }

  Widget _buildWaterUsageCard() {
    if (waterUsage == null) return Container(); // Return empty if no usage data
    return Card(
      elevation: 2,
      color: Colors.white,
      child: ExpansionTile(
        leading: const Icon(Icons.water_drop, color: Colors.blue),
        title: const Text("Wasserverbrauch"),
        children: waterUsage!.entries.map((e) {
          return ListTile(
            title: Text(e.key), // Assuming key is Zone name or similar
            trailing: Text("${e.value} ml"), // Assuming value is usage in ml
          );
        }).toList(),
      ),
    );
  }
}
