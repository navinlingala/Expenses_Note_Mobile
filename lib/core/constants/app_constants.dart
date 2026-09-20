class AppConstants {
  static const String appName = 'Money Reminder & EMI Tracker';
  static const String defaultCurrency = '₹';

  // Transaction Types
  static const String typeCredit = 'CREDIT';
  static const String typeDebit = 'DEBIT';
  static const String typeReceivable = 'RECEIVABLE'; // Who owes me
  static const String typePayable = 'PAYABLE';       // Whom I owe
  static const String typeEmi = 'EMI';

  // Status
  static const String statusPending = 'PENDING';
  static const String statusPaid = 'PAID';
  static const String statusReceived = 'RECEIVED';
  static const String statusOverdue = 'OVERDUE';
  static const String statusCancelled = 'CANCELLED';

  // Loan Status
  static const String loanActive = 'ACTIVE';
  static const String loanCompleted = 'COMPLETED';
  static const String loanArchived = 'ARCHIVED';

  // Recurrence
  static const String recurrenceNone = 'NONE';
  static const String recurrenceMonthly = 'MONTHLY';
  static const String recurrenceWeekly = 'WEEKLY';
  static const String recurrenceYearly = 'YEARLY';

  // Reminder Offsets (in days)
  static const List<int> defaultReminderDays = [7, 2, 1, 0];
}
