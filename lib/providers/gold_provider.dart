import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../core/services/api_service.dart';
import '../models/gold_asset_model.dart';

class GoldProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ApiService _api = ApiService.instance;

  List<GoldAssetModel> _assets = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'ALL';

  // Live Market Gold Price configuration (INR per gram)
  double _goldRate24K = 7650.0; // 24K per gram
  double _goldRate22K = 7012.5; // 22K per gram (91.6%)
  double _goldRate18K = 5737.5; // 18K per gram (75.0%)

  // Getters
  List<GoldAssetModel> get assets => _assets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  double get goldRate24K => _goldRate24K;
  double get goldRate22K => _goldRate22K;
  double get goldRate18K => _goldRate18K;

  // Filtered asset list
  List<GoldAssetModel> get filteredAssets {
    if (_selectedFilter == 'ALL') return _assets;
    if (_selectedFilter == 'JEWELRY') {
      return _assets.where((a) => a.typeEnum == GoldType.jewelry).toList();
    }
    if (_selectedFilter == 'COINS_BARS') {
      return _assets.where((a) => a.typeEnum == GoldType.coin || a.typeEnum == GoldType.bar).toList();
    }
    if (_selectedFilter == 'SGB') {
      return _assets.where((a) => a.typeEnum == GoldType.sgb).toList();
    }
    if (_selectedFilter == 'DIGITAL_ETF') {
      return _assets.where((a) => a.typeEnum == GoldType.digitalGold || a.typeEnum == GoldType.etf).toList();
    }
    return _assets;
  }

  // Portfolio Totals & Analytics
  double get totalGoldWeightGrams {
    return _assets.fold(0.0, (sum, item) => sum + item.weightInGrams);
  }

  double get totalGoldWeightTolas => totalGoldWeightGrams / 10.0;

  double get totalInvestedAmount {
    return _assets.fold(0.0, (sum, item) => sum + item.totalInvestedAmount);
  }

  double get totalCurrentMarketValue {
    return _assets.fold(
      0.0,
      (sum, item) =>
          sum +
          item.calculateCurrentValue(
            current24KRatePerGram: _goldRate24K,
            custom22KRatePerGram: _goldRate22K,
            custom18KRatePerGram: _goldRate18K,
          ),
    );
  }

  double get totalAbsoluteGain => totalCurrentMarketValue - totalInvestedAmount;

  double get totalGainPercentage {
    if (totalInvestedAmount <= 0) return 0.0;
    return (totalAbsoluteGain / totalInvestedAmount) * 100;
  }

  double get totalSgbAnnualInterest {
    return _assets
        .where((a) => a.isSgb)
        .fold(0.0, (sum, item) => sum + item.sgbAnnualInterest);
  }

  int get sgbHoldingCount => _assets.where((a) => a.isSgb).length;
  int get jewelryCount => _assets.where((a) => a.isJewelry).length;
  int get coinAndBarCount =>
      _assets.where((a) => a.typeEnum == GoldType.coin || a.typeEnum == GoldType.bar).length;

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void updateGoldRates({required double rate24K, double? rate22K, double? rate18K}) {
    _goldRate24K = rate24K;
    _goldRate22K = rate22K ?? (rate24K * (22.0 / 24.0));
    _goldRate18K = rate18K ?? (rate24K * (18.0 / 24.0));
    notifyListeners();
  }

  Future<void> loadGoldAssets(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load from local database first for instant offline responsiveness
      final local = await _db.getGoldAssets(userId);
      _assets = local;
      _isLoading = false;
      notifyListeners();

      // 2. Fetch from backend API and synchronize
      final remoteMaps = await _api.fetchGoldAssets(userId);
      if (remoteMaps.isNotEmpty) {
        final remoteAssets = remoteMaps.map((m) {
          final mapConverted = {
            'id': m['id'],
            'user_id': m['userId'] ?? userId,
            'title': m['title'],
            'gold_type': m['goldType'],
            'purity': m['purity'],
            'weight_in_grams': m['weightInGrams'],
            'purchase_price_per_gram': m['purchasePricePerGram'],
            'making_charges': m['makingCharges'],
            'total_invested_amount': m['totalInvestedAmount'],
            'purchase_date': m['purchaseDate'],
            'locker_location': m['lockerLocation'],
            'huid_number': m['huidNumber'],
            'jeweler_name': m['jewelerName'],
            'sgb_interest_rate': m['sgbInterestRate'],
            'maturity_date': m['maturityDate'],
            'notes': m['notes'],
            'status': m['status'],
            'created_at': m['createdAt'],
          };
          return GoldAssetModel.fromMap(mapConverted);
        }).toList();

        await _db.syncReplaceGoldAssets(userId, remoteAssets);
        _assets = remoteAssets;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGoldAsset(GoldAssetModel asset) async {
    try {
      final newAsset = asset.id.isEmpty
          ? asset.copyWith(id: const Uuid().v4())
          : asset;

      // 1. Insert into local SQLite
      await _db.insertGoldAsset(newAsset);
      _assets.insert(0, newAsset);
      notifyListeners();

      // 2. Sync to Backend
      final payload = {
        'id': newAsset.id,
        'userId': newAsset.userId,
        'title': newAsset.title,
        'goldType': newAsset.goldType,
        'purity': newAsset.purity,
        'weightInGrams': newAsset.weightInGrams,
        'purchasePricePerGram': newAsset.purchasePricePerGram,
        'makingCharges': newAsset.makingCharges,
        'totalInvestedAmount': newAsset.totalInvestedAmount,
        'purchaseDate': newAsset.purchaseDate.toIso8601String().split('T')[0],
        'lockerLocation': newAsset.lockerLocation,
        'huidNumber': newAsset.huidNumber,
        'jewelerName': newAsset.jewelerName,
        'sgbInterestRate': newAsset.sgbInterestRate,
        'maturityDate': newAsset.maturityDate?.toIso8601String().split('T')[0],
        'notes': newAsset.notes,
        'status': newAsset.status,
      };
      await _api.saveGoldAsset(payload);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateGoldAsset(GoldAssetModel asset) async {
    try {
      await _db.updateGoldAsset(asset);
      final index = _assets.indexWhere((a) => a.id == asset.id);
      if (index != -1) {
        _assets[index] = asset;
        notifyListeners();
      }

      final payload = {
        'id': asset.id,
        'userId': asset.userId,
        'title': asset.title,
        'goldType': asset.goldType,
        'purity': asset.purity,
        'weightInGrams': asset.weightInGrams,
        'purchasePricePerGram': asset.purchasePricePerGram,
        'makingCharges': asset.makingCharges,
        'totalInvestedAmount': asset.totalInvestedAmount,
        'purchaseDate': asset.purchaseDate.toIso8601String().split('T')[0],
        'lockerLocation': asset.lockerLocation,
        'huidNumber': asset.huidNumber,
        'jewelerName': asset.jewelerName,
        'sgbInterestRate': asset.sgbInterestRate,
        'maturityDate': asset.maturityDate?.toIso8601String().split('T')[0],
        'notes': asset.notes,
        'status': asset.status,
      };
      await _api.updateGoldAsset(asset.id, payload);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGoldAsset(String id) async {
    try {
      await _db.deleteGoldAsset(id);
      _assets.removeWhere((a) => a.id == id);
      notifyListeners();

      await _api.deleteGoldAsset(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
