import 'dart:math';

class InvestmentModel {
  final String id;
  final String userId;
  final String title;
  final String category; // MUTUAL_FUNDS, STOCKS, FIXED_DEPOSIT, GOLD, REAL_ESTATE, CRYPTO, OTHER
  final String investmentType; // LUMPSUM, SIP
  final double investedAmount;
  final double currentValue;
  final double expectedReturnRate; // Annual % e.g. 12.0
  final double? sipAmount;
  final DateTime startDate;
  final DateTime? maturityDate;
  final String riskLevel; // LOW, MODERATE, HIGH, VERY_HIGH
  final String? notes;
  final String status; // ACTIVE, MATURED, REDEEMED, DELETED
  final DateTime createdAt;

  InvestmentModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    this.investmentType = 'LUMPSUM',
    required this.investedAmount,
    required this.currentValue,
    this.expectedReturnRate = 0.0,
    this.sipAmount,
    required this.startDate,
    this.maturityDate,
    this.riskLevel = 'MODERATE',
    this.notes,
    this.status = 'ACTIVE',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Financial Metrics & Returns
  double get absoluteGain => currentValue - investedAmount;
  double get gainPercentage => investedAmount > 0 ? (absoluteGain / investedAmount) * 100 : 0.0;
  bool get isProfitable => absoluteGain >= 0;

  // Expected annual passive return in Currency
  double get expectedAnnualReturn => investedAmount * (expectedReturnRate / 100);

  // Expected monthly return in Currency
  double get expectedMonthlyReturn => expectedAnnualReturn / 12;

  // Duration held
  int get holdingDays => DateTime.now().difference(startDate).inDays;
  double get holdingYears => holdingDays > 0 ? holdingDays / 365.25 : 0.0;

  // Realized Compound Annual Growth Rate (CAGR %)
  double get realizedCagr {
    if (holdingYears >= 0.08 && investedAmount > 0 && currentValue > 0) {
      final ratio = currentValue / investedAmount;
      final cagr = (pow(ratio, 1.0 / holdingYears) - 1.0) * 100;
      return cagr.isFinite ? cagr : expectedReturnRate;
    }
    return expectedReturnRate;
  }

  // Future valuation forecast at year N
  double projectedValue(int years) {
    if (years <= 0) return currentValue;
    final annualRateDecimal = expectedReturnRate / 100.0;
    
    // Lump sum growth from current value
    final lumpSumGrowth = currentValue * pow(1.0 + annualRateDecimal, years);

    // If recurring SIP, compound future monthly payments
    if (investmentType == 'SIP' && sipAmount != null && sipAmount! > 0) {
      final monthlyRate = annualRateDecimal / 12.0;
      final months = years * 12;
      if (monthlyRate > 0) {
        final sipFutureValue = sipAmount! *
            ((pow(1.0 + monthlyRate, months) - 1.0) / monthlyRate) *
            (1.0 + monthlyRate);
        return lumpSumGrowth + sipFutureValue;
      }
      return lumpSumGrowth + (sipAmount! * months);
    }

    return lumpSumGrowth;
  }

  // Helper Display Properties
  String get categoryDisplayName {
    switch (category.toUpperCase()) {
      case 'MUTUAL_FUNDS':
        return 'Mutual Funds';
      case 'STOCKS':
        return 'Stocks & Equity';
      case 'FIXED_DEPOSIT':
        return 'Fixed Deposit / PPF';
      case 'GOLD':
        return 'Gold & SGB';
      case 'REAL_ESTATE':
        return 'Real Estate / REIT';
      case 'CRYPTO':
        return 'Cryptocurrency';
      default:
        return 'Other Assets';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'category': category,
      'investment_type': investmentType,
      'invested_amount': investedAmount,
      'current_value': currentValue,
      'expected_return_rate': expectedReturnRate,
      'sip_amount': sipAmount,
      'start_date': startDate.toIso8601String(),
      'maturity_date': maturityDate?.toIso8601String(),
      'risk_level': riskLevel,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? 'default_user',
      title: map['title'] as String,
      category: map['category'] as String? ?? 'OTHER',
      investmentType: map['investment_type'] as String? ?? 'LUMPSUM',
      investedAmount: (map['invested_amount'] as num).toDouble(),
      currentValue: (map['current_value'] as num).toDouble(),
      expectedReturnRate: (map['expected_return_rate'] as num?)?.toDouble() ?? 0.0,
      sipAmount: (map['sip_amount'] as num?)?.toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      maturityDate: map['maturity_date'] != null ? DateTime.parse(map['maturity_date'] as String) : null,
      riskLevel: map['risk_level'] as String? ?? 'MODERATE',
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'ACTIVE',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }

  InvestmentModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    String? investmentType,
    double? investedAmount,
    double? currentValue,
    double? expectedReturnRate,
    double? sipAmount,
    DateTime? startDate,
    DateTime? maturityDate,
    String? riskLevel,
    String? notes,
    String? status,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      investmentType: investmentType ?? this.investmentType,
      investedAmount: investedAmount ?? this.investedAmount,
      currentValue: currentValue ?? this.currentValue,
      expectedReturnRate: expectedReturnRate ?? this.expectedReturnRate,
      sipAmount: sipAmount ?? this.sipAmount,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      riskLevel: riskLevel ?? this.riskLevel,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
