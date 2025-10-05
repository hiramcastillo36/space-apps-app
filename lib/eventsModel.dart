class Evento {
  final int id;
  final String userEmail;
  final String conversationTitle;
  final String eventName;
  final DateTime eventDate;
  final String locationName;
  final double latitude;
  final double longitude;
  final String? temperature;
  final String? precipitation;
  final String? windSpeed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Evento({
    required this.id,
    required this.userEmail,
    required this.conversationTitle,
    required this.eventName,
    required this.eventDate,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.temperature,
    this.precipitation,
    this.windSpeed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    // Extraer datos del clima
    String? temp;
    String? precip;
    String? wind;

    // Verificar si weather_data existe y tiene la estructura correcta
    if (json["weather_data"] != null) {
      final weatherData = json["weather_data"];

      // Caso 1: estructura antigua con temperature y precipitation directos
      if (weatherData["temperature"] != null) {
        temp = weatherData["temperature"].toString();
      }
      if (weatherData["precipitation"] != null) {
        precip = weatherData["precipitation"].toString();
      }

      // Caso 2: estructura nueva con current.data[0]
      if (weatherData["current"] != null &&
          weatherData["current"]["data"] != null &&
          weatherData["current"]["data"] is List &&
          (weatherData["current"]["data"] as List).isNotEmpty) {
        final currentData = weatherData["current"]["data"][0];

        if (currentData["t_2m:C"] != null) {
          temp = "${currentData["t_2m:C"]} °C";
        }
        if (currentData["precip_1h:mm"] != null) {
          precip = "${currentData["precip_1h:mm"]} mm";
        }
        if (currentData["wind_speed_10m:kmh"] != null) {
          wind = "${currentData["wind_speed_10m:kmh"]} km/h";
        }
      }
    }

    // Usar campos directos si existen
    if (json["temperature"] != null) {
      temp = json["temperature"].toString();
    }
    if (json["precipitation"] != null) {
      precip = json["precipitation"].toString();
    }
    if (json["wind_speed"] != null) {
      wind = json["wind_speed"].toString();
    }

    return Evento(
      id: json["id"],
      userEmail: json["user_email"] ?? "",
      conversationTitle: json["conversation_title"] ?? "",
      eventName: json["event_name"] ?? "Sin nombre",
      eventDate: DateTime.parse(json["event_date"]),
      locationName: json["location_name"] ?? "Sin ubicación",
      latitude: (json["latitude"] as num?)?.toDouble() ?? 0.0,
      longitude: (json["longitude"] as num?)?.toDouble() ?? 0.0,
      temperature: temp,
      precipitation: precip,
      windSpeed: wind,
      createdAt: DateTime.parse(json["created_at"]),
      updatedAt: DateTime.parse(json["updated_at"]),
    );
  }
}