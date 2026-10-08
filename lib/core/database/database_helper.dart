
import '../../models/investment_model.dart';
import '../../models/gold_asset_model.dart';
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
import '../../models/child_profile_model.dart';
import '../../models/child_expense_model.dart';
import '../../models/child_investment_model.dart';
import '../../models/child_future_goal_model.dart';
import '../../models/credit_card_model.dart';
import '../../models/credit_card_transaction_model.dart';
import '../../models/vault_item_model.dart';

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
      CREATE TABLE IF NOT EXISTS credit_cards (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        card_name TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        card_network TEXT NOT NULL DEFAULT 'VISA',
        card_number TEXT,
        card_holder_name TEXT,
        expiry_date TEXT,
        cvv TEXT,
        card_pin TEXT,
        last4_digits TEXT,
        total_limit REAL NOT NULL,
        available_limit REAL NOT NULL,
        current_outstanding REAL NOT NULL DEFAULT 0.0,
        statement_day INTEGER NOT NULL DEFAULT 15,
        due_day INTEGER NOT NULL DEFAULT 5,
        color_theme TEXT DEFAULT 'BLUE_PURPLE',
        reminder_enabled INTEGER DEFAULT 1,
        interest_free_days INTEGER DEFAULT 50,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await _addColumnIfNotExists(db, 'credit_cards', 'card_number', 'TEXT');
    await _addColumnIfNotExists(db, 'credit_cards', 'card_holder_name', 'TEXT');
    await _addColumnIfNotExists(db, 'credit_cards', 'expiry_date', 'TEXT');
    await _addColumnIfNotExists(db, 'credit_cards', 'cvv', 'TEXT');
    await _addColumnIfNotExists(db, 'credit_cards', 'card_pin', 'TEXT');
    await _addColumnIfNotExists(db, 'credit_cards', 'last4_digits', 'TEXT');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vault_items (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        item_type TEXT NOT NULL DEFAULT 'CARD',
        title TEXT NOT NULL,
        subtitle TEXT,
        account_or_card_number TEXT,
        holder_name TEXT,
        expiry_date TEXT,
        cvv TEXT,
        pin TEXT,
        password TEXT,
        ifsc_code TEXT,
        upi_id TEXT,
        url_or_app TEXT,
        secret_content TEXT,
        color_theme TEXT DEFAULT 'OBSIDIAN',
        category TEXT DEFAULT 'GENERAL',
        is_favorite INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS credit_card_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        card_id TEXT NOT NULL,
        amount REAL NOT NULL,
        merchant_name TEXT,
        category TEXT NOT NULL DEFAULT 'SHOPPING',
        transaction_date TEXT NOT NULL,
        transaction_type TEXT NOT NULL DEFAULT 'EXPENSE',
        is_emi INTEGER DEFAULT 0,
        emi_months INTEGER,
        monthly_emi_amount REAL,
        is_billed INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gold_assets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        gold_type TEXT NOT NULL,
        purity TEXT NOT NULL,
        weight_in_grams REAL NOT NULL,
        purchase_price_per_gram REAL NOT NULL,
        making_charges REAL NOT NULL DEFAULT 0.0,
        total_invested_amount REAL NOT NULL,
        purchase_date TEXT NOT NULL,
        locker_location TEXT,
        huid_number TEXT,
        jeweler_name TEXT,
        sgb_interest_rate REAL DEFAULT 2.5,
        maturity_date TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL
      )
    ''');
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS child_profiles (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        gender TEXT NOT NULL DEFAULT 'MALE',
        date_of_birth TEXT NOT NULL,
        school_or_college TEXT,
        avatar_color TEXT NOT NULL DEFAULT '0xFF3B82F6',
        photo_url TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS child_expenses (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        expense_date TEXT NOT NULL,
        payment_mode TEXT DEFAULT 'UPI',
        is_recurring INTEGER DEFAULT 0,
        recurrence_frequency TEXT DEFAULT 'NONE',
        receipt_url TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS child_investments (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        investment_name TEXT NOT NULL,
        investment_type TEXT NOT NULL,
        invested_amount REAL NOT NULL,
        current_valuation REAL NOT NULL,
        expected_return_rate REAL DEFAULT 8.2,
        monthly_contribution REAL DEFAULT 0.0,
        start_date TEXT,
        maturity_date TEXT,
        account_number_or_folio TEXT,
        linked_goal_id TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS child_future_goals (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        goal_title TEXT NOT NULL,
        target_amount_today REAL NOT NULL,
        estimated_inflation_rate REAL DEFAULT 8.0,
        target_year INTEGER NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    try {
      final currency = await db.query('app_settings', where: 'key = ?', whereArgs: ['currency_symbol']);
      if (currency.isEmpty) {
        await db.insert('app_settings', {'key': 'currency_symbol', 'value': '₹'});
        await db.insert('app_settings', {'key': 'reminder_time_hour', 'value': '9'});
        await db.insert('app_settings', {'key': 'reminder_time_minute', 'value': '0'});
        await db.insert('app_settings', {'key': 'notifications_enabled', 'value': '1'});
      }
    } catch (_) {}
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

    // 6. Investments Table
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

    // 7. App Settings Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
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

  // --- Gold Asset Operations ---
  Future<int> insertGoldAsset(GoldAssetModel asset) async {
    final db = await database;
    return await db.insert(
      'gold_assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GoldAssetModel>> getGoldAssets(String userId) async {
    final db = await database;
    final res = await db.query(
      'gold_assets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return res.map((e) => GoldAssetModel.fromMap(e)).toList();
  }

  Future<int> updateGoldAsset(GoldAssetModel asset) async {
    final db = await database;
    return await db.update(
      'gold_assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  Future<int> deleteGoldAsset(String id) async {
    final db = await database;
    return await db.delete(
      'gold_assets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> syncReplaceGoldAssets(String userId, List<GoldAssetModel> remoteAssets) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('gold_assets', where: 'user_id = ?', whereArgs: [userId]);
      for (final asset in remoteAssets) {
        await txn.insert('gold_assets', asset.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // --- Child Profiles ---
  Future<int> insertChildProfile(ChildProfileModel profile) async {
    final db = await database;
    return await db.insert('child_profiles', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChildProfileModel>> getChildProfiles(String userId) async {
    final db = await database;
    final res = await db.query('child_profiles', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    return res.map((e) => ChildProfileModel.fromMap(e)).toList();
  }

  Future<int> updateChildProfile(ChildProfileModel profile) async {
    final db = await database;
    return await db.update('child_profiles', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
  }

  Future<int> deleteChildProfile(String id) async {
    final db = await database;
    await db.delete('child_expenses', where: 'child_id = ?', whereArgs: [id]);
    await db.delete('child_investments', where: 'child_id = ?', whereArgs: [id]);
    await db.delete('child_future_goals', where: 'child_id = ?', whereArgs: [id]);
    return await db.delete('child_profiles', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> syncReplaceChildProfiles(String userId, List<ChildProfileModel> remoteProfiles) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('child_profiles', where: 'user_id = ?', whereArgs: [userId]);
      for (final p in remoteProfiles) {
        await txn.insert('child_profiles', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // --- Child Expenses ---
  Future<int> insertChildExpense(ChildExpenseModel expense) async {
    final db = await database;
    return await db.insert('child_expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChildExpenseModel>> getChildExpenses(String userId, {String? childId}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (childId != null && childId.isNotEmpty) {
      res = await db.query('child_expenses', where: 'user_id = ? AND child_id = ?', whereArgs: [userId, childId], orderBy: 'expense_date DESC');
    } else {
      res = await db.query('child_expenses', where: 'user_id = ?', whereArgs: [userId], orderBy: 'expense_date DESC');
    }
    return res.map((e) => ChildExpenseModel.fromMap(e)).toList();
  }

  Future<int> updateChildExpense(ChildExpenseModel expense) async {
    final db = await database;
    return await db.update('child_expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteChildExpense(String id) async {
    final db = await database;
    return await db.delete('child_expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> syncReplaceChildExpenses(String userId, List<ChildExpenseModel> remoteExpenses) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('child_expenses', where: 'user_id = ?', whereArgs: [userId]);
      for (final e in remoteExpenses) {
        await txn.insert('child_expenses', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // --- Child Investments ---
  Future<int> insertChildInvestment(ChildInvestmentModel investment) async {
    final db = await database;
    return await db.insert('child_investments', investment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChildInvestmentModel>> getChildInvestments(String userId, {String? childId}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (childId != null && childId.isNotEmpty) {
      res = await db.query('child_investments', where: 'user_id = ? AND child_id = ?', whereArgs: [userId, childId], orderBy: 'created_at DESC');
    } else {
      res = await db.query('child_investments', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    }
    return res.map((e) => ChildInvestmentModel.fromMap(e)).toList();
  }

  Future<int> updateChildInvestment(ChildInvestmentModel investment) async {
    final db = await database;
    return await db.update('child_investments', investment.toMap(), where: 'id = ?', whereArgs: [investment.id]);
  }

  Future<int> deleteChildInvestment(String id) async {
    final db = await database;
    return await db.delete('child_investments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> syncReplaceChildInvestments(String userId, List<ChildInvestmentModel> remoteInvestments) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('child_investments', where: 'user_id = ?', whereArgs: [userId]);
      for (final inv in remoteInvestments) {
        await txn.insert('child_investments', inv.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // --- Child Future Goals ---
  Future<int> insertChildFutureGoal(ChildFutureGoalModel goal) async {
    final db = await database;
    return await db.insert('child_future_goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChildFutureGoalModel>> getChildFutureGoals(String userId, {String? childId}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (childId != null && childId.isNotEmpty) {
      res = await db.query('child_future_goals', where: 'user_id = ? AND child_id = ?', whereArgs: [userId, childId], orderBy: 'target_year ASC');
    } else {
      res = await db.query('child_future_goals', where: 'user_id = ?', whereArgs: [userId], orderBy: 'target_year ASC');
    }
    return res.map((e) => ChildFutureGoalModel.fromMap(e)).toList();
  }

  Future<int> updateChildFutureGoal(ChildFutureGoalModel goal) async {
    final db = await database;
    return await db.update('child_future_goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<int> deleteChildFutureGoal(String id) async {
    final db = await database;
    return await db.delete('child_future_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> syncReplaceChildFutureGoals(String userId, List<ChildFutureGoalModel> remoteGoals) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('child_future_goals', where: 'user_id = ?', whereArgs: [userId]);
      for (final g in remoteGoals) {
        await txn.insert('child_future_goals', g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ===================== CREDIT CARDS =====================
  Future<int> insertCreditCard(CreditCardModel card) async {
    final db = await database;
    return await db.insert('credit_cards', card.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CreditCardModel>> getCreditCards(String userId) async {
    final db = await database;
    final res = await db.query('credit_cards', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    return res.map((e) => CreditCardModel.fromMap(e)).toList();
  }

  Future<CreditCardModel?> getCreditCardById(String id) async {
    final db = await database;
    final res = await db.query('credit_cards', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) {
      return CreditCardModel.fromMap(res.first);
    }
    return null;
  }

  Future<int> updateCreditCard(CreditCardModel card) async {
    final db = await database;
    return await db.update('credit_cards', card.toMap(), where: 'id = ?', whereArgs: [card.id]);
  }

  Future<int> deleteCreditCard(String id) async {
    final db = await database;
    await db.delete('credit_card_transactions', where: 'card_id = ?', whereArgs: [id]);
    return await db.delete('credit_cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> syncReplaceCreditCards(String userId, List<CreditCardModel> remoteCards) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('credit_cards', where: 'user_id = ?', whereArgs: [userId]);
      for (final card in remoteCards) {
        await txn.insert('credit_cards', card.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ===================== CREDIT CARD TRANSACTIONS =====================
  Future<int> insertCreditCardTransaction(CreditCardTransactionModel tx) async {
    final db = await database;
    final res = await db.insert('credit_card_transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Update the parent card's outstanding & available balance in SQLite
    final cardRes = await db.query('credit_cards', where: 'id = ?', whereArgs: [tx.cardId], limit: 1);
    if (cardRes.isNotEmpty) {
      final card = CreditCardModel.fromMap(cardRes.first);
      double newOutstanding = card.currentOutstanding;
      if (tx.transactionType == 'PAYMENT' || tx.transactionType == 'REFUND') {
        newOutstanding = (newOutstanding - tx.amount).clamp(0.0, double.infinity);
      } else {
        newOutstanding = newOutstanding + tx.amount;
      }
      double newAvailable = (card.totalLimit - newOutstanding).clamp(0.0, double.infinity);
      final updatedCard = card.copyWith(
        currentOutstanding: newOutstanding,
        availableLimit: newAvailable,
      );
      await db.update('credit_cards', updatedCard.toMap(), where: 'id = ?', whereArgs: [card.id]);
    }

    return res;
  }

  Future<List<CreditCardTransactionModel>> getCreditCardTransactions(String userId, {String? cardId}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (cardId != null && cardId.isNotEmpty) {
      res = await db.query('credit_card_transactions', where: 'user_id = ? AND card_id = ?', whereArgs: [userId, cardId], orderBy: 'transaction_date DESC');
    } else {
      res = await db.query('credit_card_transactions', where: 'user_id = ?', whereArgs: [userId], orderBy: 'transaction_date DESC');
    }
    return res.map((e) => CreditCardTransactionModel.fromMap(e)).toList();
  }

  Future<int> deleteCreditCardTransaction(String id) async {
    final db = await database;
    return await db.delete('credit_card_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> syncReplaceCreditCardTransactions(String userId, List<CreditCardTransactionModel> remoteTxs) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('credit_card_transactions', where: 'user_id = ?', whereArgs: [userId]);
      for (final tx in remoteTxs) {
        await txn.insert('credit_card_transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ===================== HELPER COLUMN MIGRATION =====================
  Future<void> _addColumnIfNotExists(Database db, String tableName, String columnName, String columnType) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($tableName)');
      final exists = info.any((row) => (row['name'] as String?)?.toLowerCase() == columnName.toLowerCase());
      if (!exists) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
      }
    } catch (_) {}
  }

  // ===================== PERSONAL SECRET VAULT =====================
  Future<int> insertVaultItem(VaultItemModel item) async {
    final db = await database;
    return await db.insert('vault_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<VaultItemModel>> getVaultItems(String userId, {String? itemType}) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (itemType != null && itemType.isNotEmpty && itemType.toUpperCase() != 'ALL') {
      res = await db.query('vault_items', where: 'user_id = ? AND item_type = ?', whereArgs: [userId, itemType.toUpperCase()], orderBy: 'is_favorite DESC, created_at DESC');
    } else {
      res = await db.query('vault_items', where: 'user_id = ?', whereArgs: [userId], orderBy: 'is_favorite DESC, created_at DESC');
    }
    return res.map((e) => VaultItemModel.fromMap(e)).toList();
  }

  Future<VaultItemModel?> getVaultItemById(String id) async {
    final db = await database;
    final res = await db.query('vault_items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isNotEmpty) {
      return VaultItemModel.fromMap(res.first);
    }
    return null;
  }

  Future<int> updateVaultItem(VaultItemModel item) async {
    final db = await database;
    return await db.update('vault_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteVaultItem(String id) async {
    final db = await database;
    return await db.delete('vault_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> syncReplaceVaultItems(String userId, List<VaultItemModel> remoteItems) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('vault_items', where: 'user_id = ?', whereArgs: [userId]);
      for (final item in remoteItems) {
        await txn.insert('vault_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}



