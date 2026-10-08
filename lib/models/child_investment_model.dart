import 'dart:math' as math;

enum ChildInvestmentType {
  ssy,
  mutualFundSip,
  ppf,
  fd,
  insurance,
  gold,
  other,
}

extension ChildInvestmentTypeExt on ChildInvestmentType {
  String get name {
    switch (this) {
      case ChildInvestmentType.ssy:
        return 'SSY';
      case ChildInvestmentType.mutualFundSip:
        return 'MUTUAL_FUND_SIP';
      case ChildInvestmentType.ppf:
        return 'PPF';
      case ChildInvestmentType.fd:
        return 'FD';
      case ChildInvestmentType.insurance:
        return 'INSURANCE';
      case ChildInvestmentType.gold:
        return 'GOLD';
      case ChildInvestmentType.other:
        return 'OTHER';
    }
  }

  String get displayName {
    switch (this) {
      case ChildInvestmentType.ssy:
        return 'Sukanya Samriddhi (SSY)';
      case ChildInvestmentType.mutualFundSip:
        return 'Child Mutual Fund SIP';
      case ChildInvestmentType.ppf:
        return 'Minor PPF Account';
      case ChildInvestmentType.fd:
        return 'Child Fixed Deposit';
      case ChildInvestmentType.insurance:
        return 'Child Insurance / ULIP';
      case ChildInvestmentType.gold:
        return 'Child Gold / SGB';
      case ChildInvestmentType.other:
        return 'Other Investment';
    }
  }

  static ChildInvestmentType fromString(String val) {
    final upper = val.toUpperCase().trim();
    if (upper == 'SSY' || upper.contains('SUKANYA')) return ChildInvestmentType.ssy;
    if (upper == 'MUTUAL_FUND_SIP' || upper.contains('MUTUAL') || upper.contains('SIP')) return ChildInvestmentType.mutualFundSip;
    if (upper == 'PPF') return ChildInvestmentType.ppf;
    if (upper == 'FD' || upper.contains('DEPOSIT')) return ChildInvestmentType.fd;
    if (upper == 'INSURANCE' || upper.contains('ULIP') || upper.contains('POLICY')) return ChildInvestmentType.insurance;
    if (upper == 'GOLD' || upper.contains('SGB')) return ChildInvestmentType.gold;
    return ChildInvestmentType.other;
  }
}

class ChildInvestmentModel {
  final String id;
  final String childId;
  final String userId;
  final String investmentName;
  final String investmentType; // SSY, MUTUAL_FUND_SIP, PPF, FD, INSURANCE, GOLD, OTHER
  final double investedAmount;
  final double currentValuation;
  final double expectedReturnRate; // e.g. 8.2 for SSY, 12.0 for MF
  final double monthlyContribution;
  final DateTime? startDate;
  final DateTime? maturityDate;
  final String? accountNumberOrFolio;
  final String? linkedGoalId;
  final String? notes;
  final String status; // ACTIVE, MATURED, CLOSED
  final DateTime createdAt;

