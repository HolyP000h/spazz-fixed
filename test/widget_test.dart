import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spazz_fixed/main.dart';
import 'package:spazz_fixed/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the login screen on app launch', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SPAZZ'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('profile screen shows a save action for manual home address entry', (tester) async {
    SharedPreferences.setMockInitialValues({
      'pref_home_address': '',
      'pref_home_lat': 0.0,
      'pref_home_lng': 0.0,
      'pref_geofence_radius': 250.0,
    });

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Save Address'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123 Main St');
    await tester.ensureVisible(find.text('Save Address'));
    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pref_home_address'), '123 Main St');
  });
}
