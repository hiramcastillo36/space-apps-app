import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skai/services/auth_service.dart';

class EventsService {
  static String get baseUrl => AuthService.baseUrl;

  // Obtener todos los eventos
  static Future<Map<String, dynamic>> getEvents() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/events/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Events fetched: $data');
        return {'success': true, 'data': data};
      } else {
        print('Error fetching events: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Failed to fetch events: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error fetching events: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
}
