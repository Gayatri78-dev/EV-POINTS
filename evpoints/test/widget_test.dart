import 'package:flutter_test/flutter_test.dart';
import 'package:evpoints/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Just ensure the widget tree builds without errors
    expect(find.byType(App), findsOneWidget);
  });
}
