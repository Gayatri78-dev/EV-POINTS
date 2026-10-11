import 'package:geolocator/geolocator.dart';

class LocationUtils {
  LocationUtils._();

  /// Request permissions then return the current one-shot position.
  static Future<Position?> getCurrentPosition() async {
    if (!await _ensurePermission()) return null;
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Returns a continuous stream of positions (real-time tracking).
  /// Caller must cancel the subscription when done.
  static Future<Stream<Position>?> getPositionStream() async {
    if (!await _ensurePermission()) return null;
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // metres — update every 5 m of movement
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Checks location service + permission, requesting if needed.
  /// Returns true if permission is granted.
  static Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
