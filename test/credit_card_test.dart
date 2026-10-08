import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:money_reminder_app/models/credit_card_model.dart';
import 'package:money_reminder_app/models/credit_card_transaction_model.dart';
import 'package:money_reminder_app/providers/credit_card_provider.dart';
import 'package:money_reminder_app/providers/auth_provider.dart';
import 'package:money_reminder_app/screens/credit_cards/credit_cards_hub_screen.dart';
import 'package:money_reminder_app/screens/credit_cards/add_edit_credit_card_screen.dart';
import 'package:money_reminder_app/screens/credit_cards/add_edit_card_transaction_screen.dart';
import 'package:money_reminder_app/screens/credit_cards/record_card_payment_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Credit Card Model & Calculations Unit Tests', () {
    test('Calculates utilization percentage correctly', () {
      final card = CreditCardModel(
        id: 'c1',
        userId: 'u1',
        cardName: 'HDFC Regalia',
        bankName: 'HDFC Bank',
        totalLimit: 100000.0,
        availableLimit: 75000.0,
        currentOutstanding: 25000.0,
        statementDay: 15,
        dueDay: 5,
        createdAt: DateTime.now(),
      );

      expect(card.utilizationPercentage, 25.0);
      expect(card.utilizationHealth, 'HEALTHY');
      expect(card.utilizationColor, const Color(0xFF10B981));
    });

    test('Identifies Moderate and High utilization thresholds', () {
      final moderateCard = CreditCardModel(
        id: 'c2',
        userId: 'u1',
        cardName: 'SBI Cashback',
        bankName: 'SBI',
        totalLimit: 100000.0,
        availableLimit: 50000.0,
        currentOutstanding: 50000.0,
        createdAt: DateTime.now(),
      );
      expect(moderateCard.utilizationPercentage, 50.0);
      expect(moderateCard.utilizationHealth, 'MODERATE');

      final highCard = CreditCardModel(
        id: 'c3',
        userId: 'u1',
        cardName: 'ICICI Amazon Pay',
        bankName: 'ICICI Bank',
        totalLimit: 100000.0,
        availableLimit: 15000.0,
        currentOutstanding: 85000.0,
        createdAt: DateTime.now(),
      );
      expect(highCard.utilizationPercentage, 85.0);
      expect(highCard.utilizationHealth, 'HIGH');
    });

    test('Statement date and due date calculations return valid dates', () {
      final card = CreditCardModel(
        id: 'c1',
        userId: 'u1',
        cardName: 'Axis Magnus',
        bankName: 'Axis Bank',
        totalLimit: 300000.0,
        availableLimit: 300000.0,
        statementDay: 20,
        dueDay: 10,
        createdAt: DateTime.now(),
      );

      final nextStatement = card.nextStatementDate;
      expect(nextStatement.day, 20);
      expect(card.daysUntilStatement >= 0, true);

      final nextDue = card.nextDueDate;
      expect(nextDue.day, 10);
      expect(card.daysUntilDue >= 0, true);
    });

    test('CreditCardModel and TransactionModel serialization and deserialization', () {
      final card = CreditCardModel(
        id: 'c_test',
        userId: 'u_test',
        cardName: 'OneCard Metal',
        bankName: 'Federal Bank',
        cardNetwork: 'VISA',
        last4Digits: '9921',
        totalLimit: 150000.0,
        availableLimit: 140000.0,
        currentOutstanding: 10000.0,
        statementDay: 18,
        dueDay: 7,
        colorTheme: 'OBSIDIAN',
        reminderEnabled: true,
        interestFreeDays: 48,
        status: 'ACTIVE',
        notes: 'Metal edition card',
        createdAt: DateTime(2026, 1, 1),
      );

      final map = card.toMap();
      final fromMap = CreditCardModel.fromMap(map);

      expect(fromMap.id, 'c_test');
      expect(fromMap.cardName, 'OneCard Metal');
      expect(fromMap.totalLimit, 150000.0);
      expect(fromMap.colorTheme, 'OBSIDIAN');
      expect(fromMap.last4Digits, '9921');

      final tx = CreditCardTransactionModel(
        id: 'tx_1',
        userId: 'u_test',
        cardId: 'c_test',
        amount: 2499.0,
        merchantName: 'Flipkart Electronics',
        category: 'SHOPPING',
        transactionDate: DateTime(2026, 3, 15),
        transactionType: 'EXPENSE',
        isEmi: true,
        emiMonths: 3,
        monthlyEmiAmount: 833.0,
        isBilled: false,
        notes: 'Earphones purchase',
        createdAt: DateTime.now(),
      );

      final txMap = tx.toMap();
      final fromTxMap = CreditCardTransactionModel.fromMap(txMap);

      expect(fromTxMap.id, 'tx_1');
      expect(fromTxMap.amount, 2499.0);
      expect(fromTxMap.isEmi, true);
      expect(fromTxMap.emiMonths, 3);
    });
  });

  group('Credit Card Responsive UI Widget Tests (320px width)', () {
    Widget buildTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CreditCardProvider()),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('CreditCardsHubScreen renders without overflow on narrow 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(buildTestWidget(const CreditCardsHubScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Credit Cards Hub'), findsOneWidget);
    });

    testWidgets('AddEditCreditCardScreen renders without overflow on narrow 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(buildTestWidget(const AddEditCreditCardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Add Credit Card'), findsOneWidget);
      expect(find.text('Save Credit Card'), findsOneWidget);
    });

    testWidgets('AddEditCardTransactionScreen renders cleanly on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(buildTestWidget(const AddEditCardTransactionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Log Card Spend / Swipe'), findsOneWidget);
    });

    testWidgets('RecordCardPaymentDialog renders correctly and calculates min due', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2.0;

      final testCard = CreditCardModel(
        id: 'c_test_pay',
        userId: 'u1',
        cardName: 'HDFC Regalia Gold',
        bankName: 'HDFC Bank',
        totalLimit: 200000.0,
        availableLimit: 170000.0,
        currentOutstanding: 30000.0,
        statementDay: 15,
        dueDay: 5,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(buildTestWidget(Scaffold(body: RecordCardPaymentDialog(card: testCard))));
      await tester.pumpAndSettle();

      expect(find.text('Clear / Pay Card Bill'), findsOneWidget);
      expect(find.text('HDFC Regalia Gold'), findsOneWidget);
    });
  });
}
