import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spazz_fixed/screens/map_screen.dart';

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

  testWidgets('MapScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    
    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    await tester.pumpAndSettle();
    
    // Verify GoogleMap exists
    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
