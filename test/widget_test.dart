import 'package:flutter_test/flutter_test.dart';
import 'package:money_reminder_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MoneyReminderApp());
    expect(find.byType(MoneyReminderApp), findsOneWidget);
  });
}
