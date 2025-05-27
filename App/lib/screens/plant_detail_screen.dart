// screens/plant_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/esp_service.dart'; // Import EspService

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  Map<String, dynamic>? _currentStatus;
  Map<String, dynamic>? _waterUsage;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlantDetails();
  }

  Future<void> _fetchPlantDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _currentStatus = await EspService.getStatus();
      _waterUsage = await EspService.getWaterUsage();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Fehler beim Laden der Details: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStatusInfo() {
    String statusText = "Status: Nicht aktiv";
    Color statusColor = Colors.grey;

    if (_currentStatus != null &&
        _currentStatus!['kanal'].toString() == widget.plant.zone &&
        _currentStatus!['phase'] != 'idle') { // Assuming 'idle' is the phase for not active
      statusText = "Status: Wird gerade bewässert (Zone ${widget.plant.zone})";
      statusColor = Colors.green;
    } else if (_currentStatus != null) {
      // If status is available but plant's zone is not the active one or phase is idle
      statusText = "Status: Inaktiv (Zone ${widget.plant.zone})";
      statusColor = Colors.orange;
    }
    
    return _buildInfoTile(
      icon: Icons.info_outline,
      title: "Aktueller Status",
      value: statusText,
      valueColor: statusColor,
    );
  }

  Widget _buildWaterConsumptionInfo() {
    String consumptionText = "Wasserverbrauch (Zone ${widget.plant.zone}): Daten nicht verfügbar";
    if (_waterUsage != null && _waterUsage!.containsKey(widget.plant.zone)) {
      consumptionText = "Verbrauch heute (Zone ${widget.plant.zone}): ${_waterUsage![widget.plant.zone]} ml";
    }
    return _buildInfoTile(
      icon: Icons.history_toggle_off, // Changed icon for consumption
      title: "Wasserverbrauch Heute",
      value: consumptionText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme

    return Scaffold(
      appBar: AppBar( // AppBar will use appBarTheme from main.dart
        title: Text(widget.plant.name),
        // backgroundColor: Colors.green[700], // No longer needed here
        // foregroundColor: Colors.white, // No longer needed here
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPlantDetails,
            tooltip: "Daten aktualisieren",
          )
        ],
      ),
      backgroundColor: Colors.transparent, // Use transparent for shared background
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📷 Pflanzenbild
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.plant.imageUrl.isNotEmpty
                        ? widget.plant.imageUrl.startsWith("assets/")
                            ? Image.asset(
                                widget.plant.imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print("Error loading asset image ${widget.plant.imageUrl}: $error");
                                  return Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey[700]),
                                  );
                                },
                              )
                            : Image.network(
                                widget.plant.imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print("Error loading network image ${widget.plant.imageUrl}: $error");
                                  return Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey[700]),
                                  );
                                },
                              )
                        : Container( // Fallback for empty imageUrl
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Icon(Icons.local_florist_outlined, size: 80, color: Colors.grey[500])),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 🌿 Kategorien & Beschreibung
                  // 🌿 Kategorien & Beschreibung
                  Card( // Wrap description and category in a card
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            "Details", // Section title
                            style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.plant.category,
                            style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700], fontSize: 15), // Adjusted style
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.plant.description.isNotEmpty ? widget.plant.description : "Keine Beschreibung verfügbar.",
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  ),
                  const SizedBox(height: 16),

                  // 💧 Wasserbedarf & andere Attribute
                  _buildInfoCard(
                    title: "Attribute",
                    children: [
                      _buildInfoTile(
                        icon: Icons.opacity_outlined,
                        title: "Wasserbedarf",
                        value: "${widget.plant.waterNeed} ml pro Tag",
                        theme: theme,
                      ),
                      _buildInfoTile(
                        icon: Icons.science_outlined,
                        title: "Optimaler pH-Wert",
                        value: widget.plant.idealPH.toStringAsFixed(1),
                        theme: theme,
                      ),
                      _buildInfoTile(
                        icon: Icons.public_outlined,
                        title: "Bewässerungszone",
                        value: widget.plant.zone.isNotEmpty ? "Zone ${widget.plant.zone}" : "Nicht zugewiesen",
                        theme: theme,
                      ),
                    ],
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  
                  // ✨ Status & Verbrauch in einem Card
                  _buildInfoCard(
                    title: "Live Daten",
                    children: [
                      _buildStatusInfo(), // Already uses _buildInfoTile
                      _buildWaterConsumptionInfo(), // Already uses _buildInfoTile
                    ],
                    theme: theme,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon( // Button will use elevatedButtonTheme
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bearbeiten-Funktion noch nicht implementiert.')),
                        );
                      },
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text("Pflanze bearbeiten"),
                      // style is inherited from theme
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children, required ThemeData theme}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required ThemeData theme, // Pass theme
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), // Increased padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Center align items
        children: [
          Icon(icon, color: theme.iconTheme.color?.withOpacity(0.8), size: 22), // Use themed icon color
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
          Expanded( 
            flex: 1, // Adjusted flex for better balance
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, color: valueColor ?? theme.textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }
}
