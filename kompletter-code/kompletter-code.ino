// -----------------------------------------------------------------------------
// HYBRID-PORTIERUNG: NodeMCU (ESP8266) Code nach Raspberry Pi Pico W (RP2040)
// -----------------------------------------------------------------------------
// Ziel: Kombination der detaillierten Bewässerungslogik meiner Version mit
//       den modernen Infrastruktur-Lösungen (LittleFS, HTTP-OTA, echter Telnet)
//       der anderen KI-Portierung.
// -----------------------------------------------------------------------------

#include <Arduino.h>

// --- Bibliotheken für RP2040 ---
// Installation über den Arduino IDE Bibliotheksverwalter ist notwendig.
#include <ArduinoJson.h>     // ArduinoJson (Benoît Blanchon)
#include <WiFi.h>            // Standard WiFi-Bibliothek für RP2040
#include <WebServer.h>       // WebServer-Bibliothek für RP2040 (NICHT ESP8266WebServer.h!)
#include <WiFiManager.h>     // WiFiManager (tzapu) - Wichtig: RP2040-kompatible Version
#include <WiFiUdp.h>         // Für NTPClient
#include <NTPClient.h>       // NTPClient (Fabrice Weinberg)
#include <ESPmDNS.h>         // mDNS für RP2040 (NICHT ESP8266mDNS.h!)
#include <LittleFS.h>        // Dateisystem für RP2040 (im RP2040-Core enthalten)
#include <Update.h>          // Für HTTP-basiertes OTA-Update (im RP2040-Core enthalten)

// --- Telnet-Server Implementierung ---
// Ersetzt meine vorherige Serial-Proxy-Lösung durch einen echten Telnet-Server.
// Der API-Aufruf TelnetStream.print/println/printf bleibt erhalten.
WiFiServer telnetServer(23); // Telnet-Server auf Port 23
WiFiClient telnetClient;     // Erster Client, der verbunden ist

class TelnetStream_Class {
public:
  void begin() {
    telnetServer.begin(); // Startet den Telnet-Server
    Serial.println("Telnet-Server gestartet auf Port 23.");
  }
  // Überladungen für print/println/printf, die auf den verbundenen Telnet-Client (und Serial) schreiben
  template <typename T> void print(T arg) { 
    if (telnetClient && telnetClient.connected()) telnetClient.print(arg);
    Serial.print(arg);
  }
  template <typename T> void println(T arg) {
    if (telnetClient && telnetClient.connected()) telnetClient.println(arg);
    Serial.println(arg);
  }
  template <typename ... Args> void printf(const char* format, Args ... args) {
    char buffer[256]; // Puffer für formatierte Ausgabe
    int len = snprintf(buffer, sizeof(buffer), format, args...);
    if (telnetClient && telnetClient.connected()) telnetClient.print(buffer);
    Serial.print(buffer);
  }
  // Weitere Überladungen nach Bedarf.
  void handleClient() { // Muss im loop() aufgerufen werden
    if (!telnetClient || !telnetClient.connected()) {
      telnetClient = telnetServer.available();
    }
  }
};

TelnetStream_Class TelnetStream; // Instanz der Telnet-Implementierung

WebServer server(80); // Webserver-Instanz auf Port 80

#define MAX_ROUTINES 28
#define JSON_CAPACITY 300       // Standardkapazität für einzelne JSON-Dokumente
                                // Für Routinen-Arrays wird eine größere Kapazität berechnet.
#define AUS HIGH                // Relais-Steuerung: 'AUS' (inaktiv, HIGH für Active-Low-Relais)
#define EIN LOW                 // Relais-Steuerung: 'EIN' (aktiv, LOW für Active-Low-Relais)

// --- PIN-ZUORDNUNG FÜR RASPBERRY PI PICO W ---
// Verwenden Sie eine Kombination aus beschreibenden Namen und Zuordnungen zum 'Kanal'-Array.
// WICHTIG: Prüfen Sie die tatsächlichen GPIO-Nummern auf Ihrem Board!
#define RELAY_FERTILIZER_PIN    2    // GPIO2 (Beispiel)
#define RELAY_MAIN_VALVE_PIN    3    // GPIO3 (Beispiel)
#define RELAY_ZONE1_PIN         4    // GPIO4 (Beispiel)
#define RELAY_ZONE2_PIN         5    // GPIO5 (Beispiel)
#define RELAY_ZONE3_PIN         6    // GPIO6 (Beispiel)
#define RELAY_ZONE4_PIN         7    // GPIO7 (Beispiel)
#define PUMP_PIN                8    // GPIO8 (Beispiel)
#define FLOW_SENSOR_PIN         9    // GPIO9 (Beispiel)

const int MAX_KANAELE = 8; // Kann mehr sein, wenn mehr Relais genutzt werden
// Das Kanal-Array wird nun mit den tatsächlich zugewiesenen GPIO-Nummern gefüllt.
// Die Indizes dieses Arrays entsprechen den logischen "Kanal"-Nummern in den Routinen.
const int Kanal[MAX_KANAELE] = {
    RELAY_MAIN_VALVE_PIN,   // Kanal 0 (Hauptventil, darf nicht als Zielzone gewählt werden)
    RELAY_ZONE1_PIN,        // Kanal 1 (Zone 1)
    RELAY_FERTILIZER_PIN,   // Kanal 2 (Düngerventil, darf nicht als Zielzone gewählt werden)
    RELAY_ZONE2_PIN,        // Kanal 3 (Zone 2)
    RELAY_ZONE3_PIN,        // Kanal 4 (Zone 3)
    RELAY_ZONE4_PIN,        // Kanal 5 (Zone 4)
    PUMP_PIN,               // Kanal 6 (Pumpe, darf nicht als Zielzone gewählt werden)
    LED_BUILTIN             // Kanal 7 (Pico W LED, kann zu Debug-Zwecken verwendet werden)
};


#define WIFI_CHECK_INTERVAL 60000    // 60 Sekunden Intervall für den WLAN-Verbindungscheck
#define NTP_RETRY_INTERVAL 20        // Anzahl der NTP-Versuche beim Start
#define WATERING_TIMEOUT 60000       // 60 Sekunden globales Timeout für eine aktive Bewässerungsphase

