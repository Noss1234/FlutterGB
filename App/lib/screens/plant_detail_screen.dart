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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plant.name),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPlantDetails,
            tooltip: "Daten aktualisieren",
          )
        ],
      ),
      backgroundColor: Colors.green[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                  Text(
                    widget.plant.category,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    widget.plant.description.isNotEmpty ? widget.plant.description : "Keine Beschreibung verfügbar.",
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  // 💧 Wasserbedarf
                  _buildInfoTile(
                    icon: Icons.opacity,
                    title: "Wasserbedarf",
                    value: "${widget.plant.waterNeed} ml pro Tag",
                  ),

                  // 🌡️ pH-Wert
                  _buildInfoTile(
                    icon: Icons.science_outlined, // Changed icon
                    title: "Optimaler pH-Wert",
                    value: widget.plant.idealPH.toStringAsFixed(1),
                  ),

                  // 🌍 Zugeordnete Zone
                  _buildInfoTile(
                    icon: Icons.public_outlined, // Changed icon
                    title: "Bewässerungszone",
                    value: widget.plant.zone.isNotEmpty ? "Zone ${widget.plant.zone}" : "Nicht zugewiesen",
                  ),
                  
                  // ✨ Status & Verbrauch
                  const SizedBox(height: 8),
                  _buildStatusInfo(),
                  _buildWaterConsumptionInfo(),
                  const SizedBox(height: 8),


                  // (Zukünftige Buttons z. B. Bearbeiten, Zeitplan ändern etc.)
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement edit feature for the plant
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bearbeiten-Funktion noch nicht implementiert.')),
                        );
                      },
                      icon: const Icon(Icons.edit_note_outlined), // Changed icon
                      label: const Text("Pflanze bearbeiten"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor, // Optional color for the value text
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green[700], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded( // Allow value to wrap
            flex: 2, // Give more space to value
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 15, color: valueColor ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
