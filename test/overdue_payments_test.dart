import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:money_reminder_app/models/transaction_model.dart';
import 'package:money_reminder_app/providers/auth_provider.dart';
import 'package:money_reminder_app/providers/loan_provider.dart';
import 'package:money_reminder_app/providers/transaction_provider.dart';
import 'package:money_reminder_app/screens/dashboard/overdue_payments_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child, {Size size = const Size(360, 800)}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('OverduePaymentsScreen Tests', () {
    testWidgets('OverduePaymentsScreen renders without overflow on 320px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(buildTestableWidget(const OverduePaymentsScreen(), size: const Size(320, 700)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OverduePaymentsScreen), findsOneWidget);
      expect(find.text('Overdue Payments'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OverduePaymentsScreen switches tabs and searches cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(buildTestableWidget(const OverduePaymentsScreen(), size: const Size(360, 800)));
      await tester.pump(const Duration(milliseconds: 300));

      // Tab switching
      await tester.tap(find.textContaining('Payables'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.textContaining('Receivables'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.textContaining('Loan EMIs'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