// Logische Indizes für spezielle Kanäle im 'Kanal'-Array
#define MAIN_VALVE_CHANNEL 0    // Index des Hauptventils im Kanal-Array
#define FERTILIZER_CHANNEL 2    // Index des Düngerventils im Kanal-Array

// --- Dateisystem-Dateinamen ---
const char* ROUTINES_FILE = "/routines.json"; // JSON-Format für Routinen
const char* USAGE_FILE    = "/usage.json";    // JSON-Format für Wasserverbrauch

// ANPASSEN: STANDARD-WLAN-ZUGANGSDATEN. WiFiManager nutzt diese als Fallback.
const char* defaultSSID = "YOUR_WIFI_SSID";     // <- BITTE HIER ANPASSEN!
const char* defaultPassword = "YOUR_WIFI_PASSWORD"; // <- BITTE HIER ANPASSEN!

volatile unsigned long wasser_verbraucht[MAX_KANAELE] = {0}; // Speichert kumulierten Wasserverbrauch pro Kanal (Impulse)

unsigned long lastWifiCheck = 0;
unsigned long lastTimePrint = 0;
int ntpRetryCount = 0;
unsigned long wateringStartTime = 0; // Merkt sich den Startzeitpunkt der aktuellen Bewässerungsphase (für Timeout)

// Struktur zur Speicherung einer Bewässerungsroutine
struct BewaesserungsRoutine {
  int kanal;        // Welcher Kanal (Index im Kanal-Array) bewässert werden soll
  int duengen;      // Flag: 0 = normale Bewässerung, 1 = Düngung (mit Pumpe und Düngerventil)
  int wassermenge;  // Zielmenge in Milliliter (ml)
  int tag;          // Wochentag (0=Sonntag, 6=Samstag, -1 für manuelle/nicht-zeitbasierte Routinen)
  int stunde;       // Stunde (0-23)
  int minute;       // Minute (0-59)
  bool isEnabled;   // Ist diese Routine aktiv (soll sie ausgeführt werden)?
};

BewaesserungsRoutine routinen[MAX_ROUTINES]; // Array zur Speicherung aller definierten Routinen
int routinen_count = 0;                      // Aktuelle Anzahl der gespeicherten Routinen

// NTP Zeit-Client Setup
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "0.de.pool.ntp.org", 3600, 60000); // NTP-Server, GMT+1 (3600s Offset), Update-Intervall 60s

struct ZeitInfo {
    int tag;
    int stunde;
    int minute;
};

ZeitInfo aktualisiereZeit() {
    timeClient.update();
    ZeitInfo zeitInfo;
    zeitInfo.tag = timeClient.getDay();      // 0 = Sonntag, 6 = Samstag
    zeitInfo.stunde = timeClient.getHours(); // 0 - 23
    zeitInfo.minute = timeClient.getMinutes(); // 0 - 59
    return zeitInfo;
}

// ***** Flow-Sensor Konfiguration *****
// ANPASSEN: Kalibrierfaktor Ihres Flow-Sensors (Impulse pro Liter).
unsigned int calibrationFaktor = 840;      // Beispielwert: 840 Impulse/Liter
volatile unsigned long impulse_count = 0;   // Aktueller Impulszähler (in ISR geändert, daher 'volatile')
volatile unsigned long ziel_impulse = 0;    // Ziel-Impulse für den aktuellen Vorgang
volatile int aktueller_kanal = -1;          // Aktuell vom System geöffneter Kanal (-1 wenn keiner offen)
volatile bool kanal_eingeschaltet = false;  // Flag: Ist aktuell ein Kanal aktiv und wird bewässert?

// Steuerungsstatus für aktive Bewässerungsroutinen
enum RoutinePhase { PHASE_INAKTIV, PHASE_DUENGEN, PHASE_BEWAESSERN };
volatile RoutinePhase currentPhase = PHASE_INAKTIV; // Aktuelle Phase des Bewässerungsprozesses
volatile bool activeRoutine = false;                // Flag: Läuft aktuell eine Bewässerungsroutine?
volatile bool flushPending = false;                 // Flag: Sollte eine Spülbewässerung nach der Düngung erfolgen?
int currentZone = -1;                               // Kanal-Index der Zone, die aktuell bewässert wird
int currentVolume = 0;                              // Ziel-Volumen der aktuellen Phase (ml)

// Vorwärtsdeklarationen für HTTP-Handler
void handleGetWaterUsage();
void handleResetWaterUsage();

// --- Dateisystem-Funktionen (LittleFS) ---

// Lese Routinen aus LittleFS
void loadRoutinesFromLittleFS() {
  if (!LittleFS.exists(ROUTINES_FILE)) {
    TelnetStream.println("Routinen-Datei nicht gefunden. Starte mit leeren Routinen.");
    routinen_count = 0;
    return;
  }
  File file = LittleFS.open(ROUTINES_FILE, "r");
  if (!file) {
    TelnetStream.println("Fehler beim Öffnen der Routinen-Datei zum Lesen.");
    return;
  }

  // Kapazität für StaticJsonDocument, um alle Routinen zu halten
  StaticJsonDocument<JSON_CAPACITY * MAX_ROUTINES> doc; // Vorsicht: Größe anpassen
  DeserializationError error = deserializeJson(doc, file);
  file.close();

  if (error) {
    TelnetStream.printf("Fehler beim Parsen der Routinen-JSON-Datei: %s\n", error.c_str());
    return;
  }

  routinen_count = 0;
  JsonArray array = doc.as<JsonArray>();
  for (JsonObject obj : array) {
    if (routinen_count >= MAX_ROUTINES) {
      TelnetStream.println("WARNUNG: MAX_ROUTINES erreicht beim Laden, weitere ignoriert.");
      break;
    }
    routinen[routinen_count].kanal = obj["kanal"].as<int>();
    routinen[routinen_count].duengen = obj["duengen"].as<int>();
    routinen[routinen_count].wassermenge = obj["wassermenge"].as<int>();
    routinen[routinen_count].tag = obj["tag"].as<int>();
    routinen[routinen_count].stunde = obj["stunde"].as<int>();
    routinen[routinen_count].minute = obj["minute"].as<int>();
    routinen[routinen_count].isEnabled = obj["isEnabled"].as<bool>();
    routinen_count++;
  }
  TelnetStream.printf("%d Routinen aus LittleFS geladen.\n", routinen_count);
}

