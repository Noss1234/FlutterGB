// state.h
// Diese Datei hält globale Zustände und Statusvariablen für die Steuerlogik.
// Dazu gehören aktive Routinephasen, Wasserzähler, Flags und Status der Zonenventile.

#ifndef STATE_H
#define STATE_H

#include "config_pins.h"

// Mögliche Phasen einer Routine
enum RoutinePhase {
  PHASE_INAKTIV,
  PHASE_DUENGEN,
  PHASE_BEWAESSERN
};

// Aktueller Zustand des Systems
extern volatile RoutinePhase currentPhase;
extern volatile bool activeRoutine;
extern volatile bool flushPending;

// Welche Zone ist aktuell aktiv? (Index im zonePins[] Array)
extern int currentZone;

// Zielvolumen der aktuellen Phase in ml
extern int currentVolume;

// Array: Wasserverbrauch in Impulsen pro Zone (über ISR mitgezählt)
extern volatile unsigned long wasser_verbraucht[NUM_ZONES];

// Array: Ob eine Zone gerade aktiv ist (Ventil offen)
extern bool zoneActive[NUM_ZONES];

// Flow-Sensor Zähler
extern volatile unsigned long impulse_count;
extern volatile unsigned long ziel_impulse;
extern volatile int aktueller_kanal;
extern volatile bool kanal_eingeschaltet;

// Zeitstempel zum Timeout-Monitoring
extern unsigned long wateringStartTime;

#endif // STATE_H
