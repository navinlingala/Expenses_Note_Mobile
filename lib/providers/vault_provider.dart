import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/config/app_config.dart';
import '../core/database/database_helper.dart';
import '../models/vault_item_model.dart';

class VaultProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<VaultItemModel> _vaultItems = [];
  bool _isLoading = false;
  bool _isVaultUnlocked = false;
  bool _isPinSet = false;
  String? _masterPin;
  String _selectedTypeFilter = 'ALL';
  String _searchQuery = '';

  List<VaultItemModel> get vaultItems => _vaultItems;
  bool get isLoading => _isLoading;
  bool get isVaultUnlocked => _isVaultUnlocked;
  bool get isPinSet => _isPinSet;
  String get selectedTypeFilter => _selectedTypeFilter;
  String get searchQuery => _searchQuery;

  List<VaultItemModel> get filteredVaultItems {
    return _vaultItems.where((item) {
      if (_selectedTypeFilter != 'ALL' && item.itemType.toUpperCase() != _selectedTypeFilter.toUpperCase()) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(q);
        final matchesSubtitle = (item.subtitle ?? '').toLowerCase().contains(q);
        final matchesCategory = item.category.toLowerCase().contains(q);
        final matchesHolder = (item.holderName ?? '').toLowerCase().contains(q);
        final matchesNotes = (item.notes ?? '').toLowerCase().contains(q);
        final matchesNumber = (item.accountOrCardNumber ?? '').contains(q);
        if (!matchesTitle && !matchesSubtitle && !matchesCategory && !matchesHolder && !matchesNotes && !matchesNumber) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get totalSecretsCount => _vaultItems.length;
  int get cardsCount => _vaultItems.where((i) => i.itemType == 'CARD').length;
  int get bankAccountsCount => _vaultItems.where((i) => i.itemType == 'BANK_ACCOUNT').length;
  int get passwordsCount => _vaultItems.where((i) => i.itemType == 'PASSWORD_PIN').length;
  int get secretNotesCount => _vaultItems.where((i) => i.itemType == 'SECRET_NOTE').length;

  Future<void> checkSecurityStatus() async {
    try {
      final db = await _dbHelper.database;
      final res = await db.query('app_settings', where: 'key = ?', whereArgs: ['vault_master_pin'], limit: 1);
      if (res.isNotEmpty && res.first['value'] != null && res.first['value'].toString().isNotEmpty) {
        _masterPin = res.first['value'].toString();
        _isPinSet = true;
      } else {
        _masterPin = null;
        _isPinSet = false;
        // If no PIN is configured yet, default to unlocked or allow initial setup
        _isVaultUnlocked = true;
      }
    } catch (_) {
      _isPinSet = false;
      _isVaultUnlocked = true;
    }
    notifyListeners();
  }

  bool verifyPin(String enteredPin) {
    if (!_isPinSet || _masterPin == null || _masterPin!.isEmpty) {
      _isVaultUnlocked = true;
      notifyListeners();
      return true;
    }
    if (enteredPin == _masterPin) {
      _isVaultUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockVault() {
    if (_isPinSet) {
      _isVaultUnlocked = false;
      notifyListeners();
    }
  }

  void unlockDirectly() {
    _isVaultUnlocked = true;
    notifyListeners();
  }

  Future<void> setMasterPin(String newPin) async {
    final db = await _dbHelper.database;
    await db.insert(
      'app_settings',
      {'key': 'vault_master_pin', 'value': newPin},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _masterPin = newPin;
    _isPinSet = true;
    _isVaultUnlocked = true;
    notifyListeners();
  }

  Future<void> removeMasterPin() async {
    final db = await _dbHelper.database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: ['vault_master_pin']);
    _masterPin = null;
    _isPinSet = false;
    _isVaultUnlocked = true;
    notifyListeners();
  }

  void setTypeFilter(String filter) {
    _selectedTypeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadVaultItems(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await checkSecurityStatus();
      // 1. Load from local SQLite
      _vaultItems = await _dbHelper.getVaultItems(userId);
      notifyListeners();

      // 2. Sync from backend API
      try {
        final url = Uri.parse('${AppConfig.backendBaseUrl}/api/vault?userId=$userId');
        final res = await http.get(url).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final List data = jsonDecode(res.body);
          final remoteItems = data.map((e) => VaultItemModel.fromMap(e)).toList();
          if (remoteItems.isNotEmpty || _vaultItems.isEmpty) {
            _vaultItems = remoteItems;
            await _dbHelper.syncReplaceVaultItems(userId, remoteItems);
          }
        }
      } catch (e) {
        debugPrint('Backend vault sync failed, using offline SQLite: $e');
      }
    } catch (e) {
      debugPrint('Error loading vault items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVaultItem(VaultItemModel item) async {
    try {
      final itemId = item.id.isEmpty ? const Uuid().v4() : item.id;
      final newItem = item.copyWith(id: itemId);

      // 1. Save to SQLite
      await _dbHelper.insertVaultItem(newItem);
      _vaultItems.insert(0, newItem);
      notifyListeners();

      // 2. Sync to Backend
      try {
        final url = Uri.parse('${AppConfig.backendBaseUrl}/api/vault');
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(newItem.toJson()),
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Backend vault item add failed, saved locally: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error adding vault item: $e');
      return false;
    }
  }

  Future<bool> updateVaultItem(VaultItemModel item) async {
    try {
      final updatedItem = item.copyWith(updatedAt: DateTime.now());

      // 1. Update SQLite
      await _dbHelper.updateVaultItem(updatedItem);
      final index = _vaultItems.indexWhere((i) => i.id == updatedItem.id);
      if (index != -1) {
        _vaultItems[index] = updatedItem;
      }
      notifyListeners();

      // 2. Sync to Backend
      try {
        final url = Uri.parse('${AppConfig.backendBaseUrl}/api/vault/${updatedItem.id}');
        await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updatedItem.toJson()),
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Backend vault item update failed, updated locally: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error updating vault item: $e');
      return false;
    }
  }

  Future<bool> deleteVaultItem(String id) async {
    try {
      // 1. Delete from SQLite
      await _dbHelper.deleteVaultItem(id);
      _vaultItems.removeWhere((i) => i.id == id);
      notifyListeners();

      // 2. Sync to Backend
      try {
        final url = Uri.parse('${AppConfig.backendBaseUrl}/api/vault/$id');
        await http.delete(url).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Backend vault item delete failed, deleted locally: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting vault item: $e');
      return false;
    }
  }

  Future<void> toggleFavorite(String id) async {
    final index = _vaultItems.indexWhere((i) => i.id == id);
    if (index != -1) {
      final item = _vaultItems[index];
      final updated = item.copyWith(isFavorite: !item.isFavorite);
      await updateVaultItem(updated);
    }
  }
}