// Speichere Routinen in LittleFS
void saveRoutinesToLittleFS() {
  File file = LittleFS.open(ROUTINES_FILE, "w");
  if (!file) {
    TelnetStream.println("Fehler beim Öffnen der Routinen-Datei zum Schreiben.");
    return;
  }

  StaticJsonDocument<JSON_CAPACITY * MAX_ROUTINES> doc; // Kapazität anpassen
  JsonArray array = doc.to<JsonArray>();
  for (int i = 0; i < routinen_count; i++) {
    JsonObject obj = array.createNestedObject();
    obj["kanal"] = routinen[i].kanal;
    obj["duengen"] = routinen[i].duengen;
    obj["wassermenge"] = routinen[i].wassermenge;
    obj["tag"] = routinen[i].tag;
    obj["stunde"] = routinen[i].stunde;
    obj["minute"] = routinen[i].minute;
    obj["isEnabled"] = routinen[i].isEnabled;
  }

  if (serializeJson(doc, file) == 0) {
    TelnetStream.println("Fehler beim Schreiben der Routinen-JSON-Datei.");
  }
  file.close();
  TelnetStream.println("Routinen in LittleFS gespeichert.");
}

// Wasserverbrauch persistieren
void loadWasserVerbrauchtFromLittleFS() {
  if (!LittleFS.exists(USAGE_FILE)) {
    TelnetStream.println("Wasserverbrauchs-Datei nicht gefunden. Starte mit 0.");
    for (int i = 0; i < MAX_KANAELE; i++) wasser_verbraucht[i] = 0;
    return;
  }
  File file = LittleFS.open(USAGE_FILE, "r");
  if (!file) {
    TelnetStream.println("Fehler beim Öffnen der Wasserverbrauchs-Datei zum Lesen.");
    return;
  }

  StaticJsonDocument<512> doc; // Größe anpassen, um alle Kanäle zu speichern
  DeserializationError error = deserializeJson(doc, file);
  file.close();

  if (error) {
    TelnetStream.printf("Fehler beim Parsen der Wasserverbrauchs-JSON-Datei: %s\n", error.c_str());
    return;
  }

  for (int i = 0; i < MAX_KANAELE; i++) {
    wasser_verbraucht[i] = doc[String("kanal_") + i].as<unsigned long>();
  }
  TelnetStream.println("Wasserverbrauch aus LittleFS geladen.");
}

void saveWasserVerbrauchtToLittleFS() {
  File file = LittleFS.open(USAGE_FILE, "w");
  if (!file) {
    TelnetStream.println("Fehler beim Öffnen der Wasserverbrauchs-Datei zum Schreiben.");
    return;
  }

  StaticJsonDocument<512> doc; // Größe anpassen
  for (int i = 0; i < MAX_KANAELE; i++) {
    doc[String("kanal_") + i] = wasser_verbraucht[i];
  }

  if (serializeJson(doc, file) == 0) {
    TelnetStream.println("Fehler beim Schreiben der Wasserverbrauchs-JSON-Datei.");
  }
  file.close();
  TelnetStream.println("Wasserverbrauch in LittleFS gespeichert.");
}

// Initialisiert alle Ventil-Kanäle und die Pumpe als OUTPUTs und setzt sie auf den AUS-Zustand.
void init_kanaele() {
    for (int i = 0; i < MAX_KANAELE; i++) {
        pinMode(Kanal[i], OUTPUT); // Jetzt mit den GP-Nummern befüllt
        digitalWrite(Kanal[i], AUS); // Alle Relais auf AUS (Active-Low: HIGH)
    }
    // Pumpe wird separat behandelt (im Kanal array aber bei Bedarf separat geschalten)
    pinMode(PUMP_PIN, OUTPUT);
    digitalWrite(PUMP_PIN, LOW); // Pumpe zum Start ausgeschaltet.

    pinMode(FLOW_SENSOR_PIN, INPUT_PULLUP);
}

// Interrupt Service Routine (ISR) für den Flusssensor-Impuls.
// IRAM_ATTR: Wichtig für RP2040, um die Funktion in RAM zu legen für schnelle Ausführung.
void IRAM_ATTR fluss_sensor_ISR() {
    impulse_count++; 
    
    if (kanal_eingeschaltet && aktueller_kanal != -1 && impulse_count >= ziel_impulse) {
        detachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN));
        
        wasser_verbraucht[aktueller_kanal] += impulse_count;
        saveWasserVerbrauchtToLittleFS(); // Wichtig: Status speichern!

        if (currentPhase == PHASE_DUENGEN) {
            digitalWrite(Kanal[aktueller_kanal], AUS);
            digitalWrite(Kanal[FERTILIZER_CHANNEL], AUS);
            digitalWrite(PUMP_PIN, LOW);
            
            kanal_eingeschaltet = false;
            aktueller_kanal = -1;
            
            flushPending = true;
            TelnetStream.printf("Düngungsphase für Kanal %d abgeschlossen. Spülung ausstehend.\n", currentZone);
        } else if (currentPhase == PHASE_BEWAESSERN) {
            digitalWrite(Kanal[aktueller_kanal], AUS);
            digitalWrite(Kanal[MAIN_VALVE_CHANNEL], AUS);
            
            kanal_eingeschaltet = false;
            aktueller_kanal = -1;
            activeRoutine = false;
            currentPhase = PHASE_INAKTIV;
            TelnetStream.printf("Bewässerungsphase für Kanal %d abgeschlossen.\n", currentZone);
        }
    }
}

