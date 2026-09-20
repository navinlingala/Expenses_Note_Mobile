class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final String? personName;
  final String? phoneNumber;
  final double amount;
  final String type; // CREDIT, DEBIT, RECEIVABLE, PAYABLE, EMI
  final DateTime dueDate;
  final String status; // PENDING, PAID, RECEIVED, OVERDUE, CANCELLED
  final bool isRecurring;
  final String recurrenceFrequency; // NONE, MONTHLY, WEEKLY, YEARLY
  final String? loanId;
  final String? category;
  final String? notes;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    this.personName,
    this.phoneNumber,
    required this.amount,
    required this.type,
    required this.dueDate,
    this.status = 'PENDING',
    this.isRecurring = false,
    this.recurrenceFrequency = 'NONE',
    this.loanId,
    this.category,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue {
    if (status == 'PAID' || status == 'RECEIVED' || status == 'CANCELLED') {
      return false;
    }
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  bool get isDueToday {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isAtSameMomentAs(today);
  }

  bool get isDueTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tmrwDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isAtSameMomentAs(tmrwDate);
  }

  int get daysUntilDue {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'person_name': personName,
      'phone_number': phoneNumber,
      'amount': amount,
      'type': type,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_frequency': recurrenceFrequency,
      'loan_id': loanId,
      'category': category,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? 'default_user',
      title: map['title'] as String,
      personName: map['person_name'] as String?,
      phoneNumber: map['phone_number'] as String?,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      dueDate: DateTime.parse(map['due_date'] as String),
      status: map['status'] as String? ?? 'PENDING',
      isRecurring: (map['is_recurring'] as int?) == 1,
      recurrenceFrequency: map['recurrence_frequency'] as String? ?? 'NONE',
      loanId: map['loan_id'] as String?,
      category: map['category'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? personName,
    String? phoneNumber,
    double? amount,
    String? type,
    DateTime? dueDate,
    String? status,
    bool? isRecurring,
    String? recurrenceFrequency,
    String? loanId,
    String? category,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      personName: personName ?? this.personName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      loanId: loanId ?? this.loanId,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
