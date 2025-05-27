import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../services/esp_service.dart';
import '../models/plant.dart';
import '../widgets/plant_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _isConnected = false;
  Map<String, dynamic>? _currentStatus;
  Map<String, dynamic>? _waterUsage;
  String _espIp = "...";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      _isConnected = await EspService.ping();
      _espIp = await EspService.getBaseUrl().then((url) => url.replaceFirst('http://', ''));

      if (_isConnected) {
        await Provider.of<PlantProvider>(context, listen: false).fetchPlants();
        _currentStatus = await EspService.getStatus();
        _waterUsage = await EspService.getWaterUsage();
      } else {
        throw Exception("Keine Verbindung zum ESP");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler beim Laden der Daten: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = Colors.green,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 30, color: iconColor),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildWaterUsageTile() {
    String summary = "Keine Daten";
    if (_waterUsage != null) {
      double total = 0;
      _waterUsage!.values.forEach((usage) {
        if (usage is num) total += usage;
      });
      summary = "Gesamt: ${total.toStringAsFixed(1)} ml";
    }

    return _buildDashboardTile(
      icon: Icons.opacity_outlined,
      iconColor: Colors.blue[400]!,
      title: "Wasserverbrauch",
      subtitle: summary,
      onTap: () {
        // Optional: Navigate to a detailed water usage screen
        print("Water usage tile tapped");
      },
    );
  }

  Widget _buildCurrentStatusTile() {
    String statusText = "Unbekannt";
    String detailText = "Keine aktive Bewässerung";
    IconData statusIcon = Icons.info_outline;
    Color iconColor = Colors.grey;

    if (_currentStatus != null) {
      final phase = _currentStatus!['phase'] ?? 'idle';
      final kanal = _currentStatus!['kanal'] ?? '-';
      if (phase != 'idle') {
        statusText = "Aktiv: Zone $kanal";
        detailText = "Phase: $phase";
        statusIcon = Icons.water_damage_outlined; // More specific icon
        iconColor = Colors.green[600]!;
      } else {
        statusText = "System Bereit";
        detailText = "Keine Zone aktiv";
        statusIcon = Icons.power_settings_new_outlined;
        iconColor = Colors.orange[600]!;
      }
    }

    return _buildDashboardTile(
      icon: statusIcon,
      iconColor: iconColor,
      title: statusText,
      subtitle: detailText,
    );
  }
  
  Widget _buildConnectionInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isConnected ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isConnected ? Icons.check_circle_outline : Icons.error_outline,
            color: _isConnected ? Colors.green[700] : Colors.orange[700],
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? "Verbunden mit ESP ($_espIp)" : "Nicht verbunden ($_espIp)",
            style: TextStyle(
              color: _isConnected ? Colors.green[800] : Colors.orange[800],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final plants = Provider.of<PlantProvider>(context).plants;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Light neutral background
      appBar: AppBar(
        title: const Text("MyGarden Dashboard"),
        backgroundColor: Colors.green[600], // Softer green
        elevation: 1.0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.wifi,
              color: _isConnected ? Colors.white : Colors.orangeAccent[100],
            ),
            tooltip: _isConnected ? "Verbunden" : "Nicht verbunden",
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green[600]))
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: Colors.green[600]!,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildConnectionInfoBar()),
                  SliverPadding(
                    padding: const EdgeInsets.all(12.0),
                    sliver: SliverGrid.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _buildDashboardTile(
                          icon: Icons.wb_sunny_outlined,
                          iconColor: Colors.orangeAccent,
                          title: "Wetter",
                          subtitle: "Sonnig, 23°C", // Placeholder
                          onTap: () => print("Weather tile tapped"),
                        ),
                        _buildCurrentStatusTile(),
                        _buildWaterUsageTile(),
                        // Add more tiles here if needed
                         _buildDashboardTile( // Example for a new tile
                          icon: Icons.calendar_today_outlined,
                          iconColor: Colors.purple[400]!,
                          title: "Routinen",
                          subtitle: "3 aktiv", // Placeholder
                          onTap: () {
                             print('Navigate to Routines Screen');
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Routinen screen not yet implemented')),
                             );
                          }
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        "🌱 Meine Pflanzen",
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.green[800]),
                      ),
                    ),
                  ),
                  plants.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30.0),
                              child: Text("Keine Pflanzen hinzugefügt.", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                              child: PlantCard(plant: plants[index]),
                            ),
                            childCount: plants.length,
                          ),
                        ),
                  SliverFillRemaining( // Pushes button to bottom if content is short
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.settings_remote_outlined, color: Colors.white),
                          label: const Text("Manuelle Zonensteuerung", style: TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[500],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 50), // Full-width
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            elevation: 2,
                          ),
                          onPressed: () {
                            // TODO: Navigate to ZoneOverviewScreen (manual_control_screen)
                            // For now, using the old Routines placeholder action:
                            print('Navigate to Manual Control Screen');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Manuelle Steuerung noch nicht implementiert')),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
