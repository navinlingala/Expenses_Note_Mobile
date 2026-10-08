import 'package:flutter/material.dart';

/// Supported Gold Asset Types
enum GoldType {
  jewelry,
  coin,
  bar,
  sgb,
  digitalGold,
  etf;

  String get code {
    switch (this) {
      case GoldType.jewelry:
        return 'JEWELRY';
      case GoldType.coin:
        return 'COIN';
      case GoldType.bar:
        return 'BAR';
      case GoldType.sgb:
        return 'SGB';
      case GoldType.digitalGold:
        return 'DIGITAL_GOLD';
      case GoldType.etf:
        return 'ETF';
    }
  }

  static GoldType fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'JEWELRY':
        return GoldType.jewelry;
      case 'COIN':
        return GoldType.coin;
      case 'BAR':
        return GoldType.bar;
      case 'SGB':
        return GoldType.sgb;
      case 'DIGITAL_GOLD':
        return GoldType.digitalGold;
      case 'ETF':
        return GoldType.etf;
      default:
        return GoldType.jewelry;
    }
  }

  String get displayName {
    switch (this) {
      case GoldType.jewelry:
        return 'Jewelry / Ornaments';
      case GoldType.coin:
        return 'Gold Coin';
      case GoldType.bar:
        return 'Gold Bar / Biscuit';
      case GoldType.sgb:
        return 'Sovereign Gold Bond (SGB)';
      case GoldType.digitalGold:
        return 'Digital Gold';
      case GoldType.etf:
        return 'Gold ETF / Mutual Fund';
    }
  }

  IconData get icon {
    switch (this) {
      case GoldType.jewelry:
        return Icons.diamond_outlined;
      case GoldType.coin:
        return Icons.monetization_on_outlined;
      case GoldType.bar:
        return Icons.view_in_ar_rounded;
      case GoldType.sgb:
        return Icons.account_balance_outlined;
      case GoldType.digitalGold:
        return Icons.phonelink_ring_rounded;
      case GoldType.etf:
        return Icons.show_chart_rounded;
    }
  }
}

/// Supported Gold Purity Ratings
enum GoldPurity {
  k24,
  k22,
  k18,
  k14;

  String get code {
    switch (this) {
      case GoldPurity.k24:
        return '24K';
      case GoldPurity.k22:
        return '22K_916';
      case GoldPurity.k18:
        return '18K_750';
      case GoldPurity.k14:
        return '14K_585';
    }
  }

  static GoldPurity fromCode(String code) {
    switch (code.toUpperCase()) {
      case '24K':
        return GoldPurity.k24;
      case '22K_916':
      case '22K':
        return GoldPurity.k22;
      case '18K_750':
      case '18K':
        return GoldPurity.k18;
      case '14K_585':
      case '14K':
        return GoldPurity.k14;
      default:
        return GoldPurity.k22;
    }
  }

  String get displayName {
    switch (this) {
      case GoldPurity.k24:
        return '24K (99.9% Pure)';
      case GoldPurity.k22:
        return '22K (91.6% Hallmark)';
      case GoldPurity.k18:
        return '18K (75.0% Fine)';
      case GoldPurity.k14:
        return '14K (58.5% Alloy)';
    }
  }

  String get shortName {
    switch (this) {
      case GoldPurity.k24:
        return '24K';
      case GoldPurity.k22:
        return '22K';
      case GoldPurity.k18:
        return '18K';
      case GoldPurity.k14:
        return '14K';
    }
  }

  double get purityRatio {
    switch (this) {
      case GoldPurity.k24:
        return 1.0;
      case GoldPurity.k22:
        return 22.0 / 24.0; // 0.9166
      case GoldPurity.k18:
        return 18.0 / 24.0; // 0.7500
      case GoldPurity.k14:
        return 14.0 / 24.0; // 0.5833
    }
  }
}

class GoldAssetModel {
  final String id;
  final String userId;
  final String title;
  final String goldType; // JEWELRY, COIN, BAR, SGB, DIGITAL_GOLD, ETF
  final String purity; // 24K, 22K_916, 18K_750, 14K_585
  final double weightInGrams;
  final double purchasePricePerGram;
  final double makingCharges;
  final double totalInvestedAmount;
  final DateTime purchaseDate;
  final String? lockerLocation;
  final String? huidNumber;
  final String? jewelerName;
  final double sgbInterestRate; // Default 2.5% for SGB
  final DateTime? maturityDate;
  final String? notes;
  final String status; // ACTIVE, SOLD, GIFTED, MATURED
  final DateTime createdAt;

  GoldAssetModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.goldType,
    required this.purity,
    required this.weightInGrams,
    required this.purchasePricePerGram,
    this.makingCharges = 0.0,
    required this.totalInvestedAmount,
    required this.purchaseDate,
    this.lockerLocation,
    this.huidNumber,
    this.jewelerName,
    this.sgbInterestRate = 2.50,
    this.maturityDate,
    this.notes,
    this.status = 'ACTIVE',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper Enums
  GoldType get typeEnum => GoldType.fromCode(goldType);
  GoldPurity get purityEnum => GoldPurity.fromCode(purity);

  // Weight in standard Indian Tolas (1 Tola = 10 grams in modern Indian market)
  double get weightInTolas => weightInGrams / 10.0;

