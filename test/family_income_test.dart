
import 'package:flutter_test/flutter_test.dart';
import 'package:money_reminder_app/models/income_source_model.dart';

void main() {
  group('IncomeSourceModel & Household Earnings Calculations', () {
    test('Correctly models self and family income sources', () {
      final selfIncome = IncomeSourceModel(
        id: 'inc-1',
        userId: 'u123',
        earnerName: 'Self',
        sourceTitle: 'Software Engineer Salary',
        amount: 85000,
        payoutDay: 1,
        category: 'SALARY',
      );

      final spouseIncome = IncomeSourceModel(
        id: 'inc-2',
        userId: 'u123',
        earnerName: 'Spouse',
        sourceTitle: 'Consulting Practice',
        amount: 45000,
        payoutDay: 5,
        category: 'FREELANCE',
      );

      final rentalIncome = IncomeSourceModel(
        id: 'inc-3',
        userId: 'u123',
        earnerName: 'Rental Apartment',
        sourceTitle: 'Commercial Flat Rent',
        amount: 20000,
        payoutDay: 10,
        category: 'RENTAL',
      );

      final allIncomes = [selfIncome, spouseIncome, rentalIncome];
      final totalHouseholdInflow = allIncomes.fold<double>(0.0, (sum, i) => sum + i.amount);

      expect(totalHouseholdInflow, 150000);

      // Monthly expenses and EMI comparison
      const totalLoanEmis = 35000.0;
      const totalDailyExpenses = 40000.0;
      const totalOutflow = totalLoanEmis + totalDailyExpenses;

      final netSurplus = totalHouseholdInflow - totalOutflow;
      expect(netSurplus, 75000);
      expect(netSurplus > 0, true);

      // Savings ratio
      final savingsRate = (netSurplus / totalHouseholdInflow) * 100;
      expect(savingsRate, 50.0);
    });

    test('IncomeSourceModel serialization toMap and fromMap cleanly', () {
      final income = IncomeSourceModel(
        id: 'inc-99',
        userId: 'u123',
        earnerName: 'Father',
        sourceTitle: 'State Pension',
        amount: 32000,
        payoutDay: 1,
        category: 'PENSION',
        notes: 'Credited directly to treasury account',
      );

      final map = income.toMap();
      final restored = IncomeSourceModel.fromMap(map);

      expect(restored.id, 'inc-99');
      expect(restored.earnerName, 'Father');
      expect(restored.amount, 32000);
      expect(restored.payoutDay, 1);
      expect(restored.category, 'PENSION');
      expect(restored.notes, 'Credited directly to treasury account');
      expect(restored.isRecurring, true);
    });
  });
}
