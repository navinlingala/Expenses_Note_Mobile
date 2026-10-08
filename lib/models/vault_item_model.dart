import 'package:flutter/material.dart';

enum VaultItemType {
  card,
  bankAccount,
  passwordPin,
  secretNote,
}

class VaultItemModel {
  final String id;
  final String userId;
  final String itemType; // CARD, BANK_ACCOUNT, PASSWORD_PIN, SECRET_NOTE
  final String title;
  final String? subtitle;
  final String? accountOrCardNumber;
  final String? holderName;
  final String? expiryDate;
  final String? cvv;
  final String? pin;
  final String? password;
  final String? ifscCode;
  final String? upiId;
  final String? urlOrApp;
  final String? secretContent;
  final String colorTheme; // OBSIDIAN, EMERALD, BLUE_PURPLE, CRIMSON, GOLD, OCEAN, AMETHYST
  final String category; // GENERAL, FINANCE, SOCIAL, WORK, PERSONAL, IDENTITY
  final bool isFavorite;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultItemModel({
    required this.id,
    required this.userId,
    this.itemType = 'CARD',
    required this.title,
    this.subtitle,
    this.accountOrCardNumber,
    this.holderName,
    this.expiryDate,
    this.cvv,
    this.pin,
    this.password,
    this.ifscCode,
    this.upiId,
    this.urlOrApp,
    this.secretContent,
    this.colorTheme = 'OBSIDIAN',
    this.category = 'GENERAL',
    this.isFavorite = false,
    this.notes,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  VaultItemType get typeEnum {
    switch (itemType.toUpperCase()) {
      case 'BANK_ACCOUNT':
        return VaultItemType.bankAccount;
      case 'PASSWORD_PIN':
        return VaultItemType.passwordPin;
      case 'SECRET_NOTE':
        return VaultItemType.secretNote;
      case 'CARD':
      default:
        return VaultItemType.card;
    }
  }

  String get maskedNumber {
    if (accountOrCardNumber == null || accountOrCardNumber!.isEmpty) return '';
    final clean = accountOrCardNumber!.replaceAll(RegExp(r'\s+'), '');
    if (clean.length <= 4) return '•••• $clean';
    final last4 = clean.substring(clean.length - 4);
    if (itemType == 'CARD') {
      final first4 = clean.length >= 8 ? clean.substring(0, 4) : '••••';
      return '$first4 •••• •••• $last4';
    }
    return '••••••••$last4';
  }

  String get formattedCardNumber {
    if (accountOrCardNumber == null || accountOrCardNumber!.isEmpty) return '';
    final clean = accountOrCardNumber!.replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  List<Color> get gradientColors {
    switch (colorTheme.toUpperCase()) {
      case 'EMERALD':
        return [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF10B981)];
      case 'BLUE_PURPLE':
        return [const Color(0xFF312E81), const Color(0xFF4338CA), const Color(0xFF7C3AED)];
      case 'CRIMSON':
        return [const Color(0xFF881337), const Color(0xFFBE123C), const Color(0xFFE11D48)];
      case 'GOLD':
        return [const Color(0xFF78350F), const Color(0xFFB45309), const Color(0xFFF59E0B)];
      case 'OCEAN':
        return [const Color(0xFF0C4A6E), const Color(0xFF0284C7), const Color(0xFF38BDF8)];
      case 'AMETHYST':
        return [const Color(0xFF4C1D95), const Color(0xFF6D28D9), const Color(0xFFA855F7)];
      case 'OBSIDIAN':
      default:
        return [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)];
    }
  }

  IconData get iconData {
    switch (typeEnum) {
      case VaultItemType.card:
        return Icons.credit_card_rounded;
      case VaultItemType.bankAccount:
        return Icons.account_balance_rounded;
      case VaultItemType.passwordPin:
        return Icons.vpn_key_rounded;
      case VaultItemType.secretNote:
        return Icons.security_rounded;
    }
  }

  /// SQLite compatible map with snake_case keys
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'item_type': itemType,
      'title': title,
      'subtitle': subtitle,
      'account_or_card_number': accountOrCardNumber,
      'holder_name': holderName,
      'expiry_date': expiryDate,
      'cvv': cvv,
      'pin': pin,
      'password': password,
      'ifsc_code': ifscCode,
      'upi_id': upiId,
      'url_or_app': urlOrApp,
      'secret_content': secretContent,
      'color_theme': colorTheme,
      'category': category,
      'is_favorite': isFavorite ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// REST API compatible JSON map with camelCase keys
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'itemType': itemType,
      'title': title,
      'subtitle': subtitle,
      'accountOrCardNumber': accountOrCardNumber,
      'holderName': holderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'pin': pin,
      'password': password,
      'ifscCode': ifscCode,
      'upiId': upiId,
      'urlOrApp': urlOrApp,
      'secretContent': secretContent,
      'colorTheme': colorTheme,
      'category': category,
      'isFavorite': isFavorite,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VaultItemModel.fromMap(Map<String, dynamic> map) {
    return VaultItemModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      itemType: map['item_type']?.toString() ?? map['itemType']?.toString() ?? 'CARD',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? map['bank_name']?.toString(),
      accountOrCardNumber: map['account_or_card_number']?.toString() ?? map['accountOrCardNumber']?.toString(),
      holderName: map['holder_name']?.toString() ?? map['holderName']?.toString(),
      expiryDate: map['expiry_date']?.toString() ?? map['expiryDate']?.toString(),
      cvv: map['cvv']?.toString(),
      pin: map['pin']?.toString(),
      password: map['password']?.toString(),
      ifscCode: map['ifsc_code']?.toString() ?? map['ifscCode']?.toString(),
      upiId: map['upi_id']?.toString() ?? map['upiId']?.toString(),
      urlOrApp: map['url_or_app']?.toString() ?? map['urlOrApp']?.toString(),
      secretContent: map['secret_content']?.toString() ?? map['secretContent']?.toString(),
      colorTheme: map['color_theme']?.toString() ?? map['colorTheme']?.toString() ?? 'OBSIDIAN',
      category: map['category']?.toString() ?? 'GENERAL',
      isFavorite: map['is_favorite'] == 1 || map['is_favorite'] == true || map['isFavorite'] == 1 || map['isFavorite'] == true,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now()),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : (map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }

  factory VaultItemModel.fromJson(Map<String, dynamic> json) => VaultItemModel.fromMap(json);

  VaultItemModel copyWith({
    String? id,
    String? userId,
    String? itemType,
    String? title,
    String? subtitle,
    String? accountOrCardNumber,
    String? holderName,
    String? expiryDate,
    String? cvv,
    String? pin,
    String? password,
    String? ifscCode,
    String? upiId,
    String? urlOrApp,
    String? secretContent,
    String? colorTheme,
    String? category,
    bool? isFavorite,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaultItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      accountOrCardNumber: accountOrCardNumber ?? this.accountOrCardNumber,
      holderName: holderName ?? this.holderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      pin: pin ?? this.pin,
      password: password ?? this.password,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      urlOrApp: urlOrApp ?? this.urlOrApp,
      secretContent: secretContent ?? this.secretContent,
      colorTheme: colorTheme ?? this.colorTheme,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
