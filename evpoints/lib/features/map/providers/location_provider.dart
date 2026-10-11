import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/location_utils.dart';

enum LocationStatus { initial, loading, available, denied, error }

class LocationProvider extends ChangeNotifier {
  LocationStatus _status = LocationStatus.initial;
  Position? _position;
  String? _errorMessage;
  StreamSubscription<Position>? _positionSubscription;

  // Minimum distance (in meters) between position updates to trigger a rebuild.
  // This prevents the map from rebuilding 5–10 times per second when stationary.
  static const double _minUpdateDistanceMeters = 5.0;

  LocationStatus get status => _status;
  Position? get position => _position;
  String? get errorMessage => _errorMessage;

  /// Starts continuous real-time GPS tracking.
  /// Call once from initState; the position updates automatically.
  Future<void> startTracking() async {
    if (_status == LocationStatus.loading) return; // already starting

    _status = LocationStatus.loading;
    notifyListeners();

    try {
      // Get an immediate fix first so the dot appears right away
      final initialPos = await LocationUtils.getCurrentPosition();
      if (initialPos != null) {
        _position = initialPos;
        _status = LocationStatus.available;
        notifyListeners();
      }

      // Subscribe to the live stream for continuous updates
      final stream = await LocationUtils.getPositionStream();
      if (stream == null) {
        _errorMessage = 'Location permission denied or service unavailable.';
        _status = LocationStatus.denied;
        notifyListeners();
        return;
      }

      await _positionSubscription?.cancel();
      _positionSubscription = stream.listen(
        (pos) {
          // Only notify if we've moved at least _minUpdateDistanceMeters
          if (_position != null) {
            final moved = Geolocator.distanceBetween(
              _position!.latitude,
              _position!.longitude,
              pos.latitude,
              pos.longitude,
            );
            if (moved < _minUpdateDistanceMeters) return; // skip tiny jitter
          }
          _position = pos;
          _status = LocationStatus.available;
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = e.toString();
          _status = LocationStatus.error;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _status = LocationStatus.error;
      notifyListeners();
    }
  }

  /// Legacy alias so existing call-sites continue to work.
  Future<void> fetchLocation() => startTracking();

  double? distanceTo(double lat, double lng) {
    if (_position == null) return null;
    return LocationUtils.calculateDistance(
      _position!.latitude,
      _position!.longitude,
      lat,
      lng,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
