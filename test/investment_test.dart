import 'package:flutter_test/flutter_test.dart';
import 'package:money_reminder_app/models/investment_model.dart';

void main() {
  group('InvestmentModel Financial Calculations', () {
    test('Calculates absolute gain, gain percentage, and profit status correctly', () {
      final inv = InvestmentModel(
        id: 'inv_1',
        userId: 'user_123',
        title: 'Nifty 50 Index Fund',
        category: 'MUTUAL_FUNDS',
        investedAmount: 100000,
        currentValue: 125000,
        expectedReturnRate: 12.0,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
      );

      expect(inv.absoluteGain, equals(25000));
      expect(inv.gainPercentage, equals(25.0));
      expect(inv.isProfitable, isTrue);
    });

    test('Calculates monthly and yearly expected returns accurately', () {
      final inv = InvestmentModel(
        id: 'inv_2',
        userId: 'user_123',
        title: 'High Yield Fixed Deposit',
        category: 'FIXED_DEPOSIT',
        investedAmount: 200000,
        currentValue: 200000,
        expectedReturnRate: 7.5,
        startDate: DateTime.now(),
      );

      // Annual return: 200000 * 7.5% = 15,000
      expect(inv.expectedAnnualReturn, equals(15000.0));
      // Monthly return: 15,000 / 12 = 1,250
      expect(inv.expectedMonthlyReturn, equals(1250.0));
    });

    test('Computes future compounding projections for lump sum', () {
      final inv = InvestmentModel(
        id: 'inv_3',
        userId: 'user_123',
        title: 'Bluechip Equity',
        category: 'STOCKS',
        investmentType: 'LUMPSUM',
        investedAmount: 100000,
        currentValue: 100000,
        expectedReturnRate: 10.0,
        startDate: DateTime.now(),
      );

      // 1 Year at 10%: 100,000 * 1.10 = 110,000
      expect(inv.projectedValue(1), closeTo(110000, 0.01));
      // 3 Years at 10%: 100,000 * (1.10)^3 = 133,100
      expect(inv.projectedValue(3), closeTo(133100, 0.01));
    });

    test('Computes future compounding projections for monthly SIP', () {
      final inv = InvestmentModel(
        id: 'inv_4',
        userId: 'user_123',
        title: 'Flexi Cap SIP',
        category: 'MUTUAL_FUNDS',
        investmentType: 'SIP',
        investedAmount: 50000,
        currentValue: 50000,
        expectedReturnRate: 12.0,
        sipAmount: 5000,
        startDate: DateTime.now(),
      );

      // Future value should be greater than just the initial capital compounding
      final proj1Year = inv.projectedValue(1);
      expect(proj1Year, greaterThan(50000 * 1.12));
      // Initial 50k compounded + 12 monthly installments of 5k compounded
      expect(proj1Year, greaterThan(110000));
    });

    test('Handles serialization toMap and fromMap cleanly', () {
      final original = InvestmentModel(
        id: 'inv_5',
        userId: 'user_abc',
        title: 'Sovereign Gold Bonds',
        category: 'GOLD',
        investedAmount: 75000,
        currentValue: 88000,
        expectedReturnRate: 8.0,
        startDate: DateTime(2025, 1, 1),
        notes: 'RBI SGB Series IV',
      );

      final map = original.toMap();
      final reconstructed = InvestmentModel.fromMap(map);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.userId, equals(original.userId));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.category, equals(original.category));
      expect(reconstructed.investedAmount, equals(original.investedAmount));
      expect(reconstructed.currentValue, equals(original.currentValue));
      expect(reconstructed.expectedReturnRate, equals(original.expectedReturnRate));
      expect(reconstructed.notes, equals('RBI SGB Series IV'));
    });
  });
}
