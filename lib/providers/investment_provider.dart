import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/api_service.dart';
import '../../models/investment_model.dart';

class InvestmentProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ApiService _api = ApiService.instance;

  List<InvestmentModel> _investments = [];
  bool _isLoading = false;
  String? _currentUserId;

  List<InvestmentModel> get allInvestments => _investments;
  List<InvestmentModel> get investments => _investments.where((i) => i.status != 'DELETED').toList();
  List<InvestmentModel> get deletedInvestments => _investments.where((i) => i.status == 'DELETED').toList();

  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;

  // Portfolio Totals & Metrics
  double get totalInvested => investments.fold(0.0, (sum, i) => sum + i.investedAmount);
  double get totalCurrentValue => investments.fold(0.0, (sum, i) => sum + i.currentValue);
  double get totalGainLoss => totalCurrentValue - totalInvested;
  double get overallGainPercentage => totalInvested > 0 ? (totalGainLoss / totalInvested) * 100 : 0.0;
  bool get isOverallProfitable => totalGainLoss >= 0;

  // Expected Passive Returns
  double get totalExpectedAnnualReturn => investments.fold(0.0, (sum, i) => sum + i.expectedAnnualReturn);
  double get totalExpectedMonthlyReturn => totalExpectedAnnualReturn / 12;

  // Filtering
  List<InvestmentModel> byCategory(String cat) {
    if (cat == 'All') return investments;
    return investments.where((i) => i.category.toUpperCase() == cat.toUpperCase()).toList();
  }

  Future<void> loadInvestments(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load instantly from local SQLite offline cache
      _investments = await _db.getInvestments(userId);
      _isLoading = false;
      notifyListeners();

      // 2. Refresh from Spring Boot backend asynchronously
      try {
        final remote = await _api.fetchInvestments(userId);
        if (remote.isNotEmpty || _investments.isEmpty) {
          _investments = remote;
          await _db.syncReplaceInvestments(userId, remote);
          notifyListeners();
        }
      } catch (_) {
        // Backend offline; offline data already loaded
      }
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInvestment(InvestmentModel inv) async {
    await _db.insertInvestment(inv);
    _investments.insert(0, inv);
    notifyListeners();

    try {
      await _api.saveInvestment(inv);
    } catch (_) {}
  }

  Future<void> updateInvestment(InvestmentModel inv) async {
    await _db.updateInvestment(inv);
    final idx = _investments.indexWhere((i) => i.id == inv.id);
    if (idx != -1) {
      _investments[idx] = inv;
      notifyListeners();
    }

    try {
      await _api.updateInvestment(inv);
    } catch (_) {}
  }

  Future<void> updateValuation(String id, double newCurrentValue) async {
    final idx = _investments.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final updated = _investments[idx].copyWith(currentValue: newCurrentValue);
      _investments[idx] = updated;
      await _db.updateInvestmentValuation(id, newCurrentValue);
      notifyListeners();

      try {
        await _api.updateInvestment(updated);
      } catch (_) {}
    }
  }

  Future<void> softDeleteInvestment(String id) async {
    await _db.softDeleteInvestment(id);
    final idx = _investments.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final updated = _investments[idx].copyWith(status: 'DELETED');
      _investments[idx] = updated;
      notifyListeners();

      try {
        await _api.updateInvestment(updated);
      } catch (_) {}
    }
  }

  Future<void> restoreInvestment(String id) async {
    await _db.restoreInvestment(id);
    final idx = _investments.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final updated = _investments[idx].copyWith(status: 'ACTIVE');
      _investments[idx] = updated;
      notifyListeners();

      try {
        await _api.updateInvestment(updated);
      } catch (_) {}
    }
  }

  Future<void> deleteInvestmentPermanently(String id) async {
    await _db.deleteInvestmentPermanently(id);
    _investments.removeWhere((i) => i.id == id);
    notifyListeners();

    try {
      await _api.deleteInvestment(id);
    } catch (_) {}
  }
}
