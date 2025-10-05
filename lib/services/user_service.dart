import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skai/services/auth_service.dart';

class UserService {
  static const String baseUrl = 'http://20.151.177.103:8080';

  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final token = await AuthService.getToken();

      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token available'
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/me/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'email': data['email'],
          'name': data['name'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch user info: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error fetching user info: $e'
      };
    }
  }
}
