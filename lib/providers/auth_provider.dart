import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Holds the logged-in rider. Only users with the "rider" role may sign in here.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _busy = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;

  /// Try to log in automatically using a saved token (used by SplashScreen).
  Future<bool> tryAutoLogin() async {
    await _authService.loadSavedToken();
    final token = await _authService.getSavedToken();
    if (token == null || token.isEmpty) return false;

    try {
      final user = await _authService.me();
      if (!user.isRider) {
        await _authService.logout();
        return false;
      }
      _user = user;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    _setBusy(true);
    try {
      final user = await _authService.login(email: email, password: password);
      // This app is only for riders.
      if (!user.isRider) {
        await _authService.logout();
        throw 'This account is not a rider account.';
      }
      _user = user;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
