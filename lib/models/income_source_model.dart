
class IncomeSourceModel {
  final String id;
  final String userId;
  final String earnerName; // e.g., "Self (Naveen)", "Spouse", "Father (Pension)", "Rental House"
  final String sourceTitle; // e.g., "Software Engineer Salary", "Freelance Work", "Apartment Rent"
  final double amount; // Monthly amount in INR
  final int payoutDay; // Day of the month received (1-31)
  final String category; // SALARY, BUSINESS, RENTAL, PENSION, FREELANCE, OTHER
  final bool isRecurring; // Usually true for salary
  final String? notes;
  final String status; // ACTIVE, PAUSED, DELETED
  final DateTime createdAt;

  IncomeSourceModel({
    required this.id,
    required this.userId,
    required this.earnerName,
    required this.sourceTitle,
    required this.amount,
    this.payoutDay = 1,
    this.category = 'SALARY',
    this.isRecurring = true,
    this.notes,
    this.status = 'ACTIVE',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'earner_name': earnerName,
      'source_title': sourceTitle,
      'amount': amount,
      'payout_day': payoutDay,
      'category': category,
      'is_recurring': isRecurring ? 1 : 0,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IncomeSourceModel.fromMap(Map<String, dynamic> map) {
    return IncomeSourceModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      earnerName: map['earner_name'] as String,
      sourceTitle: map['source_title'] as String,
      amount: (map['amount'] as num).toDouble(),
      payoutDay: map['payout_day'] as int? ?? 1,
      category: map['category'] as String? ?? 'SALARY',
      isRecurring: (map['is_recurring'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'ACTIVE',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }

  IncomeSourceModel copyWith({
    String? earnerName,
    String? sourceTitle,
    double? amount,
    int? payoutDay,
    String? category,
    bool? isRecurring,
    String? notes,
    String? status,
  }) {
    return IncomeSourceModel(
      id: id,
      userId: userId,
      earnerName: earnerName ?? this.earnerName,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      amount: amount ?? this.amount,
      payoutDay: payoutDay ?? this.payoutDay,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
