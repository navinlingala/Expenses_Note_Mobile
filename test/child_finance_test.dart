import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:money_reminder_app/models/child_profile_model.dart';
import 'package:money_reminder_app/models/child_expense_model.dart';
import 'package:money_reminder_app/models/child_investment_model.dart';
import 'package:money_reminder_app/models/child_future_goal_model.dart';
import 'package:money_reminder_app/providers/child_provider.dart';
import 'package:money_reminder_app/providers/auth_provider.dart';
import 'package:money_reminder_app/providers/loan_provider.dart';
import 'package:money_reminder_app/providers/transaction_provider.dart';
import 'package:money_reminder_app/providers/investment_provider.dart';
import 'package:money_reminder_app/providers/income_provider.dart';
import 'package:money_reminder_app/providers/gold_provider.dart';
import 'package:money_reminder_app/screens/child/child_hub_screen.dart';
import 'package:money_reminder_app/screens/child/add_edit_child_profile_screen.dart';
import 'package:money_reminder_app/screens/child/add_edit_child_expense_screen.dart';
import 'package:money_reminder_app/screens/child/add_edit_child_investment_screen.dart';
import 'package:money_reminder_app/screens/child/add_edit_child_goal_screen.dart';

Widget createTestableWidget(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => LoanProvider()),
      ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ChangeNotifierProvider(create: (_) => InvestmentProvider()),
      ChangeNotifierProvider(create: (_) => IncomeProvider()),
      ChangeNotifierProvider(create: (_) => GoldProvider()),
      ChangeNotifierProvider(create: (_) => ChildProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('ChildFinanceModel Unit & Financial Formula Tests', () {
    test('Calculates child age in years and formatted string correctly', () {
      final dob = DateTime.now().subtract(const Duration(days: 365 * 6 + 40));
      final child = ChildProfileModel(
        id: 'c1',
        userId: 'u1',
        name: 'Aarav',
        gender: 'MALE',
        dateOfBirth: dob,
      );

      expect(child.ageInYears, 6);
      expect(child.formattedAge.contains('6 Yrs'), isTrue);
    });

    test('Calculates SSY maturity and investment ROI correctly', () {
      final inv = ChildInvestmentModel(
        id: 'inv1',
        childId: 'c1',
        userId: 'u1',
        investmentName: 'Sukanya Samriddhi Yojana',
        investmentType: 'SSY',
        investedAmount: 150000.0,
        currentValuation: 180000.0,
        expectedReturnRate: 8.2,
        monthlyContribution: 5000.0,
      );

      expect(inv.profitOrLoss, 30000.0);
      expect(inv.roiPercentage, 20.0);

      final maturityVal = inv.estimateMaturityValuation(years: 15);
      expect(maturityVal > 1000000.0, isTrue);
    });

    test('Calculates Education Inflation Projected Cost and Suggested SIP', () {
      final goal = ChildFutureGoalModel(
        id: 'g1',
        childId: 'c1',
        userId: 'u1',
        goalTitle: 'B.Tech College Fund',
        targetAmountToday: 2000000.0, // 20 Lakhs
        estimatedInflationRate: 8.0, // 8% p.a.
        targetYear: DateTime.now().year + 10, // 10 years later
      );

      expect(goal.yearsRemaining, 10);
      // 20L * (1.08)^10 ~ 43.17 Lakhs
      final futureCost = goal.estimatedFutureCost;
      expect(futureCost > 4000000.0, isTrue);

      final suggestedSip = goal.calculateSuggestedMonthlySip(
        currentAccumulated: 200000.0,
        expectedReturnRate: 12.0,
      );
      expect(suggestedSip > 10000.0, isTrue);
    });
  });

  group('Child Screens Responsive Render Tests (320px Width)', () {
    testWidgets('ChildHubScreen renders without overflow on 320px width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createTestableWidget(const ChildHubScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ChildHubScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap + Add FAB and verify action sheet opens with 0 overflow
      await tester.tap(find.text('+ Add'));
      await tester.pumpAndSettle();
      expect(find.text('Quick Add Options'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddEditChildProfileScreen renders without overflow on 320px width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createTestableWidget(const AddEditChildProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditChildProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddEditChildExpenseScreen renders without overflow on 320px width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createTestableWidget(const AddEditChildExpenseScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditChildExpenseScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddEditChildInvestmentScreen renders without overflow on 320px width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createTestableWidget(const AddEditChildInvestmentScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditChildInvestmentScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddEditChildGoalScreen renders without overflow on 320px width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createTestableWidget(const AddEditChildGoalScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditChildGoalScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
