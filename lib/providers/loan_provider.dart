import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../models/loan_model.dart';
import '../../models/payment_history_model.dart';

class LoanProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ApiService _api = ApiService.instance;
  final NotificationService _notifications = NotificationService.instance;

  List<LoanModel> _loans = [];
  bool _isLoading = false;
  String? _currentUserId;

  // Active & Completed loans exclude soft-deleted loans
  List<LoanModel> get allLoans => _loans;
  List<LoanModel> get loans => _loans.where((l) => l.status != 'DELETED').toList();
  List<LoanModel> get activeLoans => _loans.where((l) => l.status == 'ACTIVE').toList();
  List<LoanModel> get completedLoans => _loans.where((l) => l.status == 'COMPLETED').toList();
  List<LoanModel> get deletedLoans => _loans.where((l) => l.status == 'DELETED').toList();
  bool get isLoading => _isLoading;

  double get totalMonthlyEmis {
    return activeLoans.fold(0.0, (sum, loan) => sum + loan.emiAmount);
  }

  void clearData() {
    _loans = [];
    _currentUserId = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLoans(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();
    try {
      _loans = await _db.getAllLoans(userId: userId);
      try {
        final remote = await _api.fetchLoans(userId);
        if (remote.isNotEmpty) {
          await _db.syncReplaceLoans(userId, remote);
          _loans = await _db.getAllLoans(userId: userId);
        } else if (_loans.isNotEmpty) {
          // If remote is empty but local has items, push local items to server
          for (final loan in _loans) {
            await _api.syncLoan(loan);
          }
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLoan({
    required String userId,
    required String title,
    required String lenderName,
    required double totalPrincipal,
    required double emiAmount,
    double interestRate = 0.0,
    required int totalEmis,
    int paidEmis = 0,
    required int dueDay,
    required DateTime startDate,
    List<int> reminderOffsets = const [7, 2, 1, 0],
    String? notes,
  }) async {
    final remaining = (totalEmis - paidEmis).clamp(0, totalEmis);
    final status = remaining == 0 ? 'COMPLETED' : 'ACTIVE';
    final newLoan = LoanModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      lenderName: lenderName,
      totalPrincipal: totalPrincipal,
      emiAmount: emiAmount,
      interestRate: interestRate,
      totalEmis: totalEmis,
      remainingEmis: remaining,
      dueDay: dueDay,
      startDate: startDate,
      reminderOffsets: reminderOffsets,
      status: status,
      notes: notes,
    );

    await _db.insertLoan(newLoan);
    try {
      await _api.syncLoan(newLoan);
    } catch (_) {}
    try {
      await _scheduleLoanReminders(newLoan);
    } catch (_) {}
    await loadLoans(userId);
  }

  Future<void> payEmi({
    required LoanModel loan,
    String? note,
  }) async {
    if (loan.remainingEmis <= 0) return;

    final newRemaining = loan.remainingEmis - 1;
    final isCompleted = newRemaining == 0;

    final updatedLoan = loan.copyWith(
      remainingEmis: newRemaining,
      status: isCompleted ? 'COMPLETED' : 'ACTIVE',
    );

    await _db.updateLoan(updatedLoan);
    await _api.payLoanEmi(loan.id);

    // Record payment history
    final payment = PaymentHistoryModel(
      id: const Uuid().v4(),
      userId: loan.userId,
      referenceId: loan.id,
      type: 'EMI_PAYMENT',
      amount: loan.emiAmount,
      paidDate: DateTime.now(),
      note: note ?? 'EMI #${loan.paidEmis + 1} paid for ${loan.title}',
    );
    await _db.insertPaymentHistory(payment);

    // Cancel old reminders and reschedule if still active
    await _cancelLoanReminders(loan);
    if (!isCompleted) {
      await _scheduleLoanReminders(updatedLoan);
    }

    if (_currentUserId != null) {
      await loadLoans(_currentUserId!);
    }
  }

  Future<void> updateLoan(LoanModel loan) async {
    final remaining = loan.remainingEmis.clamp(0, loan.totalEmis);
    final status = (loan.status == 'DELETED')
        ? 'DELETED'
        : (remaining == 0 ? 'COMPLETED' : 'ACTIVE');
    final updatedLoan = loan.copyWith(
      remainingEmis: remaining,
      status: status,
    );
    await _db.updateLoan(updatedLoan);
    try {
      await _api.updateLoan(updatedLoan);
    } catch (_) {
      await _api.syncLoan(updatedLoan);
    }
    await _cancelLoanReminders(updatedLoan);
    if (updatedLoan.status == 'ACTIVE') {
      await _scheduleLoanReminders(updatedLoan);
    }
    if (_currentUserId != null) {
      await loadLoans(_currentUserId!);
    }
  }

  // --- SOFT DELETE (Move to Trash) ---
  Future<void> softDeleteLoan(String id) async {
    final loan = _loans.firstWhere((l) => l.id == id, orElse: () => _loans.first);
    await _cancelLoanReminders(loan);
    final deletedLoan = loan.copyWith(status: 'DELETED');
    await _db.updateLoan(deletedLoan);
    await _api.syncLoan(deletedLoan);
    if (_currentUserId != null) {
      await loadLoans(_currentUserId!);
    }
  }

  // Alias for deleteLoan
  Future<void> deleteLoan(String id) async {
    await softDeleteLoan(id);
  }

  // --- RESTORE FROM TRASH ---
  Future<void> restoreLoan(String id) async {
    final loan = _loans.firstWhere((l) => l.id == id, orElse: () => _loans.first);
    final restoredStatus = loan.remainingEmis == 0 ? 'COMPLETED' : 'ACTIVE';
    final restoredLoan = loan.copyWith(status: restoredStatus);
    await _db.updateLoan(restoredLoan);
    await _api.syncLoan(restoredLoan);
    if (restoredStatus == 'ACTIVE') {
      await _scheduleLoanReminders(restoredLoan);
    }
    if (_currentUserId != null) {
      await loadLoans(_currentUserId!);
    }
  }

  // --- PERMANENT DELETE ---
  Future<void> deleteLoanPermanently(String id) async {
    final loan = _loans.firstWhere((l) => l.id == id, orElse: () => _loans.first);
    await _cancelLoanReminders(loan);
    await _db.deleteLoan(id, loan.userId);
    await _api.deleteLoan(id);
    if (_currentUserId != null) {
      await loadLoans(_currentUserId!);
    }
  }

  Future<List<PaymentHistoryModel>> getLoanPaymentHistory(String loanId, String userId) async {
    return await _db.getPaymentHistoryForReference(loanId, userId);
  }

  Future<void> _scheduleLoanReminders(LoanModel loan) async {
    final nextDue = loan.nextDueDate;
    for (final offset in loan.reminderOffsets) {
      final scheduledDate = nextDue.subtract(Duration(days: offset));
      final alertTime = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day, 9, 0);

      final notifId = (loan.id.hashCode ^ offset).abs() % 100000;
      final body = offset == 0
          ? '${loan.title} EMI of ₹${loan.emiAmount.toInt()} is due today!'
          : '${loan.title} EMI of ₹${loan.emiAmount.toInt()} is due in $offset days (${nextDue.day}/${nextDue.month}).';

      await _notifications.scheduleNotification(
        id: notifId,
        title: '🔔 EMI Reminder: ${loan.title}',
        body: body,
        scheduledDate: alertTime,
      );
    }
  }

  Future<void> _cancelLoanReminders(LoanModel loan) async {
    for (final offset in loan.reminderOffsets) {
      final notifId = (loan.id.hashCode ^ offset).abs() % 100000;
      await _notifications.cancelNotification(notifId);
    }
  }
}