// Schaltet einen Bewässerungskanal für eine bestimmte Wassermenge ein.
int wasserEinschalten(int kanal_index, int milliLiter) {
    if (kanal_index < 0 || kanal_index >= MAX_KANAELE) {
        TelnetStream.println("Fehler: ungültiger Kanalindex beim Einschalten.");
        return 1;
    }
    
    // Hauptventil 1 Sekunde vor dem Zielkanal öffnen (falls der Kanal nicht selbst das Haupt- oder Düngerventil ist).
    // DIES IST EIN BLOCKIERENDES DELAY! (wie im Original zur Beibehaltung der Funktionalität).
    if (Kanal[kanal_index] != Kanal[MAIN_VALVE_CHANNEL] && Kanal[kanal_index] != Kanal[FERTILIZER_CHANNEL]) {
        digitalWrite(Kanal[MAIN_VALVE_CHANNEL], EIN);
        TelnetStream.println("Hauptventil geöffnet");
        delay(1000);
    }
    digitalWrite(PUMP_PIN, HIGH); // Pumpe einschalten
    TelnetStream.println("Pumpe eingeschaltet");


    ziel_impulse = (milliLiter * calibrationFaktor) / 1000;
    impulse_count = 0;

    aktueller_kanal = kanal_index;
    kanal_eingeschaltet = true;
    wateringStartTime = millis();

    attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), fluss_sensor_ISR, RISING);
    digitalWrite(Kanal[kanal_index], EIN);
    TelnetStream.printf("Kanal %d eingeschaltet für %d ml. Ziel: %lu Impulse.\n", kanal_index, milliLiter, ziel_impulse);
    return 0;
}

// Schaltet einen spezifischen Kanal manuell aus (nicht Teil des Haupt-Workflows).
int ausschalten(int kanal_index) {
    if (kanal_index < 0 || kanal_index >= MAX_KANAELE) {
        TelnetStream.println("Fehler: ungültiger Kanalindex beim Ausschalten.");
        return 1;
    }
    digitalWrite(Kanal[kanal_index], AUS);
    aktueller_kanal = -1;
    kanal_eingeschaltet = false;
    ziel_impulse = 0;
    TelnetStream.printf("Kanal %d ausgeschaltet\n", kanal_index);
    return 0;
}

// --- Routinen-Warteschlange (Queue) Management ---
struct BewaesserungsQueueItem {
    BewaesserungsRoutine routine;
};
BewaesserungsQueueItem bewaesserungsQueue[MAX_ROUTINES + 2];
int queueCount = 0;

void addToQueue(BewaesserungsRoutine routine) {
    if (queueCount < (MAX_ROUTINES + 2)) {
        bewaesserungsQueue[queueCount++] = {routine};
        TelnetStream.println("Routine zur Warteschlange hinzugefügt.");
    } else {
        TelnetStream.println("Warteschlange ist voll. Routine wurde verworfen.");
    }
}

void checkAndQueueRoutines() {
  if (activeRoutine) return;

  ZeitInfo aktuelleZeit = aktualisiereZeit();
  static int lastCheckedMinute = -1; 

  if (aktuelleZeit.minute != lastCheckedMinute) {
    for (int i = 0; i < routinen_count; i++) {
        BewaesserungsRoutine routine = routinen[i];
        if (routine.isEnabled && 
            routine.tag == aktuelleZeit.tag &&
            routine.stunde == aktuelleZeit.stunde &&
            routine.minute == aktuelleZeit.minute) {
          TelnetStream.printf("Fällige Routine gefunden: Kanal %d, Menge %dml, Tag %d, Zeit %02d:%02d\n",
                                routine.kanal, routine.wassermenge, routine.tag, routine.stunde, routine.minute);
          addToQueue(routine);
        }
    }
    lastCheckedMinute = aktuelleZeit.minute;
  }
}

void processQueue() {
  if (queueCount > 0 && !activeRoutine) {
    BewaesserungsRoutine routine = bewaesserungsQueue[0].routine;
    
    // Gültigkeitsprüfung des Kanals: Haupt- oder Düngerventil dürfen keine direkten "Zielkanäle" sein.
    // Pumpe darf auch nicht als Zielkanal sein.
    if (Kanal[routine.kanal] == Kanal[MAIN_VALVE_CHANNEL] || Kanal[routine.kanal] == Kanal[FERTILIZER_CHANNEL] || Kanal[routine.kanal] == Kanal[6]) {
      TelnetStream.printf("WARNUNG: Routine mit ungültigem Zielkanal %d übersprungen.\n", routine.kanal);
      for (int i = 1; i < queueCount; i++) { bewaesserungsQueue[i - 1] = bewaesserungsQueue[i]; }
      queueCount--;
      return;
    }

    for (int i = 1; i < queueCount; i++) { bewaesserungsQueue[i - 1] = bewaesserungsQueue[i]; }
    queueCount--;
    
    activeRoutine = true;
    currentZone = routine.kanal;
    currentVolume = routine.wassermenge;
    impulse_count = 0;

    if (routine.duengen == 1) {
      currentPhase = PHASE_DUENGEN;
      digitalWrite(Kanal[MAIN_VALVE_CHANNEL], EIN);
      TelnetStream.println("Hauptventil geöffnet (Düngungsvorbereitung)");
      delay(1000); // BLOCKIERENDES DELAY!

      digitalWrite(Kanal[FERTILIZER_CHANNEL], EIN);
      TelnetStream.println("Düngerventil geöffnet");
      digitalWrite(PUMP_PIN, HIGH);
      TelnetStream.println("Pumpe eingeschaltet");

      ziel_impulse = (routine.wassermenge * calibrationFaktor) / 1000;
      aktueller_kanal = routine.kanal;
      kanal_eingeschaltet = true;
      wateringStartTime = millis();
      attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), fluss_sensor_ISR, RISING);
      digitalWrite(Kanal[routine.kanal], EIN);
      TelnetStream.printf("Kanal %d eingeschaltet für %d ml (Düngung).\n", routine.kanal, routine.wassermenge);
    } else {
      currentPhase = PHASE_BEWAESSERN;
      int result = wasserEinschalten(routine.kanal, routine.wassermenge);
      if (result != 0) {
        TelnetStream.println("Fehler beim Starten der normalen Bewässerung aus der Queue.");
        activeRoutine = false;
        currentPhase = PHASE_INAKTIV;
      }
    }
  }
}