  // Real-time valuation calculator based on current market rate for 24K gold
  double calculateCurrentValue({
    required double current24KRatePerGram,
    double? custom22KRatePerGram,
    double? custom18KRatePerGram,
  }) {
    if (status == 'SOLD') return totalInvestedAmount;

    double effectiveRatePerGram;
    switch (purityEnum) {
      case GoldPurity.k24:
        effectiveRatePerGram = current24KRatePerGram;
        break;
      case GoldPurity.k22:
        effectiveRatePerGram = custom22KRatePerGram ?? (current24KRatePerGram * (22.0 / 24.0));
        break;
      case GoldPurity.k18:
        effectiveRatePerGram = custom18KRatePerGram ?? (current24KRatePerGram * (18.0 / 24.0));
        break;
      case GoldPurity.k14:
        effectiveRatePerGram = current24KRatePerGram * (14.0 / 24.0);
        break;
    }

    return weightInGrams * effectiveRatePerGram;
  }

  // Returns absolute gain in Currency
  double absoluteGain({required double current24KRatePerGram, double? custom22KRate, double? custom18KRate}) {
    final currentVal = calculateCurrentValue(
      current24KRatePerGram: current24KRatePerGram,
      custom22KRatePerGram: custom22KRate,
      custom18KRatePerGram: custom18KRate,
    );
    return currentVal - totalInvestedAmount;
  }

  // Returns gain percentage %
  double gainPercentage({required double current24KRatePerGram, double? custom22KRate, double? custom18KRate}) {
    if (totalInvestedAmount <= 0) return 0.0;
    final gain = absoluteGain(
      current24KRatePerGram: current24KRatePerGram,
      custom22KRate: custom22KRate,
      custom18KRate: custom18KRate,
    );
    return (gain / totalInvestedAmount) * 100;
  }

  // SGB annual and semi-annual interest (RBI pays every 6 months)
  double get sgbAnnualInterest => isSgb ? (totalInvestedAmount * (sgbInterestRate / 100)) : 0.0;
  double get sgbSemiAnnualInterest => sgbAnnualInterest / 2.0;

  bool get isSgb => typeEnum == GoldType.sgb;
  bool get isJewelry => typeEnum == GoldType.jewelry;

  // Days held
  int get holdingDays => DateTime.now().difference(purchaseDate).inDays;
  double get holdingYears => holdingDays > 0 ? holdingDays / 365.25 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'gold_type': goldType,
      'purity': purity,
      'weight_in_grams': weightInGrams,
      'purchase_price_per_gram': purchasePricePerGram,
      'making_charges': makingCharges,
      'total_invested_amount': totalInvestedAmount,
      'purchase_date': purchaseDate.toIso8601String(),
      'locker_location': lockerLocation,
      'huid_number': huidNumber,
      'jeweler_name': jewelerName,
      'sgb_interest_rate': sgbInterestRate,
      'maturity_date': maturityDate?.toIso8601String(),
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoldAssetModel.fromMap(Map<String, dynamic> map) {
    return GoldAssetModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Gold Asset',
      goldType: map['gold_type']?.toString() ?? 'JEWELRY',
      purity: map['purity']?.toString() ?? '22K_916',
      weightInGrams: (map['weight_in_grams'] as num?)?.toDouble() ?? 0.0,
      purchasePricePerGram: (map['purchase_price_per_gram'] as num?)?.toDouble() ?? 0.0,
      makingCharges: (map['making_charges'] as num?)?.toDouble() ?? 0.0,
      totalInvestedAmount: (map['total_invested_amount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: map['purchase_date'] != null
          ? DateTime.tryParse(map['purchase_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lockerLocation: map['locker_location']?.toString(),
      huidNumber: map['huid_number']?.toString(),
      jewelerName: map['jeweler_name']?.toString(),
      sgbInterestRate: (map['sgb_interest_rate'] as num?)?.toDouble() ?? 2.50,
      maturityDate: map['maturity_date'] != null ? DateTime.tryParse(map['maturity_date'].toString()) : null,
      notes: map['notes']?.toString(),
      status: map['status']?.toString() ?? 'ACTIVE',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory GoldAssetModel.fromJson(Map<String, dynamic> json) => GoldAssetModel.fromMap(json);

  GoldAssetModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? goldType,
    String? purity,
    double? weightInGrams,
    double? purchasePricePerGram,
    double? makingCharges,
    double? totalInvestedAmount,
    DateTime? purchaseDate,
    String? lockerLocation,
    String? huidNumber,
    String? jewelerName,
    double? sgbInterestRate,
    DateTime? maturityDate,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return GoldAssetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      goldType: goldType ?? this.goldType,
      purity: purity ?? this.purity,
      weightInGrams: weightInGrams ?? this.weightInGrams,
      purchasePricePerGram: purchasePricePerGram ?? this.purchasePricePerGram,
      makingCharges: makingCharges ?? this.makingCharges,
      totalInvestedAmount: totalInvestedAmount ?? this.totalInvestedAmount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lockerLocation: lockerLocation ?? this.lockerLocation,
      huidNumber: huidNumber ?? this.huidNumber,
      jewelerName: jewelerName ?? this.jewelerName,
      sgbInterestRate: sgbInterestRate ?? this.sgbInterestRate,
      maturityDate: maturityDate ?? this.maturityDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
