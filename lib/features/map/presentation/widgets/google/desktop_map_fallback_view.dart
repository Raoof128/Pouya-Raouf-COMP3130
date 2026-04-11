
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/geo_utils.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';

/// Fallback map view for desktop platforms (macOS, Linux, Windows) where
/// `google_maps_flutter` is not supported.
///
/// Uses `flutter_map` with OpenStreetMap tiles to provide a real interactive
/// map experience. Supports building markers, route polylines, user location,
/// and camera animations just like the native Google Maps renderer.
class DesktopMapFallbackView extends StatefulWidget {
  const DesktopMapFallbackView({
    super.key,
    required this.searchResults,
    required this.searchQuery,
    required this.selectedBuilding,
    required this.route,
    required this.currentLocation,
    required this.isNavigating,
    required this.onSelectBuilding,
  });

  final List<Building> searchResults;
  final String searchQuery;
  final Building? selectedBuilding;
  final MapRoute? route;
  final LocationSample? currentLocation;
  final bool isNavigating;
  final ValueChanged<Building> onSelectBuilding;

  @override
  State<DesktopMapFallbackView> createState() =>
      _DesktopMapFallbackViewState();
}

class _DesktopMapFallbackViewState extends State<DesktopMapFallbackView> {
  final MapController _controller = MapController();
  bool _hasFitRouteBounds = false;

  static const _campusCenter = latlong.LatLng(-33.7738, 151.1130);
  static const _initialZoom = 15.5;

