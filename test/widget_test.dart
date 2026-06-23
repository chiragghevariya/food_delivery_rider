// A small parsing test (pure Dart, no UI/network).
// Also takes the place of Flutter's default counter test.

import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_rider/models/order.dart';

void main() {
  test('Order.fromJson reads restaurant + delivery locations and items', () {
    final json = {
      'id': 5,
      'status': 'ready_for_pickup',
      'subtotal': '20.00',
      'delivery_fee': '2.00',
      'total': '22.00',
      'address': '123 Main St',
      'lat': '24.86',
      'lng': '67.00',
      'restaurant': {
        'id': 3,
        'name': 'Pizza Place',
        'address': '1 Food St',
        'lat': '24.90',
        'lng': '67.05',
      },
      'items': [
        {'id': 1, 'menu_item_id': 9, 'name': 'Pizza', 'quantity': 2, 'unit_price': '10.00', 'subtotal': '20.00'}
      ],
      'distance_km': 1.5,
    };

    final order = Order.fromJson(json);

    expect(order.id, 5);
    expect(order.isReadyForPickup, true);
    expect(order.restaurantName, 'Pizza Place');
    expect(order.restaurantLat, 24.90);
    expect(order.deliveryLat, 24.86);
    expect(order.total, 22.0);
    expect(order.items.length, 1);
    expect(order.items.first.quantity, 2);
    expect(order.distanceKm, 1.5);
  });
}
