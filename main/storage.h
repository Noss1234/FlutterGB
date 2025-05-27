// storage.h
// Diese Datei speichert Routinen und Wasserverbrauch persistent in LittleFS (Flash).
// Sie nutzt ArduinoJson für die einfache Serialisierung.

#ifndef STORAGE_H
#define STORAGE_H

#include <LittleFS.h>
#define PICO_FLASH_FS LittleFS

#include <ArduinoJson.h>
#include "config_pins.h"
#include "state.h"
#include "telnet_stream.h"
#include "routines.h"

// Dateinamen für Speicherdateien
const char* ROUTINES_FILE = "/routines.json";
const char* USAGE_FILE = "/usage.json";

// ==== Wasserverbrauch laden/speichern ====

void loadWasserVerbrauchtFromFS() {
    if (!PICO_FLASH_FS.exists(USAGE_FILE)) {
        for (int i = 0; i < NUM_ZONES; i++) wasser_verbraucht[i] = 0;
        LOG("Wasserverbrauchsdatei nicht gefunden – init mit 0");
        return;
    }

    File file = PICO_FLASH_FS.open(USAGE_FILE, "r");
    if (!file) return;

    StaticJsonDocument<512> doc;
    if (deserializeJson(doc, file)) {
        LOG("Fehler beim Parsen der usage.json");
        file.close();
        return;
    }

    for (int i = 0; i < NUM_ZONES; i++) {
        String key = "kanal_" + String(i);
        wasser_verbraucht[i] = doc[key] | 0;
    }
    file.close();
    LOG("Wasserverbrauch geladen");
}

void saveWasserVerbrauchtToFS() {
    File file = PICO_FLASH_FS.open(USAGE_FILE, "w");
    if (!file) return;

    StaticJsonDocument<512> doc;
    for (int i = 0; i < NUM_ZONES; i++) {
        doc["kanal_" + String(i)] = wasser_verbraucht[i];
    }
    serializeJson(doc, file);
    file.close();
    LOG("Wasserverbrauch gespeichert");
}

// ==== Routinen speichern/laden ====

void loadRoutinenFromFS(Routine* pool, int& count, int maxCount) {
    if (!PICO_FLASH_FS.exists(ROUTINES_FILE)) {
        LOG("Routinen-Datei nicht gefunden");
        count = 0;
        return;
    }

    File file = PICO_FLASH_FS.open(ROUTINES_FILE, "r");
    if (!file) return;

    StaticJsonDocument<2048> doc;
    DeserializationError err = deserializeJson(doc, file);
    if (err) {
        LOG("Fehler beim Parsen der routines.json");
        file.close();
        return;
    }

    JsonArray arr = doc.as<JsonArray>();
    count = 0;
    for (JsonObject o : arr) {
        if (count >= maxCount) break;
        pool[count].kanal = o["kanal"];
        pool[count].duengen = o["duengen"];
        pool[count].wassermenge = o["wassermenge"];
        pool[count].tag = o["tag"];
        pool[count].stunde = o["stunde"];
        pool[count].minute = o["minute"];
        pool[count].isEnabled = o["isEnabled"];
        count++;
    }
    file.close();
    LOG("Routinen geladen");
}

void saveRoutinenToFS(Routine* pool, int count) {
    File file = PICO_FLASH_FS.open(ROUTINES_FILE, "w");
    if (!file) return;

    StaticJsonDocument<2048> doc;
    JsonArray arr = doc.to<JsonArray>();
    for (int i = 0; i < count; i++) {
        JsonObject o = arr.createNestedObject();
        o["kanal"] = pool[i].kanal;
        o["duengen"] = pool[i].duengen;
        o["wassermenge"] = pool[i].wassermenge;
        o["tag"] = pool[i].tag;
        o["stunde"] = pool[i].stunde;
        o["minute"] = pool[i].minute;
        o["isEnabled"] = pool[i].isEnabled;
    }
    serializeJson(doc, file);
    file.close();
    LOG("Routinen gespeichert");
}

#endif // STORAGE_H
