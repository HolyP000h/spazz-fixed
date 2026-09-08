import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? _currentUsername;
  static bool _isAuthenticated = false;

  static Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('auth_username');
    _isAuthenticated = prefs.getBool('auth_is_authenticated') ?? false;
  }

  static Future<Map<String, dynamic>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'gender': prefs.getString('pref_gender') ?? 'Not Set',
      'age': prefs.getInt('pref_age') ?? 18,
      'interested_in': prefs.getString('pref_interested_in') ?? 'Both',
      'min_age': prefs.getInt('pref_min_age') ?? 18,
      'max_age': prefs.getInt('pref_max_age') ?? 99,
      'is_broadcasting': prefs.getBool('pref_is_broadcasting') ?? false,
      'home_address': prefs.getString('pref_home_address') ?? '',
      'home_lat': prefs.getDouble('pref_home_lat') ?? 0.0,
      'home_lng': prefs.getDouble('pref_home_lng') ?? 0.0,
      'geofence_radius': prefs.getDouble('pref_geofence_radius') ?? 250.0,
    };
  }

  static Future<void> updatePreferences({
    String? gender,
    int? age,
    String? interestedIn,
    int? minAge,
    int? maxAge,
    bool? isBroadcasting,
    String? homeAddress,
    double? homeLat,
    double? homeLng,
    double? geofenceRadius,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (gender != null) await prefs.setString('pref_gender', gender);
    if (age != null) await prefs.setInt('pref_age', age);
    if (interestedIn != null) await prefs.setString('pref_interested_in', interestedIn);
    if (minAge != null) await prefs.setInt('pref_min_age', minAge);
    if (maxAge != null) await prefs.setInt('pref_max_age', maxAge);
    if (isBroadcasting != null) await prefs.setBool('pref_is_broadcasting', isBroadcasting);
    if (homeAddress != null) await prefs.setString('pref_home_address', homeAddress);
    if (homeLat != null) await prefs.setDouble('pref_home_lat', homeLat);
    if (homeLng != null) await prefs.setDouble('pref_home_lng', homeLng);
    if (geofenceRadius != null) await prefs.setDouble('pref_geofence_radius', geofenceRadius);
  }

  static Future<bool> isBankLinked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auth_bank_linked') ?? false;
  }

  static Future<void> linkBank(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_bank_linked', value);
  }

  static Future<bool> login(String email, String password) async {
    final username = email.trim();
    if (username.isEmpty) return false;

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
    final username = email.trim();
    if (username.isEmpty) return false;

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

    _currentUsername = 'google-user'; // Simulated google user
    _isAuthenticated = true;

    await prefs.setString('auth_username', _currentUsername!);
    await prefs.setBool('auth_is_authenticated', true);
    await prefs.setString('token', 'demo-token');
    await prefs.setString('user_id', 'google-user');
  }

  static Future<String?> getUsername() async {
    if (_currentUsername == null) {
      await _loadFromStorage();
    }
    return _currentUsername;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = null;
    _isAuthenticated = false;
    await prefs.setString('auth_username', ''); // Using empty string instead of remove to ensure it exists if requested, or just remove and handle null
    await prefs.setBool('auth_is_authenticated', false);
    await prefs.remove('token');
    await prefs.remove('user_id');
    // Actually, to match the test's expectation of prefs.getString(...) being null, we should remove it.
    await prefs.remove('auth_username');
  }

  static Future<bool> get isAuthenticated async {
    await _loadFromStorage();
    return _isAuthenticated;
  }
}