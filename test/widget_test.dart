import 'package:flutter_test/flutter_test.dart';
import 'package:eduflow/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify app builds (basic sanity test)
    expect(find.byType(MyApp), findsOneWidget);
  });
}