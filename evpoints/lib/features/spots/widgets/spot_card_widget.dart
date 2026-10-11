import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../map/models/ev_spot_model.dart';
import '../../map/providers/map_provider.dart';
import '../../map/providers/location_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class SpotCardWidget extends StatefulWidget {
  final EvSpotModel spot;
  final String? distanceText;
  final VoidCallback? onTap;

  const SpotCardWidget({
    super.key,
    required this.spot,
    this.distanceText,
    this.onTap,
  });

  @override
  State<SpotCardWidget> createState() => _SpotCardWidgetState();
}

class _SpotCardWidgetState extends State<SpotCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color get _badgeColor {
    switch (widget.spot.chargerType) {
      case 'AC':
        return AppColors.acBadge;
      case 'DC':
        return AppColors.dcBadge;
      default:
        return AppColors.fastChargeBadge;
    }
  }

  void _navigate(BuildContext context) {
    final mapProvider = context.read<MapProvider>();
    final locProvider = context.read<LocationProvider>();
    final pos = locProvider.position;

    // Pass user's current location for road-following route
    final userLatLng = pos != null ? LatLng(pos.latitude, pos.longitude) : null;

    // Start navigation in-app
    mapProvider.navigateTo(widget.spot, userLocation: userLatLng);
    
    // Switch to Map tab
    context.go('/home?index=0');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          context.push('/spot/${widget.spot.id}');
        }
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Accent bar
                  Container(
                    width: 6,
                    color: _badgeColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _badgeColor.withOpacity(0.2),
                                  _badgeColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.ev_station_rounded,
                              color: _badgeColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.spot.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _badgeColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        widget.spot.chargerType,
                                        style: TextStyle(
                                          color: _badgeColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.spot.address,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Availability dot
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: widget.spot.isAvailable
                                            ? AppColors.available
                                            : AppColors.unavailable,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (widget.spot.isAvailable
                                                    ? AppColors.available
                                                    : AppColors.unavailable)
                                                .withOpacity(0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        widget.spot.isAvailable
                                            ? AppStrings.available
                                            : AppStrings.unavailable,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.spot.isAvailable
                                              ? AppColors.available
                                              : AppColors.unavailable,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.distanceText != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.directions_car_outlined,
                                          size: 13, color: AppColors.textSecondary),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          widget.distanceText!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    // Navigate button
                                    GestureDetector(
                                      onTap: () => _navigate(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.primaryGradient,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.navigation_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
