import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/rider_service.dart';
import '../utils/error_utils.dart';

/// Fetches and holds the list of orders available for pickup.
class RiderOrderProvider extends ChangeNotifier {
  final RiderService _service = RiderService();

  List<Order> _available = [];
  bool _loading = false;
  String? _error;

  List<Order> get available => _available;
  bool get loading => _loading;
  String? get error => _error;

  /// Load orders that are ready for pickup and not yet taken.
  Future<void> loadAvailable() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _available = await _service.available();
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Accept an order. On success it is removed from the available list and the
  /// updated order (now assigned to this rider) is returned.
  Future<Order> accept(Order order) async {
    final updated = await _service.accept(order.id);
    _available.removeWhere((o) => o.id == order.id);
    notifyListeners();
    return updated;
  }
}
