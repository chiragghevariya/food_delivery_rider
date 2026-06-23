import 'package:dio/dio.dart';
import '../models/order.dart';
import 'api_service.dart';

/// Talks to the /rider/* endpoints (all require the "rider" role).
class RiderService {
  final Dio _dio = ApiService.instance.dio;

  /// GET /api/rider/orders/available
  Future<List<Order>> available({double? lat, double? lng, double? radius}) async {
    final res = await _dio.get('/rider/orders/available', queryParameters: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radius != null) 'radius': radius,
    });
    final list = res.data['data'] as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/rider/orders/{id}/accept
  Future<Order> accept(int id) async {
    final res = await _dio.post('/rider/orders/$id/accept');
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/rider/orders/{id}/picked-up
  Future<Order> pickedUp(int id) async {
    final res = await _dio.post('/rider/orders/$id/picked-up');
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/rider/orders/{id}/delivered
  Future<Order> delivered(int id) async {
    final res = await _dio.post('/rider/orders/$id/delivered');
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/rider/orders/history
  Future<List<Order>> history() async {
    final res = await _dio.get('/rider/orders/history');
    final list = res.data['data'] as List;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/rider/location
  Future<void> updateLocation(double lat, double lng) async {
    await _dio.post('/rider/location', data: {'lat': lat, 'lng': lng});
  }
}
