#include <Arduino.h>
#include <LittleFS.h>
#include <ElegantOTA.h>

// Eigene Module
#include "config_pins.h"
#include "state.h"
#include "wifi_setup.h"
#include "telnet_stream.h"
#include "flow_sensor.h"
#include "storage.h"
#include "routines.h"
#include "http_routes.h"

// WebServer Instanz (wird auch in http_routes.h verwendet)
extern WebServer server;

// === Initialisierung globaler Zustände (aus state.h) ===
volatile RoutinePhase currentPhase = PHASE_INAKTIV;
volatile bool activeRoutine = false;
volatile bool flushPending = false;

int currentZone = -1;
int currentVolume = 0;

volatile unsigned long wasser_verbraucht[NUM_ZONES] = {0};
bool zoneActive[NUM_ZONES] = {false};

volatile unsigned long impulse_count = 0;
volatile unsigned long ziel_impulse = 0;
volatile int aktueller_kanal = -1;
volatile bool kanal_eingeschaltet = false;

Routine routinePool[20];
int routineCount = 0;

unsigned long wateringStartTime = 0;
// === Setup ===
void setup() {
  // I/O Pins vorbereiten
  for (int i = 0; i < NUM_ZONES; i++) {
    pinMode(zonePins[i], OUTPUT);
    digitalWrite(zonePins[i], HIGH);  // AUS
  }
  pinMode(PUMP_PIN, OUTPUT);
  pinMode(MAIN_VALVE_PIN, OUTPUT);
  pinMode(FERT_VALVE_PIN, OUTPUT);
  digitalWrite(PUMP_PIN, HIGH);
  digitalWrite(MAIN_VALVE_PIN, HIGH);
  digitalWrite(FERT_VALVE_PIN, HIGH);

  Serial.begin(115200);
  delay(1000); // Stabilisierung

  TelnetStream.begin();     // Telnet Logging starten
  LOG("Systemstart...");

  if (!PICO_FLASH_FS.begin()) {
    LOG("Fehler beim Mounten von LittleFS");
    while (1);
  }

  initWiFi();
  initFlowSensor();
  loadWasserVerbrauchtFromFS();
  loadRoutinenFromFS(routinePool, routineCount, 20);
  setupHttpRoutes();
  ElegantOTA.begin(&server);
  LOG("ElegantOTA aktiv");
  LOG("Setup abgeschlossen");
}

// === Loop ===
void loop() {
  server.handleClient();
  TelnetStream.handle();

  if (!activeRoutine) {
    checkAndQueueTimedRoutines(routinePool, routineCount);
    processQueue();
  }

  startFlushAfterDuengen();
  checkRoutineTimeout();

  delay(50); // Zykluszeit
}
