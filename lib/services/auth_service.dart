import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? _currentUsername;
  static bool _isAuthenticated = false;

  static Future<void> _loadFromStorage() async {
    // --- DEVELOPMENT OVERRIDE ---
    // This forces your local storage to always be authenticated as 'ben'
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = 'ben';
    _isAuthenticated = true;
    
    await prefs.setString('auth_username', 'ben');
    await prefs.setBool('auth_is_authenticated', true);
    await prefs.setString('token', 'demo-token'); 
    await prefs.setString('user_id', 'ben');
    return;
    // ----------------------------
  }

  static Future<bool> login(String email, String password) async {
    final username = email.trim().isEmpty ? 'ben' : email.trim();
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
    final username = email.trim().isEmpty ? 'ben' : email.trim();
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

    _currentUsername = 'ben';
    _isAuthenticated = true;

    await prefs.setString('auth_username', _currentUsername!);
    await prefs.setBool('auth_is_authenticated', true);
    await prefs.setString('token', 'demo-token');
    await prefs.setString('user_id', 'ben');
  }

  static Future<String?> getUsername() async {
    await _loadFromStorage();
    return _currentUsername;
  }

  static Future<void> clearSession() async {
    // Disabled during testing so it doesn't wipe our forced auth block
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = 'ben';
    _isAuthenticated = true;
  }

  static Future<bool> get isAuthenticated async {
    await _loadFromStorage();
    return _isAuthenticated;
  }
}