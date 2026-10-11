// spot_marker_widget.dart
// Helper for building flutter_map marker objects (no Google Maps needed).

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ev_spot_model.dart';
import '../../../core/constants/app_colors.dart';

class SpotMarkerHelper {
  SpotMarkerHelper._();

  static Color colorForType(String type) {
    switch (type) {
      case 'AC':
        return AppColors.acBadge;
      case 'DC':
        return AppColors.dcBadge;
      case 'Fast Charge':
        return AppColors.fastChargeBadge;
      default:
        return AppColors.primary;
    }
  }

  static List<Marker> buildMarkers({
    required List<EvSpotModel> spots,
    required Function(EvSpotModel) onTap,
  }) {
    return spots.map((spot) {
      final color = colorForType(spot.chargerType);
      return Marker(
        point: LatLng(spot.latitude, spot.longitude),
        width: 32,
        height: 38,
        child: GestureDetector(
          onTap: () => onTap(spot),
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(100),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.ev_station_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              // Marker pin tip
              CustomPaint(
                size: const Size(8, 4),
                painter: _PinTipPainter(color),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter(this.color);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
