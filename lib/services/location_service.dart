import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'rider_service.dart';

/// A simple lat/lng pair.
class LatLngResult {
  final double lat;
  final double lng;
  LatLngResult(this.lat, this.lng);
}

/// Reads the rider's GPS location AND can keep sending it to the backend
/// every 10 seconds while a delivery is active.
class LocationService {
  final RiderService _riderService;
  Timer? _timer;

  LocationService(this._riderService);

  /// Read the device's current location once, or throw a readable String error.
  static Future<LatLngResult> getCurrentLocation() async {
    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      throw 'Location services are turned off.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw 'Location permission was denied.';
    }

    final position = await Geolocator.getCurrentPosition();
    return LatLngResult(position.latitude, position.longitude);
  }

  /// Start sending the rider's location to the backend every 10 seconds.
  void startSharing() {
    stopSharing(); // make sure we don't run two timers
    _shareOnce(); // send immediately, then on a timer
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _shareOnce());
  }

  Future<void> _shareOnce() async {
    try {
      final loc = await getCurrentLocation();
      await _riderService.updateLocation(loc.lat, loc.lng);
    } catch (_) {
      // best-effort: ignore GPS/network errors so we don't crash the screen
    }
  }

  /// Stop sending location (call when the delivery is finished / screen closes).
  void stopSharing() {
    _timer?.cancel();
    _timer = null;
  }
}
