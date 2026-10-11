import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/ev_spot_model.dart';
import '../providers/location_provider.dart';
import '../providers/map_provider.dart';
import '../widgets/spot_marker_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/widgets/custom_button.dart';

class SpotBottomSheet extends StatelessWidget {
  final EvSpotModel spot;

  const SpotBottomSheet({super.key, required this.spot});

  static void show(BuildContext context, EvSpotModel spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpotBottomSheet(spot: spot),
    );
  }

  void _navigateOnMap(BuildContext context) {
    final mapProvider = context.read<MapProvider>();
    final locProvider = context.read<LocationProvider>();
    final pos = locProvider.position;

    // Pass user's current location so OSRM can compute the real route
    final userLatLng = pos != null ? LatLng(pos.latitude, pos.longitude) : null;

    mapProvider.navigateTo(spot, userLocation: userLatLng);
    Navigator.of(context).pop(); // close bottom sheet
  }

  Color _badgeColor() => SpotMarkerHelper.colorForType(spot.chargerType);

  @override
  Widget build(BuildContext context) {
    final locProvider = context.watch<LocationProvider>();
    final distMeters = locProvider.distanceTo(spot.latitude, spot.longitude);
    final distText = distMeters != null
        ? LocationUtils.formatDistance(distMeters)
        : 'Distance unknown';

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spot.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _badgeColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        spot.chargerType,
                        style: TextStyle(
                          color: _badgeColor(),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 18, color: AppColors.textSecondary.withOpacity(0.8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        spot.address,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _infoChip(
                        Icons.directions_car_outlined, distText, AppColors.primary),
                    const SizedBox(width: 10),
                    _infoChip(
                      Icons.circle,
                      spot.isAvailable
                          ? AppStrings.available
                          : AppStrings.unavailable,
                      spot.isAvailable
                          ? AppColors.available
                          : AppColors.unavailable,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: AppStrings.viewDetails,
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push('/spot/${spot.id}');
                        },
                        icon: Icons.info_outline_rounded,
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        label: AppStrings.navigate,
                        onPressed: () => _navigateOnMap(context),
                        icon: Icons.navigation_rounded,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
