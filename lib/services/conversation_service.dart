import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skai/services/auth_service.dart';

class ConversationService {
  static String get baseUrl => AuthService.baseUrl;

  // Crear una nueva conversación
  static Future<Map<String, dynamic>> createConversation(String title) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/conversations/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'title': title,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Conversation created: $data');
        return {'success': true, 'data': data};
      } else {
        print('Error creating conversation: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Failed to create conversation: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error creating conversation: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Obtener ID de conversación del response
  static int? getConversationId(Map<String, dynamic> response) {
    if (response['success'] == true && response['data'] != null) {
      return response['data']['id'] as int?;
    }
    return null;
  }
}
