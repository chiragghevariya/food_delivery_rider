/// Central place for the API connection settings.
/// (Same setup as the customer app — both talk to the same Laravel backend.)
class ApiConfig {
  /// Base URL of the Laravel API.
  ///   - Android emulator:        http://10.0.2.2:8000/api   (10.0.2.2 = your PC's localhost)
  ///   - iOS simulator / web:     http://127.0.0.1:8000/api
  ///   - Real phone (same wifi):  http://<YOUR-PC-IP>:8000/api
  ///
  /// Start the backend with:  php artisan serve
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static Map<String, String> get defaultHeaders => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
}
