class RoutineTime {
  final int day; // Wochentag (0 = Sonntag, 1 = Montag, ..., 6 = Samstag)
  bool isEnabled; // Ob diese Zeit aktiviert ist
  int hour; // Stunde der Bewässerung (0-23)
  int minute; // Minute der Bewässerung
  final int relay; // Kanal/Relais für diese Bewässerung (1-8)
  int duration; // Dauer der Bewässerung in Sekunden

  RoutineTime({
    required this.day,
    required this.isEnabled,
    required this.hour,
    required this.minute,
    required this.relay,
    required this.duration,
  });

  // Serialisiert das RoutineTime-Objekt in eine JSON-Karte
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isEnabled': isEnabled,
      'hour': hour,
      'minute': minute,
      'relay': relay,
      'duration': duration,
    };
  }

  // Erzeugt ein RoutineTime-Objekt aus einer JSON-Karte
  factory RoutineTime.fromJson(Map<String, dynamic> json) {
    return RoutineTime(
      day: json['day'],
      isEnabled: json['isEnabled'],
      hour: json['hour'],
      minute: json['minute'],
      relay: json['relay'],
      duration: json['duration'],
    );
  }

  // Erzeugt eine Standard-Wochenroutine (7 Einträge, für jeden Wochentag einen Eintrag)
  static List<RoutineTime> defaultWeekSchedule(int relay) {
    return List.generate(7, (index) {
      return RoutineTime(
        day: index,
        isEnabled: false,
        hour: 0,
        minute: 0,
        relay: relay,
        duration: 0,
      );
    });
  }
}
