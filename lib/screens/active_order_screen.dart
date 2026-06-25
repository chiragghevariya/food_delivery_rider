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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Delivered! Great job 🎉'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Move the map camera to the rider's current GPS location.
  Future<void> _centerOnRider() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(loc.lat, loc.lng), 15),
      );
    } catch (_) {
      // ignore — keep the default camera position
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Active Transit #${order.id}'),
      ),
      bottomNavigationBar: _actionBar(order),
      body: Column(
        children: [
          // Map Section (40% Screen height)
          Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.38,
                child: _buildMap(order),
              ),
              // Floating Action Buttons on top of the Map
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _centerOnRider,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
          
          // Details Card Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Header
                  _buildHeaderCard(order),
                  const SizedBox(height: 12),
                  
                  // Routing Details (Pickup / Drop-off)
                  _buildRoutingCard(order),
                  const SizedBox(height: 12),
                  
                  // Verification Checklist
                  _buildChecklistCard(order),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(Order order) {
    final hasRestaurant = order.restaurantLat != null && order.restaurantLng != null;
    final hasCustomer = order.deliveryLat != null && order.deliveryLng != null;

    if (!hasRestaurant && !hasCustomer) {
      return Container(
        color: const Color(0xFFE2E8F0),
        child: const Center(child: Text('Map coordinates missing for this order.')),
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
        infoWindow: InfoWindow(title: 'Restaurant Pickup', snippet: order.restaurantName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    }
    if (hasCustomer) {
      final p = LatLng(order.deliveryLat!, order.deliveryLng!);
      routePoints.add(p);
      markers.add(Marker(
        markerId: const MarkerId('customer'),
        position: p,
        infoWindow: const InfoWindow(title: 'Customer Drop-off'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

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
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _centerOnRider();
      },
    );
  }

  Widget _buildHeaderCard(Order order) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                order.isPickedUp ? Icons.delivery_dining : Icons.store_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Payout',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutingCard(Order order) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DELIVERY DIRECTIONS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Pickup details row
            _routingRow(
              icon: Icons.circle_outlined,
              iconColor: AppColors.accent,
              title: 'PICKUP FROM',
              name: order.restaurantName ?? 'Restaurant',
              address: order.restaurantAddress,
              isActive: order.isReadyForPickup,
            ),
            
            // Connecting line
            Padding(
              padding: const EdgeInsets.only(left: 8.5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 2,
                  height: 24,
                  color: AppColors.border,
                ),
              ),
            ),
            
            // Dropoff details row
            _routingRow(
              icon: Icons.location_on_outlined,
              iconColor: AppColors.primary,
              title: 'DELIVER TO',
              name: 'Customer Address',
              address: order.deliveryAddress,
              isActive: order.isPickedUp,
            ),
            
            // Customer Notes alert card
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COURIER INSTRUCTIONS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.notes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.text,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String name,
    required String? address,
    required bool isActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.primary : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isActive ? AppColors.text : AppColors.text.withOpacity(0.6),
                ),
              ),
              if (address != null && address.isNotEmpty)
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistCard(Order order) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ORDER INVOICE CHECKLIST',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, idx) {
                final it = order.items[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${it.quantity}x',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          it.name ?? 'Item #${it.menuItemId}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const Icon(Icons.check_box_outline_blank, color: AppColors.border, size: 20),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom button changes with the order's status.
  Widget _actionBar(Order order) {
    String label;
    IconData icon;
    VoidCallback? onTap;

    if (order.isReadyForPickup) {
      label = 'Confirm Pickup';
      icon = Icons.shopping_bag_outlined;
      onTap = _advance;
    } else if (order.isPickedUp) {
      label = 'Confirm Delivery';
      icon = Icons.check_circle_outline;
      onTap = _advance;
    } else {
      label = 'Done — Back to Feed';
      icon = Icons.arrow_back_rounded;
      onTap = () => Navigator.popUntil(context, ModalRoute.withName(Routes.available));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: PrimaryButton(
          label: label,
          icon: icon,
          loading: _busy,
          onPressed: onTap,
        ),
      ),
    );
  }
}
