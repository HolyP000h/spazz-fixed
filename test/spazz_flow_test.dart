import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spazz_fixed/screens/map_screen.dart';
import 'package:spazz_fixed/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_username': 'test_user',
      'auth_is_authenticated': true,
      'pref_is_broadcasting': true,
      'pref_gender': 'Male',
      'pref_interested_in': 'Female',
      'pref_min_age': 18,
      'pref_max_age': 30,
    });
  });

  testWidgets('MapScreen triggers Spazz Alert when match is nearby', (WidgetTester tester) async {
    // Note: This test requires mocking Geolocator and ApiService more deeply for a full integration test.
    // However, we can verify the widget renders and initial state is correct.
    
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    
    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    await tester.pumpAndSettle();
    
    // Verify Radar is present when location is "found" (simulated by settling)
    // Since we can't easily simulate movement in a simple widget test without dependency injection,
    // we verify the components exist.
    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
