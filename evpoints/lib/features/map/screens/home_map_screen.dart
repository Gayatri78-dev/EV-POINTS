import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/filter_bar_widget.dart';
import '../widgets/spot_bottom_sheet.dart';
import '../widgets/spot_marker_widget.dart';
import '../widgets/map_settings_sheet.dart';
import '../../spots/screens/spots_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';

class HomeMapScreen extends StatefulWidget {
  final int initialIndex;
  const HomeMapScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  final MapController _mapController = MapController();
  // Tracks the last spot we fitted the camera for, so we only fit once per nav start.
  String? _lastNavSpotId;
  // Pulse animation for the user location dot
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Search bar controller
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Default centre: Bhopal (MP Nagar Zone 1)
  static const _defaultCenter = LatLng(23.2332, 77.4272);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Pulsing animation for the user location dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rebuild when search text changes so the clear button appears/disappears
    _searchController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().loadSpots();
      
      final locProvider = context.read<LocationProvider>();
      // Start continuous real-time tracking
      locProvider.startTracking();
      // Listen for location changes to update the active navigation route
      locProvider.addListener(_onLocationChanged);
    });
  }

  void _onLocationChanged() {
    if (!mounted) return;
    final locProvider = context.read<LocationProvider>();
    final pos = locProvider.position;
    if (pos != null) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      final mapProv = context.read<MapProvider>();
      mapProv.userPosition = latLng;
      mapProv.updateRouteIfNecessary(latLng);
    }
  }

  @override
  void dispose() {
    context.read<LocationProvider>().removeListener(_onLocationChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _centreOnUser() {
    final pos = context.read<LocationProvider>().position;
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.locationPermissionDenied),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Widget _buildMapTab() {
    return Consumer2<MapProvider, LocationProvider>(
      builder: (context, mapProvider, locProvider, _) {
        final userPos = locProvider.position;

        // Build user location marker — animated pulsing blue dot
        final userMarkers = userPos != null
            ? [
                Marker(
                  point: LatLng(userPos.latitude, userPos.longitude),
                  width: 48,
                  height: 48,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing halo
                        Opacity(
                          opacity: _pulseAnimation.value,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(60),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Inner solid dot
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            : <Marker>[];

        // Build spot markers
        final spotMarkers = mapProvider.status == MapStatus.loaded
            ? SpotMarkerHelper.buildMarkers(
                spots: mapProvider.filteredSpots,
                onTap: (spot) {
                  mapProvider.selectSpot(spot);
                  SpotBottomSheet.show(context, spot);
                },
              )
            : <Marker>[];

        // Build polyline from OSRM road-following route points
        final navSpot = mapProvider.navigatingToSpot;
        final routePoints = mapProvider.routePoints;

        final polylines = routePoints.length >= 2
            ? [
                Polyline(
                  points: routePoints,
                  color: AppColors.primary,
                  strokeWidth: 5,
                  borderColor: Colors.white,
                  borderStrokeWidth: 2,
                ),
              ]
            : <Polyline>[];

        // Fit camera ONCE when route points are loaded for a new destination
        if (navSpot != null && routePoints.length >= 2 && navSpot.id != _lastNavSpotId) {
          _lastNavSpotId = navSpot.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final bounds = LatLngBounds.fromPoints(routePoints);
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(80),
                ),
              );
            }
          });
        } else if (navSpot == null) {
          _lastNavSpotId = null;
        }

        return Stack(
          children: [
            // ── OpenStreetMap — no API key required ──────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 13,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (_, __) => mapProvider.selectSpot(null),
              ),
              children: [
                TileLayer(
                  // CartoDB Voyager: sharper, modern, no API key needed
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.evpoints',
                  maxZoom: 20,
                  minZoom: 3,
                  // Keep tiles in memory for smoother panning
                  keepBuffer: 4,
                  tileDisplay: const TileDisplay.fadeIn(),
                ),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: [...spotMarkers, ...userMarkers]),
                // Built-in attribution widget — satisfies CartoDB + OSM license
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                    TextSourceAttribution('© CARTO'),
                  ],
                  alignment: AttributionAlignment.bottomLeft,
                  popupInitialDisplayDuration: Duration.zero,
                ),
              ],
            ),

            // ── Top overlay: search + filter ────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(204),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withAlpha(128),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Icon(Icons.search,
                                  color: AppColors.textPrimary.withAlpha(128)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                  onChanged: (q) =>
                                      mapProvider.setSearchQuery(q),
                                  onSubmitted: (q) {
                                    mapProvider.setSearchQueryImmediate(q);
                                    _searchFocus.unfocus();
                                    if (mapProvider.filteredSpots.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'No stations match your search'),
                                          behavior:
                                              SnackBarBehavior.floating,
                                          backgroundColor:
                                              AppColors.primary,
                                        ),
                                      );
                                    }
                                  },
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: AppStrings.searchHint,
                                    hintStyle: TextStyle(
                                      color: AppColors.textPrimary
                                          .withAlpha(128),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              // Clear button (visible when text is entered)
                              if (_searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    mapProvider.clearSearch();
                                    _searchFocus.unfocus();
                                    setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(Icons.close_rounded,
                                        color: AppColors.textSecondary,
                                        size: 18),
                                  ),
                                ),
                              // Tune / settings button
                              GestureDetector(
                                onTap: () =>
                                    MapSettingsSheet.show(context),
                                child: Container(
                                  margin:
                                      const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient:
                                        AppColors.primaryGradient,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.tune_rounded,
                                      color: Colors.white,
                                      size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Filter chips
                  const FilterBarWidget(),
                ],
              ),
            ),

            // ── Loading overlay ──────────────────────────────────────────────
            if (mapProvider.status == MapStatus.loading)
              const Positioned(
                top: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: LoadingWidget(message: 'Loading stations...'),
                    ),
                  ),
                ),
              ),

            // ── Route fetching indicator ─────────────────────────────────────
            if (mapProvider.routeStatus == RouteStatus.loading)
              Positioned(
                top: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Calculating route...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Error overlay ────────────────────────────────────────────────
            if (mapProvider.status == MapStatus.error)
              Positioned(
                top: 140,
                left: 16,
                right: 16,
                child: Card(
                  child: AppErrorWidget(
                    message:
                        mapProvider.errorMessage ?? AppStrings.genericError,
                    onRetry: mapProvider.reloadSpots,
                  ),
                ),
              ),

            // ── Station count badge ──────────────────────────────────────────
            if (mapProvider.status == MapStatus.loaded)
              Positioned(
                top: 140,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${mapProvider.filteredSpots.length} Stations',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Centre-on-me FAB ─────────────────────────────────────────────
            Positioned(
              bottom: navSpot != null ? 104 : 24,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _centreOnUser,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  tooltip: AppStrings.centreOnMe,
                  child: const Icon(Icons.my_location_rounded, color: Colors.white),
                ),
              ),
            ),

            // ── Stop Navigation banner (shown when route is active) ──────────
            if (navSpot != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Navigating to',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  navSpot.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => mapProvider.stopNavigation(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Stop',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Attribution is handled by flutter_map's RichAttributionWidget inside the FlutterMap.
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildMapTab(),
      const SpotsListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withOpacity(0.12),
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon:
                  Icon(Icons.map_rounded, color: AppColors.primary),
              label: AppStrings.tabMap,
            ),
            NavigationDestination(
              icon: Icon(Icons.ev_station_outlined),
              selectedIcon:
                  Icon(Icons.ev_station_rounded, color: AppColors.primary),
              label: AppStrings.tabSpots,
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon:
                  Icon(Icons.person_rounded, color: AppColors.primary),
              label: AppStrings.tabProfile,
            ),
          ],
        ),
      ),
    );
  }
}
