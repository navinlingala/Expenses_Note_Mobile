import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../models/income_source_model.dart';

class IncomeProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<IncomeSourceModel> _incomes = [];
  bool _isLoading = false;
  String? currentUserId;

  List<IncomeSourceModel> get allIncomes => _incomes;
  List<IncomeSourceModel> get activeIncomes => _incomes.where((i) => i.status == 'ACTIVE').toList();
  List<IncomeSourceModel> get deletedIncomes => _incomes.where((i) => i.status == 'DELETED').toList();
  bool get isLoading => _isLoading;

  /// Total Constant Household Monthly Inflow
  double get totalMonthlyIncome => activeIncomes.fold(0.0, (sum, i) => sum + i.amount);

  /// Self Incomes vs Family Incomes
  double get selfMonthlyIncome => activeIncomes
      .where((i) => i.earnerName.toLowerCase().contains('self') || i.earnerName.toLowerCase().contains('my'))
      .fold(0.0, (sum, i) => sum + i.amount);

  double get familyMonthlyIncome => activeIncomes
      .where((i) => !i.earnerName.toLowerCase().contains('self') && !i.earnerName.toLowerCase().contains('my'))
      .fold(0.0, (sum, i) => sum + i.amount);

  Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS income_sources (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        earner_name TEXT NOT NULL,
        source_title TEXT NOT NULL,
        amount REAL NOT NULL,
        payout_day INTEGER NOT NULL DEFAULT 1,
        category TEXT NOT NULL DEFAULT 'SALARY',
        is_recurring INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> loadIncomes(String userId) async {
    currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _db.database;
      await _ensureTable(db);
      final maps = await db.query(
        'income_sources',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      _incomes = maps.map((m) => IncomeSourceModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error loading incomes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addIncome({
    required String userId,
    required String earnerName,
    required String sourceTitle,
    required double amount,
    int payoutDay = 1,
    String category = 'SALARY',
    bool isRecurring = true,
    String? notes,
  }) async {
    final income = IncomeSourceModel(
      id: const Uuid().v4(),
      userId: userId,
      earnerName: earnerName,
      sourceTitle: sourceTitle,
      amount: amount,
      payoutDay: payoutDay,
      category: category,
      isRecurring: isRecurring,
      notes: notes,
    );

    final db = await _db.database;
    await _ensureTable(db);
    await db.insert('income_sources', income.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    _incomes.insert(0, income);
    notifyListeners();
  }

  Future<void> updateIncome(IncomeSourceModel income) async {
    final db = await _db.database;
    await _ensureTable(db);
    await db.update(
      'income_sources',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );

    final index = _incomes.indexWhere((i) => i.id == income.id);
    if (index != -1) {
      _incomes[index] = income;
      notifyListeners();
    }
  }

  Future<void> softDeleteIncome(String id) async {
    final db = await _db.database;
    await _ensureTable(db);
    await db.update(
      'income_sources',
      {'status': 'DELETED'},
      where: 'id = ?',
      whereArgs: [id],
    );

    final index = _incomes.indexWhere((i) => i.id == id);
    if (index != -1) {
      _incomes[index] = _incomes[index].copyWith(status: 'DELETED');
      notifyListeners();
    }
  }

  Future<void> restoreIncome(String id) async {
    final db = await _db.database;
    await _ensureTable(db);
    await db.update(
      'income_sources',
      {'status': 'ACTIVE'},
      where: 'id = ?',
      whereArgs: [id],
    );

    final index = _incomes.indexWhere((i) => i.id == id);
    if (index != -1) {
      _incomes[index] = _incomes[index].copyWith(status: 'ACTIVE');
      notifyListeners();
    }
  }
}
