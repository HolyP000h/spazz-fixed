import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ignore_for_file: avoid_print

class ApiService {
  static const String _baseUrl = 'https://www.spazzapp.com';

  static Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    // --- DEVELOPMENT MOCK SYSTEM ---
    // Intercept requests locally to prevent 401/404 server blocks
    
    if (path.contains('/api/user/')) {
      return {
        "username": "ben",
        "level": 1,
        "xp": 35,
        "steps": 4820,
        "calories": 245,
        "wisps": 12
      };
    }

    if (path.contains('/api/leaderboard')) {
      return [
        {"username": "ben", "wisps": 12, "level": 1},
        {"username": "ShadowHunter", "wisps": 9, "level": 1},
        {"username": "WispMaster", "wisps": 5, "level": 1}
      ];
    }

    if (path.contains('/api/nearby') || path.contains('/api/ping/nearby')) {
      // Returns empty list or simulated nearby data if needed
      return [];
    }
    // ---------------------------------

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?headers,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    throw Exception('Request failed with ${response.statusCode}: ${response.body}');
  }

  static Future<dynamic> post(String path, dynamic body, {Map<String, String>? headers}) async {
    // --- DEVELOPMENT MOCK SYSTEM ---
    print("ApiService MOCK POST Intercepted: $path");
    
    if (path.contains('/api/location/update')) {
      return {"status": "success", "message": "Location mocked successfully"};
    }
    // ---------------------------------

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?headers,
      },
      body: json.encode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    throw Exception('Request failed with ${response.statusCode}: ${response.body}');
  }
}