import 'dart:convert';

class LoanModel {
  final String id;
  final String userId;
  final String title;
  final String lenderName;
  final double totalPrincipal;
  final double emiAmount;
  final double interestRate;
  final int totalEmis;
  final int remainingEmis;
  final int dueDay; // Day of month (1-31)
  final DateTime startDate;
  final List<int> reminderOffsets; // [7, 2, 1, 0]
  final String status; // ACTIVE, COMPLETED, ARCHIVED
  final String? notes;
  final DateTime createdAt;

  LoanModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.lenderName,
    required this.totalPrincipal,
    required this.emiAmount,
    this.interestRate = 0.0,
    required this.totalEmis,
    required this.remainingEmis,
    required this.dueDay,
    required this.startDate,
    this.reminderOffsets = const [7, 2, 1, 0],
    this.status = 'ACTIVE',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get paidEmis => totalEmis - remainingEmis;
  double get progressPercentage => totalEmis > 0 ? paidEmis / totalEmis : 0.0;
  double get totalPaidAmount => paidEmis * emiAmount;
  double get remainingBalance => remainingEmis * emiAmount;

  DateTime get nextDueDate {
    final now = DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, dueDay.clamp(1, 28));
    if (candidate.isBefore(DateTime(now.year, now.month, now.day))) {
      candidate = DateTime(now.year, now.month + 1, dueDay.clamp(1, 28));
    }
    return candidate;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'lender_name': lenderName,
      'total_principal': totalPrincipal,
      'emi_amount': emiAmount,
      'interest_rate': interestRate,
      'total_emis': totalEmis,
      'remaining_emis': remainingEmis,
      'due_day': dueDay,
      'start_date': startDate.toIso8601String(),
      'reminder_offsets': jsonEncode(reminderOffsets),
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    List<int> offsets = [7, 2, 1, 0];
    if (map['reminder_offsets'] != null) {
      try {
        final decoded = jsonDecode(map['reminder_offsets'] as String);
        offsets = List<int>.from(decoded);
      } catch (_) {}
    }

    return LoanModel(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? 'default_user',
      title: map['title'] as String,
      lenderName: map['lender_name'] as String,
      totalPrincipal: (map['total_principal'] as num).toDouble(),
      emiAmount: (map['emi_amount'] as num).toDouble(),
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0.0,
      totalEmis: map['total_emis'] as int,
      remainingEmis: map['remaining_emis'] as int,
      dueDay: map['due_day'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      reminderOffsets: offsets,
      status: map['status'] as String? ?? 'ACTIVE',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }

  LoanModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? lenderName,
    double? totalPrincipal,
    double? emiAmount,
    double? interestRate,
    int? totalEmis,
    int? remainingEmis,
    int? dueDay,
    DateTime? startDate,
    List<int>? reminderOffsets,
    String? status,
    String? notes,
  }) {
    return LoanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      lenderName: lenderName ?? this.lenderName,
      totalPrincipal: totalPrincipal ?? this.totalPrincipal,
      emiAmount: emiAmount ?? this.emiAmount,
      interestRate: interestRate ?? this.interestRate,
      totalEmis: totalEmis ?? this.totalEmis,
      remainingEmis: remainingEmis ?? this.remainingEmis,
      dueDay: dueDay ?? this.dueDay,
      startDate: startDate ?? this.startDate,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
