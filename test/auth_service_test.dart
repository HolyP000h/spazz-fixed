import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spazz_fixed/services/auth_service.dart';
import 'package:spazz_fixed/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiService.authRequest = (path, body) async => {
      'token': 'test-token',
      'user_id': body['username'],
      'username': body['username'],
    };
    await AuthService.clearSession();
  });

  tearDown(() {
    ApiService.authRequest = null;
  });

  test('login persists username and clearSession removes it', () async {
    await AuthService.register('alice@example.com', 'password123');
    await AuthService.clearSession();
    await AuthService.login('alice@example.com', 'password123');

    expect(await AuthService.getUsername(), 'alice@example.com');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_username'), 'alice@example.com');
    expect(prefs.getBool('auth_is_authenticated'), true);

    await AuthService.clearSession();

    expect(await AuthService.getUsername(), isNull);
    expect(prefs.getString('auth_username'), isNull);
    expect(prefs.getBool('auth_is_authenticated'), false);
  });
}
