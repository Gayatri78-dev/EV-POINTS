import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Fetches a real road-following route from the free OSRM routing API.
/// No API key required — powered by OpenStreetMap data.
class RoutingService {
  RoutingService._();

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));

  // Simple in-memory route cache: key = "lat1,lng1|lat2,lng2" (rounded to 3dp)
  // Avoids redundant OSRM calls when the user has barely moved.
  static final Map<String, List<LatLng>> _cache = {};
  static const _maxCacheEntries = 10;

  static String _cacheKey(LatLng a, LatLng b) {
    // Round to ~111m precision to get cache hits for nearby positions
    final aLat = (a.latitude * 1000).round() / 1000;
    final aLng = (a.longitude * 1000).round() / 1000;
    final bLat = (b.latitude * 1000).round() / 1000;
    final bLng = (b.longitude * 1000).round() / 1000;
    return '$aLat,$aLng|$bLat,$bLng';
  }

  /// Returns a list of [LatLng] points following actual roads from [origin] to [destination].
  /// Returns an empty list on failure (caller can fall back to straight line).
  static Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final key = _cacheKey(origin, destination);

    // Return cached result if available
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      // OSRM public demo server — driving profile, polyline6 geometry
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=polyline6&steps=false';

      final response = await _dio.get(url);

      if (response.statusCode != 200) return [];

      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return [];

      final geometry = routes[0]['geometry'] as String?;
      if (geometry == null) return [];

      final points = _decodePolyline6(geometry);

      // Store in cache, evict oldest entry if cache is full
      if (_cache.length >= _maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[key] = points;

      return points;
    } catch (_) {
      return [];
    }
  }

  /// Clears the route cache (call when app goes to background or user logs out).
  static void clearCache() => _cache.clear();

  /// Decodes a Google-style encoded polyline (precision 6) into [LatLng] points.
  static List<LatLng> _decodePolyline6(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude delta
      int result = 0, shift = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Decode longitude delta
      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e6, lng / 1e6));
    }

    return points;
  }
}
