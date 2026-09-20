
import '../../models/investment_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../models/loan_model.dart';
import '../../models/transaction_model.dart';
import '../../models/payment_history_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      await _ensureTables(_database!);
      return _database!;
    }
    _database = await _initDB('money_reminder.db');
    await _ensureTables(_database!);
    return _database!;
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS investments (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        investment_type TEXT NOT NULL DEFAULT 'LUMPSUM',
        invested_amount REAL NOT NULL,
        current_value REAL NOT NULL,
        expected_return_rate REAL NOT NULL DEFAULT 0.0,
        sip_amount REAL,
        start_date TEXT NOT NULL,
        maturity_date TEXT,
        risk_level TEXT NOT NULL DEFAULT 'MODERATE',
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return await openDatabase(
        filePath,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Loans Table
    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        lender_name TEXT NOT NULL,
        total_principal REAL NOT NULL,
        emi_amount REAL NOT NULL,
        interest_rate REAL DEFAULT 0.0,
        total_emis INTEGER NOT NULL,
        remaining_emis INTEGER NOT NULL,
        due_day INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        reminder_offsets TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        person_name TEXT,
        phone_number TEXT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        due_date TEXT NOT NULL,
        status TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurrence_frequency TEXT NOT NULL DEFAULT 'NONE',
        loan_id TEXT,
        category TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Reminders Table
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        reference_id TEXT NOT NULL,
        reference_type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        offset_days INTEGER NOT NULL,
        channel TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Payment History Table
    await db.execute('''
      CREATE TABLE payment_history (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        reference_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        paid_date TEXT NOT NULL,
        note TEXT
      )
    ''');

    // 6. App Settings Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS investments (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        investment_type TEXT NOT NULL DEFAULT 'LUMPSUM',
        invested_amount REAL NOT NULL,
        current_value REAL NOT NULL,
        expected_return_rate REAL NOT NULL DEFAULT 0.0,
        sip_amount REAL,
        start_date TEXT NOT NULL,
        maturity_date TEXT,
        risk_level TEXT NOT NULL DEFAULT 'MODERATE',
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL
      );

      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Seed default settings
    await db.insert('app_settings', {'key': 'currency_symbol', 'value': '₹'});
    await db.insert('app_settings', {'key': 'reminder_time_hour', 'value': '9'});
    await db.insert('app_settings', {'key': 'reminder_time_minute', 'value': '0'});
    await db.insert('app_settings', {'key': 'notifications_enabled', 'value': '1'});
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS investments (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          investment_type TEXT NOT NULL DEFAULT 'LUMPSUM',
          invested_amount REAL NOT NULL,
          current_value REAL NOT NULL,
          expected_return_rate REAL NOT NULL DEFAULT 0.0,
          sip_amount REAL,
          start_date TEXT NOT NULL,
          maturity_date TEXT,
          risk_level TEXT NOT NULL DEFAULT 'MODERATE',
          notes TEXT,
          status TEXT NOT NULL DEFAULT 'ACTIVE',
          created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          phone TEXT,
          password_hash TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      try {
        await db.execute("ALTER TABLE loans ADD COLUMN user_id TEXT NOT NULL DEFAULT 'default_user'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN user_id TEXT NOT NULL DEFAULT 'default_user'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE reminders ADD COLUMN user_id TEXT NOT NULL DEFAULT 'default_user'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE payment_history ADD COLUMN user_id TEXT NOT NULL DEFAULT 'default_user'");
      } catch (_) {}
    }
  }

  // --- PASSWORD HASHING ---
  String _hashPassword(String password) {
    const salt = 'mr_salt_2026_secure';
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  Future<void> syncReplaceLoans(String userId, List<LoanModel> remoteLoans) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('loans', where: 'user_id = ?', whereArgs: [userId]);
      for (final loan in remoteLoans) {
        await txn.insert('loans', loan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> syncReplaceTransactions(String userId, List<TransactionModel> remoteTransactions) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
      for (final tx in remoteTransactions) {
        await txn.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // --- USER AUTH CRUD ---
  Future<UserModel> registerUser({
    required String name,
    required String email,
    String? phone,
    required String password,
    String? existingId,
  }) async {
    final db = await instance.database;
    final normalizedEmail = email.trim().toLowerCase();

    // Check existing email
    final existing = await db.query('users', where: 'email = ?', whereArgs: [normalizedEmail]);
    if (existing.isNotEmpty) {
      final existingUser = UserModel.fromMap(existing.first);
      await saveActiveSession(existingUser.id);
      return existingUser;
    }

    final newUser = UserModel(
      id: existingId ?? const Uuid().v4(),
      name: name.trim(),
      email: normalizedEmail,
      phone: phone?.trim(),
      createdAt: DateTime.now(),
    );

    await db.insert('users', {
      'id': newUser.id,
      'name': newUser.name,
      'email': newUser.email,
      'phone': newUser.phone,
      'password_hash': _hashPassword(password),
      'created_at': newUser.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await saveActiveSession(newUser.id);
    return newUser;
  }

  Future<void> updateUserDetails(UserModel user) async {
    final db = await instance.database;
    await db.update(
      'users',
      {
        'name': user.name,
        'phone': user.phone?.trim(),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> saveOrUpdateUser(UserModel user, String password) async {
    final db = await instance.database;
    await db.insert(
      'users',
      {
        'id': user.id,
        'name': user.name,
        'email': user.email.trim().toLowerCase(),
        'phone': user.phone?.trim(),
        'password_hash': _hashPassword(password),
        'created_at': user.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> authenticateUser({
    required String emailOrPhone,
    required String password,
  }) async {
    final db = await instance.database;
    final input = emailOrPhone.trim().toLowerCase();
    final hash = _hashPassword(password);

    final maps = await db.query(
      'users',
      where: '(email = ? OR phone = ?) AND password_hash = ?',
      whereArgs: [input, input, hash],
    );

    if (maps.isNotEmpty) {
      final user = UserModel.fromMap(maps.first);
      await saveActiveSession(user.id);
      return user;
    }
    return null;
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveActiveSession(String userId) async {
    await setSetting('active_session_user_id', userId);
  }

  Future<String?> getActiveSession() async {
    return await getSetting('active_session_user_id');
  }

  Future<void> clearActiveSession() async {
    final db = await instance.database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: ['active_session_user_id']);
  }

  // --- USER-SCOPED LOAN CRUD ---
  Future<int> insertLoan(LoanModel loan) async {
    final db = await instance.database;
    return await db.insert('loans', loan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LoanModel>> getAllLoans({required String userId, String? status}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps;
    if (status != null) {
      maps = await db.query(
        'loans',
        where: 'user_id = ? AND status = ?',
        whereArgs: [userId, status],
        orderBy: 'due_day ASC',
      );
    } else {
      maps = await db.query(
        'loans',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'status ASC, due_day ASC',
      );
    }
    return maps.map((map) => LoanModel.fromMap(map)).toList();
  }

  Future<LoanModel?> getLoanById(String id, String userId) async {
    final db = await instance.database;
    final maps = await db.query('loans', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
    if (maps.isNotEmpty) {
      return LoanModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateLoan(LoanModel loan) async {
    final db = await instance.database;
    return await db.update('loans', loan.toMap(), where: 'id = ? AND user_id = ?', whereArgs: [loan.id, loan.userId]);
  }

  Future<int> deleteLoan(String id, String userId) async {
    final db = await instance.database;
    await db.delete('payment_history', where: 'reference_id = ? AND user_id = ?', whereArgs: [id, userId]);
    await db.delete('reminders', where: 'reference_id = ? AND user_id = ?', whereArgs: [id, userId]);
    return await db.delete('loans', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
  }

  // --- USER-SCOPED TRANSACTION CRUD ---
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TransactionModel>> getAllTransactions({
    required String userId,
    String? type,
    String? status,
  }) async {
    final db = await instance.database;
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (type != null && status != null) {
      whereClause += ' AND type = ? AND status = ?';
      whereArgs.addAll([type, status]);
    } else if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    } else if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    final maps = await db.query('transactions', where: whereClause, whereArgs: whereArgs, orderBy: 'due_date ASC');
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getReceivablesAndPayables({required String userId}) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND type IN (?, ?)',
      whereArgs: [userId, 'RECEIVABLE', 'PAYABLE'],
      orderBy: 'status ASC, due_date ASC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getMonthlyTransactions({
    required String userId,
    required int year,
    required int month,
  }) async {
    final db = await instance.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND due_date >= ? AND due_date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getUpcomingTransactions({
    required String userId,
    required int days,
  }) async {
    final db = await instance.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    final endLimit = DateTime(now.year, now.month, now.day + days, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND due_date >= ? AND due_date <= ? AND status = ?',
      whereArgs: [userId, today, endLimit, 'PENDING'],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getOverdueTransactions({required String userId}) async {
    final db = await instance.database;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String();

    final maps = await db.query(
      'transactions',
      where: 'user_id = ? AND due_date < ? AND status = ?',
      whereArgs: [userId, today, 'PENDING'],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update('transactions', transaction.toMap(), where: 'id = ? AND user_id = ?', whereArgs: [transaction.id, transaction.userId]);
  }

  Future<int> deleteTransaction(String id, String userId) async {
    final db = await instance.database;
    await db.delete('payment_history', where: 'reference_id = ? AND user_id = ?', whereArgs: [id, userId]);
    await db.delete('reminders', where: 'reference_id = ? AND user_id = ?', whereArgs: [id, userId]);
    return await db.delete('transactions', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
  }

  // --- USER-SCOPED PAYMENT HISTORY CRUD ---
  Future<int> insertPaymentHistory(PaymentHistoryModel payment) async {
    final db = await instance.database;
    return await db.insert('payment_history', payment.toMap());
  }

  Future<List<PaymentHistoryModel>> getPaymentHistoryForReference(String referenceId, String userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'payment_history',
      where: 'reference_id = ? AND user_id = ?',
      whereArgs: [referenceId, userId],
      orderBy: 'paid_date DESC',
    );
    return maps.map((map) => PaymentHistoryModel.fromMap(map)).toList();
  }

  // --- SETTINGS CRUD ---
  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('app_settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // ===================== INVESTMENTS =====================

  Future<int> insertInvestment(InvestmentModel inv) async {
    final db = await database;
    await _ensureTables(db);
    return await db.insert(
      'investments',
      inv.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InvestmentModel>> getInvestments(String userId) async {
    final db = await database;
    await _ensureTables(db);
    final maps = await db.query(
      'investments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => InvestmentModel.fromMap(m)).toList();
  }

  Future<int> updateInvestment(InvestmentModel inv) async {
    final db = await database;
    return await db.update(
      'investments',
      inv.toMap(),
      where: 'id = ?',
      whereArgs: [inv.id],
    );
  }

  Future<int> updateInvestmentValuation(String id, double newValue) async {
    final db = await database;
    return await db.update(
      'investments',
      {'current_value': newValue},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> softDeleteInvestment(String id) async {
    final db = await database;
    return await db.update(
      'investments',
      {'status': 'DELETED'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreInvestment(String id) async {
    final db = await database;
    return await db.update(
      'investments',
      {'status': 'ACTIVE'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInvestmentPermanently(String id) async {
    final db = await database;
    return await db.delete(
      'investments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> syncReplaceInvestments(String userId, List<InvestmentModel> remoteInvestments) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('investments', where: 'user_id = ?', whereArgs: [userId]);
      for (final inv in remoteInvestments) {
        await txn.insert('investments', inv.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
