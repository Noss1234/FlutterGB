import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';
import 'package:flutter/foundation.dart';

class EspService {
  /// Holt die aktuelle Base-URL aus den App-Einstellungen
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('esp_ip') ?? '192.168.4.1';
    return 'http://$ip';
  }

  /// Pflanzen aus ESP laden
  static Future<List<Plant>> getPlantsFromESP() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/routines');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Plant.fromJson(json)).toList();
    } else {
      throw Exception('Fehler beim Laden der Pflanzen vom ESP');
    }
  }

  /// Manuelle Bewässerung starten
  static Future<void> startManualWatering(int kanal, int wassermenge) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/start_manual');
    final body = jsonEncode({
      'kanal': kanal,
      'wassermenge': wassermenge,
    });
    final headers = {'Content-Type': 'application/json'};
    final response = await http.post(url, body: body, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Start der manuellen Bewässerung fehlgeschlagen');
    }
  }

  /// Aktuellen Status vom ESP abfragen
  static Future<Map<String, dynamic>> getStatus() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/current_routine');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Status konnte nicht vom ESP geladen werden');
    }
  }

  /// Wasserverbrauch laden
  static Future<Map<String, dynamic>> getWaterUsage() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/water_usage');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Wasserverbrauch konnte nicht geladen werden');
    }
  }

  /// Aktuellen Impulszähler vom Flusssensor abfragen
  static Future<int> getPulseCount() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/pulse_count');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return int.parse(response.body.trim());
    } else {
      throw Exception('Fehler beim Abrufen des Impulszählers');
    }
  }

  /// Wasserverbrauch zurücksetzen
  static Future<void> resetWaterUsage() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/reset_water_usage');
    final response = await http.post(url);

    if (response.statusCode != 200) {
      throw Exception('Zurücksetzen des Wasserverbrauchs fehlgeschlagen');
    }
  }

/// Verbindung testen
static Future<bool> ping() async {
  try {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/status');
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    debugPrint('📡 PING: $url → Status ${response.statusCode}');
    debugPrint('📦 Response: ${response.body}');
    return response.statusCode == 200;
  } catch (e, stacktrace) {
    debugPrint('❌ Ping fehlgeschlagen: $e');
    debugPrint('📛 Stacktrace: $stacktrace');
    return false;
  }
  // Removed extra closing brace here that was causing methods to be outside the class

  /// Manuelle Bewässerung stoppen
  static Future<void> stopManualWatering(int kanal) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/stop_manual');
    final body = jsonEncode({'kanal': kanal});
    final headers = {'Content-Type': 'application/json'};
    final response = await http.post(url, body: body, headers: headers);

    if (response.statusCode != 200) {
      // Consider parsing response.body if the ESP sends a specific error message
      throw Exception('Stoppen der manuellen Bewässerung für Kanal $kanal fehlgeschlagen. Status: ${response.statusCode}');
    }
  }

  /// Routinen an den ESP senden
  static Future<void> receiveRoutines(List<Map<String, dynamic>> routinesData) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/receive_routines');
    final body = jsonEncode(routinesData);
    final headers = {'Content-Type': 'application/json'};
    final response = await http.post(url, body: body, headers: headers);

    if (response.statusCode != 200) {
      // Consider parsing response.body for error details
      throw Exception('Senden der Routinen fehlgeschlagen. Status: ${response.statusCode}');
    }
  }
}
// Removed extra closing brace here
