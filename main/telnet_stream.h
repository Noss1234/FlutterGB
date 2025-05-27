// telnet_stream.h
// Diese Datei implementiert eine Telnet-Debug-Ausgabe mit optionaler Serial-Kopie.
// Kein TelnetStream-Bibliotheksimport nötig – volle Kompatibilität mit Pico W.

#ifndef TELNET_STREAM_H
#define TELNET_STREAM_H

#include <WiFi.h>
#include <WiFiServer.h>

// Telnet-Server (Port 23) + erster verbundener Client
WiFiServer telnetServer(23);
WiFiClient telnetClient;

class TelnetLogger {
public:
  void begin() {
    telnetServer.begin();
    Serial.println("Telnet-Server gestartet auf Port 23.");
  }

  void handle() {
    if (!telnetClient || !telnetClient.connected()) {
      telnetClient = telnetServer.accept();
    }
  }

  template <typename T>
  void print(T msg) {
    if (telnetClient && telnetClient.connected()) {
      telnetClient.print(msg);
    }
    Serial.print(msg);
  }

  template <typename T>
  void println(T msg) {
    if (telnetClient && telnetClient.connected()) {
      telnetClient.println(msg);
    }
    Serial.println(msg);
  }

  void printf(const char* format, ...) {
    char buffer[256];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);
    if (telnetClient && telnetClient.connected()) {
      telnetClient.print(buffer);
    }
    Serial.print(buffer);
  }
};

// Globale Instanz
TelnetLogger TelnetStream;

// Logging-Makro
#define LOG(x) TelnetStream.println(x)

#endif // TELNET_STREAM_H
