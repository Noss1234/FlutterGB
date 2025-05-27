// flow_sensor.h
// Diese Datei enthält die ISR für den Flusssensor sowie die Start-/Stopp-Logik für bewässerte Zonen.
// Sie verarbeitet Impulszählung, Mengenüberwachung und Übergänge zwischen Phasen.

#ifndef FLOW_SENSOR_H
#define FLOW_SENSOR_H

#include "Arduino.h"
#include "config_pins.h"
#include "state.h"
#include "telnet_stream.h"
#include "storage.h"

// Kalibrierfaktor (Impulse pro Liter)
// Beispiel: 840 Impulse = 1 Liter ⇒ 0.84 pro ml
extern const unsigned int calibrationFaktor;

void flowISR() {
    impulse_count++;

    if (kanal_eingeschaltet && aktueller_kanal != -1 && impulse_count >= ziel_impulse) {
        detachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN));

        // Wasserverbrauch erfassen
        wasser_verbraucht[aktueller_kanal] += impulse_count;
        saveWasserVerbrauchtToFS();

        if (currentPhase == PHASE_DUENGEN) {
            digitalWrite(zonePins[aktueller_kanal], HIGH);
            digitalWrite(FERT_VALVE_PIN, HIGH);
            digitalWrite(PUMP_PIN, HIGH);
            kanal_eingeschaltet = false;
            aktueller_kanal = -1;
            flushPending = true;

            LOG("Düngung abgeschlossen – Spülung folgt");
        } 
        else if (currentPhase == PHASE_BEWAESSERN) {
            digitalWrite(zonePins[aktueller_kanal], HIGH);
            digitalWrite(MAIN_VALVE_PIN, HIGH);
            digitalWrite(PUMP_PIN, HIGH);
            kanal_eingeschaltet = false;
            aktueller_kanal = -1;
            activeRoutine = false;
            currentPhase = PHASE_INAKTIV;

            LOG("Bewässerung abgeschlossen");
        }
    }
}

// Initialisierung: Pin setzen, Interrupt aktivieren
void initFlowSensor() {
    pinMode(FLOW_SENSOR_PIN, INPUT_PULLUP);
    attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), flowISR, RISING);
    LOG("Flusssensor-ISR aktiviert");
}

#endif // FLOW_SENSOR_H