  @override
  void didUpdateWidget(covariant DesktopMapFallbackView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Follow user during active navigation
    if (widget.isNavigating) {
      final newLocation = widget.currentLocation;
      final oldLocation = oldWidget.currentLocation;
      if (newLocation != null &&
          (oldLocation == null ||
              newLocation.latitude != oldLocation.latitude ||
              newLocation.longitude != oldLocation.longitude)) {
        _moveToLatLng(
          latlong.LatLng(newLocation.latitude, newLocation.longitude),
        );
        return;
      }
    }

    // Focus on newly selected building
    if (widget.selectedBuilding != null &&
        widget.selectedBuilding?.id != oldWidget.selectedBuilding?.id) {
      _hasFitRouteBounds = false;
      _focusBuilding(widget.selectedBuilding!);
      return;
    }

    // Fit route bounds when route first appears
    if (widget.route != null &&
        oldWidget.route == null &&
        !_hasFitRouteBounds) {
      _fitRouteBounds();
      return;
    }

    // Focus on location changes when not navigating
    final newLocation = widget.currentLocation;
    final oldLocation = oldWidget.currentLocation;
    if (!widget.isNavigating &&
        newLocation != null &&
        (oldLocation == null ||
            newLocation.latitude != oldLocation.latitude ||
            newLocation.longitude != oldLocation.longitude)) {
      _moveToLatLng(
        latlong.LatLng(newLocation.latitude, newLocation.longitude),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleBuildings = resolveVisibleBuildings(
      searchResults: widget.searchResults,
      searchQuery: widget.searchQuery,
      selectedBuilding: widget.selectedBuilding,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _campusCenter,
        initialZoom: _initialZoom,
        minZoom: 10,
        maxZoom: 19,
        onMapReady: _syncCameraToState,
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
          userAgentPackageName: 'io.mqnavigation.mq_navigation',
          retinaMode: true,
        ),
        // Route polylines
        if (widget.route != null) _buildRouteLayer(),
        // Building markers
        MarkerLayer(
          markers: [
            for (final building in visibleBuildings)
              if (resolveBuildingGeographicTarget(building)
                  case final target?)
                Marker(
                  point: latlong.LatLng(target.latitude, target.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => widget.onSelectBuilding(building),
                    child: Tooltip(
                      message: '${building.name} (${building.code})',
                      child: Icon(
                        Icons.location_on,
                        size: 36,
                        color: widget.selectedBuilding?.id == building.id
                            ? Colors.red
                            : MqColors.info,
                        shadows: const [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black38,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            // Origin marker at route start
            if (widget.route != null)
              if (resolveRoutePoints(widget.route!).firstOrNull
                  case final origin?)
                Marker(
                  point: latlong.LatLng(origin.latitude, origin.longitude),
                  width: 30,
                  height: 30,
                  child: const Icon(
                    Icons.circle,
                    size: 16,
                    color: Colors.green,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black38,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
            // User location marker
            if (widget.currentLocation case final location?)
              Marker(
                point:
                    latlong.LatLng(location.latitude, location.longitude),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: MqColors.mapUserLocation.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black26,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  width: 16,
                  height: 16,
                ),
              ),
          ],
        ),
      ],
    );
  }

  PolylineLayer _buildRouteLayer() {
    final allPoints = resolveRoutePoints(widget.route!);
    if (allPoints.isEmpty) {
      return const PolylineLayer(polylines: []);
    }

    final isWalking = widget.route!.travelMode == TravelMode.walk;
    final routeColor = _colorFor(widget.route!.travelMode);
    final polylines = <Polyline>[];

    final StrokePattern walkingPattern = isWalking
        ? StrokePattern.dashed(segments: const [12, 8])
        : const StrokePattern.solid();

    if (widget.isNavigating && widget.currentLocation != null) {
      final splitIdx = findClosestPointIndex(
        allPoints,
        widget.currentLocation!,
      );

      if (splitIdx > 0) {
        final walkedPoints = allPoints.sublist(0, splitIdx + 1);
        polylines.add(
          Polyline(
            points: walkedPoints
                .map((p) => latlong.LatLng(p.latitude, p.longitude))
                .toList(),
            strokeWidth: 5,
            color: const Color(0xFF94a3b8),
          ),
        );
      }

      final remainingPoints =
          splitIdx > 0 ? allPoints.sublist(splitIdx) : allPoints;
      polylines.add(
        Polyline(
          points: remainingPoints
              .map((p) => latlong.LatLng(p.latitude, p.longitude))
              .toList(),
          strokeWidth: 5,
          color: routeColor,
          pattern: walkingPattern,
        ),
      );
    } else {
      polylines.add(
        Polyline(
          points: allPoints
              .map((p) => latlong.LatLng(p.latitude, p.longitude))
              .toList(),
          strokeWidth: 5,
          color: routeColor,
          pattern: walkingPattern,
        ),
      );
    }

    return PolylineLayer(polylines: polylines);
  }

  void _syncCameraToState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.selectedBuilding case final building?) {
        _focusBuilding(building);
        return;
      }

      if (widget.currentLocation case final location?) {
        _moveToLatLng(
          latlong.LatLng(location.latitude, location.longitude),
        );
      }
    });
  }

  void _focusBuilding(Building building) {
    final target = resolveBuildingGeographicTarget(building);
    if (target == null) return;
    _controller.move(latlong.LatLng(target.latitude, target.longitude), 17);
  }

  void _moveToLatLng(latlong.LatLng point) {
    try {
      _controller.move(point, _controller.camera.zoom);
    } on StateError {
      _controller.move(point, _initialZoom);
    }
  }

  void _fitRouteBounds() {
    final points = widget.route == null
        ? const <LocationSample>[]
        : resolveRoutePoints(widget.route!);
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    if (widget.currentLocation case final loc?) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    _hasFitRouteBounds = true;
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          latlong.LatLng(minLat, minLng),
          latlong.LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  Color _colorFor(TravelMode travelMode) {
    return switch (travelMode) {
      TravelMode.walk => const Color(0xFF4285F4),
      TravelMode.drive => const Color(0xFF6C757D),
      TravelMode.bike => const Color(0xFF2E8B57),
      TravelMode.transit => const Color(0xFFF57C00),
    };
  }
}

