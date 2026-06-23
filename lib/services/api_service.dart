import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// A single shared Dio HTTP client for the whole app.
/// It automatically attaches the JWT token to every request.
/// (Same as the customer app's ApiService.)
class ApiService {
  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null && _token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
    ));
  }

  static final ApiService instance = ApiService._internal();

  late final Dio dio;
  String? _token;

  void setToken(String? token) => _token = token;
}
