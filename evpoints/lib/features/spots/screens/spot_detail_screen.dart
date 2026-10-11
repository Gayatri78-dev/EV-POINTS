import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../map/models/ev_spot_model.dart';
import '../../map/providers/map_provider.dart';
import '../../map/providers/location_provider.dart';
import '../../map/widgets/spot_marker_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/custom_button.dart';

class SpotDetailScreen extends StatefulWidget {
  final String spotId;
  const SpotDetailScreen({super.key, required this.spotId});

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  EvSpotModel? _spot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSpot();
  }

  Future<void> _loadSpot() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await context.read<MapProvider>().getSpotById(widget.spotId);
    if (mounted) {
      setState(() {
        _spot = result;
        _loading = false;
        _error = result == null ? 'Spot not found.' : null;
      });
    }
  }

  void _navigate() {
    if (_spot == null) return;
    
    final mapProvider = context.read<MapProvider>();
    final locProvider = context.read<LocationProvider>();
    final pos = locProvider.position;

    // Pass user's current location for road-following route
    final userLatLng = pos != null ? LatLng(pos.latitude, pos.longitude) : null;

    // Start navigation in-app
    mapProvider.navigateTo(_spot!, userLocation: userLatLng);
    
    // Return to the Map tab on the Home screen
    context.go('/home?index=0');
  }

  Color _badgeColor(String type) =>
      SpotMarkerHelper.colorForType(type);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: const Text('Station Details'),
      ),
      body: _loading
          ? const LoadingWidget(message: 'Loading details...')
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadSpot)
              : _buildContent(),
      bottomNavigationBar: _spot != null
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: CustomButton(
                  label: AppStrings.navigate,
                  onPressed: _navigate,
                  icon: Icons.navigation_rounded,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    final spot = _spot!;
    final spotLatLng = LatLng(spot.latitude, spot.longitude);
    final badgeColor = _badgeColor(spot.chargerType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  // Colored strip at top
                  Container(
                    height: 8,
                    width: double.infinity,
                    color: badgeColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    badgeColor.withOpacity(0.2),
                                    badgeColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.ev_station_rounded,
                                  color: badgeColor, size: 36),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    spot.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    spot.operatorName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 16),
                        _detailRow(Icons.location_on_outlined, 'Address',
                            spot.address, iconColor: badgeColor),
                        const SizedBox(height: 16),
                        _detailRow(Icons.bolt_rounded, 'Charger Type',
                            spot.chargerType,
                            valueColor: badgeColor, iconColor: badgeColor),
                        const SizedBox(height: 16),
                        _detailRow(
                          Icons.circle,
                          'Availability',
                          spot.isAvailable
                              ? AppStrings.available
                              : AppStrings.unavailable,
                          valueColor: spot.isAvailable
                              ? AppColors.available
                              : AppColors.unavailable,
                          iconColor: spot.isAvailable
                              ? AppColors.available
                              : AppColors.unavailable,
                        ),
                        const SizedBox(height: 16),
                        _detailRow(Icons.access_time_rounded, 'Open Hours',
                            spot.openHours, iconColor: badgeColor),
                        const SizedBox(height: 16),
                        _detailRow(Icons.business_rounded, 'Operator',
                            spot.operatorName, iconColor: badgeColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Map Preview Header ──────────────────────────────────────────
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // ── Embedded map snippet (OpenStreetMap, no API key) ─────────────
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: spotLatLng,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none, // non-interactive
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.evpoints',
                      maxZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: spotLatLng,
                          width: 50,
                          height: 58,
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.ev_station_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              CustomPaint(
                                size: const Size(12, 8),
                                painter: _PinTip(AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor, Color? iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PinTip extends CustomPainter {
  final Color color;
  const _PinTip(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
