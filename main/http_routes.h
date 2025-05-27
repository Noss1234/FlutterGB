// http_routes.h
// Diese Datei definiert alle HTTP-Endpunkte für API-Zugriff auf Routinen, Wasserzähler und manuelle Steuerung.

#ifndef HTTP_ROUTES_H
#define HTTP_ROUTES_H

#include <WebServer.h>
#include <ArduinoJson.h>
#include "config_pins.h"
#include "state.h"
#include "routines.h"
#include "storage.h"
#include "telnet_stream.h"

WebServer server(80);

// Lokaler Speicher (nicht persistent)
extern Routine routinePool[20];
extern int routineCount;

// GET / => einfaches Ping
void handleRoot() {
  server.send(200, "text/plain", "Pico W - Bewässerungssteuerung");
}

// POST /receive_routines => Liste empfangen und speichern
void handleReceiveRoutines() {
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "Kein JSON übermittelt");
    return;
  }
  StaticJsonDocument<4096> doc;
  DeserializationError err = deserializeJson(doc, server.arg("plain"));
  if (err) {
    server.send(400, "application/json", "{\"error\":\"JSON-Fehler\"}");
    return;
  }

  routineCount = 0;
  JsonArray arr = doc.as<JsonArray>();
  for (JsonObject o : arr) {
    if (routineCount >= 20) break;
    routinePool[routineCount].kanal = o["kanal"];
    routinePool[routineCount].duengen = o["duengen"];
    routinePool[routineCount].wassermenge = o["wassermenge"];
    routinePool[routineCount].tag = o["tag"];
    routinePool[routineCount].stunde = o["stunde"];
    routinePool[routineCount].minute = o["minute"];
    routinePool[routineCount].isEnabled = o["isEnabled"];
    routineCount++;
  }

  saveRoutinenToFS(routinePool, routineCount); // Routinen persistent speichern
  saveWasserVerbrauchtToFS(); // Optional: auch sichern

  server.send(200, "application/json", "{\"status\":\"ok\"}");
  LOG("Routinen empfangen und gespeichert");
}


// GET /routines
void handleGetRoutines() {
  StaticJsonDocument<4096> doc;
  JsonArray arr = doc.to<JsonArray>();
  for (int i = 0; i < routineCount; i++) {
    JsonObject o = arr.createNestedObject();
    o["kanal"] = routinePool[i].kanal;
    o["duengen"] = routinePool[i].duengen;
    o["wassermenge"] = routinePool[i].wassermenge;
    o["tag"] = routinePool[i].tag;
    o["stunde"] = routinePool[i].stunde;
    o["minute"] = routinePool[i].minute;
    o["isEnabled"] = routinePool[i].isEnabled;
  }
  String result;
  serializeJson(doc, result);
  server.send(200, "application/json", result);
}

// POST /start_manual
void handleStartManual() {
  if (!server.hasArg("plain")) return;
  StaticJsonDocument<256> doc;
  deserializeJson(doc, server.arg("plain"));
  Routine r;
  r.kanal = doc["kanal"];
  r.duengen = doc["duengen"] | 0;
  r.wassermenge = doc["wassermenge"];
  r.tag = -1;
  r.stunde = 0;
  r.minute = 0;
  r.isEnabled = true;
  addToQueue(r);
  server.send(200, "application/json", "{\"status\":\"queued\"}");
}

// POST /stop_manual
void handleStopManual() {
  detachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN));
  digitalWrite(zonePins[aktueller_kanal], HIGH);
  digitalWrite(MAIN_VALVE_PIN, HIGH);
  digitalWrite(PUMP_PIN, HIGH);
  digitalWrite(FERT_VALVE_PIN, HIGH);
  kanal_eingeschaltet = false;
  aktueller_kanal = -1;
  activeRoutine = false;
  currentPhase = PHASE_INAKTIV;
  flushPending = false;
  impulse_count = 0;
  server.send(200, "application/json", "{\"status\":\"stopped\"}");
}

// GET /status
void handleGetStatus() {
  StaticJsonDocument<256> doc;
  doc["phase"] = (currentPhase == PHASE_DUENGEN) ? "duengen" :
                 (currentPhase == PHASE_BEWAESSERN) ? "bewässern" : "inaktiv";
  doc["kanal"] = aktueller_kanal;
  doc["impulse"] = impulse_count;
  doc["ziel"] = ziel_impulse;
  doc["active"] = activeRoutine;
  String result;
  serializeJson(doc, result);
  server.send(200, "application/json", result);
}

// GET /water_usage
void handleGetWaterUsage() {
  StaticJsonDocument<512> doc;
  for (int i = 0; i < NUM_ZONES; i++) {
    doc["zone_" + String(i)] = wasser_verbraucht[i];
  }
  String result;
  serializeJson(doc, result);
  server.send(200, "application/json", result);
}

// POST /reset_water_usage
void handleResetWaterUsage() {
  for (int i = 0; i < NUM_ZONES; i++) wasser_verbraucht[i] = 0;
  saveWasserVerbrauchtToFS();
  server.send(200, "application/json", "{\"status\":\"reset\"}");
}

// GET /current_routine => gibt aktive Routine und Details zurück
void handleGetCurrentRoutine() {
  StaticJsonDocument<256> doc;
  doc["aktiv"] = activeRoutine;
  doc["kanal"] = aktueller_kanal;
  doc["wassermenge"] = currentVolume;
  doc["impulse_gesamt"] = impulse_count;
  doc["impulse_ziel"] = ziel_impulse;
  doc["duengen"] = (currentPhase == PHASE_DUENGEN);
  String result;
  serializeJson(doc, result);
  server.send(200, "application/json", result);
}

// GET /pulse_count => gibt aktuelle Impulsanzahl des Flusssensors zurück
void handleGetPulseCount() {
  server.send(200, "text/plain", String(impulse_count));
}

// Setup-Funktion zur Registrierung aller HTTP-Routen
void setupHttpRoutes() {
  server.on("/", HTTP_GET, handleRoot);
  server.on("/receive_routines", HTTP_POST, handleReceiveRoutines);
  server.on("/routines", HTTP_GET, handleGetRoutines);
  server.on("/start_manual", HTTP_POST, handleStartManual);
  server.on("/stop_manual", HTTP_POST, handleStopManual);
  server.on("/status", HTTP_GET, handleGetStatus);
  server.on("/water_usage", HTTP_GET, handleGetWaterUsage);
  server.on("/reset_water_usage", HTTP_POST, handleResetWaterUsage);
  server.on("/current_routine", HTTP_GET, handleGetCurrentRoutine);
  server.on("/pulse_count", HTTP_GET, handleGetPulseCount);

  server.begin();
  LOG("HTTP-Server gestartet");
}

#endif // HTTP_ROUTES_H
