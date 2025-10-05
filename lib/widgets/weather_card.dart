import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  late Future<WeatherData> _future;

  // ✅ Usa --dart-define (recomendado) o cambia el defaultValue por tu key
  static final String _owmApiKey =
      const String.fromEnvironment('OWM_API_KEY', defaultValue: '473bca70c79f7118680bd8a59bd58c18');

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<WeatherData> _load() async {
    // 1) Permisos y ubicación
    final position = await _getPosition();
    // 2) Fetch clima
    return _fetchWeather(position.latitude, position.longitude);
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Intenta habilitar, o lanza error legible
      throw 'Servicios de ubicación deshabilitados.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw 'Permiso de ubicación denegado permanentemente (ajustes del sistema).';
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw 'Permiso de ubicación denegado.';
      }
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<WeatherData> _fetchWeather(double lat, double lon) async {
    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/weather',
      {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'appid': _owmApiKey,
        'units': 'metric',
        'lang': 'es',
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw 'Error al obtener clima (${res.statusCode})';
    }

    final json = jsonDecode(res.body);
    return WeatherData.fromJson(json);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _card(
            child: Row(
              children: [
                const SizedBox(width: 8),
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(width: 16),
                Text('Cargando clima...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
              ],
            ),
          );
        }

        if (snap.hasError) {
          return _card(
            child: Text(
              snap.error.toString(),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          );
        }

        final data = snap.data!;
        return _card(
          child: Row(
            children: [
              // Icono del clima de OWM
              if (data.iconUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Image.network(
                    data.iconUrl!,
                    width: 52,
                    height: 52,
                  ),
                ),
              // Texto principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data.city}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 2),
                    Text('${data.description}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.95),
                        )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _chip('${data.temp.toStringAsFixed(1)}°C'),
                        _chip('ST ${data.feelsLike.toStringAsFixed(0)}°'),
                        _chip('Humedad ${data.humidity}%'),
                        _chip('Viento ${data.wind.toStringAsFixed(0)} km/h'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B86E5), Color(0xFF9C27B0), Color(0xFFE91E63)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class WeatherData {
  final String city;
  final String description;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double wind;
  final String? iconUrl;

  WeatherData({
    required this.city,
    required this.description,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.iconUrl,
  });

  factory WeatherData.fromJson(Map<String, dynamic> j) {
    final weather = (j['weather'] as List).isNotEmpty ? j['weather'][0] : null;
    final icon = weather?['icon'];
    return WeatherData(
      city: j['name'] ?? 'Tu ubicación',
      description: weather?['description'] ?? '—',
      temp: (j['main']?['temp'] ?? 0).toDouble(),
      feelsLike: (j['main']?['feels_like'] ?? 0).toDouble(),
      humidity: (j['main']?['humidity'] ?? 0).toInt(),
      wind: ((j['wind']?['speed'] ?? 0) as num).toDouble() * 3.6, // m/s → km/h
      iconUrl: icon != null ? 'https://openweathermap.org/img/wn/$icon@2x.png' : null,
    );
  }
}
