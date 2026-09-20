import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/api_service.dart';
import '../../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ApiService _api = ApiService.instance;

  UserModel? _currentUser;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final activeUserId = await _db.getActiveSession();
      if (activeUserId != null) {
        _currentUser = await _db.getUserById(activeUserId);
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String emailOrPhone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserModel? user;
      // 1. Attempt Spring Boot Backend authentication
      try {
        user = await _api.login(
          emailOrPhone: emailOrPhone.trim(),
          password: password,
        );
        // Cache user in local SQLite for offline access
        await _db.saveOrUpdateUser(user, password);
        await _db.saveActiveSession(user.id);
      } catch (apiEx) {
        final errText = apiEx.toString();
        if (errText.contains('Invalid') || errText.contains('credentials')) {
          _errorMessage = 'Invalid email/phone or password. Please try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        // If server is unreachable / offline, fall back to local SQLite credentials
        user = await _db.authenticateUser(
          emailOrPhone: emailOrPhone,
          password: password,
        );
        if (user == null) {
          _errorMessage = 'Invalid credentials or server unavailable.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString().replaceAll('Exception: ', '')}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserModel? apiUser;
      // 1. Attempt Spring Boot Backend registration
      try {
        apiUser = await _api.register(
          name: name,
          email: email,
          phone: phone,
          password: password,
        );
      } catch (apiEx) {
        final err = apiEx.toString();
        if (err.contains('already exists')) {
          _errorMessage = 'An account with this email or phone already exists.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        // If server is unreachable, continue with local creation
      }

      // 2. Persist locally in SQLite
      final localUser = await _db.registerUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
        existingId: apiUser?.id,
      );

      _currentUser = localUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateCurrentUser(UserModel updated) async {
    _currentUser = updated;
    await _db.updateUserDetails(updated);
    notifyListeners();
  }

  Future<void> logout() async {
    await _db.clearActiveSession();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}