  ChildInvestmentModel({
    required this.id,
    required this.childId,
    required this.userId,
    required this.investmentName,
    required this.investmentType,
    required this.investedAmount,
    required this.currentValuation,
    this.expectedReturnRate = 8.2,
    this.monthlyContribution = 0.0,
    this.startDate,
    this.maturityDate,
    this.accountNumberOrFolio,
    this.linkedGoalId,
    this.notes,
    this.status = 'ACTIVE',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ChildInvestmentType get typeEnum => ChildInvestmentTypeExt.fromString(investmentType);

  double get profitOrLoss => currentValuation - investedAmount;

  double get roiPercentage {
    if (investedAmount <= 0) return 0.0;
    return (profitOrLoss / investedAmount) * 100.0;
  }

  // Return Rate & Passive Income Helpers
  double get annualReturnRate => expectedReturnRate;
  double get monthlyReturnRate => expectedReturnRate / 12.0;
  double get expectedAnnualReturn => currentValuation * (expectedReturnRate / 100.0);
  double get expectedMonthlyReturn => expectedAnnualReturn / 12.0;

  /// Calculates estimated maturity value based on annual compounding formula
  double estimateMaturityValuation({int years = 15}) {
    final r = expectedReturnRate / 100.0;
    // Lump-sum compounding on current valuation
    double lumpSumFuture = currentValuation * math.pow(1 + r, years);

    // SIP annuity compounding if monthly contribution exists
    double sipFuture = 0.0;
    if (monthlyContribution > 0) {
      final monthlyRate = r / 12.0;
      final totalMonths = years * 12;
      sipFuture = monthlyContribution * ((math.pow(1 + monthlyRate, totalMonths) - 1) / monthlyRate) * (1 + monthlyRate);
    }
    return lumpSumFuture + sipFuture;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'userId': userId,
      'investmentName': investmentName,
      'investmentType': investmentType,
      'investedAmount': investedAmount,
      'currentValuation': currentValuation,
      'expectedReturnRate': expectedReturnRate,
      'monthlyContribution': monthlyContribution,
      'startDate': startDate?.toIso8601String().split('T')[0],
      'maturityDate': maturityDate?.toIso8601String().split('T')[0],
      'accountNumberOrFolio': accountNumberOrFolio,
      'linkedGoalId': linkedGoalId,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChildInvestmentModel.fromJson(Map<String, dynamic> json) {
    return ChildInvestmentModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? json['child_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      investmentName: json['investmentName'] ?? json['investment_name'] ?? '',
      investmentType: json['investmentType'] ?? json['investment_type'] ?? 'OTHER',
      investedAmount: (json['investedAmount'] is num)
          ? (json['investedAmount'] as num).toDouble()
          : ((json['invested_amount'] is num) ? (json['invested_amount'] as num).toDouble() : 0.0),
      currentValuation: (json['currentValuation'] is num)
          ? (json['currentValuation'] as num).toDouble()
          : ((json['current_valuation'] is num) ? (json['current_valuation'] as num).toDouble() : 0.0),
      expectedReturnRate: (json['expectedReturnRate'] is num)
          ? (json['expectedReturnRate'] as num).toDouble()
          : ((json['expected_return_rate'] is num) ? (json['expected_return_rate'] as num).toDouble() : 8.2),
      monthlyContribution: (json['monthlyContribution'] is num)
          ? (json['monthlyContribution'] as num).toDouble()
          : ((json['monthly_contribution'] is num) ? (json['monthly_contribution'] as num).toDouble() : 0.0),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString())
          : (json['start_date'] != null ? DateTime.parse(json['start_date'].toString()) : null),
      maturityDate: json['maturityDate'] != null
          ? DateTime.parse(json['maturityDate'].toString())
          : (json['maturity_date'] != null ? DateTime.parse(json['maturity_date'].toString()) : null),
      accountNumberOrFolio: json['accountNumberOrFolio'] ?? json['account_number_or_folio'],
      linkedGoalId: json['linkedGoalId'] ?? json['linked_goal_id'],
      notes: json['notes'],
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : (json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'user_id': userId,
      'investment_name': investmentName,
      'investment_type': investmentType,
      'invested_amount': investedAmount,
      'current_valuation': currentValuation,
      'expected_return_rate': expectedReturnRate,
      'monthly_contribution': monthlyContribution,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'maturity_date': maturityDate?.toIso8601String().split('T')[0],
      'account_number_or_folio': accountNumberOrFolio,
      'linked_goal_id': linkedGoalId,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChildInvestmentModel.fromMap(Map<String, dynamic> map) {
    return ChildInvestmentModel.fromJson(map);
  }

  ChildInvestmentModel copyWith({
    String? id,
    String? childId,
    String? userId,
    String? investmentName,
    String? investmentType,
    double? investedAmount,
    double? currentValuation,
    double? expectedReturnRate,
    double? monthlyContribution,
    DateTime? startDate,
    DateTime? maturityDate,
    String? accountNumberOrFolio,
    String? linkedGoalId,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return ChildInvestmentModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      userId: userId ?? this.userId,
      investmentName: investmentName ?? this.investmentName,
      investmentType: investmentType ?? this.investmentType,
      investedAmount: investedAmount ?? this.investedAmount,
      currentValuation: currentValuation ?? this.currentValuation,
      expectedReturnRate: expectedReturnRate ?? this.expectedReturnRate,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      accountNumberOrFolio: accountNumberOrFolio ?? this.accountNumberOrFolio,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
