import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../data/spots_repository.dart';
import '../data/routing_service.dart';
import '../models/ev_spot_model.dart';

enum MapStatus { initial, loading, loaded, error }

enum RouteStatus { idle, loading, loaded, error }

enum SortMode { none, name, distance, availability }

class MapProvider extends ChangeNotifier {
  final SpotsRepository _repo = SpotsRepository();

  MapStatus _status = MapStatus.initial;
  List<EvSpotModel> _allSpots = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';
  SortMode _sortMode = SortMode.none;
  bool _showOnlyAvailable = false;
  String? _errorMessage;
  EvSpotModel? _selectedSpot;
  EvSpotModel? _navigatingToSpot;

  // Route data
  RouteStatus _routeStatus = RouteStatus.idle;
  List<LatLng> _routePoints = [];
  String? _routeError;
  LatLng? _lastFetchLocation;
  bool _isFetchingRoute = false;

  // Debounce timer for location-triggered route updates
  Timer? _routeDebounce;
  // Debounce timer for search query
  Timer? _searchDebounce;

  // User position for distance-based sorting (set externally)
  LatLng? userPosition;

  MapStatus get status => _status;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  SortMode get sortMode => _sortMode;
  bool get showOnlyAvailable => _showOnlyAvailable;
  String? get errorMessage => _errorMessage;
  EvSpotModel? get selectedSpot => _selectedSpot;

  /// Non-null when user pressed Navigate — drives the on-map polyline route.
  EvSpotModel? get navigatingToSpot => _navigatingToSpot;

  RouteStatus get routeStatus => _routeStatus;

  /// Road-following waypoints decoded from OSRM. Empty list = no route / not loaded yet.
  List<LatLng> get routePoints => _routePoints;

  String? get routeError => _routeError;

  List<EvSpotModel> get filteredSpots {
    var spots = List<EvSpotModel>.from(_allSpots);

    // 1. Apply charger-type filter
    if (_selectedFilter != 'All') {
      spots = spots.where((s) => s.chargerType == _selectedFilter).toList();
    }

    // 2. Apply search query (match name or address, case-insensitive)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      spots = spots.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.address.toLowerCase().contains(q) ||
            s.operatorName.toLowerCase().contains(q);
      }).toList();
    }

    // 3. Apply "available only" filter
    if (_showOnlyAvailable) {
      spots = spots.where((s) => s.isAvailable).toList();
    }

    // 4. Apply sort
    switch (_sortMode) {
      case SortMode.name:
        spots.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortMode.distance:
        if (userPosition != null) {
          final dist = const Distance();
          spots.sort((a, b) {
            final da = dist.as(LengthUnit.Meter, userPosition!,
                LatLng(a.latitude, a.longitude));
            final db = dist.as(LengthUnit.Meter, userPosition!,
                LatLng(b.latitude, b.longitude));
            return da.compareTo(db);
          });
        }
        break;
      case SortMode.availability:
        spots.sort((a, b) {
          // Available first
          if (a.isAvailable && !b.isAvailable) return -1;
          if (!a.isAvailable && b.isAvailable) return 1;
          return 0;
        });
        break;
      case SortMode.none:
        break;
    }

    return spots;
  }

  List<EvSpotModel> get allSpots => _allSpots;

  Future<void> loadSpots() async {
    if (_status == MapStatus.loaded) return; // already loaded — skip
    _status = MapStatus.loading;
    notifyListeners();

    final result = await _repo.getSpots();
    if (result.isSuccess) {
      _allSpots = result.data!;
      _status = MapStatus.loaded;
    } else {
      _errorMessage = result.error;
      _status = MapStatus.error;
    }
    notifyListeners();
  }

  /// Force-reload spots (e.g., pull-to-refresh).
  Future<void> reloadSpots() async {
    _status = MapStatus.loading;
    notifyListeners();
    final result = await _repo.getSpots();
    if (result.isSuccess) {
      _allSpots = result.data!;
      _status = MapStatus.loaded;
    } else {
      _errorMessage = result.error;
      _status = MapStatus.error;
    }
    notifyListeners();
  }

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Update the search query with a debounce so typing is responsive.
  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (_searchQuery == query) return;
      _searchQuery = query;
      notifyListeners();
    });
  }

  /// Immediately apply the search (used on submit).
  void setSearchQueryImmediate(String query) {
    _searchDebounce?.cancel();
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    if (_sortMode == mode) return;
    _sortMode = mode;
    notifyListeners();
  }

  void setShowOnlyAvailable(bool value) {
    if (_showOnlyAvailable == value) return;
    _showOnlyAvailable = value;
    notifyListeners();
  }

  void selectSpot(EvSpotModel? spot) {
    if (_selectedSpot == spot) return;
    _selectedSpot = spot;
    notifyListeners();
  }

  /// Called when user presses the Navigate button.
  /// Fetches a real road-following route from OSRM, then notifies listeners.
  Future<void> navigateTo(EvSpotModel spot, {LatLng? userLocation}) async {
    _navigatingToSpot = spot;
    _selectedSpot = spot;
    _routePoints = [];
    _routeError = null;
    _routeStatus = RouteStatus.loading;
    notifyListeners();

    if (userLocation != null) {
      _lastFetchLocation = userLocation;
      final points = await RoutingService.getRoute(
        origin: userLocation,
        destination: LatLng(spot.latitude, spot.longitude),
      );

      if (points.isNotEmpty) {
        _routePoints = points;
        _routeStatus = RouteStatus.loaded;
      } else {
        // Fallback: straight line between user and destination
        _routePoints = [
          userLocation,
          LatLng(spot.latitude, spot.longitude),
        ];
        _routeStatus = RouteStatus.error;
        _routeError = 'Could not fetch road route. Showing straight line.';
      }
    } else {
      _routeStatus = RouteStatus.error;
      _routeError = 'User location unavailable.';
    }

    notifyListeners();
  }

  /// Automatically updates the route if the user has moved significantly.
  /// Debounced to avoid hammering the OSRM API on every GPS ping.
  Future<void> updateRouteIfNecessary(LatLng currentPos) async {
    if (_navigatingToSpot == null || _isFetchingRoute) return;

    // Only update if we've moved significantly (e.g., > 20 meters)
    if (_lastFetchLocation != null) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        _lastFetchLocation!,
        currentPos,
      );

      if (distance < 20) {
        // Tiny movement: just snap the first route point to user's position
        if (_routePoints.isNotEmpty) {
          _routePoints[0] = currentPos;
          notifyListeners();
        }
        return;
      }
    }

    // Debounce: only fire the OSRM call after 2s of no further movement
    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(seconds: 2), () async {
      if (_navigatingToSpot == null || _isFetchingRoute) return;

      _isFetchingRoute = true;
      _lastFetchLocation = currentPos;

      final points = await RoutingService.getRoute(
        origin: currentPos,
        destination: LatLng(
            _navigatingToSpot!.latitude, _navigatingToSpot!.longitude),
      );

      if (points.isNotEmpty) {
        _routePoints = points;
        _routeStatus = RouteStatus.loaded;
      }

      _isFetchingRoute = false;
      notifyListeners();
    });
  }

  /// Clears the active navigation route.
  void stopNavigation() {
    _routeDebounce?.cancel();
    _navigatingToSpot = null;
    _routePoints = [];
    _routeStatus = RouteStatus.idle;
    _routeError = null;
    notifyListeners();
  }

  Future<EvSpotModel?> getSpotById(String id) async {
    final result = await _repo.getSpotById(id);
    if (result.isSuccess) return result.data;
    return null;
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }
}
