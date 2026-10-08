import 'package:flutter/material.dart';
import '../models/child_profile_model.dart';
import '../models/child_expense_model.dart';
import '../models/child_investment_model.dart';
import '../models/child_future_goal_model.dart';
import '../core/database/database_helper.dart';
import '../core/services/api_service.dart';

class ChildProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService.instance;

  List<ChildProfileModel> _profiles = [];
  List<ChildExpenseModel> _expenses = [];
  List<ChildInvestmentModel> _investments = [];
  List<ChildFutureGoalModel> _goals = [];

  String? _selectedChildId; // null = 'All Children'
  String _selectedExpenseCategory = 'ALL'; // 'ALL', 'EDUCATION', 'HEALTHCARE', etc.
  bool _isLoading = false;
  String? _errorMessage;

  List<ChildProfileModel> get profiles => _profiles;
  List<ChildExpenseModel> get expenses => _expenses;
  List<ChildInvestmentModel> get investments => _investments;
  List<ChildFutureGoalModel> get goals => _goals;
  String? get selectedChildId => _selectedChildId;
  String get selectedExpenseCategory => _selectedExpenseCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ChildProfileModel? get selectedChild {
    if (_selectedChildId == null) return null;
    try {
      return _profiles.firstWhere((p) => p.id == _selectedChildId);
    } catch (_) {
      return null;
    }
  }

  void selectChild(String? childId) {
    _selectedChildId = childId;
    notifyListeners();
  }

  void selectExpenseCategory(String category) {
    _selectedExpenseCategory = category;
    notifyListeners();
  }

  List<ChildExpenseModel> get filteredExpenses {
    var list = _expenses;
    if (_selectedChildId != null && _selectedChildId!.isNotEmpty) {
      list = list.where((e) => e.childId == _selectedChildId).toList();
    }
    if (_selectedExpenseCategory != 'ALL') {
      list = list.where((e) => e.category.toUpperCase() == _selectedExpenseCategory.toUpperCase()).toList();
    }
    return list;
  }

  List<ChildInvestmentModel> get filteredInvestments {
    if (_selectedChildId == null || _selectedChildId!.isEmpty) {
      return _investments;
    }
    return _investments.where((inv) => inv.childId == _selectedChildId).toList();
  }

  List<ChildFutureGoalModel> get filteredGoals {
    if (_selectedChildId == null || _selectedChildId!.isEmpty) {
      return _goals;
    }
    return _goals.where((g) => g.childId == _selectedChildId).toList();
  }

  // --- Financial Metrics ---
  double get totalMonthlyChildExpenses {
    final now = DateTime.now();
    return filteredExpenses
        .where((e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalYearlyChildExpenses {
    final now = DateTime.now();
    return filteredExpenses
        .where((e) => e.expenseDate.year == now.year)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalAllTimeExpenses {
    return filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalInvestedAmount {
    return filteredInvestments
        .where((i) => i.status == 'ACTIVE')
        .fold(0.0, (sum, item) => sum + item.investedAmount);
  }

  double get totalCurrentValuation {
    return filteredInvestments
        .where((i) => i.status == 'ACTIVE')
        .fold(0.0, (sum, item) => sum + item.currentValuation);
  }

  double get totalMonthlySipCommitment {
    return filteredInvestments
        .where((i) => i.status == 'ACTIVE')
        .fold(0.0, (sum, item) => sum + item.monthlyContribution);
  }

  double get totalFutureGoalsTargetCost {
    return filteredGoals.fold(0.0, (sum, g) => sum + g.estimatedFutureCost);
  }

  Map<String, double> get categoryExpenseBreakdown {
    final Map<String, double> map = {};
    for (final exp in filteredExpenses) {
      map[exp.category] = (map[exp.category] ?? 0.0) + exp.amount;
    }
    return map;
  }

  Map<String, double> get investmentTypeBreakdown {
    final Map<String, double> map = {};
    for (final inv in filteredInvestments.where((i) => i.status == 'ACTIVE')) {
      map[inv.investmentType] = (map[inv.investmentType] ?? 0.0) + inv.currentValuation;
    }
    return map;
  }

  // --- Load and Sync ---
  Future<void> loadChildData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load from local SQLite cache first (offline-first instant render)
      _profiles = await _dbHelper.getChildProfiles(userId);
      _expenses = await _dbHelper.getChildExpenses(userId);
      _investments = await _dbHelper.getChildInvestments(userId);
      _goals = await _dbHelper.getChildFutureGoals(userId);
      _isLoading = false;
      notifyListeners();

      // 2. Fetch remote and sync in background
      _syncRemoteData(userId);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncRemoteData(String userId) async {
    try {
      final remoteProfilesData = await _apiService.fetchChildProfiles(userId);
      if (remoteProfilesData.isNotEmpty) {
        final remoteProfiles = remoteProfilesData.map((e) => ChildProfileModel.fromJson(e)).toList();
        await _dbHelper.syncReplaceChildProfiles(userId, remoteProfiles);
        _profiles = remoteProfiles;
      }

      final remoteExpensesData = await _apiService.fetchChildExpenses(userId);
      if (remoteExpensesData.isNotEmpty) {
        final remoteExpenses = remoteExpensesData.map((e) => ChildExpenseModel.fromJson(e)).toList();
        await _dbHelper.syncReplaceChildExpenses(userId, remoteExpenses);
        _expenses = remoteExpenses;
      }

      final remoteInvestmentsData = await _apiService.fetchChildInvestments(userId);
      if (remoteInvestmentsData.isNotEmpty) {
        final remoteInvestments = remoteInvestmentsData.map((e) => ChildInvestmentModel.fromJson(e)).toList();
        await _dbHelper.syncReplaceChildInvestments(userId, remoteInvestments);
        _investments = remoteInvestments;
      }

      final remoteGoalsData = await _apiService.fetchChildFutureGoals(userId);
      if (remoteGoalsData.isNotEmpty) {
        final remoteGoals = remoteGoalsData.map((e) => ChildFutureGoalModel.fromJson(e)).toList();
        await _dbHelper.syncReplaceChildFutureGoals(userId, remoteGoals);
        _goals = remoteGoals;
      }
      notifyListeners();
    } catch (_) {}
  }

  // --- Child Profile CRUD ---
  Future<bool> addChildProfile(ChildProfileModel profile) async {
    try {
      await _dbHelper.insertChildProfile(profile);
      _profiles.insert(0, profile);
      _selectedChildId = profile.id;
      notifyListeners();
      _apiService.saveChildProfile(profile.toJson());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateChildProfile(ChildProfileModel profile) async {
    try {
      await _dbHelper.updateChildProfile(profile);
      final index = _profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _profiles[index] = profile;
      }
      notifyListeners();
      _apiService.updateChildProfile(profile.id, profile.toJson());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteChildProfile(String profileId) async {
    try {
      await _dbHelper.deleteChildProfile(profileId);
      _profiles.removeWhere((p) => p.id == profileId);
      _expenses.removeWhere((e) => e.childId == profileId);
      _investments.removeWhere((i) => i.childId == profileId);
      _goals.removeWhere((g) => g.childId == profileId);
      if (_selectedChildId == profileId) {
        _selectedChildId = null;
      }
      notifyListeners();
      _apiService.deleteChildProfile(profileId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Child Expense CRUD ---
  Future<bool> addChildExpense(ChildExpenseModel expense) async {
    try {
      await _dbHelper.insertChildExpense(expense);
      _expenses.insert(0, expense);
      _expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      notifyListeners();
      _apiService.saveChildExpense(expense.toJson());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateChildExpense(ChildExpenseModel expense) async {
    try {
      await _dbHelper.updateChildExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        _expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      }
      notifyListeners();
      _apiService.updateChildExpense(expense.id, expense.toJson());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteChildExpense(String expenseId) async {
    try {
      await _dbHelper.deleteChildExpense(expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);
      notifyListeners();
      _apiService.deleteChildExpense(expenseId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Child Investment CRUD ---
  Future<bool> addChildInvestment(ChildInvestmentModel investment) async {
    try {
      await _dbHelper.insertChildInvestment(investment);
      _investments.insert(0, investment);
      notifyListeners();
      _apiService.saveChildInvestment(investment.toJson());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateChildInvestment(ChildInvestmentModel investment) async {
    try {
      await _dbHelper.updateChildInvestment(investment);
      final index = _investments.indexWhere((i) => i.id == investment.id);
      if (index != -1) {
        _investments[index] = investment;
      }
      notifyListeners();
      _apiService.updateChildInvestment(investment.id, investment.toJson());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteChildInvestment(String investmentId) async {
    try {
      await _dbHelper.deleteChildInvestment(investmentId);
      _investments.removeWhere((i) => i.id == investmentId);
      notifyListeners();
      _apiService.deleteChildInvestment(investmentId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Child Future Goal CRUD ---
  Future<bool> addChildFutureGoal(ChildFutureGoalModel goal) async {
    try {
      await _dbHelper.insertChildFutureGoal(goal);
      _goals.add(goal);
      _goals.sort((a, b) => a.targetYear.compareTo(b.targetYear));
      notifyListeners();
      _apiService.saveChildFutureGoal(goal.toJson());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateChildFutureGoal(ChildFutureGoalModel goal) async {
    try {
      await _dbHelper.updateChildFutureGoal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        _goals.sort((a, b) => a.targetYear.compareTo(b.targetYear));
      }
      notifyListeners();
      _apiService.updateChildFutureGoal(goal.id, goal.toJson());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteChildFutureGoal(String goalId) async {
    try {
      await _dbHelper.deleteChildFutureGoal(goalId);
      _goals.removeWhere((g) => g.id == goalId);
      notifyListeners();
      _apiService.deleteChildFutureGoal(goalId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
