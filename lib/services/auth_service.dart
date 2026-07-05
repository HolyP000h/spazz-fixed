import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? _currentUsername;
  static bool _isAuthenticated = false;

  static Future<void> _loadFromStorage() async {
    if (_currentUsername != null || _isAuthenticated) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('auth_username');
    _isAuthenticated = prefs.getBool('auth_is_authenticated') ?? false;
  }

  static Future<bool> login(String email, String password) async {
    final username = email.trim().isEmpty ? 'user' : email.trim();
    final prefs = await SharedPreferences.getInstance();

    _currentUsername = username;
    _isAuthenticated = true;

    await prefs.setString('auth_username', username);
    await prefs.setBool('auth_is_authenticated', true);
    await prefs.setString('token', 'demo-token');
    await prefs.setString('user_id', username);
    return true;
  }

  static Future<bool> register(String email, String password) async {
    final username = email.trim().isEmpty ? 'user' : email.trim();
    final prefs = await SharedPreferences.getInstance();

    _currentUsername = username;
    _isAuthenticated = true;

    await prefs.setString('auth_username', username);
    await prefs.setBool('auth_is_authenticated', true);
    await prefs.setString('token', 'demo-token');
    await prefs.setString('user_id', username);
    return true;
  }

  static Future<void> signInWithGoogle() async {
    final prefs = await SharedPreferences.getInstance();

    _currentUsername = 'Google User';
    _isAuthenticated = true;

    await prefs.setString('auth_username', _currentUsername!);
    await prefs.setBool('auth_is_authenticated', true);
    await prefs.setString('token', 'demo-token');
    await prefs.setString('user_id', 'google-user');
  }

  static Future<String?> getUsername() async {
    await _loadFromStorage();
    return _currentUsername;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    _currentUsername = null;
    _isAuthenticated = false;

    await prefs.remove('auth_username');
    await prefs.setBool('auth_is_authenticated', false);
    await prefs.remove('token');
    await prefs.remove('user_id');
  }

  static Future<bool> get isAuthenticated async {
    await _loadFromStorage();
    return _isAuthenticated;
  }
}