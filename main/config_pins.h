#ifndef CONFIG_PINS_H
#define CONFIG_PINS_H

#define EIN LOW
#define AUS HIGH

// Anzahl realer Zonen
#define NUM_ZONES 8

// Zonen-GPIOs (nur für Bewässerungszonen)
const int zonePins[NUM_ZONES] = {
  6, 7, 8, 9, 10, 11, 12, 13
};

// Steuer-Pins (nicht im Zonenarray!)
#define PUMP_PIN           2   // Pumpe
#define MAIN_VALVE_PIN     3   // Hauptventil
#define FERT_VALVE_PIN     4   // Düngerventil
#define FLOW_SENSOR_PIN    5   // Flusssensor

const unsigned int calibrationFaktor = 840;

#endif // CONFIG_PINS_H
