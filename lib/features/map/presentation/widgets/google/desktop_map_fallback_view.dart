import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/data/services/offline_maps_service.dart';
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
class DesktopMapFallbackView extends ConsumerStatefulWidget {
  const DesktopMapFallbackView({
    super.key,
    required this.searchResults,
    required this.searchQuery,
    required this.selectedBuilding,
    required this.route,
    required this.currentLocation,
    required this.locationCenterRequestToken,
    required this.isNavigating,
    required this.onSelectBuilding,
  });

  final List<Building> searchResults;
  final String searchQuery;
  final Building? selectedBuilding;
  final MapRoute? route;
  final LocationSample? currentLocation;
  final int locationCenterRequestToken;
  final bool isNavigating;
  final ValueChanged<Building> onSelectBuilding;

  @override
  ConsumerState<DesktopMapFallbackView> createState() =>
      _DesktopMapFallbackViewState();
}

class _DesktopMapFallbackViewState
    extends ConsumerState<DesktopMapFallbackView> {
  final MapController _controller = MapController();
  late final TileProvider _tileProvider;
  bool _hasFitRouteBounds = false;
  DateTime? _lastNavigationCameraUpdateAt;
  LocationSample? _lastNavigationCameraLocation;

  // 18 Wally's Walk entrance — kept in sync with MapController._campusFallback
  // and GoogleMapView's initial camera position so all renderers open on the
  // same point when no GPS fix is available.
  static const _campusCenter = latlong.LatLng(-33.77388, 151.11275);
  static const _initialZoom = 15.5;
  // Mirrors GoogleMapView so all renderers behave identically.
  static const double _locateZoom = 17;
  static const double _navigationFollowZoom = 18;
  static const Duration _navigationCameraMinInterval = Duration(
    milliseconds: 900,
  );
  static const double _navigationCameraMinMoveMetres = 3;

  @override
  void initState() {
    super.initState();
    _tileProvider = ref.read(offlineMapsServiceProvider).tileProvider();
  }

  @override
  void didUpdateWidget(covariant DesktopMapFallbackView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.locationCenterRequestToken !=
        oldWidget.locationCenterRequestToken) {
      final location = widget.currentLocation;
      if (location != null) {
        // Always move with an explicit zoom so a repeated locate-me press
        // (camera already on the user's coordinate) still animates.
        _controller.move(
          latlong.LatLng(location.latitude, location.longitude),
          _locateZoom,
        );
      }
      return;
    }

    // Follow user during active navigation. Snap to a navigation-grade zoom
    // on the first tick so the user can tell navigation is live.
    if (widget.isNavigating) {
      final newLocation = widget.currentLocation;
      final oldLocation = oldWidget.currentLocation;
      final justStartedNavigating =
          widget.isNavigating && !oldWidget.isNavigating;
      final movedSinceLastTick =
          newLocation != null &&
          (oldLocation == null ||
              newLocation.latitude != oldLocation.latitude ||
              newLocation.longitude != oldLocation.longitude);
      if (newLocation != null &&
          (justStartedNavigating || movedSinceLastTick) &&
          _shouldFollowNavigationCamera(
            location: newLocation,
            force: justStartedNavigating,
          )) {
        _controller.move(
          latlong.LatLng(newLocation.latitude, newLocation.longitude),
          _navigationFollowZoom,
        );
        _lastNavigationCameraUpdateAt = DateTime.now();
        _lastNavigationCameraLocation = newLocation;
        return;
      }
    } else if (oldWidget.isNavigating && !widget.isNavigating) {
      _lastNavigationCameraUpdateAt = null;
      _lastNavigationCameraLocation = null;
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
  }

  @override
  Widget build(BuildContext context) {
    final visibleBuildings = resolveVisibleBuildings(
      searchResults: widget.searchResults,
      searchQuery: widget.searchQuery,
      selectedBuilding: widget.selectedBuilding,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        _buildFlutterMap(isDark, visibleBuildings),
        // On web the Google Maps renderer falls back to OSM whenever no
        // Maps JS API key is configured. Surface that so users understand
        // why tiles look different from Google Maps rather than thinking
        // the app is broken.
        if (kIsWeb)
          const Positioned(
            left: MqSpacing.space3,
            bottom: MqSpacing.space3,
            child: _OsmFallbackBadge(),
          ),
      ],
    );
  }

  FlutterMap _buildFlutterMap(bool isDark, List<Building> visibleBuildings) {
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
          subdomains: isDark ? ['a', 'b', 'c', 'd'] : [],
          userAgentPackageName: 'io.mqnavigation.mq_navigation',
          retinaMode: true,
          tileProvider: _tileProvider,
        ),
        // Route polylines
        if (widget.route != null) _buildRouteLayer(),
        // Building markers
        MarkerLayer(
          markers: [
            for (final building in visibleBuildings)
              if (resolveBuildingGeographicTarget(building) case final target?)
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
                            ? MqColors.red
                            : MqColors.info,
                        shadows: const [
                          Shadow(
                            blurRadius: 4,
                            color: MqColors.black38,
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
                    color: MqColors.success,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: MqColors.black38,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
            // User location marker
            if (widget.currentLocation case final location?)
              Marker(
                point: latlong.LatLng(location.latitude, location.longitude),
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
                        color: MqColors.black26,
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
        ? StrokePattern.dashed(segments: [12, 8])
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
            color: MqColors.slate400,
          ),
        );
      }

      final remainingPoints = splitIdx > 0
          ? allPoints.sublist(splitIdx)
          : allPoints;
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
        _moveToLatLng(latlong.LatLng(location.latitude, location.longitude));
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
        padding: const EdgeInsets.all(MqSpacing.space16),
      ),
    );
  }

  Color _colorFor(TravelMode travelMode) {
    return switch (travelMode) {
      TravelMode.walk => MqColors.mapRouteActive,
      TravelMode.drive => MqColors.charcoal600,
      TravelMode.bike => MqColors.success,
      TravelMode.transit => MqColors.warning,
    };
  }

  bool _shouldFollowNavigationCamera({
    required LocationSample location,
    required bool force,
  }) {
    if (force) {
      return true;
    }
    final now = DateTime.now();
    final lastAt = _lastNavigationCameraUpdateAt;
    if (lastAt != null &&
        now.difference(lastAt) < _navigationCameraMinInterval) {
      return false;
    }
    final lastLocation = _lastNavigationCameraLocation;
    if (lastLocation == null) {
      return true;
    }
    final movedMetres = haversineMetres(
      lat1: lastLocation.latitude,
      lng1: lastLocation.longitude,
      lat2: location.latitude,
      lng2: location.longitude,
    );
    return movedMetres >= _navigationCameraMinMoveMetres;
  }
}

class _OsmFallbackBadge extends StatelessWidget {
  const _OsmFallbackBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? MqColors.charcoal800.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MqSpacing.space3,
          vertical: MqSpacing.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 14, color: MqColors.info),
            const SizedBox(width: MqSpacing.space2),
            Text(
              l10n.mapOsmFallbackBadge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.white : MqColors.contentSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
