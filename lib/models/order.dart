import '../utils/json_utils.dart';
import 'order_item.dart';

/// An order as seen by the rider. It carries BOTH locations the rider needs:
///   - the restaurant (pickup) location
///   - the customer (delivery) location
class Order {
  final int id;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double total;

  // delivery (customer) details
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? notes;

  // restaurant (pickup) details
  final int? restaurantId;
  final String? restaurantName;
  final String? restaurantAddress;
  final double? restaurantLat;
  final double? restaurantLng;

  final double? distanceKm; // distance rider->restaurant (in the "available" list)
  final List<OrderItem> items;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.notes,
    this.restaurantId,
    this.restaurantName,
    this.restaurantAddress,
    this.restaurantLat,
    this.restaurantLng,
    this.distanceKm,
    this.items = const [],
    this.createdAt,
  });

  bool get isReadyForPickup => status == 'ready_for_pickup';
  bool get isPickedUp => status == 'picked_up';
  bool get isDelivered => status == 'delivered';

  factory Order.fromJson(Map<String, dynamic> json) {
    final restaurant = json['restaurant'];
    return Order(
      id: toInt(json['id']),
      status: json['status'] ?? '',
      subtotal: toDouble(json['subtotal']),
      deliveryFee: toDouble(json['delivery_fee']),
      total: toDouble(json['total']),
      deliveryAddress: json['address'],
      deliveryLat: toDoubleOrNull(json['lat']),
      deliveryLng: toDoubleOrNull(json['lng']),
      notes: json['notes'],
      restaurantId: restaurant is Map ? toInt(restaurant['id']) : null,
      restaurantName: restaurant is Map ? restaurant['name'] as String? : null,
      restaurantAddress: restaurant is Map ? restaurant['address'] as String? : null,
      restaurantLat: restaurant is Map ? toDoubleOrNull(restaurant['lat']) : null,
      restaurantLng: restaurant is Map ? toDoubleOrNull(restaurant['lng']) : null,
      distanceKm: toDoubleOrNull(json['distance_km']),
      items: (json['items'] as List?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: toDate(json['created_at']),
    );
  }
}
