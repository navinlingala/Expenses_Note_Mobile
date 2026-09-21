import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../models/transaction_model.dart';
import '../../models/payment_history_model.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ApiService _api = ApiService.instance;
  final NotificationService _notifications = NotificationService.instance;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _currentUserId;

  // Filter state
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _searchQuery = '';

  // Active transactions (excludes soft-deleted items)
  List<TransactionModel> get allTransactions => _transactions;
  List<TransactionModel> get transactions => _transactions.where((t) => t.status != 'DELETED').toList();
  List<TransactionModel> get deletedTransactions => _transactions.where((t) => t.status == 'DELETED').toList();

  bool get isLoading => _isLoading;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  String get searchQuery => _searchQuery;

  // Receivables ("Who owes me")
  List<TransactionModel> get receivables => _transactions
      .where((t) => t.type == 'RECEIVABLE' && t.status != 'DELETED')
      .toList();

  List<TransactionModel> get pendingReceivables => receivables
      .where((t) => t.status == 'PENDING')
      .toList();

  double get totalToReceive => pendingReceivables.fold(
      0.0, (sum, t) => sum + t.amount);

  // Payables ("Whom I owe")
  List<TransactionModel> get payables => _transactions
      .where((t) => t.type == 'PAYABLE' && t.status != 'DELETED')
      .toList();

  List<TransactionModel> get pendingPayables => payables
      .where((t) => t.status == 'PENDING')
      .toList();

  double get totalToPay => pendingPayables.fold(
      0.0, (sum, t) => sum + t.amount);

  // Credits & Debits for Monthly Cashflow
  List<TransactionModel> get monthlyTransactions => _transactions.where((t) {
        return t.status != 'DELETED' &&
            t.dueDate.year == _selectedYear &&
            t.dueDate.month == _selectedMonth;
      }).toList();

  double get monthlyCredit => monthlyTransactions
      .where((t) => t.type == 'CREDIT')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get monthlyDebit => monthlyTransactions
      .where((t) => t.type == 'DEBIT')
      .fold(0.0, (sum, t) => sum + t.amount);

  // Receivables for selected month
  List<TransactionModel> get monthlyReceivablesList => monthlyTransactions
      .where((t) => t.type == 'RECEIVABLE')
      .toList();

  double get monthlyReceivable => monthlyReceivablesList
      .fold(0.0, (sum, t) => sum + t.amount);

  // Payables for selected month
  List<TransactionModel> get monthlyPayablesList => monthlyTransactions
      .where((t) => t.type == 'PAYABLE')
      .toList();

  double get monthlyPayable => monthlyPayablesList
      .fold(0.0, (sum, t) => sum + t.amount);

  // Overdue and Upcoming
  List<TransactionModel> get overdueTransactions => _transactions
      .where((t) => t.status != 'DELETED' && t.isOverdue)
      .toList();

  List<TransactionModel> get upcomingTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    return _transactions.where((t) {
      if (t.status != 'PENDING') return false;
      final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return (due.isAtSameMomentAs(today) || due.isAfter(today)) &&
          (due.isAtSameMomentAs(nextWeek) || due.isBefore(nextWeek));
    }).toList();
  }

  void clearData() {
    _transactions = [];
    _currentUserId = null;
    _isLoading = false;
    notifyListeners();
  }

  void setMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadTransactions(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _db.getAllTransactions(userId: userId);
      try {
        final remote = await _api.fetchTransactions(userId);
        if (remote.isNotEmpty) {
          await _db.syncReplaceTransactions(userId, remote);
          _transactions = await _db.getAllTransactions(userId: userId);
        } else if (_transactions.isNotEmpty) {
          for (final tx in _transactions) {
            await _api.syncTransaction(tx);
          }
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction({
    required String userId,
    required String title,
    String? personName,
    String? phoneNumber,
    required double amount,
    required String type, // CREDIT, DEBIT, RECEIVABLE, PAYABLE
    required DateTime dueDate,
    bool isRecurring = false,
    String recurrenceFrequency = 'NONE',
    String? category,
    String? notes,
  }) async {
    final newTx = TransactionModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      personName: personName,
      phoneNumber: phoneNumber,
      amount: amount,
      type: type,
      dueDate: dueDate,
      status: 'PENDING',
      isRecurring: isRecurring,
      recurrenceFrequency: recurrenceFrequency,
      category: category,
      notes: notes,
    );

    await _db.insertTransaction(newTx);
    try {
      await _api.syncTransaction(newTx);
    } catch (_) {}
    try {
      await _scheduleTransactionReminder(newTx);
    } catch (_) {}
    await loadTransactions(userId);
  }

  Future<void> markAsCompleted(TransactionModel transaction, {String? note}) async {
    final newStatus = transaction.type == 'RECEIVABLE' ? 'RECEIVED' : 'PAID';
    final updatedTx = transaction.copyWith(status: newStatus);

    await _db.updateTransaction(updatedTx);
    await _api.updateTransactionStatus(transaction.id, newStatus);

    // Record payment history
    final payment = PaymentHistoryModel(
      id: const Uuid().v4(),
      userId: transaction.userId,
      referenceId: transaction.id,
      type: '${transaction.type}_$newStatus',
      amount: transaction.amount,
      paidDate: DateTime.now(),
      note: note ?? '${transaction.title} marked as $newStatus',
    );
    await _db.insertPaymentHistory(payment);

    // Cancel notification
    await _cancelTransactionReminder(transaction);

    // If recurring (monthly), automatically create next occurrence!
    if (transaction.isRecurring && transaction.recurrenceFrequency == 'MONTHLY') {
      final nextMonthDue = DateTime(
        transaction.dueDate.year,
        transaction.dueDate.month + 1,
        transaction.dueDate.day.clamp(1, 28),
      );

      final nextTx = TransactionModel(
        id: const Uuid().v4(),
        userId: transaction.userId,
        title: transaction.title,
        personName: transaction.personName,
        phoneNumber: transaction.phoneNumber,
        amount: transaction.amount,
        type: transaction.type,
        dueDate: nextMonthDue,
        status: 'PENDING',
        isRecurring: true,
        recurrenceFrequency: 'MONTHLY',
        category: transaction.category,
        notes: transaction.notes,
      );
      await _db.insertTransaction(nextTx);
      await _api.syncTransaction(nextTx);
      await _scheduleTransactionReminder(nextTx);
    }

    if (_currentUserId != null) {
      await loadTransactions(_currentUserId!);
    }
  }

  Future<void> recordPartialPayment({
    required TransactionModel transaction,
    required double paidAmount,
    String? note,
  }) async {
    if (paidAmount <= 0) return;

    final newRemaining = (transaction.amount - paidAmount).clamp(0.0, double.infinity);
    final isFullyPaid = newRemaining <= 0;
    final newStatus = isFullyPaid
        ? (transaction.type == 'RECEIVABLE' ? 'RECEIVED' : 'PAID')
        : 'PENDING';

    final historyNote = note ?? 'Partial payment of ₹ recorded. Remaining: ₹';
    final existingNotes = transaction.notes != null && transaction.notes!.isNotEmpty
        ? '\n• '
        : '• ';

    final updatedTx = transaction.copyWith(
      amount: isFullyPaid ? transaction.amount : newRemaining,
      status: newStatus,
      notes: existingNotes,
    );

    await _db.updateTransaction(updatedTx);
    await _api.syncTransaction(updatedTx);

    // Record payment history entry
    final payment = PaymentHistoryModel(
      id: const Uuid().v4(),
      userId: transaction.userId,
      referenceId: transaction.id,
      type: '_PARTIAL',
      amount: paidAmount,
      paidDate: DateTime.now(),
      note: historyNote,
    );
    await _db.insertPaymentHistory(payment);

    if (isFullyPaid) {
      await _cancelTransactionReminder(transaction);
    } else {
      await _scheduleTransactionReminder(updatedTx);
    }

    if (_currentUserId != null) {
      await loadTransactions(_currentUserId!);
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _db.updateTransaction(transaction);
    await _api.syncTransaction(transaction);
    await _cancelTransactionReminder(transaction);
    if (transaction.status == 'PENDING') {
      await _scheduleTransactionReminder(transaction);
    }
    if (_currentUserId != null) {
      await loadTransactions(_currentUserId!);
    }
  }

  // --- SOFT DELETE (Move to Trash) ---
  Future<void> softDeleteTransaction(String id) async {
    final tx = _transactions.firstWhere((t) => t.id == id, orElse: () => _transactions.first);
    await _cancelTransactionReminder(tx);
    final deletedTx = tx.copyWith(status: 'DELETED');
    await _db.updateTransaction(deletedTx);
    await _api.syncTransaction(deletedTx);
    if (_currentUserId != null) {
      await loadTransactions(_currentUserId!);
    }
  }

  // Alias for deleteTransaction
  Future<void> deleteTransaction(String id) async {
    await softDeleteTransaction(id);
  }

  // --- RESTORE FROM TRASH ---
  Future<void> restoreTransaction(String id) async {
    final tx = _transactions.firstWhere((t) => t.id == id, orElse: () => _transactions.first);
    final restoredTx = tx.copyWith(status: 'PENDING');
    await _db.updateTransaction(restoredTx);
    await _api.syncTransaction(restoredTx);
    await _scheduleTransactionReminder(restoredTx);
    if (_currentUserId != null) {
      await loadTransactions(_currentUserId!);
    }
  }

  // --- PERMANENT DELETE ---
  Future<void> deleteTransactionPermanently(String id) async {
    final tx = _transactions.firstWhere((t) => t.id == id, orElse: () => _transactions.first);
    await _cancelTransactionReminder(tx);
    await _db.deleteTransaction(id, tx.userId);
    await _api.deleteTransaction(id);
    if (_currentUserId != null) {
      await loadTransactions(_currentUserId!);
    }
  }

  Future<void> _scheduleTransactionReminder(TransactionModel tx) async {
    if (tx.status != 'PENDING') return;

    final notifBaseId = tx.id.hashCode.abs() % 100000;

    // Day before
    final dayBefore = tx.dueDate.subtract(const Duration(days: 1));
    final alertTime1 = DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 9, 0);

    final title = tx.type == 'RECEIVABLE'
        ? '🔔 Payment Due to Receive: ${tx.personName ?? tx.title}'
        : '🔔 Payment Reminder: ${tx.title}';

    final body1 = tx.type == 'RECEIVABLE'
        ? '${tx.personName ?? "Someone"} owes you ₹${tx.amount.toInt()}, due tomorrow!'
        : 'Payment of ₹${tx.amount.toInt()} for "${tx.title}" is due tomorrow!';

    await _notifications.scheduleNotification(
      id: notifBaseId,
      title: title,
      body: body1,
      scheduledDate: alertTime1,
    );

    // On due date
    final alertTime2 = DateTime(tx.dueDate.year, tx.dueDate.month, tx.dueDate.day, 9, 0);
    final body2 = tx.type == 'RECEIVABLE'
        ? '${tx.personName ?? "Someone"} owes you ₹${tx.amount.toInt()}, due TODAY!'
        : 'Payment of ₹${tx.amount.toInt()} for "${tx.title}" is due TODAY!';

    await _notifications.scheduleNotification(
      id: notifBaseId + 1,
      title: title,
      body: body2,
      scheduledDate: alertTime2,
    );
  }

  Future<void> _cancelTransactionReminder(TransactionModel tx) async {
    final notifBaseId = tx.id.hashCode.abs() % 100000;
    await _notifications.cancelNotification(notifBaseId);
    await _notifications.cancelNotification(notifBaseId + 1);
  }
}