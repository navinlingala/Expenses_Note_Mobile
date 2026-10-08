import 'package:flutter/material.dart';

class CreditCardModel {
  final String id;
  final String userId;
  final String cardName;
  final String bankName;
  final String cardNetwork; // VISA, MASTERCARD, RUPAY, AMEX, DINERS
  final String? cardNumber; // Full 16-digit card number (stored securely)
  final String? cardHolderName;
  final String? expiryDate; // MM/YY
  final String? cvv; // 3 or 4 digits
  final String? cardPin; // 4-digit ATM/POS PIN
  final String? last4Digits;
  final double totalLimit;
  final double availableLimit;
  final double currentOutstanding;
  final int statementDay; // 1 - 31
  final int dueDay; // 1 - 31
  final String colorTheme; // BLUE_PURPLE, EMERALD, MIDNIGHT_GOLD, CRIMSON, SUNSET, OBSIDIAN, ROYAL_BLUE
  final bool reminderEnabled;
  final int interestFreeDays;
  final String status; // ACTIVE, BLOCKED, CLOSED
  final String? notes;
  final DateTime createdAt;

  CreditCardModel({
    required this.id,
    required this.userId,
    required this.cardName,
    required this.bankName,
    this.cardNetwork = 'VISA',
    this.cardNumber,
    this.cardHolderName,
    this.expiryDate,
    this.cvv,
    this.cardPin,
    this.last4Digits,
    required this.totalLimit,
    required this.availableLimit,
    this.currentOutstanding = 0.0,
    this.statementDay = 15,
    this.dueDay = 5,
    this.colorTheme = 'BLUE_PURPLE',
    this.reminderEnabled = true,
    this.interestFreeDays = 50,
    this.status = 'ACTIVE',
    this.notes,
    required this.createdAt,
  });

  String get displayLast4 {
    if (last4Digits != null && last4Digits!.isNotEmpty) {
      return last4Digits!;
    }
    if (cardNumber != null && cardNumber!.replaceAll(RegExp(r'\s+'), '').length >= 4) {
      final clean = cardNumber!.replaceAll(RegExp(r'\s+'), '');
      return clean.substring(clean.length - 4);
    }
    return '••••';
  }

