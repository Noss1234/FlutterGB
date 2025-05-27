import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/esp_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// ⚙️ Einstellungen: IP-Adresse, Kalibrierung, Farben, zukünftige MQTT etc.
class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _calibrationController = TextEditingController();
  final TextEditingController _httpTestEndpointController = TextEditingController(text: '/status');
  final TextEditingController _httpTestPostBodyController = TextEditingController();

  bool _isSaving = false;
  String _httpTestMethod = 'GET';
  String? _httpTestResponse;
  bool _isTestingHttp = false;

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
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();

    final rawIp = _ipController.text.trim();
    final ip = rawIp.replaceAll(RegExp(r'^https?://'), '');
    final calibration = _calibrationController.text.trim();

    await prefs.setString('esp_ip', ip);
    await prefs.setString('calibration', calibration);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Einstellungen gespeichert")),
      );
    }
  }

  Future<void> _resetWaterUsage() async {
    final confirmed = await _showConfirmationDialog(
      title: "Wasserverbrauch zurücksetzen",
      content: "Möchten Sie den gesamten Wasserverbrauch auf dem ESP wirklich zurücksetzen?",
    );
    if (!confirmed) return;

    try {
      await EspService.resetWaterUsage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wasserverbrauch erfolgreich zurückgesetzt."), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetRoutines() async {
    final confirmed = await _showConfirmationDialog(
      title: "Routinen zurücksetzen",
      content: "Möchten Sie wirklich alle Bewässerungsroutinen auf dem ESP löschen?",
    );
    if (!confirmed) return;

    try {
      await EspService.receiveRoutines([]); // Send empty list to clear
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Routinen erfolgreich zurückgesetzt."), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<bool> _showConfirmationDialog({required String title, required String content}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text("Abbrechen"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Bestätigen"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _sendHttpTestRequest() async {
    if (_httpTestEndpointController.text.isEmpty) {
      setState(() => _httpTestResponse = "Fehler: Endpoint darf nicht leer sein.");
      return;
    }
    setState(() {
      _isTestingHttp = true;
      _httpTestResponse = "Sende Anfrage...";
    });

    try {
      final baseUrl = await EspService.getBaseUrl();
      final endpoint = _httpTestEndpointController.text.startsWith('/')
          ? _httpTestEndpointController.text
          : '/${_httpTestEndpointController.text}';
      final url = Uri.parse('$baseUrl$endpoint');
      
      http.Response response;

      if (_httpTestMethod == 'GET') {
        response = await http.get(url).timeout(const Duration(seconds: 10));
      } else if (_httpTestMethod == 'POST') {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: _httpTestPostBodyController.text,
        ).timeout(const Duration(seconds: 10));
      } else {
        throw Exception("Unbekannte HTTP Methode: $_httpTestMethod");
      }
      
      if(mounted) {
        setState(() {
          _httpTestResponse = "Status: ${response.statusCode}\nBody: ${response.body}";
        });
      }

    } catch (e) {
      if(mounted) {
        setState(() {
          _httpTestResponse = "Fehler bei der Anfrage: $e";
        });
      }
    } finally {
      if(mounted) {
        setState(() => _isTestingHttp = false);
      }
    }
  }


  @override
  void dispose() {
    _ipController.dispose();
    _calibrationController.dispose();
    _httpTestEndpointController.dispose();
    _httpTestPostBodyController.dispose();
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
            _buildSectionTitle("Verbindung & Kalibrierung"),
            _buildTextField("IP-Adresse des ESP", _ipController),
            const SizedBox(height: 12),
            _buildTextField(
              "Kalibrierfaktor (Impulse/Liter)",
              _calibrationController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: const Icon(Icons.save_outlined),
              label: const Text("Einstellungen speichern"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
            const Divider(height: 30, thickness: 1),

            _buildSectionTitle("Systemaktionen"),
            _buildActionButton(
              title: "Wasserverbrauch zurücksetzen",
              icon: Icons.delete_sweep_outlined,
              onPressed: _resetWaterUsage,
              color: Colors.orange[700],
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              title: "Routinen zurücksetzen",
              icon: Icons.event_busy_outlined,
              onPressed: _resetRoutines,
              color: Colors.orange[700],
            ),
            const Divider(height: 30, thickness: 1),

            _buildSectionTitle("HTTP Testtool"),
            _buildTextField("Endpoint (z.B. /status)", _httpTestEndpointController),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _httpTestMethod,
              decoration: const InputDecoration(
                labelText: "HTTP Methode",
                border: OutlineInputBorder(),
              ),
              items: <String>['GET', 'POST'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _httpTestMethod = newValue!;
                });
              },
            ),
            if (_httpTestMethod == 'POST') ...[
              const SizedBox(height: 12),
              _buildTextField(
                "POST Body (JSON)", 
                _httpTestPostBodyController,
                maxLines: 3
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isTestingHttp ? null : _sendHttpTestRequest,
              icon: _isTestingHttp ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Icon(Icons.send_outlined),
              label: const Text("HTTP Anfrage senden"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
            if (_httpTestResponse != null) ...[
              const SizedBox(height: 16),
              Text("Antwort:", style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[400]!)
                ),
                child: SelectableText(
                  _httpTestResponse!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.green[800]),
      ),
    );
  }

  Widget _buildActionButton({required String title, required IconData icon, required VoidCallback onPressed, Color? color}) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(title),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: const TextStyle(fontSize: 15)
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}
