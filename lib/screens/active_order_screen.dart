import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_theme.dart';
import '../config/routes.dart';
import '../models/order.dart';
import '../services/location_service.dart';
import '../services/rider_service.dart';
import '../utils/error_utils.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';

/// The rider's current delivery: a map (restaurant + customer + route), the
/// order details, and a button to move it Picked Up -> Delivered.
/// While this screen is open it shares the rider's GPS every 10 seconds.
class ActiveOrderScreen extends StatefulWidget {
  const ActiveOrderScreen({super.key});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  final RiderService _service = RiderService();
  late final LocationService _location;

  Order? _order;
  GoogleMapController? _mapController;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_order == null) {
      _order = ModalRoute.of(context)!.settings.arguments as Order;
      _location = LocationService(_service);
      _location.startSharing(); // POST /rider/location every 10 seconds
    }
  }

  @override
  void dispose() {
    _location.stopSharing();
    _mapController?.dispose();
    super.dispose();
  }

  /// Move the order to its next status (picked up, then delivered).
  Future<void> _advance() async {
    final order = _order!;
    setState(() => _busy = true);
    try {
      Order updated;
      if (order.isReadyForPickup) {
        updated = await _service.pickedUp(order.id);
      } else if (order.isPickedUp) {
        updated = await _service.delivered(order.id);
        _location.stopSharing(); // delivery done — stop sharing GPS
      } else {
        return;
      }
      if (!mounted) return;
      setState(() => _order = updated);
      if (updated.isDelivered) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Delivered! Great job 🎉')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Move the map camera to the rider's current GPS location.
  Future<void> _centerOnRider() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      await _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
      );
    } catch (_) {
      // ignore — keep the default camera position
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order!;
    return Scaffold(
      appBar: AppBar(title: Text('Delivery #${order.id}')),
      bottomNavigationBar: _actionBar(order),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.4, child: _buildMap(order)),
          Expanded(child: _buildDetails(order)),
        ],
      ),
    );
  }

  Widget _buildMap(Order order) {
    final hasRestaurant = order.restaurantLat != null && order.restaurantLng != null;
    final hasCustomer = order.deliveryLat != null && order.deliveryLng != null;

    if (!hasRestaurant && !hasCustomer) {
      return Container(
        color: const Color(0xFFE0E4E4),
        child: const Center(child: Text('Map unavailable (no coordinates for this order).')),
      );
    }

    final markers = <Marker>{};
    final routePoints = <LatLng>[];

    if (hasRestaurant) {
      final p = LatLng(order.restaurantLat!, order.restaurantLng!);
      routePoints.add(p);
      markers.add(Marker(
        markerId: const MarkerId('restaurant'),
        position: p,
        infoWindow: InfoWindow(title: 'Pickup', snippet: order.restaurantName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }
    if (hasCustomer) {
      final p = LatLng(order.deliveryLat!, order.deliveryLng!);
      routePoints.add(p);
      markers.add(Marker(
        markerId: const MarkerId('customer'),
        position: p,
        infoWindow: const InfoWindow(title: 'Drop-off'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    // Straight line between the two pins. (A real road route would use the
    // Google Directions API; a straight line keeps this simple.)
    final polylines = <Polyline>{};
    if (hasRestaurant && hasCustomer) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: AppColors.primary,
        width: 4,
      ));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: routePoints.first, zoom: 13),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: true, // shows the rider's blue dot (needs location permission)
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _centerOnRider(); // center the camera on the rider
      },
    );
  }

  Widget _buildDetails(Order order) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            StatusBadge(status: order.status),
          ],
        ),
        const Divider(height: 24),
        _infoRow(Icons.store, 'Pickup from', order.restaurantName ?? 'Restaurant', order.restaurantAddress),
        const SizedBox(height: 10),
        _infoRow(Icons.location_on, 'Deliver to', order.deliveryAddress ?? 'Customer', order.notes),
        const Divider(height: 24),
        const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...order.items.map((it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text('${it.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(it.name ?? 'Item #${it.menuItemId ?? ''}')),
                ],
              ),
            )),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Order total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, String? sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (sub != null && sub.isNotEmpty)
                Text(sub, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  /// Bottom button changes with the order's status.
  Widget _actionBar(Order order) {
    String label;
    VoidCallback? onTap;

    if (order.isReadyForPickup) {
      label = 'Mark as Picked Up';
      onTap = _advance;
    } else if (order.isPickedUp) {
      label = 'Mark as Delivered';
      onTap = _advance;
    } else {
      // delivered (or anything else) -> let the rider go back to the list
      label = 'Done — back to orders';
      onTap = () => Navigator.popUntil(context, ModalRoute.withName(Routes.available));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: PrimaryButton(label: label, loading: _busy, onPressed: onTap),
      ),
    );
  }
}
