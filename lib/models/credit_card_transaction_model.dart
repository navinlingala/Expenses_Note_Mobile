class CreditCardTransactionModel {
  final String id;
  final String userId;
  final String cardId;
  final double amount;
  final String? merchantName;
  final String category; // SHOPPING, DINING, GROCERIES, FUEL, BILLS, TRAVEL, ENTERTAINMENT, HEALTHCARE, OTHER
  final DateTime transactionDate;
  final String transactionType; // EXPENSE, PAYMENT, REFUND
  final bool isEmi;
  final int? emiMonths;
  final double? monthlyEmiAmount;
  final bool isBilled;
  final String? notes;
  final DateTime createdAt;

  CreditCardTransactionModel({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.amount,
    this.merchantName,
    this.category = 'SHOPPING',
    required this.transactionDate,
    this.transactionType = 'EXPENSE',
    this.isEmi = false,
    this.emiMonths,
    this.monthlyEmiAmount,
    this.isBilled = false,
    this.notes,
    required this.createdAt,
  });

  /// SQLite compatible map with snake_case keys
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'card_id': cardId,
      'amount': amount,
      'merchant_name': merchantName,
      'category': category,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
      'transaction_type': transactionType,
      'is_emi': isEmi ? 1 : 0,
      'emi_months': emiMonths,
      'monthly_emi_amount': monthlyEmiAmount,
      'is_billed': isBilled ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// REST API compatible map with camelCase keys
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cardId': cardId,
      'amount': amount,
      'merchantName': merchantName,
      'category': category,
      'transactionDate': transactionDate.toIso8601String().split('T').first,
      'transactionType': transactionType,
      'isEmi': isEmi,
      'emiMonths': emiMonths,
      'monthlyEmiAmount': monthlyEmiAmount,
      'isBilled': isBilled,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CreditCardTransactionModel.fromMap(Map<String, dynamic> map) {
    return CreditCardTransactionModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      cardId: map['card_id']?.toString() ?? map['cardId']?.toString() ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      merchantName: map['merchant_name']?.toString() ?? map['merchantName']?.toString(),
      category: map['category']?.toString() ?? 'SHOPPING',
      transactionDate: map['transaction_date'] != null
          ? DateTime.tryParse(map['transaction_date'].toString()) ?? DateTime.now()
          : (map['transactionDate'] != null
              ? DateTime.tryParse(map['transactionDate'].toString()) ?? DateTime.now()
              : DateTime.now()),
      transactionType: map['transaction_type']?.toString() ?? map['transactionType']?.toString() ?? 'EXPENSE',
      isEmi: map['is_emi'] == 1 || map['is_emi'] == true || map['isEmi'] == 1 || map['isEmi'] == true,
      emiMonths: map['emi_months'] != null
          ? int.tryParse(map['emi_months'].toString())
          : (map['emiMonths'] != null ? int.tryParse(map['emiMonths'].toString()) : null),
      monthlyEmiAmount: map['monthly_emi_amount'] != null
          ? (map['monthly_emi_amount'] as num).toDouble()
          : (map['monthlyEmiAmount'] != null ? (map['monthlyEmiAmount'] as num).toDouble() : null),
      isBilled: map['is_billed'] == 1 || map['is_billed'] == true || map['isBilled'] == 1 || map['isBilled'] == true,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }

  factory CreditCardTransactionModel.fromJson(Map<String, dynamic> json) => CreditCardTransactionModel.fromMap(json);
}
