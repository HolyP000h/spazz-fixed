import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ignore_for_file: avoid_print

class ApiService {
  static const String _baseUrl = 'https://www.spazzapp.com';
  static Future<dynamic> Function(String, Map<String, dynamic>)? authRequest;

  // --- MOCK DATABASE ---
  static final List<Map<String, dynamic>> _friends = [];
  static final Map<String, List<Map<String, dynamic>>> _messagesByFriend = {};
  static final List<Map<String, dynamic>> _droppedNotes = [];
  static final List<Map<String, dynamic>> _blessedWisps = [];
  // ---------------------

  static Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    // --- DEVELOPMENT MOCK SYSTEM ---
    
    if (path.contains('/api/friends')) {
      return {"friends": _friends};
    }

    if (path.contains('/api/chat/')) {
      final friendId = path.split('/').last;
      return {"messages": _messagesByFriend[friendId] ?? []};
    }

    if (path.contains('/api/notes/nearby')) {
      return {"notes": _droppedNotes};
    }

    if (path.contains('/api/wisps/blessed')) {
      return {"wisps": _blessedWisps};
    }

    if (path.contains('/api/coach/status')) {
      return {
        "main_nudge": "Hey it's nice outside, it's the weekend lets go for a walk get some sun little by little we can be better than ever! Lets make today the 1st day of our new lives.",
        "pinpoints": [
          "Remember to smile more! Your energy is great, but a smile opens doors.",
          "Keep it fresh! A sharp outfit makes you demand attention when you go out.",
          "Work on US so when we find OURS we will be ready!"
        ],
        "goals": [
          {
            "title": "Stay Spazz-Ready",
            "description": "Walk 2 miles today to keep your energy high.",
            "progress": 0.65
          },
          {
            "title": "Character Building",
            "description": "Complete 3 encounters this week.",
            "progress": 0.33
          }
        ]
      };
    }

    if (path.contains('/api/encounter/feedback')) {
      return {"status": "success", "message": "Feedback processed by Coach AI"};
    }

    if (path.contains('/api/leaderboard')) {
      return [
        {"username": "ben", "wisps": 12, "level": 1},
        {"username": "ShadowHunter", "wisps": 9, "level": 1},
        {"username": "WispMaster", "wisps": 5, "level": 1}
      ];
    }

    if (path.contains('/api/ping/nearby')) {
      // Return a simulated match for testing the "Spazz" flow
      return {
        "users": [
          {
            "id": "match_123",
            "username": "Sarah",
            "lat": 0.0, // Will be offset from user in MapScreen
            "lng": 0.0,
            "is_premium": false,
            "gender": "Female",
            "age": 24,
            "is_broadcasting": true
          }
        ],
        "wisps": [
          {"id": "wisp_1", "lat": 0.001, "lng": 0.001, "xp": 10, "credits": 5}
        ],
        "hotspots": []
      };
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
    
    if (path.contains('/api/register') || path.contains('/api/login')) {
      final request = authRequest;
      if (request != null) return request(path, Map<String, dynamic>.from(body as Map));

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          ...?headers,
        },
        body: json.encode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      }
      throw Exception('Request failed with ${response.statusCode}: ${response.body}');
    }

    if (path.contains('/api/friends/add')) {
      final friend = body as Map<String, dynamic>;
      if (!_friends.any((f) => f['id'] == friend['id'])) {
        _friends.add({
          ...friend,
          'met_at': DateTime.now().toIso8601String(),
        });
      }
      return {"status": "success"};
    }

    if (path.contains('/api/chat/send')) {
      final data = body as Map<String, dynamic>;
      final friendId = data['friend_id'];
      final message = {
        'username': 'ben', // assuming current user
        'message': data['message'],
        'timestamp': DateTime.now().toIso8601String(),
      };
      _messagesByFriend.putIfAbsent(friendId, () => []).add(message);
      return {"status": "success", "message": message};
    }

    if (path.contains('/api/notes/drop')) {
      final note = body as Map<String, dynamic>;
      _droppedNotes.add({
        ...note,
        'id': 'note_${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
      });
      return {"status": "success"};
    }

    if (path.contains('/api/wisp/bless')) {
      final data = body as Map<String, dynamic>;
      _blessedWisps.add({
        'id': 'blessed_${DateTime.now().millisecondsSinceEpoch}',
        'lat': data['lat'],
        'lng': data['lng'],
        'cash_value': data['amount'],
        'message': data['message'] ?? 'A blessing for you!',
        'created_at': DateTime.now().toIso8601String(),
      });
      return {"status": "success"};
    }

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