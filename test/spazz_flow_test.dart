import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    // Initial loading state is stable and should not hang the test runner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // The screen intentionally starts background location/timer work, which should not
    // be awaited with pumpAndSettle in a widget test because it keeps scheduling updates.
    await tester.pump();
    expect(find.byType(MapScreen), findsOneWidget);
  });
}
