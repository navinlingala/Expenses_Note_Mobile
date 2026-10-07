import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Formats amount in Indian Standard format:
  /// Examples:
  ///  100000 -> ₹1,00,000
  ///  1500.50 -> ₹1,500.50
  ///  0 -> ₹0
  static String format(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount);
  }

  /// Compact Indian Format (for tight spaces, e.g. ₹1.5L / ₹2.5Cr)
  static String formatCompact(double amount, {String symbol = '₹'}) {
    final absAmount = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (absAmount >= 10000000) {
      return '$sign$symbol${(absAmount / 10000000).toStringAsFixed(2)} Cr';
    } else if (absAmount >= 100000) {
      return '$sign$symbol${(absAmount / 100000).toStringAsFixed(2)} L';
    } else {
      return format(amount, symbol: symbol);
    }
  }
}
