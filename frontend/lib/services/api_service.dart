import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use relative URL for same-origin requests
  // Nginx will proxy /api/* to backend
  final String baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: '/api/v1',
  );

  /// Get hello message from backend
  Future<Map<String, dynamic>> getHello() async {
    final response = await http.get(Uri.parse('$baseUrl/hello'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load hello message: ${response.statusCode}');
    }
  }

  /// Get system information from backend
  Future<Map<String, dynamic>> getSystemInfo() async {
    final response = await http.get(Uri.parse('$baseUrl/info'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load system info: ${response.statusCode}');
    }
  }

  /// Check backend health
  Future<Map<String, dynamic>> getHealth() async {
    final response = await http.get(Uri.parse('/health'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check health: ${response.statusCode}');
    }
  }
}
