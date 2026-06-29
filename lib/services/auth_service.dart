import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Handles rider login and remembers the JWT token on the device.
class AuthService {
  static const String _tokenKey = 'rider_auth_token';
  final Dio _dio = ApiService.instance.dio;

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Load any saved token into the API client (call once at app start).
  Future<void> loadSavedToken() async {
    final token = await getSavedToken();
    ApiService.instance.setToken(token);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    ApiService.instance.setToken(token);
  }

  Future<User> login({required String email, required String password, String? fcmToken}) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      if (fcmToken != null) 'fcm_token': fcmToken,
    });
    await _saveToken(res.data['access_token'] as String);
    return User.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<User> me() async {
    final res = await _dio.get('/auth/me');
    return User.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    ApiService.instance.setToken(null);
  }
}