void checkWateringTimeout() {
    if (activeRoutine && kanal_eingeschaltet && (millis() - wateringStartTime > WATERING_TIMEOUT)) {
        TelnetStream.println("Bewaesserungs-Timeout erreicht. Breche aktuelle Routine ab.");
        detachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN));
        
        wasser_verbraucht[currentZone] += impulse_count; 
        saveWasserVerbrauchtToLittleFS();

        if (currentPhase == PHASE_DUENGEN) {
            digitalWrite(Kanal[currentZone], AUS);
            digitalWrite(Kanal[FERTILIZER_CHANNEL], AUS);
            digitalWrite(PUMP_PIN, LOW);
            digitalWrite(Kanal[MAIN_VALVE_CHANNEL], AUS);
        } else if (currentPhase == PHASE_BEWAESSERN) {
            digitalWrite(Kanal[currentZone], AUS);
            digitalWrite(Kanal[MAIN_VALVE_CHANNEL], AUS);
            digitalWrite(PUMP_PIN, LOW);
        }
        
        kanal_eingeschaltet = false;
        aktueller_kanal = -1;
        activeRoutine = false;
        currentPhase = PHASE_INAKTIV;
        flushPending = false;
        impulse_count = 0;
        
        TelnetStream.println("Routine nach Timeout beendet.");
    }
}

// --- HTTP-Server Handler Funktionen ---
void handleRoot() {
    server.send(200, "text/plain", "RP2040 Bewaesserungssystem ist online.");
    TelnetStream.println("Root-Seite aufgerufen.");
}

void handleNotFound() {
    server.send(404, "text/plain", "404: Seite nicht gefunden.");
    TelnetStream.println("Fehler 404: Seite nicht gefunden.");
}

void handleReceiveRoutines() {
    if (!server.hasArg("plain")) {
        server.send(400, "text/plain", "400: Ungueltige Anfrage - kein 'plain' Argument im HTTP-Body.");
        TelnetStream.println("handleReceiveRoutines: Ungültige Anfrage - kein JSON-Körper.");
        return;
    }
    String json = server.arg("plain");
    StaticJsonDocument<JSON_CAPACITY * MAX_ROUTINES> doc; // Kapazität anpassen
    
    DeserializationError error = deserializeJson(doc, json);
    if (error) {
        server.send(400, "application/json", "{\"error\":\"Ungueltiges JSON Format\",\"details\":\"" + String(error.c_str()) + "\"}");
        TelnetStream.printf("handleReceiveRoutines: Fehler beim Parsen des JSON: %s\n", error.c_str());
        return;
    }
    
    routinen_count = 0; 
    JsonArray array = doc.as<JsonArray>();
    if (array.isNull()) {
        server.send(400, "application/json", "{\"error\":\"Erwartete ein JSON-Array von Routinen.\"}");
        TelnetStream.println("handleReceiveRoutines: JSON-Body ist kein Array.");
        return;
    }

    for (JsonObject obj : array) {
        if (routinen_count >= MAX_ROUTINES) {
          TelnetStream.println("WARNUNG: Maximale Routinenanzahl beim Empfang überschritten. Einige ignoriert.");
          break;
        }
        routinen[routinen_count].kanal = obj["kanal"].as<int>();
        routinen[routinen_count].duengen = obj["duengen"].as<int>();
        routinen[routinen_count].wassermenge = obj["wassermenge"].as<int>();
        routinen[routinen_count].tag = obj["tag"].as<int>();
        routinen[routinen_count].stunde = obj["stunde"].as<int>();
        routinen[routinen_count].minute = obj["minute"].as<int>();
        routinen[routinen_count].isEnabled = obj["isEnabled"].as<bool>();
        routinen_count++;
    }
    saveRoutinesToLittleFS();
    server.send(200, "application/json", "{\"status\":\"success\",\"routines_loaded\": " + String(routinen_count) + "}");
    TelnetStream.printf("%d Routinen empfangen und gespeichert.\n", routinen_count);
}

void handleGetRoutines() {
    StaticJsonDocument<JSON_CAPACITY * MAX_ROUTINES> doc;
    JsonArray array = doc.to<JsonArray>();
    for (int i = 0; i < routinen_count; i++) {
        JsonObject obj = array.createNestedObject();
        obj["kanal"] = routinen[i].kanal;
        obj["duengen"] = routinen[i].duengen;
        obj["wassermenge"] = routinen[i].wassermenge;
        obj["tag"] = routinen[i].tag;
        obj["stunde"] = routinen[i].stunde;
        obj["minute"] = routinen[i].minute;
        obj["isEnabled"] = routinen[i].isEnabled;
    }
    String json_output;
    serializeJson(doc, json_output);
    server.send(200, "application/json", json_output);
    TelnetStream.println("Alle Routinen gesendet.");
}

void handleGetCurrentRoutine() {
    StaticJsonDocument<JSON_CAPACITY> doc;
    JsonObject currentRoutine = doc.to<JsonObject>();
    if (activeRoutine) {
        const char* phaseStr;
        if (currentPhase == PHASE_DUENGEN) phaseStr = "duengen";
        else if (currentPhase == PHASE_BEWAESSERN) phaseStr = "bewaessern";
        else phaseStr = "inaktiv";
        
        currentRoutine["phase"] = phaseStr;
        unsigned long fortschritt_ml = (impulse_count * 1000UL) / calibrationFaktor;
        currentRoutine["fortschritt_ml"] = fortschritt_ml;
        currentRoutine["ziel_ml"] = currentVolume;
        currentRoutine["kanal"] = currentZone;
        currentRoutine["time_elapsed_ms"] = millis() - wateringStartTime;
    } else {
        currentRoutine["phase"] = "inaktiv";
        currentRoutine["fortschritt_ml"] = 0;
        currentRoutine["ziel_ml"] = 0;
        currentRoutine["kanal"] = -1;
        currentRoutine["time_elapsed_ms"] = 0;
    }
    String json_output;
    serializeJson(doc, json_output);
    server.send(200, "application/json", json_output);
    TelnetStream.println("Aktueller Routinen-Status gesendet.");
}

