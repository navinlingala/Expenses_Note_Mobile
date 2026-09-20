import 'package:flutter_test/flutter_test.dart';
import 'package:money_reminder_app/models/user_model.dart';
import 'package:money_reminder_app/models/loan_model.dart';
import 'package:money_reminder_app/models/transaction_model.dart';
import 'package:money_reminder_app/core/utils/currency_formatter.dart';
import 'package:money_reminder_app/core/utils/date_utils.dart';

void main() {
  group('User Authentication & Data Isolation Tests', () {
    test('UserModel serialization and mapping', () {
      final user = UserModel(
        id: 'user_123',
        name: 'Naveen Kumar',
        email: 'naveen@example.com',
        phone: '9876543210',
      );

      final map = user.toMap();
      expect(map['id'], 'user_123');
      expect(map['email'], 'naveen@example.com');

      final fromMap = UserModel.fromMap(map);
      expect(fromMap.id, 'user_123');
      expect(fromMap.name, 'Naveen Kumar');
      expect(fromMap.phone, '9876543210');
    });

    test('LoanModel requires userId and calculates amortization', () {
      final loan = LoanModel(
        id: 'loan_1',
        userId: 'user_123',
        title: 'HDFC Personal Loan',
        lenderName: 'HDFC Bank',
        totalPrincipal: 200000.0,
        emiAmount: 8500.0,
        totalEmis: 24,
        remainingEmis: 18,
        dueDay: 5,
        startDate: DateTime(2026, 1, 1),
      );

      expect(loan.userId, 'user_123');
      expect(loan.paidEmis, 6);
      expect(loan.progressPercentage, 0.25);
      expect(loan.totalPaidAmount, 51000.0);
      expect(loan.remainingBalance, 153000.0);
    });

    test('TransactionModel user scoping and relative due date', () {
      final tx = TransactionModel(
        id: 'tx_1',
        userId: 'user_123',
        title: 'Ravi owes me',
        personName: 'Ravi',
        phoneNumber: '9876543210',
        amount: 5000.0,
        type: 'RECEIVABLE',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      expect(tx.userId, 'user_123');
      expect(tx.isDueTomorrow, true);
      expect(AppDateUtils.getRelativeDueDate(tx.dueDate), 'Due Tomorrow');
      expect(CurrencyFormatter.format(tx.amount), '₹5,000');
    });
    test('LoanModel handles historical loans with already cleared EMIs (e.g. 24 of 60)', () {
      const totalEmis = 60;
      const alreadyPaid = 24;
      const remaining = totalEmis - alreadyPaid;
      const emiAmount = 27886.0;

      final loan = LoanModel(
        id: 'loan_user_case',
        userId: 'user_123',
        title: 'personal loan',
        lenderName: 'piramal',
        totalPrincipal: 1673160.0,
        emiAmount: emiAmount,
        totalEmis: totalEmis,
        remainingEmis: remaining,
        dueDay: 5,
        startDate: DateTime.now().subtract(const Duration(days: 730)), // 2 years ago
      );

      expect(loan.totalEmis, 60);
      expect(loan.remainingEmis, 36);
      expect(loan.paidEmis, 24);
      expect(loan.progressPercentage, 0.40);
      expect(loan.remainingBalance, 36 * 27886.0);
      expect(loan.totalPaidAmount, 24 * 27886.0);
      expect(loan.status, 'ACTIVE');
    });
  });
}