  String get formattedCardNumber {
    if (cardNumber == null || cardNumber!.isEmpty) {
      return '•••• •••• •••• $displayLast4';
    }
    final clean = cardNumber!.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  String get maskedCardNumber {
    if (cardNumber == null || cardNumber!.isEmpty) {
      return '•••• •••• •••• $displayLast4';
    }
    final clean = cardNumber!.replaceAll(RegExp(r'\s+'), '');
    if (clean.length <= 4) return clean;
    final first4 = clean.length >= 8 ? clean.substring(0, 4) : '••••';
    final last4 = clean.substring(clean.length - 4);
    return '$first4 •••• •••• $last4';
  }

  double get utilizationPercentage {
    if (totalLimit <= 0) return 0.0;
    final pct = (currentOutstanding / totalLimit) * 100;
    return pct.clamp(0.0, 100.0);
  }

  String get utilizationHealth {
    final pct = utilizationPercentage;
    if (pct <= 30.0) return 'HEALTHY';
    if (pct <= 70.0) return 'MODERATE';
    return 'HIGH';
  }

  Color get utilizationColor {
    final health = utilizationHealth;
    if (health == 'HEALTHY') return const Color(0xFF10B981);
    if (health == 'MODERATE') return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  DateTime get nextStatementDate {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    int maxDayInMonth = DateTime(year, month + 1, 0).day;
    int targetDay = statementDay.clamp(1, maxDayInMonth);

    DateTime statementThisMonth = DateTime(year, month, targetDay);
    if (now.isAfter(statementThisMonth)) {
      int nextMonth = month + 1;
      int nextYear = year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      int maxDayNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      return DateTime(nextYear, nextMonth, statementDay.clamp(1, maxDayNextMonth));
    }
    return statementThisMonth;
  }

  int get daysUntilStatement {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextStatementDate.year, nextStatementDate.month, nextStatementDate.day);
    return target.difference(today).inDays;
  }

  DateTime get nextDueDate {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    int maxDayInMonth = DateTime(year, month + 1, 0).day;
    int targetDay = dueDay.clamp(1, maxDayInMonth);

    DateTime dueThisMonth = DateTime(year, month, targetDay);
    if (now.isAfter(dueThisMonth)) {
      int nextMonth = month + 1;
      int nextYear = year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      int maxDayNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      return DateTime(nextYear, nextMonth, dueDay.clamp(1, maxDayNextMonth));
    }
    return dueThisMonth;
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return target.difference(today).inDays;
  }

  List<Color> get gradientColors {
    switch (colorTheme) {
      case 'EMERALD':
        return [const Color(0xFF065F46), const Color(0xFF047857), const Color(0xFF10B981)];
      case 'MIDNIGHT_GOLD':
        return [const Color(0xFF1F2937), const Color(0xFF374151), const Color(0xFFD97706)];
      case 'CRIMSON':
        return [const Color(0xFF881337), const Color(0xFFBE123C), const Color(0xFFE11D48)];
      case 'SUNSET':
        return [const Color(0xFF7C2D12), const Color(0xFFC2410C), const Color(0xFFF97316)];
      case 'OBSIDIAN':
        return [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)];
      case 'ROYAL_BLUE':
        return [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF3B82F6)];
      case 'BLUE_PURPLE':
      default:
        return [const Color(0xFF312E81), const Color(0xFF4F46E5), const Color(0xFF7C3AED)];
    }
  }

  /// SQLite-compatible Map with snake_case keys
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'card_name': cardName,
      'bank_name': bankName,
      'card_network': cardNetwork,
      'card_number': cardNumber,
      'card_holder_name': cardHolderName,
      'expiry_date': expiryDate,
      'cvv': cvv,
      'card_pin': cardPin,
      'last4_digits': displayLast4,
      'total_limit': totalLimit,
      'available_limit': availableLimit,
      'current_outstanding': currentOutstanding,
      'statement_day': statementDay,
      'due_day': dueDay,
      'color_theme': colorTheme,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'interest_free_days': interestFreeDays,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// REST API compatible JSON map with camelCase keys
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cardName': cardName,
      'bankName': bankName,
      'cardNetwork': cardNetwork,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardPin': cardPin,
      'last4Digits': displayLast4,
      'totalLimit': totalLimit,
      'availableLimit': availableLimit,
      'currentOutstanding': currentOutstanding,
      'statementDay': statementDay,
      'dueDay': dueDay,
      'colorTheme': colorTheme,
      'reminderEnabled': reminderEnabled,
      'interestFreeDays': interestFreeDays,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CreditCardModel.fromMap(Map<String, dynamic> map) {
    return CreditCardModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      cardName: map['card_name']?.toString() ?? map['cardName']?.toString() ?? '',
      bankName: map['bank_name']?.toString() ?? map['bankName']?.toString() ?? '',
      cardNetwork: map['card_network']?.toString() ?? map['cardNetwork']?.toString() ?? 'VISA',
      cardNumber: map['card_number']?.toString() ?? map['cardNumber']?.toString(),
      cardHolderName: map['card_holder_name']?.toString() ?? map['cardHolderName']?.toString(),
      expiryDate: map['expiry_date']?.toString() ?? map['expiryDate']?.toString(),
      cvv: map['cvv']?.toString(),
      cardPin: map['card_pin']?.toString() ?? map['cardPin']?.toString(),
      last4Digits: map['last4_digits']?.toString() ?? map['last4Digits']?.toString(),
      totalLimit: (map['total_limit'] ?? map['totalLimit'] ?? 0.0).toDouble(),
      availableLimit: (map['available_limit'] ?? map['availableLimit'] ?? 0.0).toDouble(),
      currentOutstanding: (map['current_outstanding'] ?? map['currentOutstanding'] ?? 0.0).toDouble(),
      statementDay: (map['statement_day'] ?? map['statementDay'] ?? 15) is int
          ? (map['statement_day'] ?? map['statementDay'] ?? 15)
          : int.tryParse(map['statement_day']?.toString() ?? map['statementDay']?.toString() ?? '15') ?? 15,
      dueDay: (map['due_day'] ?? map['dueDay'] ?? 5) is int
          ? (map['due_day'] ?? map['dueDay'] ?? 5)
          : int.tryParse(map['due_day']?.toString() ?? map['dueDay']?.toString() ?? '5') ?? 5,
      colorTheme: map['color_theme']?.toString() ?? map['colorTheme']?.toString() ?? 'BLUE_PURPLE',
      reminderEnabled: map['reminder_enabled'] == 1 ||
          map['reminder_enabled'] == true ||
          map['reminderEnabled'] == 1 ||
          map['reminderEnabled'] == true,
      interestFreeDays: (map['interest_free_days'] ?? map['interestFreeDays'] ?? 50) is int
          ? (map['interest_free_days'] ?? map['interestFreeDays'] ?? 50)
          : int.tryParse(map['interest_free_days']?.toString() ?? map['interestFreeDays']?.toString() ?? '50') ?? 50,
      status: map['status']?.toString() ?? 'ACTIVE',
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }

  factory CreditCardModel.fromJson(Map<String, dynamic> json) => CreditCardModel.fromMap(json);

  CreditCardModel copyWith({
    String? id,
    String? userId,
    String? cardName,
    String? bankName,
    String? cardNetwork,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? cvv,
    String? cardPin,
    String? last4Digits,
    double? totalLimit,
    double? availableLimit,
    double? currentOutstanding,
    int? statementDay,
    int? dueDay,
    String? colorTheme,
    bool? reminderEnabled,
    int? interestFreeDays,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return CreditCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardName: cardName ?? this.cardName,
      bankName: bankName ?? this.bankName,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      cardPin: cardPin ?? this.cardPin,
      last4Digits: last4Digits ?? this.last4Digits,
      totalLimit: totalLimit ?? this.totalLimit,
      availableLimit: availableLimit ?? this.availableLimit,
      currentOutstanding: currentOutstanding ?? this.currentOutstanding,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      colorTheme: colorTheme ?? this.colorTheme,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      interestFreeDays: interestFreeDays ?? this.interestFreeDays,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
