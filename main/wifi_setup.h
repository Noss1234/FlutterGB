// wifi_setup.h
// Diese Datei kümmert sich um WLAN-Verbindung und NTP-Zeit. mDNS wird deaktiviert.

#ifndef WIFI_SETUP_H
#define WIFI_SETUP_H

#include <WiFi.h>
#include <WiFiUdp.h>
#include <NTPClient.h>
#include "telnet_stream.h"

// WLAN-Zugangsdaten
#define WIFI_SSID     "gigacube-4F75"
#define WIFI_PASS     "66toggotv"

// Zeitzone + NTP-Client (UTC+1 für Mitteleuropa)
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 3600, 60000);

// Initialisiert WLAN und NTP
void initWiFi() {
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    LOG("WLAN verbunden: " + WiFi.localIP().toString());

    timeClient.begin();
}

// Aktuelle Zeit (zur Auswertung von Routinen)
struct ZeitInfo {
  int tag;
  int stunde;
  int minute;
};

ZeitInfo aktualisiereZeit() {
    timeClient.update();
    ZeitInfo z;
    z.tag = timeClient.getDay();         // 0 = Sonntag, 6 = Samstag
    z.stunde = timeClient.getHours();
    z.minute = timeClient.getMinutes();
    return z;
}

#endif // WIFI_SETUP_H
