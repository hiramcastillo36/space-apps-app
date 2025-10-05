import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Token almacenado en memoria
  static String? _authToken;

  static String get baseUrl {
    // Servidor de producción
    return 'http://20.151.177.103:8080';
  }

  // Login - Usa el endpoint /api/user/token/
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/token/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Login response: $data');

          // Guardar token (el endpoint retorna 'token')
          if (data['token'] != null) {
            try {
              await _saveToken(data['token']);
              print('Token saved successfully');
            } catch (saveError) {
              print('Error saving token: $saveError');
              return {'success': false, 'error': 'Failed to save token: $saveError'};
            }
          } else {
            return {'success': false, 'error': 'No token in response'};
          }

          return {'success': true, 'data': data};
        } catch (e) {
          print('Error parsing response: $e');
          return {'success': false, 'error': 'Invalid response format: $e'};
        }
      } else {
        // Intentar decodificar el error
        try {
          final error = json.decode(response.body);
          return {'success': false, 'error': error['message'] ?? error.toString()};
        } catch (e) {
          return {'success': false, 'error': 'Login failed: ${response.statusCode} - ${response.body}'};
        }
      }
    } catch (e) {
      print('Connection error: $e');
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Registro - Usa el endpoint /api/user/create/
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/create/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Después de crear el usuario, hacer login automáticamente
        final loginResult = await login(email, password);
        return loginResult;
      } else {
        // Intentar decodificar el error
        try {
          final error = json.decode(response.body);
          return {'success': false, 'error': error['message'] ?? error.toString()};
        } catch (e) {
          return {'success': false, 'error': 'Registration failed: ${response.statusCode} - ${response.body}'};
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Guardar token (en memoria)
  static Future<void> _saveToken(String token) async {
    _authToken = token;
    print('Token guardado en memoria: $_authToken');
  }

  // Obtener token
  static Future<String?> getToken() async {
    return _authToken;
  }

  // Verificar si está autenticado
  static Future<bool> isAuthenticated() async {
    return _authToken != null;
  }

  // Cerrar sesión
  static Future<void> logout() async {
    _authToken = null;
  }
}
