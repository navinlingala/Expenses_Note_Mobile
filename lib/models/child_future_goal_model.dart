import 'dart:math' as math;

class ChildFutureGoalModel {
  final String id;
  final String childId;
  final String userId;
  final String goalTitle; // e.g. "B.Tech College Fund at 18"
  final double targetAmountToday;
  final double estimatedInflationRate; // default 8.0%
  final int targetYear;
  final String? notes;
  final DateTime createdAt;

  ChildFutureGoalModel({
    required this.id,
    required this.childId,
    required this.userId,
    required this.goalTitle,
    required this.targetAmountToday,
    this.estimatedInflationRate = 8.0,
    required this.targetYear,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get yearsRemaining {
    final currentYear = DateTime.now().year;
    final diff = targetYear - currentYear;
    return diff > 0 ? diff : 0;
  }

  /// Calculates future cost taking education inflation into account
  double get estimatedFutureCost {
    final years = yearsRemaining;
    if (years == 0) return targetAmountToday;
    final inflationFactor = math.pow(1 + (estimatedInflationRate / 100.0), years);
    return targetAmountToday * inflationFactor;
  }

  /// Calculates the suggested monthly SIP needed (assuming 12% equity mutual fund returns)
  double calculateSuggestedMonthlySip({
    double currentAccumulated = 0.0,
    double expectedReturnRate = 12.0,
  }) {
    final years = yearsRemaining;
    if (years <= 0) return 0.0;

    final futureTarget = estimatedFutureCost;
    final r = expectedReturnRate / 100.0;
    
    // Future value of already accumulated funds
    final accumulatedGrowth = currentAccumulated * math.pow(1 + r, years);
    final remainingGap = futureTarget - accumulatedGrowth;
    if (remainingGap <= 0) return 0.0;

    final monthlyRate = r / 12.0;
    final totalMonths = years * 12;

    // SIP annuity formula: Target = SIP * [((1 + i)^n - 1) / i] * (1 + i)
    final annuityFactor = ((math.pow(1 + monthlyRate, totalMonths) - 1) / monthlyRate) * (1 + monthlyRate);
    if (annuityFactor <= 0) return 0.0;

    return remainingGap / annuityFactor;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'userId': userId,
      'goalTitle': goalTitle,
      'targetAmountToday': targetAmountToday,
      'estimatedInflationRate': estimatedInflationRate,
      'targetYear': targetYear,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChildFutureGoalModel.fromJson(Map<String, dynamic> json) {
    return ChildFutureGoalModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? json['child_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      goalTitle: json['goalTitle'] ?? json['goal_title'] ?? '',
      targetAmountToday: (json['targetAmountToday'] is num)
          ? (json['targetAmountToday'] as num).toDouble()
          : ((json['target_amount_today'] is num) ? (json['target_amount_today'] as num).toDouble() : 0.0),
      estimatedInflationRate: (json['estimatedInflationRate'] is num)
          ? (json['estimatedInflationRate'] as num).toDouble()
          : ((json['estimated_inflation_rate'] is num) ? (json['estimated_inflation_rate'] as num).toDouble() : 8.0),
      targetYear: (json['targetYear'] is num)
          ? (json['targetYear'] as num).toInt()
          : ((json['target_year'] is num) ? (json['target_year'] as num).toInt() : (DateTime.now().year + 10)),
      notes: json['notes'],
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
      'goal_title': goalTitle,
      'target_amount_today': targetAmountToday,
      'estimated_inflation_rate': estimatedInflationRate,
      'target_year': targetYear,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChildFutureGoalModel.fromMap(Map<String, dynamic> map) {
    return ChildFutureGoalModel.fromJson(map);
  }

  ChildFutureGoalModel copyWith({
    String? id,
    String? childId,
    String? userId,
    String? goalTitle,
    double? targetAmountToday,
    double? estimatedInflationRate,
    int? targetYear,
    String? notes,
    DateTime? createdAt,
  }) {
    return ChildFutureGoalModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      userId: userId ?? this.userId,
      goalTitle: goalTitle ?? this.goalTitle,
      targetAmountToday: targetAmountToday ?? this.targetAmountToday,
      estimatedInflationRate: estimatedInflationRate ?? this.estimatedInflationRate,
      targetYear: targetYear ?? this.targetYear,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
