import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/geo_utils.dart';

/// Renders the route polyline on the campus map.
///
/// When navigating, the traversed portion is drawn in grey while the
/// remaining portion keeps the travel-mode colour.
class CampusMapRouteLayer extends StatelessWidget {
  const CampusMapRouteLayer({
    super.key,
    required this.route,
    required this.routePoints,
    required this.rawRoutePoints,
    required this.isNavigating,
    required this.currentLocation,
  });

  final MapRoute route;
  final List<latlong.LatLng> routePoints;
  final List<LocationSample> rawRoutePoints;
  final bool isNavigating;
  final LocationSample? currentLocation;

  static const Color _traversedColor = MqColors.slate400; // was 0xFF94a3b8
  static const double _strokeWidth = 5.0;
  static const double _borderWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    // Optimization: Only calculate polylines if points exist.
    // The computation of 'splitIdx' is O(N) where N is route points.
    // For typical campus routes (N < 200), this is negligible on UI thread.
    // If routes become massive, move this to a provider or isolate.
    return PolylineLayer(
      polylines: _buildCampusPolylines(routePoints, rawRoutePoints),
    );
  }

  List<Polyline> _buildCampusPolylines(
    List<latlong.LatLng> mapPoints,
    List<LocationSample> rawPoints,
  ) {
    final routeColor = _colorFor(route.travelMode);
    final isWalking = route.travelMode == TravelMode.walk;
    final StrokePattern pattern = isWalking
        ? StrokePattern.dashed(segments: const [12, 8])
        : const StrokePattern.solid();

    // If not navigating or no location, return single full polyline
    if (!isNavigating || currentLocation == null || rawPoints.length <= 1) {
      return [
        Polyline(
          points: mapPoints,
          strokeWidth: _strokeWidth,
          color: routeColor,
          borderStrokeWidth: _borderWidth,
          borderColor: Colors.white.withValues(alpha: 0.45),
          pattern: pattern,
        ),
      ];
    }

    final splitIdx = findClosestPointIndex(rawPoints, currentLocation!);
    final polylines = <Polyline>[];

    // Traversed segment (Grey)
    if (splitIdx > 0) {
      polylines.add(
        Polyline(
          points: mapPoints.sublist(0, splitIdx + 1),
          strokeWidth: _strokeWidth,
          color: _traversedColor,
          borderStrokeWidth: _borderWidth,
          borderColor: Colors.white.withValues(alpha: 0.25),
          pattern: pattern,
        ),
      );
    }

    // Remaining segment (Colored)
    final remaining = splitIdx > 0 ? mapPoints.sublist(splitIdx) : mapPoints;
    if (remaining.isNotEmpty) {
      polylines.add(
        Polyline(
          points: remaining,
          strokeWidth: _strokeWidth,
          color: routeColor,
          borderStrokeWidth: _borderWidth,
          borderColor: Colors.white.withValues(alpha: 0.45),
          pattern: pattern,
        ),
      );
    }

    return polylines;
  }

  static Color _colorFor(TravelMode travelMode) {
    return switch (travelMode) {
      TravelMode.walk => MqColors.red,
      TravelMode.drive => MqColors.charcoal600, // was 0xFF6C757D
      TravelMode.bike => MqColors.success, // was 0xFF2E8B57 (approx)
      TravelMode.transit => MqColors.warning, // was 0xFFF57C00 (orange-ish)
    };
  }
}
