// routines.h
// Diese Datei verwaltet alle Bewässerungsroutinen: Queue, Start, Abbruch, Übergänge.
// Sie implementiert Düngung, Spülphase, Zeitvergleiche und Hardwaresteuerung.

#ifndef ROUTINES_H
#define ROUTINES_H

#include <Arduino.h>
#include "config_pins.h"
#include "state.h"
#include "flow_sensor.h"
#include "wifi_setup.h"
#include "telnet_stream.h"
#include "storage.h"

#define MAX_QUEUE 10
#define WATERING_TIMEOUT 60000  // 60s Sicherheitszeit pro Phase

void flowISR(); // vorher deklarieren sonst fehlt sie einer funktion

// Struktur: Einzelne Routine
struct Routine {
  int kanal;
  int duengen;
  int wassermenge; // ml
  int tag;
  int stunde;
  int minute;
  bool isEnabled;
};

// Warteschlange
Routine queue[MAX_QUEUE];
int queueCount = 0;

// Routinenpool (persistent)
extern Routine routinePool[20];
extern int routineCount;

void addToQueue(Routine r) {
  if (queueCount < MAX_QUEUE) {
    queue[queueCount++] = r;
    LOG("Routine zur Queue hinzugefügt");
  } else {
    LOG("Warteschlange voll – nicht hinzugefügt");
  }
}

void startRoutine(Routine r) {
  activeRoutine = true;
  currentZone = r.kanal;
  currentVolume = r.wassermenge;
  impulse_count = 0;

  if (r.duengen == 1) {
    currentPhase = PHASE_DUENGEN;
    digitalWrite(MAIN_VALVE_PIN, EIN);
    LOG("Hauptventil geöffnet (Düngung)");
    delay(1000);
    digitalWrite(FERT_VALVE_PIN, EIN);
    digitalWrite(PUMP_PIN, EIN);
    LOG("Düngerventil und Pumpe aktiviert");

    ziel_impulse = (r.wassermenge * calibrationFaktor) / 1000;
    aktueller_kanal = r.kanal;
    kanal_eingeschaltet = true;
    wateringStartTime = millis();
    attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), flowISR, RISING);
    digitalWrite(zonePins[r.kanal], EIN);
    LOG("Zone aktiviert (Düngung)");
  } else {
    currentPhase = PHASE_BEWAESSERN;
    wateringStartTime = millis();
    ziel_impulse = (r.wassermenge * calibrationFaktor) / 1000;
    impulse_count = 0;
    aktueller_kanal = r.kanal;
    kanal_eingeschaltet = true;
    digitalWrite(MAIN_VALVE_PIN, EIN);
    delay(1000);
    digitalWrite(PUMP_PIN, EIN);
    attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), flowISR, RISING);
    digitalWrite(zonePins[r.kanal], EIN);
    LOG("Zone aktiviert (Bewässerung)");
  }
}

void processQueue() {
  if (!activeRoutine && queueCount > 0) {
    Routine r = queue[0];
    for (int i = 1; i < queueCount; i++) queue[i - 1] = queue[i];
    queueCount--;
    startRoutine(r);
  }
}

void checkRoutineTimeout() {
  if (activeRoutine && kanal_eingeschaltet && millis() - wateringStartTime > WATERING_TIMEOUT) {
    detachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN));
    digitalWrite(zonePins[aktueller_kanal], AUS);
    digitalWrite(MAIN_VALVE_PIN, AUS);
    digitalWrite(FERT_VALVE_PIN, AUS);
    digitalWrite(PUMP_PIN, AUS);
    kanal_eingeschaltet = false;
    aktueller_kanal = -1;
    activeRoutine = false;
    currentPhase = PHASE_INAKTIV;
    flushPending = false;
    LOG("Timeout – Routine abgebrochen");
  }
}

void checkAndQueueTimedRoutines(Routine* pool, int count) {
  ZeitInfo now = aktualisiereZeit();
  for (int i = 0; i < count; i++) {
    Routine r = pool[i];
    if (!r.isEnabled) continue;
    if (r.tag == now.tag && r.stunde == now.stunde && r.minute == now.minute) {
      addToQueue(r);
    }
  }
}

// Optional: Aufruf nach Düngung → Spülung
void startFlushAfterDuengen() {
  if (flushPending && !kanal_eingeschaltet && activeRoutine) {
    currentPhase = PHASE_BEWAESSERN;
    flushPending = false;
    wateringStartTime = millis();
    ziel_impulse = (currentVolume * calibrationFaktor) / 1000;
    impulse_count = 0;
    aktueller_kanal = currentZone;
    kanal_eingeschaltet = true;
    digitalWrite(MAIN_VALVE_PIN, EIN);
    delay(1000);
    digitalWrite(PUMP_PIN, EIN);
    attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), flowISR, RISING);
    digitalWrite(zonePins[currentZone], EIN);
    LOG("Spülphase gestartet");
  }
}

#endif // ROUTINES_H
