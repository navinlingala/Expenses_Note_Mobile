import 'package:intl/intl.dart';

class AppDateUtils {
  /// Bank Statement Standard: 21-Sep-2026
  static String formatShort(DateTime date) {
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  /// Short Day-Month: 21-Sep
  static String formatDayMonth(DateTime date) {
    return DateFormat('dd-MMM').format(date);
  }

  /// Month-Year: September 2026
  static String formatMonthYear(int year, int month) {
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Full Date: 21-Sep-2026
  static String formatFull(DateTime date) {
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  /// Relative Due Date Indicator
  static String getRelativeDueDate(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) return 'Due Today';
    if (difference == 1) return 'Due Tomorrow';
    if (difference > 1 && difference <= 7) return 'Due in $difference days';
    if (difference < 0) return '${difference.abs()} days overdue';
    return DateFormat('dd-MMM-yyyy').format(date);
  }
}
