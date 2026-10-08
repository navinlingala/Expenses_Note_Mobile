import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card_model.dart';
import '../models/credit_card_transaction_model.dart';
import '../core/database/database_helper.dart';
import '../core/services/api_service.dart';

class CreditCardProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService.instance;
  final Uuid _uuid = const Uuid();

  List<CreditCardModel> _cards = [];
  List<CreditCardTransactionModel> _transactions = [];
  String? _selectedCardId;
  bool _isLoading = false;

  List<CreditCardModel> get cards => _cards;
  List<CreditCardTransactionModel> get transactions => _transactions;
  String? get selectedCardId => _selectedCardId;
  bool get isLoading => _isLoading;

  CreditCardModel? get selectedCard {
    if (_cards.isEmpty) return null;
    if (_selectedCardId == null) return _cards.first;
    return _cards.firstWhere((c) => c.id == _selectedCardId, orElse: () => _cards.first);
  }

  List<CreditCardTransactionModel> get selectedCardTransactions {
    if (_selectedCardId == null) return _transactions;
    return _transactions.where((tx) => tx.cardId == _selectedCardId).toList();
  }

  double get totalCreditLimit {
    return _cards
        .where((c) => c.status == 'ACTIVE')
        .fold(0.0, (sum, c) => sum + c.totalLimit);
  }

  double get totalCurrentOutstanding {
    return _cards
        .where((c) => c.status == 'ACTIVE')
        .fold(0.0, (sum, c) => sum + c.currentOutstanding);
  }

  double get totalAvailableLimit {
    return _cards
        .where((c) => c.status == 'ACTIVE')
        .fold(0.0, (sum, c) => sum + c.availableLimit);
  }

  double get overallUtilizationPercentage {
    if (totalCreditLimit <= 0) return 0.0;
    return ((totalCurrentOutstanding / totalCreditLimit) * 100).clamp(0.0, 100.0);
  }

  String get overallUtilizationHealth {
    final pct = overallUtilizationPercentage;
    if (pct <= 30.0) return 'HEALTHY';
    if (pct <= 70.0) return 'MODERATE';
    return 'HIGH';
  }

  List<CreditCardModel> get upcomingStatements {
    final active = _cards.where((c) => c.status == 'ACTIVE').toList();
    active.sort((a, b) => a.daysUntilStatement.compareTo(b.daysUntilStatement));
    return active;
  }

  List<CreditCardModel> get upcomingDueBills {
    final active = _cards.where((c) => c.status == 'ACTIVE' && c.currentOutstanding > 0).toList();
    active.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    return active;
  }

  /// Best Card to Spend Today:
  /// The card where statement day is furthest away from today gives maximum interest-free days!
  CreditCardModel? get bestCardToSpendToday {
    final active = _cards.where((c) => c.status == 'ACTIVE' && c.availableLimit > 100).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => b.daysUntilStatement.compareTo(a.daysUntilStatement));
    return active.first;
  }

  void selectCard(String? cardId) {
    _selectedCardId = cardId;
    notifyListeners();
  }

  Future<void> loadData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Local SQLite fetch
      _cards = await _dbHelper.getCreditCards(userId);
      _transactions = await _dbHelper.getCreditCardTransactions(userId);
      if (_cards.isNotEmpty && (_selectedCardId == null || !_cards.any((c) => c.id == _selectedCardId))) {
        _selectedCardId = _cards.first.id;
      }
      notifyListeners();

      // 2. Remote API sync
      _syncFromRemote(userId);
    } catch (e) {
      debugPrint('Error loading credit card data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncFromRemote(String userId) async {
    try {
      final remoteCardsData = await _apiService.fetchCreditCards(userId);
      if (remoteCardsData.isNotEmpty) {
        final remoteCards = remoteCardsData.map((e) => CreditCardModel.fromMap(e)).toList();
        await _dbHelper.syncReplaceCreditCards(userId, remoteCards);
        _cards = remoteCards;
      }

      final remoteTxData = await _apiService.fetchCreditCardTransactions(userId);
      if (remoteTxData.isNotEmpty) {
        final remoteTxs = remoteTxData.map((e) => CreditCardTransactionModel.fromMap(e)).toList();
        await _dbHelper.syncReplaceCreditCardTransactions(userId, remoteTxs);
        _transactions = remoteTxs;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Remote sync error for credit cards: $e');
    }
  }

  Future<bool> addCreditCard(CreditCardModel card) async {
    try {
      final cardWithId = card.id.isEmpty
          ? card.copyWith(id: _uuid.v4())
          : card;

      await _dbHelper.insertCreditCard(cardWithId);
      _cards.insert(0, cardWithId);
      if (_selectedCardId == null) {
        _selectedCardId = cardWithId.id;
      }
      notifyListeners();

      _apiService.saveCreditCard(cardWithId.toMap());
      return true;
    } catch (e) {
      debugPrint('Error adding credit card: $e');
      return false;
    }
  }

  Future<bool> updateCreditCard(CreditCardModel card) async {
    try {
      await _dbHelper.updateCreditCard(card);
      final idx = _cards.indexWhere((c) => c.id == card.id);
      if (idx != -1) {
        _cards[idx] = card;
      }
      notifyListeners();

      _apiService.updateCreditCard(card.id, card.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating credit card: $e');
      return false;
    }
  }

  Future<bool> deleteCreditCard(String id, String userId) async {
    try {
      await _dbHelper.deleteCreditCard(id);
      _cards.removeWhere((c) => c.id == id);
      _transactions.removeWhere((t) => t.cardId == id);
      if (_selectedCardId == id) {
        _selectedCardId = _cards.isNotEmpty ? _cards.first.id : null;
      }
      notifyListeners();

      _apiService.deleteCreditCard(id);
      return true;
    } catch (e) {
      debugPrint('Error deleting credit card: $e');
      return false;
    }
  }

  Future<bool> addTransaction(CreditCardTransactionModel tx) async {
    try {
      final txWithId = tx.id.isEmpty
          ? CreditCardTransactionModel(
              id: _uuid.v4(),
              userId: tx.userId,
              cardId: tx.cardId,
              amount: tx.amount,
              merchantName: tx.merchantName,
              category: tx.category,
              transactionDate: tx.transactionDate,
              transactionType: tx.transactionType,
              isEmi: tx.isEmi,
              emiMonths: tx.emiMonths,
              monthlyEmiAmount: tx.monthlyEmiAmount,
              isBilled: tx.isBilled,
              notes: tx.notes,
              createdAt: tx.createdAt,
            )
          : tx;

      await _dbHelper.insertCreditCardTransaction(txWithId);
      _transactions.insert(0, txWithId);

      // Re-fetch the updated card state from db
      final updatedCard = await _dbHelper.getCreditCardById(txWithId.cardId);
      if (updatedCard != null) {
        final idx = _cards.indexWhere((c) => c.id == updatedCard.id);
        if (idx != -1) {
          _cards[idx] = updatedCard;
        }
      }

      notifyListeners();
      _apiService.saveCreditCardTransaction(txWithId.toMap());
      return true;
    } catch (e) {
      debugPrint('Error adding card transaction: $e');
      return false;
    }
  }

  Future<bool> recordBillPayment({
    required String cardId,
    required String userId,
    required double amount,
    String? notes,
    DateTime? paymentDate,
  }) async {
    try {
      final paymentTx = CreditCardTransactionModel(
        id: _uuid.v4(),
        userId: userId,
        cardId: cardId,
        amount: amount,
        merchantName: 'Card Bill Payment / Clearance',
        category: 'BILLS',
        transactionDate: paymentDate ?? DateTime.now(),
        transactionType: 'PAYMENT',
        isBilled: true,
        notes: notes ?? 'Cleared credit card balance',
        createdAt: DateTime.now(),
      );

      return await addTransaction(paymentTx);
    } catch (e) {
      debugPrint('Error recording bill payment: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id, String userId, {String? cardId}) async {
    try {
      await _dbHelper.deleteCreditCardTransaction(id);
      _transactions.removeWhere((t) => t.id == id);

      if (cardId != null) {
        final updatedCard = await _dbHelper.getCreditCardById(cardId);
        if (updatedCard != null) {
          final idx = _cards.indexWhere((c) => c.id == updatedCard.id);
          if (idx != -1) {
            _cards[idx] = updatedCard;
          }
        }
      }

      notifyListeners();
      _apiService.deleteCreditCardTransaction(id);
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }
}
