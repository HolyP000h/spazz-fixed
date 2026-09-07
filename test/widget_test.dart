import 'package:flutter_test/flutter_test.dart';
import 'package:spazz_fixed/main.dart';

void main() {
  testWidgets('shows the login screen on app launch', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SPAZZ'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
