import '../config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static final WhatsAppService instance = WhatsAppService._init();
  WhatsAppService._init();

  static const String defaultAppWhatsAppNumber = '919010067464';
  static const String appFormattedNumber = '+91 9010067464';
  static String get backendApiUrl => AppConfig.whatsAppApiUrl;

  /// Sanitizes phone number: strips non-digits, converts 10-digit Indian numbers to 91XXXXXXXXXX
  String? sanitizePhoneNumber(String raw) {
    if (raw.trim().isEmpty) return null;
    String clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) {
      clean = '91$clean';
    } else if (clean.startsWith('0') && clean.length == 11) {
      clean = '91${clean.substring(1)}';
    }
    return (clean.length >= 10 && clean.length <= 15) ? clean : null;
  }

  /// 1. Professional Borrower Due Reminder (Who Owes Me / Receivable)
  String generateReminderMessage({
    required String personName,
    required double amount,
    required DateTime dueDate,
    String? title,
    String? customNote,
  }) {
    return generateBorrowerDueReminder(
      personName: personName,
      amount: amount,
      dueDate: dueDate,
      title: title,
      customNote: customNote,
    );
  }

  /// Professional notice sent to borrower/friend
  String generateBorrowerDueReminder({
    required String personName,
    required double amount,
    required DateTime dueDate,
    String? title,
    String? customNote,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formattedAmount = currencyFormat.format(amount);
    final formattedDate = DateFormat('dd MMMM yyyy').format(dueDate);
    final name = personName.trim().isEmpty ? 'Valued Contact' : personName.trim();

    final buffer = StringBuffer();
    buffer.writeln('*MONEY REMINDER* | *PAYMENT NOTICE*');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Dear *$name*,\n');
    buffer.writeln('This is a gentle payment reminder regarding the pending amount:');
    buffer.writeln('• *Amount Due*: *$formattedAmount*');
    buffer.writeln('• *Due Date*: $formattedDate');
    if (title != null && title.trim().isNotEmpty) {
      buffer.writeln('• *Reference*: ${title.trim()}');
    }
    if (customNote != null && customNote.trim().isNotEmpty) {
      buffer.writeln('• *Note*: ${customNote.trim()}');
    }
    buffer.writeln('• *Status*: Pending Clearance\n');
    buffer.writeln('Kindly arrange to clear the payment via UPI / GPay / PhonePe / Bank Transfer at your earliest convenience.\n');
    buffer.writeln('If you have already completed this payment, please disregard this notice.');
    buffer.writeln('----------------------------------------');
    buffer.writeln('*Money Reminder Automated Alert*');
    buffer.writeln('Verified Sender: $appFormattedNumber');

    return buffer.toString();
  }

  /// 2. Self Payment Reminder (Whom I Owe / Payable)
  String generateSelfPayableReminder({
    required String payeeName,
    required double amount,
    required DateTime dueDate,
    String? title,
    String? customNote,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formattedAmount = currencyFormat.format(amount);
    final formattedDate = DateFormat('dd MMMM yyyy').format(dueDate);
    final name = payeeName.trim().isEmpty ? 'Payee' : payeeName.trim();

    final buffer = StringBuffer();
    buffer.writeln('*MONEY REMINDER* | *UPCOMING PAYMENT ALERT*');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Hello,\n');
    buffer.writeln('This is a scheduled reminder for an upcoming payment you need to make:');
    buffer.writeln('• *Payable To*: *$name*');
    buffer.writeln('• *Amount to Pay*: *$formattedAmount*');
    buffer.writeln('• *Due Date*: $formattedDate');
    if (title != null && title.trim().isNotEmpty) {
      buffer.writeln('• *Purpose*: ${title.trim()}');
    }
    if (customNote != null && customNote.trim().isNotEmpty) {
      buffer.writeln('• *Notes*: ${customNote.trim()}');
    }
    buffer.writeln('• *Status*: Due for Settlement\n');
    buffer.writeln('Please ensure sufficient balance is available to settle this payment on time.');
    buffer.writeln('----------------------------------------');
    buffer.writeln('*Money Reminder Self-Alert*');
    buffer.writeln('Helpline: $appFormattedNumber');

    return buffer.toString();
  }

  /// 3. Loan & EMI Alert
  String generateLoanEmiReminder({
    required String loanTitle,
    required String lenderName,
    required double emiAmount,
    required int dueDay,
    required int paidEmis,
    required int totalEmis,
    required double remainingBalance,
    DateTime? nextDueDate,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formattedEmi = currencyFormat.format(emiAmount);
    final formattedBal = currencyFormat.format(remainingBalance);
    final progress = totalEmis > 0 ? (paidEmis / totalEmis * 100).toStringAsFixed(0) : '0';

    final buffer = StringBuffer();
    buffer.writeln('*MONEY REMINDER* | *MONTHLY EMI ALERT*');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Hello,\n');
    buffer.writeln('This is an upcoming EMI reminder for your active loan:');
    buffer.writeln('• *Loan*: *$loanTitle*');
    buffer.writeln('• *Lender / Bank*: $lenderName');
    buffer.writeln('• *Monthly EMI*: *$formattedEmi*');
    buffer.writeln('• *Due Day*: ${dueDay}th of the month');
    buffer.writeln('• *Tenure Status*: $paidEmis of $totalEmis EMIs Cleared ($progress%)');
    buffer.writeln('• *Remaining Loan Balance*: $formattedBal\n');
    buffer.writeln('Please ensure sufficient balance in your linked bank account for timely auto-debit.');
    buffer.writeln('----------------------------------------');
    buffer.writeln('*Money Reminder Automated Alert*');
    buffer.writeln('Helpline: $appFormattedNumber');

    return buffer.toString();
  }

  /// 4. Cashflow / Credit & Debit Transaction Alert
  String generateTransactionAlert({
    required String type,
    required double amount,
    required String title,
    required DateTime date,
    String? category,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formattedAmount = currencyFormat.format(amount);
    final formattedDate = DateFormat('dd MMMM yyyy').format(date);
    final isCredit = type.toUpperCase() == 'CREDIT';

    final buffer = StringBuffer();
    buffer.writeln('*MONEY REMINDER* | *CASHFLOW ALERT*');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Transaction Recorded in App:\n');
    buffer.writeln('• *Type*: ${isCredit ? "CREDIT (+)" : "DEBIT (-)"}');
    buffer.writeln('• *Amount*: *$formattedAmount*');
    buffer.writeln('• *Title*: $title');
    if (category != null && category.trim().isNotEmpty) {
      buffer.writeln('• *Category*: $category');
    }
    buffer.writeln('• *Date*: $formattedDate\n');
    buffer.writeln('Track your daily expenses, monthly surplus, and analytics in Money Reminder.');
    buffer.writeln('----------------------------------------');
    buffer.writeln('*Money Reminder App*');
    buffer.writeln('Verified Number: $appFormattedNumber');

    return buffer.toString();
  }

  /// Sends reminder to recipient phone number
  Future<bool> sendReminder({
    required String phoneNumber,
    required String message,
    String? personName,
    double? amount,
    DateTime? dueDate,
  }) async {
    final sanitizedNumber = sanitizePhoneNumber(phoneNumber);
    if (sanitizedNumber == null) return false;

    // Try backend automated dispatch in background
    try {
      final response = await http.post(
        Uri.parse('$backendApiUrl/send'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'recipientPhone': sanitizedNumber,
          'personName': personName ?? 'Contact',
          'amount': amount ?? 0.0,
          'dueDate': dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate) : null,
          'note': message,
        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        // Backend processed
      }
    } catch (_) {}

    // Direct WhatsApp dispatch with proper UTF-8 URI encoding
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$sanitizedNumber?text=$encodedMessage');

    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Sends reminder directly to the user's registered WhatsApp number
  Future<bool> sendToUserWhatsApp({
    required String message,
    String userPhone = defaultAppWhatsAppNumber,
  }) async {
    return await sendReminder(
      phoneNumber: userPhone,
      message: message,
    );
  }
}
