import 'package:flutter_test/flutter_test.dart';
import 'package:money_reminder_app/models/investment_model.dart';
import 'package:money_reminder_app/models/loan_model.dart';
import 'package:money_reminder_app/models/transaction_model.dart';

void main() {
  group('Comprehensive Monthly Cashflow Calculations Tests', () {
    test('Calculates monthly inflow combining credits, investment returns, and receivables', () {
      final now = DateTime.now();

      // 1. Transaction Credit (e.g. Salary = 50,000)
      final salaryTx = TransactionModel(
        id: 'tx-1',
        userId: 'u1',
        title: 'Tech Salary',
        amount: 50000,
        type: 'CREDIT',
        dueDate: now,
      );

      // 2. Investment earning 60% p.a. on 6,00,000 = 30,000 / month
      final investment = InvestmentModel(
        id: 'inv-1',
        userId: 'u1',
        title: 'Hemant',
        category: 'MUTUAL_FUNDS',
        investedAmount: 600000,
        currentValue: 600000,
        expectedReturnRate: 60.0,
        startDate: now,
      );

      // 3. Receivable due this month = 10,000
      final receivableTx = TransactionModel(
        id: 'tx-2',
        userId: 'u1',
        title: 'Friend Repayment',
        amount: 10000,
        type: 'RECEIVABLE',
        dueDate: now,
      );

      final monthlyCredit = salaryTx.amount;
      final monthlyInvestmentReturn = investment.expectedMonthlyReturn;
      final monthlyReceivable = receivableTx.amount;

      final totalMonthlyInflow = monthlyCredit + monthlyInvestmentReturn + monthlyReceivable;

      expect(investment.expectedMonthlyReturn, 30000.0);
      expect(totalMonthlyInflow, 90000.0);
    });

    test('Calculates monthly outflow combining debits, loan EMIs, and payables', () {
      final now = DateTime.now();

      // 1. Expense Debit = 15,000
      final groceryTx = TransactionModel(
        id: 'tx-3',
        userId: 'u1',
        title: 'Groceries & Utilities',
        amount: 15000,
        type: 'DEBIT',
        dueDate: now,
      );

      // 2. Active Loan with EMI = 12,000
      final loan = LoanModel(
        id: 'loan-1',
        userId: 'u1',
        title: 'Car Loan',
        lenderName: 'HDFC Bank',
        totalPrincipal: 500000,
        emiAmount: 12000,
        totalEmis: 48,
        remainingEmis: 36,
        dueDay: 5,
        startDate: now,
      );

      // 3. Payable due this month = 3,000
      final payableTx = TransactionModel(
        id: 'tx-4',
        userId: 'u1',
        title: 'Maintenance Fee',
        amount: 3000,
        type: 'PAYABLE',
        dueDate: now,
      );

      final monthlyDebit = groceryTx.amount;
      final monthlyLoanEmi = loan.emiAmount;
      final monthlyPayable = payableTx.amount;

      final totalMonthlyOutflow = monthlyDebit + monthlyLoanEmi + monthlyPayable;

      expect(totalMonthlyOutflow, 30000.0);
    });

    test('Accurately computes Net Cashflow and Surplus status', () {
      const totalInflow = 90000.0;
      const totalOutflow = 30000.0;
      const netCashflow = totalInflow - totalOutflow;

      expect(netCashflow, 60000.0);
      expect(netCashflow > 0, isTrue); // Surplus
    });
    test('Accurately tracks partial payment deduction and balance updating for dues', () {
      final dueTx = TransactionModel(
        id: 'due-1',
        userId: 'u1',
        title: 'omkar owes me',
        personName: 'omkar',
        phoneNumber: '9876543210',
        amount: 1500.0,
        type: 'RECEIVABLE',
        dueDate: DateTime.now().add(const Duration(days: 2)),
      );

      // User pays partial 33.3% / 500
      const partialPayment = 500.0;
      final remainingBalance = (dueTx.amount - partialPayment).clamp(0.0, double.infinity);
      final isCompleted = remainingBalance <= 0;

      final updatedTx = dueTx.copyWith(
        amount: remainingBalance,
        status: isCompleted ? 'RECEIVED' : 'PENDING',
        notes: 'Partial payment of ₹500 recorded. Remaining: ₹1000',
      );

      expect(updatedTx.amount, 1000.0);
      expect(updatedTx.status, 'PENDING');
      expect(updatedTx.personName, 'omkar');
      expect(updatedTx.phoneNumber, '9876543210');
      expect(updatedTx.notes, contains('Remaining: ₹1000'));
    });
  });
}
