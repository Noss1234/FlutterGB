import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// ⚙️ Einstellungen: IP-Adresse, Kalibrierung, Farben, zukünftige MQTT etc.
class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _calibrationController = TextEditingController();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ipController.text = prefs.getString('esp_ip') ?? '192.168.4.1';
    _calibrationController.text = prefs.getString('calibration') ?? '840';
  }

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    final rawIp = _ipController.text.trim();
    final ip = rawIp.replaceAll(RegExp(r'^https?://'), '');
    final calibration = _calibrationController.text.trim();

    await prefs.setString('esp_ip', ip);
    await prefs.setString('calibration', calibration);

    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Einstellungen gespeichert")),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _calibrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Einstellungen"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.green[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Verbindung zum Bewässerungssystem",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildTextField("IP-Adresse des ESP", _ipController),
            const SizedBox(height: 16),
            const Text(
              "Sensor-Kalibrierung",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              "Kalibrierfaktor (Impulse/Liter)",
              _calibrationController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isSaving ? null : _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text("Speichern"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
    );
  }
}