void handleStartManual() {
    if (!server.hasArg("plain")) {
        server.send(400, "text/plain", "400: Ungueltige Anfrage - kein JSON-Body.");
        TelnetStream.println("handleStartManual: Ungültige Anfrage - kein JSON-Körper.");
        return;
    }
    String json = server.arg("plain");
    StaticJsonDocument<JSON_CAPACITY> doc;
    DeserializationError error = deserializeJson(doc, json);
    if (error) {
        server.send(400, "application/json", "{\"error\":\"Ungueltiges JSON Format\",\"details\":\"" + String(error.c_str()) + "\"}");
        TelnetStream.printf("handleStartManual: Fehler beim Parsen des JSON: %s\n", error.c_str());
        return;
    }
    int kanal = doc["kanal"].as<int>();
    int wassermenge = doc["wassermenge"].as<int>();
    
    if (Kanal[kanal] == Kanal[MAIN_VALVE_CHANNEL] || Kanal[kanal] == Kanal[FERTILIZER_CHANNEL] || Kanal[kanal] == Kanal[6]) {
        server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Ungueltiger Kanal angegeben (darf nicht Haupt-/Duengerventil oder Pumpe sein).\"}");
        TelnetStream.printf("handleStartManual: Ungültiger Kanal %d.\n", kanal);
        return;
    }

    if (!activeRoutine) {
        activeRoutine = true;
        currentPhase = PHASE_BEWAESSERN;
        currentZone = kanal;
        currentVolume = wassermenge;
        
        int result = wasserEinschalten(kanal, wassermenge);
        if (result == 0) {
            server.send(200, "application/json", "{\"status\":\"success\",\"message\":\"Manuelle Bewaesserung gestartet.\"}");
            TelnetStream.println("Manuelle Bewässerung gestartet.");
        } else {
            server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Fehler beim Starten der manuellen Bewaesserung.\"}");
            TelnetStream.println("handleStartManual: Fehler beim Einschalten.");
            activeRoutine = false; currentPhase = PHASE_INAKTIV;
        }
    } else {
        BewaesserungsRoutine new_routine;
        new_routine.kanal = kanal; new_routine.duengen = 0; new_routine.wassermenge = wassermenge;
        new_routine.tag = -1; new_routine.stunde = 0; new_routine.minute = 0; new_routine.isEnabled = true;
        
        addToQueue(new_routine);
        server.send(200, "application/json", "{\"status\":\"queued\",\"message\":\"Eine Routine laeuft bereits, Auftrag wurde zur Warteschlange hinzugefuegt.\"}");
        TelnetStream.printf("Manuelle Bewässerung für Kanal %d zur Warteschlange hinzugefügt.\n", kanal);
    }
}

void handleStartRoutine() {
    if (!server.hasArg("plain")) {
        server.send(400, "text/plain", "400: Ungueltige Anfrage - kein JSON-Body.");
        TelnetStream.println("handleStartRoutine: Ungültige Anfrage - kein JSON-Körper.");
        return;
    }
    String json = server.arg("plain");
    StaticJsonDocument<JSON_CAPACITY> doc;
    DeserializationError error = deserializeJson(doc, json);
    if (error) {
        server.send(400, "application/json", "{\"error\":\"Ungueltiges JSON Format\",\"details\":\"" + String(error.c_str()) + "\"}");
        TelnetStream.printf("handleStartRoutine: Fehler beim Parsen des JSON: %s\n", error.c_str());
        return;
    }
    int kanal = doc["kanal"].as<int>();
    int wassermenge = doc["wassermenge"].as<int>();
    bool duengenFlag = doc.containsKey("duengen") ? doc["duengen"].as<bool>() : false;
    
    if (Kanal[kanal] == Kanal[MAIN_VALVE_CHANNEL] || Kanal[kanal] == Kanal[FERTILIZER_CHANNEL] || Kanal[kanal] == Kanal[6]) {
        server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Ungueltiger Kanal angegeben (darf nicht Haupt-/Duengerventil oder Pumpe sein).\"}");
        TelnetStream.printf("handleStartRoutine: Ungültiger Kanal %d.\n", kanal);
        return;
    }

    if (!activeRoutine) {
        activeRoutine = true; currentZone = kanal; currentVolume = wassermenge;
        impulse_count = 0;

        if (duengenFlag) {
            currentPhase = PHASE_DUENGEN;
            digitalWrite(Kanal[MAIN_VALVE_CHANNEL], EIN); TelnetStream.println("Hauptventil geöffnet (manuelle Düngungsvorbereitung)");
            delay(1000); 

            digitalWrite(Kanal[FERTILIZER_CHANNEL], EIN); TelnetStream.println("Düngerventil geöffnet");
            digitalWrite(PUMP_PIN, HIGH); TelnetStream.println("Pumpe eingeschaltet");

            ziel_impulse = (wassermenge * calibrationFaktor) / 1000;
            aktueller_kanal = kanal; kanal_eingeschaltet = true; wateringStartTime = millis();
            attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), fluss_sensor_ISR, RISING);
            digitalWrite(Kanal[kanal], EIN); TelnetStream.printf("Kanal %d eingeschaltet für %d ml (manuelle Düngung).\n", kanal, wassermenge);
        } else {
            currentPhase = PHASE_BEWAESSERN;
            int result = wasserEinschalten(kanal, wassermenge);
            if (result != 0) {
                server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"Fehler beim Starten der Bewaesserung.\"}");
                TelnetStream.println("handleStartRoutine: Fehler beim Start der Bewässerung.");
                activeRoutine = false; currentPhase = PHASE_INAKTIV; return;
            }
        }
        server.send(200, "application/json", "{\"status\":\"success\",\"message\":\"Routine gestartet.\"}");
        TelnetStream.println("Routine manuell gestartet.");
    } else {
        BewaesserungsRoutine new_routine;
        new_routine.kanal = kanal; new_routine.duengen = duengenFlag ? 1 : 0; new_routine.wassermenge = wassermenge;
        new_routine.tag = -1; new_routine.stunde = 0; new_routine.minute = 0; new_routine.isEnabled = true;
        
        addToQueue(new_routine);
        server.send(200, "application/json", "{\"status\":\"queued\",\"message\":\"Eine Routine laeuft bereits, Auftrag wurde zur Warteschlange hinzugefuegt.\"}");
        TelnetStream.printf("Routine für Kanal %d zur Warteschlange hinzugefügt.\n", kanal);
    }
}

