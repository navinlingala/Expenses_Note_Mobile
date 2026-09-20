import '../config/app_config.dart';
import '../../models/investment_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../models/loan_model.dart';
import '../../models/transaction_model.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  String get baseUrl => AppConfig.apiBaseUrl;

  // --- AUTHENTICATION ---
  Future<UserModel> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return UserModel(
        id: data['id'] as String,
        name: data['name'] as String,
        email: data['email'] as String,
        phone: data['phone'] as String?,
      );
    } else {
      throw Exception(data['message'] ?? 'Registration failed.');
    }
  }

  Future<UserModel> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'emailOrPhone': emailOrPhone,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel(
        id: data['id'] as String,
        name: data['name'] as String,
        email: data['email'] as String,
        phone: data['phone'] as String?,
      );
    } else {
      throw Exception(data['message'] ?? 'Invalid credentials.');
    }
  }

  // --- LOANS CRUD ---
  Future<List<LoanModel>> fetchLoans(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/loans?userId=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) {
          return LoanModel(
            id: item['id'],
            userId: item['userId'] ?? userId,
            title: item['title'],
            lenderName: item['lenderName'],
            totalPrincipal: (item['totalPrincipal'] as num).toDouble(),
            emiAmount: (item['emiAmount'] as num).toDouble(),
            interestRate: (item['interestRate'] as num?)?.toDouble() ?? 0.0,
            totalEmis: item['totalEmis'] as int,
            remainingEmis: item['remainingEmis'] as int,
            dueDay: item['dueDay'] as int,
            startDate: DateTime.parse(item['startDate'] as String),
            status: item['status'] ?? 'ACTIVE',
            notes: item['notes'],
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> syncLoan(LoanModel loan) async {
    try {
      final url = Uri.parse('$baseUrl/loans');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': loan.id,
          'userId': loan.userId,
          'title': loan.title,
          'lenderName': loan.lenderName,
          'totalPrincipal': loan.totalPrincipal,
          'emiAmount': loan.emiAmount,
          'interestRate': loan.interestRate,
          'totalEmis': loan.totalEmis,
          'remainingEmis': loan.remainingEmis,
          'dueDay': loan.dueDay,
          'startDate': loan.startDate.toIso8601String().split('T')[0],
          'status': loan.status,
          'notes': loan.notes,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> updateLoan(LoanModel loan) async {
    try {
      final url = Uri.parse('$baseUrl/loans/${loan.id}');
      await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': loan.id,
          'userId': loan.userId,
          'title': loan.title,
          'lenderName': loan.lenderName,
          'totalPrincipal': loan.totalPrincipal,
          'emiAmount': loan.emiAmount,
          'interestRate': loan.interestRate,
          'totalEmis': loan.totalEmis,
          'remainingEmis': loan.remainingEmis,
          'dueDay': loan.dueDay,
          'startDate': loan.startDate.toIso8601String().split('T')[0],
          'status': loan.status,
          'notes': loan.notes,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> payLoanEmi(String loanId) async {
    try {
      final url = Uri.parse('$baseUrl/loans/$loanId/pay-emi');
      await http.put(url).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> deleteLoan(String loanId) async {
    try {
      final url = Uri.parse('$baseUrl/loans/$loanId');
      await http.delete(url).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // --- TRANSACTIONS CRUD ---
  Future<List<TransactionModel>> fetchTransactions(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/transactions?userId=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) {
          return TransactionModel(
            id: item['id'],
            userId: item['userId'] ?? userId,
            title: item['title'],
            personName: item['personName'],
            phoneNumber: item['phoneNumber'],
            amount: (item['amount'] as num).toDouble(),
            type: item['type'],
            dueDate: DateTime.parse(item['dueDate'] as String),
            status: item['status'] ?? 'PENDING',
            isRecurring: item['isRecurring'] == true,
            recurrenceFrequency: item['recurrenceFrequency'] ?? 'NONE',
            category: item['category'],
            notes: item['notes'],
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> syncTransaction(TransactionModel tx) async {
    try {
      final url = Uri.parse('$baseUrl/transactions');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': tx.id,
          'userId': tx.userId,
          'title': tx.title,
          'personName': tx.personName,
          'phoneNumber': tx.phoneNumber,
          'amount': tx.amount,
          'type': tx.type,
          'dueDate': tx.dueDate.toUtc().toIso8601String(),
          'status': tx.status,
          'isRecurring': tx.isRecurring,
          'recurrenceFrequency': tx.recurrenceFrequency,
          'category': tx.category,
          'notes': tx.notes,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    try {
      final url = Uri.parse('$baseUrl/transactions/${tx.id}');
      await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': tx.id,
          'userId': tx.userId,
          'title': tx.title,
          'personName': tx.personName,
          'phoneNumber': tx.phoneNumber,
          'amount': tx.amount,
          'type': tx.type,
          'dueDate': tx.dueDate.toUtc().toIso8601String(),
          'status': tx.status,
          'isRecurring': tx.isRecurring,
          'recurrenceFrequency': tx.recurrenceFrequency,
          'category': tx.category,
          'notes': tx.notes,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> updateTransactionStatus(String id, String status) async {
    try {
      final url = Uri.parse('$baseUrl/transactions/$id/status');
      await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final url = Uri.parse('$baseUrl/transactions/$id');
      await http.delete(url).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ===================== INVESTMENTS =====================

  Future<List<InvestmentModel>> fetchInvestments(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/investments?userId=$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) {
          return InvestmentModel(
            id: item['id'],
            userId: item['userId'] ?? userId,
            title: item['title'],
            category: item['category'] ?? 'OTHER',
            investmentType: item['investmentType'] ?? 'LUMPSUM',
            investedAmount: (item['investedAmount'] as num).toDouble(),
            currentValue: (item['currentValue'] as num).toDouble(),
            expectedReturnRate: (item['expectedReturnRate'] as num?)?.toDouble() ?? 0.0,
            sipAmount: (item['sipAmount'] as num?)?.toDouble(),
            startDate: DateTime.parse(item['startDate']),
            maturityDate: item['maturityDate'] != null ? DateTime.parse(item['maturityDate']) : null,
            riskLevel: item['riskLevel'] ?? 'MODERATE',
            notes: item['notes'],
            status: item['status'] ?? 'ACTIVE',
            createdAt: item['createdAt'] != null ? DateTime.parse(item['createdAt']) : DateTime.now(),
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveInvestment(InvestmentModel inv) async {
    try {
      final url = Uri.parse('$baseUrl/investments');
      final payload = {
        'id': inv.id,
        'userId': inv.userId,
        'title': inv.title,
        'category': inv.category,
        'investmentType': inv.investmentType,
        'investedAmount': inv.investedAmount,
        'currentValue': inv.currentValue,
        'expectedReturnRate': inv.expectedReturnRate,
        'sipAmount': inv.sipAmount,
        'startDate': inv.startDate.toIso8601String().split('T')[0],
        'maturityDate': inv.maturityDate?.toIso8601String().split('T')[0],
        'riskLevel': inv.riskLevel,
        'notes': inv.notes,
        'status': inv.status,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateInvestment(InvestmentModel inv) async {
    try {
      final url = Uri.parse('$baseUrl/investments/${inv.id}');
      final payload = {
        'id': inv.id,
        'userId': inv.userId,
        'title': inv.title,
        'category': inv.category,
        'investmentType': inv.investmentType,
        'investedAmount': inv.investedAmount,
        'currentValue': inv.currentValue,
        'expectedReturnRate': inv.expectedReturnRate,
        'sipAmount': inv.sipAmount,
        'startDate': inv.startDate.toIso8601String().split('T')[0],
        'maturityDate': inv.maturityDate?.toIso8601String().split('T')[0],
        'riskLevel': inv.riskLevel,
        'notes': inv.notes,
        'status': inv.status,
      };

      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteInvestment(String id) async {
    try {
      final url = Uri.parse('$baseUrl/investments/$id');
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
