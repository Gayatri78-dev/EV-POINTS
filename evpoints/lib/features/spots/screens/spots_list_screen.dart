import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../map/providers/map_provider.dart';
import '../../map/providers/location_provider.dart';
import '../../map/widgets/filter_bar_widget.dart';
import '../widgets/spot_card_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';

class SpotsListScreen extends StatelessWidget {
  const SpotsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Charging Stations',
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: FilterBarWidget(),
          ),
        ),
      ),
      body: Consumer2<MapProvider, LocationProvider>(
        builder: (context, mapProvider, locProvider, _) {
          if (mapProvider.status == MapStatus.loading) {
            return const LoadingWidget(message: 'Fetching stations...');
          }
          if (mapProvider.status == MapStatus.error) {
            return AppErrorWidget(
              message: mapProvider.errorMessage ?? AppStrings.genericError,
              onRetry: mapProvider.reloadSpots,
            );
          }

          final spots = mapProvider.filteredSpots;

          if (spots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.ev_station_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    AppStrings.noSpots,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try adjusting your filters or location',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: mapProvider.reloadSpots,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Available Stations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${spots.length} Found',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: spots.length,
                    itemBuilder: (context, index) {
                      final spot = spots[index];
                      final distMeters =
                          locProvider.distanceTo(spot.latitude, spot.longitude);
                      final distText = distMeters != null
                          ? LocationUtils.formatDistance(distMeters)
                          : null;
                      return SpotCardWidget(spot: spot, distanceText: distText);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