void handleStopManual() {
    if (!activeRoutine) {
        server.send(200, "application/json", "{\"status\":\"no active routine\",\"message\":\"Keine laufende Routine zum Stoppen.\"}");
        TelnetStream.println("handleStopManual: Keine laufende Routine zum Stoppen.");
        return;
    }
    
    detachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN));
    
    wasser_verbraucht[currentZone] += impulse_count; 
    saveWasserVerbrauchtToLittleFS();

    if (kanal_eingeschaltet && aktueller_kanal != -1) { digitalWrite(Kanal[aktueller_kanal], AUS); }
    digitalWrite(Kanal[FERTILIZER_CHANNEL], AUS);
    digitalWrite(PUMP_PIN, LOW);
    digitalWrite(Kanal[MAIN_VALVE_CHANNEL], AUS);

    TelnetStream.printf("Bewaesserung manuell abgebrochen (Phase: %s).\n", 
                       (currentPhase == PHASE_DUENGEN ? "Düngung" : (currentPhase == PHASE_BEWAESSERN ? "Bewässerung" : "Unbekannt")));
    
    kanal_eingeschaltet = false; aktueller_kanal = -1; activeRoutine = false;
    currentPhase = PHASE_INAKTIV; flushPending = false; impulse_count = 0;

    server.send(200, "application/json", "{\"status\":\"stopped\",\"message\":\"Aktuelle Routine wurde gestoppt.\"}");
    TelnetStream.println("Bewaesserungsroutine manuell gestoppt.");
}

void handleAddToQueue() {
    if (!server.hasArg("plain")) {
        server.send(400, "text/plain", "400: Ungueltige Anfrage - kein JSON-Body.");
        TelnetStream.println("handleAddToQueue: Ungültige Anfrage - kein JSON-Körper.");
        return;
    }
    String json = server.arg("plain");
    StaticJsonDocument<JSON_CAPACITY * 2> doc;
    DeserializationError error = deserializeJson(doc, json);
    if (error) {
        server.send(400, "application/json", "{\"error\":\"Ungueltiges JSON Format\",\"details\":\"" + String(error.c_str()) + "\"}");
        TelnetStream.printf("handleAddToQueue: Fehler beim Parsen des JSON: %s\n", error.c_str());
        return;
    }
    
    JsonArray array = doc.as<JsonArray>();

    if (!array.isNull()) {
        for (JsonObject obj : array) {
            if (queueCount >= MAX_ROUTINES + 2) { 
                TelnetStream.println("WARNUNG: Warteschlange voll, weitere Routinen konnten nicht hinzugefügt werden.");
                break;
            }
            BewaesserungsRoutine new_routine;
            new_routine.kanal = obj["kanal"].as<int>();
            new_routine.duengen = obj["duengen"].as<int>();
            new_routine.wassermenge = obj["wassermenge"].as<int>();
            new_routine.tag = obj["tag"].as<int>();
            new_routine.stunde = obj["stunde"].as<int>();
            new_routine.minute = obj["minute"].as<int>();
            new_routine.isEnabled = true;
            addToQueue(new_routine);
        }
    } else {
        JsonObject obj = doc.as<JsonObject>();
        if (!obj.isNull()) {
            if (queueCount >= MAX_ROUTINES + 2) { 
                TelnetStream.println("WARNUNG: Warteschlange voll, Routine konnte nicht hinzugefügt werden.");
                server.send(500, "application/json", "{\"status\":\"error\",\"message\":\"Warteschlange voll.\"}"); 
                return; 
            }
            BewaesserungsRoutine new_routine;
            new_routine.kanal = obj["kanal"].as<int>();
            new_routine.duengen = obj["duengen"].as<int>();
            new_routine.wassermenge = obj["wassermenge"].as<int>();
            new_routine.tag = obj["tag"].as<int>();
            new_routine.stunde = obj["stunde"].as<int>();
            new_routine.minute = obj["minute"].as<int>();
            new_routine.isEnabled = true;
            addToQueue(new_routine);
        } else {
            server.send(400, "application/json", "{\"error\":\"Erwartete ein JSON-Objekt oder -Array von Routinen.\"}");
            TelnetStream.println("handleAddToQueue: JSON ist kein Objekt oder Array.");
            return;
        }
    }
    server.send(200, "application/json", "{\"status\":\"success\",\"queued_items\": " + String(queueCount) + "}");
    TelnetStream.println("Zusätzliche Routinen zur Warteschlange hinzugefügt.");
}

void handleGetPulseCount() {
    StaticJsonDocument<JSON_CAPACITY> doc;
    JsonObject pulseData = doc.to<JsonObject>();
    pulseData["impulse_count"] = impulse_count;
    pulseData["ziel_impulse"] = ziel_impulse;
    pulseData["active_channel"] = aktueller_kanal;
    pulseData["current_phase"] = (currentPhase == PHASE_DUENGEN ? "duengen" : (currentPhase == PHASE_BEWAESSERN ? "bewaessern" : "inaktiv"));
    String json_output;
    serializeJson(doc, json_output);
    server.send(200, "application/json", json_output);
    TelnetStream.println("Impulszählung gesendet.");
}

void handleGetWaterUsage() {
    StaticJsonDocument<512> doc;
    for (int i = 0; i < MAX_KANAELE; i++) {
        doc[String("kanal_") + i + "_ml"] = (wasser_verbraucht[i] * 1000UL) / (unsigned long)calibrationFaktor;
        doc[String("kanal_") + i + "_impulse"] = wasser_verbraucht[i];
    }
    String json_output; 
    serializeJson(doc, json_output);
    server.send(200, "application/json", json_output);
    TelnetStream.println("Wasserverbrauch gesendet.");
}

void handleResetWaterUsage() {
    for (int i = 0; i < MAX_KANAELE; i++) { wasser_verbraucht[i] = 0; }
    saveWasserVerbrauchtToLittleFS();
    server.send(200, "application/json", "{\"status\":\"reset\",\"message\":\"Wasserverbrauch wurde zurueckgesetzt.\"}");
    TelnetStream.println("Wasserverbrauch zurückgesetzt.");
}

// --- HTTP-Update Handler ---
void handleUpdate() {
    server.sendHeader("Connection", "close");
    server.send(200, "text/plain", (Update.hasError()) ? "FAIL" : "OK");
    TelnetStream.println("Firmware Update erfolgreich, starte neu...");
    delay(100); // Kurzes Delay, um Antwort zu senden
    rp2040.reboot(); // Neustart nach Update (ersetzt NVIC_SystemReset)
}

