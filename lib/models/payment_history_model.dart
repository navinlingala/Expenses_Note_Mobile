class PaymentHistoryModel {
  final String id;
  final String userId;
  final String referenceId; // loan_id or transaction_id
  final String type; // EMI_PAYMENT, RECEIVABLE_COLLECTED, PAYABLE_PAID, TRANSACTION
  final double amount;
  final DateTime paidDate;
  final String? note;

  PaymentHistoryModel({
    required this.id,
    required this.userId,
    required this.referenceId,
    required this.type,
    required this.amount,
    required this.paidDate,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'reference_id': referenceId,
      'type': type,
      'amount': amount,
      'paid_date': paidDate.toIso8601String(),
      'note': note,
    };
  }

  factory PaymentHistoryModel.fromMap(Map<String, dynamic> map) {
    return PaymentHistoryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? 'default_user',
      referenceId: map['reference_id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidDate: DateTime.parse(map['paid_date'] as String),
      note: map['note'] as String?,
    );
  }
}
