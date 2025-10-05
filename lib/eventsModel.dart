class Evento {
  final int id;
  final String userEmail;
  final String conversationTitle;
  final String eventName;
  final DateTime eventDate;
  final String locationName;
  final double latitude;
  final double longitude;
  final String temperature;
  final String precipitation;
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
    required this.temperature,
    required this.precipitation,
    this.windSpeed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json["id"],
      userEmail: json["user_email"],
      conversationTitle: json["conversation_title"],
      eventName: json["event_name"],
      eventDate: DateTime.parse(json["event_date"]),
      locationName: json["location_name"],
      latitude: (json["latitude"] as num).toDouble(),
      longitude: (json["longitude"] as num).toDouble(),
      temperature: json["weather_data"]["temperature"],
      precipitation: json["weather_data"]["precipitation"],
      windSpeed: json["wind_speed"],
      createdAt: DateTime.parse(json["created_at"]),
      updatedAt: DateTime.parse(json["updated_at"]),
    );
  }
}