void handleUpdateUpload() {
    HTTPUpload& upload = server.upload(); // Zugriff auf die Upload-Informationen
    if (upload.status == UPLOAD_FILE_START) {
        TelnetStream.printf("Firmware-Upload startet: %s\n", upload.filename.c_str());
        // Starte den Update-Prozess, UNKNOWN_SIZE, da die Größe nicht immer im Voraus bekannt ist
        if (!Update.begin(UPDATE_SIZE_UNKNOWN)) { 
            TelnetStream.print("Update-Fehler: ");
            Update.printError(Serial); // Schreibt Fehler auf Serial
        }
    } else if (upload.status == UPLOAD_FILE_WRITE) {
        // Schreibe Daten in den Flash
        if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
            TelnetStream.print("Update-Fehler beim Schreiben: ");
            Update.printError(Serial);
        }
    } else if (upload.status == UPLOAD_FILE_END) {
        // Beende Update-Prozess
        if (Update.end(true)) { // 'true' bedeutet, dass das Update erfolgreich war
            TelnetStream.printf("Update erfolgreich, %u Bytes geschrieben\n", upload.totalSize);
        } else {
            TelnetStream.print("Update-Fehler (Ende): ");
            Update.printError(Serial);
        }
    }
}


// Konfiguriert alle HTTP-Endpunkte des Webservers.
void setupServer() {
    server.on("/", HTTP_GET, handleRoot);
    server.on("/receive_routines", HTTP_POST, handleReceiveRoutines);
    server.on("/routines", HTTP_GET, handleGetRoutines);
    server.on("/current_routine", HTTP_GET, handleGetCurrentRoutine);
    server.on("/start_routine", HTTP_POST, handleStartRoutine);
    server.on("/stop_routine", HTTP_POST, handleStopManual);
    server.on("/start_manual", HTTP_POST, handleStartManual);
    server.on("/stop_manual", HTTP_POST, handleStopManual);
    server.on("/water_usage", HTTP_GET, handleGetWaterUsage);
    server.on("/reset_water_usage", HTTP_POST, handleResetWaterUsage);
    server.on("/add_to_queue", HTTP_POST, handleAddToQueue);
    server.on("/pulse_count", HTTP_GET, handleGetPulseCount);
    
    // HTTP-Update Endpunkt
    server.on("/update", HTTP_POST, handleUpdate, handleUpdateUpload);

    server.onNotFound(handleNotFound);
    server.begin();
    TelnetStream.println("HTTP-Server gestartet auf Port 80.");
}


// Stellt die WLAN-Verbindung her oder startet das Captive Portal (WiFiManager).
void setupWifi() {
  WiFiManager wifiManager;
  wifiManager.setHostname("watress"); 

  TelnetStream.println("Versuche WLAN-Verbindung herzustellen oder AP zu starten...");
  bool res = wifiManager.autoConnect("watress"); 

  if (!res) { TelnetStream.println("WLAN-Verbindung fehlgeschlagen oder Konfigurations-AP beendet."); } 
  else {
    TelnetStream.println("WLAN-Verbindung hergestellt!");
    TelnetStream.printf("IP-Adresse: %s\n", WiFi.localIP().toString().c_str());
  }

  if (!MDNS.begin("watress")) { TelnetStream.println("Fehler beim Starten von mDNS!"); } 
  else {
    TelnetStream.println("mDNS-Responder gestartet.");
    MDNS.addService("http", "tcp", 80);
  }
  
  timeClient.begin();
}

// Die Standard Arduino Setup-Funktion, die einmal beim Start des Boards aufgerufen wird.
void setup() {
    Serial.begin(115200);
    // TelnetStream.begin() muss nach Serial.begin() aufgerufen werden
    TelnetStream.begin(); 

    TelnetStream.println("\nSystemstart...");

    // LittleFS initialisieren
    if (!LittleFS.begin()) {
        TelnetStream.println("Fehler: LittleFS konnte nicht gemountet werden.");
        // Im Fehlerfall hier abbrechen oder Recovery-Logik einfügen
        while(true) delay(100); 
    } else {
        TelnetStream.println("LittleFS gemountet.");
    }
    
    init_kanaele();       
    setupWifi();          
    loadRoutinesFromLittleFS();     // Routinen aus LittleFS laden
    loadWasserVerbrauchtFromLittleFS(); // Wasserverbrauch aus LittleFS laden
    
    setupServer();      
    
    TelnetStream.println("Setup abgeschlossen.");
}

// Die Standard Arduino Loop-Funktion, die kontinuierlich wiederholt wird.
void loop() {
    checkWifiConnection(); 
    TelnetStream.handleClient(); // Telnet-Client-Verbindung prüfen

    if (!activeRoutine) { 
      checkAndQueueRoutines();
      processQueue();          
    }
    
    if (flushPending && !kanal_eingeschaltet && activeRoutine && currentPhase == PHASE_DUENGEN) {
        TelnetStream.println("Starte Nachspül-Bewässerung nach Düngung.");
        currentPhase = PHASE_BEWAESSERN;
        flushPending = false;
        
        wateringStartTime = millis();
        impulse_count = 0;
        ziel_impulse = (currentVolume * calibrationFaktor) / 1000;
        aktueller_kanal = currentZone;
        kanal_eingeschaltet = true;
        attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), fluss_sensor_ISR, RISING);
        digitalWrite(Kanal[currentZone], EIN);
        digitalWrite(Kanal[MAIN_VALVE_CHANNEL], EIN);
        TelnetStream.printf("Kanal %d eingeschaltet für %d ml (Spülung).\n", currentZone, currentVolume);
    }
    
    checkWateringTimeout();

    server.handleClient();   
    MDNS.update();         

    if (millis() - lastTimePrint >= 60000) {
        lastTimePrint = millis();
        ZeitInfo zeitInfo = aktualisiereZeit();
        TelnetStream.printf("Aktuelle Zeit: %02d:%02d:%02d, Tag: %d (0=So, 6=Sa)\n", 
            zeitInfo.stunde, zeitInfo.minute, timeClient.getSeconds(), zeitInfo.tag);
    }
}