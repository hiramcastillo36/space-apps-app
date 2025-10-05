import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'eventsModel.dart'; 
import 'package:skai/utils/constans.dart';



final List<Map<String, dynamic>> eventJsonList = [
  {
    "id": 1,
    "user_email": "user@example.com",
    "conversation_title": "Weather Consultation",
    "event_name": "Fiesta de cumpleaños",
    "event_date": "2027-08-29T21:00:00Z",
    "location_name": "Queretaro",
    "latitude": 20.58806,
    "longitude": -100.38806,
    "weather_data": {
      "temperature": "25.3 C",
      "precipitation": "0 mm"
    },
    "temperature": null,
    "precipitation": null,
    "wind_speed": null,
    "created_at": "2025-10-05T04:30:08.853633Z",
    "updated_at": "2025-10-05T04:30:08.853655Z"
  }
];

final List<Evento> sampleEvents =
    eventJsonList.map((json) => Evento.fromJson(json)).toList();

class Eventos extends StatelessWidget {
  const Eventos({super.key});

  @override
  Widget build(BuildContext context) {
    const LinearGradient gradient = LinearGradient(
      colors: [
        Color(0xFF5B86E5),
        Color(0xFF9C27B0),
        Color(0xFFE91E63),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Scaffold(
  body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: Text(
                'Mis eventos',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: sampleEvents.length,
              itemBuilder: (context, index) {
                final evento = sampleEvents[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(
                      evento.eventName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 ${evento.eventDate.toLocal()}"),
                        Text("📍 ${evento.locationName}"),
                        Text("🌡️ Temp: ${evento.temperature}"),
                        Text("☔ Precipitación: ${evento.precipitation}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', false),
              _buildSkaiItem(),
              _buildNavItem(Icons.person, 'Profile', true),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? primaryTextColor : Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? primaryTextColor : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        )
      ],
    );
  }

  Widget _buildSkaiItem() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 4),
        Text('SkAI', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

}