enum ChildExpenseCategory {
  education,
  healthcare,
  childcare,
  events,
  allowance,
  others,
}

extension ChildExpenseCategoryExt on ChildExpenseCategory {
  String get name {
    switch (this) {
      case ChildExpenseCategory.education:
        return 'EDUCATION';
      case ChildExpenseCategory.healthcare:
        return 'HEALTHCARE';
      case ChildExpenseCategory.childcare:
        return 'CHILDCARE';
      case ChildExpenseCategory.events:
        return 'EVENTS';
      case ChildExpenseCategory.allowance:
        return 'ALLOWANCE';
      case ChildExpenseCategory.others:
        return 'OTHERS';
    }
  }

  String get displayName {
    switch (this) {
      case ChildExpenseCategory.education:
        return 'Education & School';
      case ChildExpenseCategory.healthcare:
        return 'Health & Medical';
      case ChildExpenseCategory.childcare:
        return 'Daily Care & Toys';
      case ChildExpenseCategory.events:
        return 'Events & Outings';
      case ChildExpenseCategory.allowance:
        return 'Pocket Money';
      case ChildExpenseCategory.others:
        return 'Other Expenses';
    }
  }

  static ChildExpenseCategory fromString(String val) {
    final lower = val.toUpperCase().trim();
    if (lower == 'EDUCATION') return ChildExpenseCategory.education;
    if (lower == 'HEALTHCARE' || lower == 'HEALTH' || lower == 'MEDICAL') return ChildExpenseCategory.healthcare;
    if (lower == 'CHILDCARE' || lower == 'DAYCARE' || lower == 'LIFESTYLE') return ChildExpenseCategory.childcare;
    if (lower == 'EVENTS' || lower == 'BIRTHDAY' || lower == 'CELEBRATION') return ChildExpenseCategory.events;
    if (lower == 'ALLOWANCE' || lower == 'POCKET_MONEY') return ChildExpenseCategory.allowance;
    return ChildExpenseCategory.others;
  }
}

class ChildExpenseModel {
  final String id;
  final String childId;
  final String userId;
  final String title;
  final double amount;
  final String category; // EDUCATION, HEALTHCARE, CHILDCARE, EVENTS, ALLOWANCE, OTHERS
  final DateTime expenseDate;
  final String paymentMode; // UPI, CASH, CARD, NET_BANKING
  final bool isRecurring;
  final String recurrenceFrequency; // NONE, MONTHLY, QUARTERLY, YEARLY
  final String? receiptUrl;
  final String? notes;
  final DateTime createdAt;

  ChildExpenseModel({
    required this.id,
    required this.childId,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.expenseDate,
    this.paymentMode = 'UPI',
    this.isRecurring = false,
    this.recurrenceFrequency = 'NONE',
    this.receiptUrl,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ChildExpenseCategory get categoryEnum => ChildExpenseCategoryExt.fromString(category);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'expenseDate': expenseDate.toIso8601String().split('T')[0],
      'paymentMode': paymentMode,
      'isRecurring': isRecurring,
      'recurrenceFrequency': recurrenceFrequency,
      'receiptUrl': receiptUrl,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChildExpenseModel.fromJson(Map<String, dynamic> json) {
    return ChildExpenseModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? json['child_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      category: json['category'] ?? 'OTHERS',
      expenseDate: json['expenseDate'] != null
          ? DateTime.parse(json['expenseDate'].toString())
          : (json['expense_date'] != null
              ? DateTime.parse(json['expense_date'].toString())
              : DateTime.now()),
      paymentMode: json['paymentMode'] ?? json['payment_mode'] ?? 'UPI',
      isRecurring: json['isRecurring'] == true || json['is_recurring'] == 1 || json['is_recurring'] == true,
      recurrenceFrequency: json['recurrenceFrequency'] ?? json['recurrence_frequency'] ?? 'NONE',
      receiptUrl: json['receiptUrl'] ?? json['receipt_url'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'payment_mode': paymentMode,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_frequency': recurrenceFrequency,
      'receipt_url': receiptUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChildExpenseModel.fromMap(Map<String, dynamic> map) {
    return ChildExpenseModel.fromJson(map);
  }

  ChildExpenseModel copyWith({
    String? id,
    String? childId,
    String? userId,
    String? title,
    double? amount,
    String? category,
    DateTime? expenseDate,
    String? paymentMode,
    bool? isRecurring,
    String? recurrenceFrequency,
    String? receiptUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return ChildExpenseModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMode: paymentMode ?? this.paymentMode,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
