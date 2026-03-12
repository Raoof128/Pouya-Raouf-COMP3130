import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/features/map/data/datasources/map_assets_source.dart';
import 'package:mq_navigation/features/map/data/mappers/campus_projection_impl.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/campus_projection.dart';
import 'package:mq_navigation/features/map/presentation/widgets/campus/campus_map_location_layer.dart';
import 'package:mq_navigation/features/map/presentation/widgets/campus/campus_map_marker_layer.dart';
import 'package:mq_navigation/features/map/presentation/widgets/campus/campus_map_overlay.dart';
import 'package:mq_navigation/features/map/presentation/widgets/campus/campus_map_route_layer.dart';
import 'package:mq_navigation/features/map/presentation/widgets/campus/campus_overlay_layers.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

/// The primary `flutter_map` renderer for the 2D illustrated campus map.
///
/// Orchestrates several specialized layers (overlays, markers, routes) and
/// handles the lifecycle of the map projection. It blocks rendering until
/// [CampusOverlayMeta] is loaded from assets, ensuring the map is always
/// correctly calibrated to real-world GPS coordinates.
class CampusMapView extends ConsumerStatefulWidget {
  const CampusMapView({
    super.key,
    required this.searchResults,
    required this.searchQuery,
    required this.selectedBuilding,
    required this.route,
    required this.currentLocation,
    required this.isNavigating,
    required this.onSelectBuilding,
    this.activeOverlayIds = const {},
  });

  final List<Building> searchResults;
  final String searchQuery;
  final Building? selectedBuilding;
  final MapRoute? route;
  final LocationSample? currentLocation;
  final bool isNavigating;
  final ValueChanged<Building> onSelectBuilding;
  final Set<String> activeOverlayIds;

  @override
  ConsumerState<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends ConsumerState<CampusMapView> {
  final MapController _controller = MapController();
  late final Future<CampusOverlayMeta> _metaFuture;
  CampusProjection? _projection;
  @override
  void initState() {
    super.initState();
    _metaFuture = ref.read(mapAssetsSourceProvider).loadCampusOverlayMeta();
    _metaFuture.then((meta) {
      if (!mounted) {
        return;
      }
      _projection = CampusProjectionImpl(meta);
    });
  }

  @override
  void didUpdateWidget(covariant CampusMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final projection = _projection;
    if (projection == null) {
      return;
    }

    // Follow user during active navigation
    if (widget.isNavigating) {
      final newLocation = widget.currentLocation;
      final oldLocation = oldWidget.currentLocation;
      if (newLocation != null &&
          (oldLocation == null ||
              newLocation.latitude != oldLocation.latitude ||
              newLocation.longitude != oldLocation.longitude)) {
        _moveMap(
          projection.gpsToMapPoint(
            latitude: newLocation.latitude,
            longitude: newLocation.longitude,
          ),
        );
        return;
      }
    }

    if (widget.selectedBuilding != null &&
        widget.selectedBuilding?.id != oldWidget.selectedBuilding?.id) {
      _moveMap(
        resolveBuildingPoint(widget.selectedBuilding!, projection),
        zoom: 1,
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CampusOverlayMeta>(
      future: _metaFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final l10n = AppLocalizations.of(context)!;
          return MqCard(
            child: Text(
              l10n.campusOverlayUnavailable,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final meta = snapshot.data;
        if (meta == null) {
          return const Center(
            child: CircularProgressIndicator(color: MqColors.red),
          );
        }

        final projection = _projection ?? CampusProjectionImpl(meta);
        _projection = projection;
        final visibleBuildings = resolveVisibleBuildings(
          searchResults: widget.searchResults,
          searchQuery: widget.searchQuery,
          selectedBuilding: widget.selectedBuilding,
          requireCampusCoordinates: true,
        );
        final rawRoutePoints = widget.route == null
            ? const <LocationSample>[]
            : resolveRoutePoints(widget.route!);
        final routePoints = rawRoutePoints
            .map(
              (point) => projection.gpsToMapPoint(
                latitude: point.latitude,
                longitude: point.longitude,
              ),
            )
            .toList();
        final bounds = LatLngBounds(
          latlong.LatLng(meta.mapSouth, meta.mapWest),
          latlong.LatLng(meta.mapNorth, meta.mapEast),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [MqColors.charcoal950, MqColors.charcoal850]
                  : const [MqColors.sand100, MqColors.alabaster],
            ),
          ),
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              crs: const CrsSimple(),
              initialCenter: latlong.LatLng(
                meta.centerLatitude,
                meta.centerLongitude,
              ),
              initialZoom: 0,
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                // Extra top/bottom padding for the overlaid glass controls
                // (search bar + toggle ~120px top, side controls ~60px bottom).
                padding: EdgeInsets.fromLTRB(
                  meta.initialFitPadding,
                  meta.initialFitPadding + 100,
                  meta.initialFitPadding,
                  meta.initialFitPadding + 40,
                ),
                maxZoom: meta.maxZoom,
              ),
              minZoom: -2,
              maxZoom: meta.maxZoom,
              cameraConstraint: const CameraConstraint.unconstrained(),
              onMapReady: () => _handleMapReady(meta, projection),
            ),
            children: [
              CampusMapOverlay(meta: meta),
              CampusOverlayLayers(
                activeOverlayIds: widget.activeOverlayIds,
                meta: meta,
              ),
              if (routePoints.isNotEmpty)
                CampusMapRouteLayer(
                  route: widget.route!,
                  routePoints: routePoints,
                  rawRoutePoints: rawRoutePoints,
                  isNavigating: widget.isNavigating,
                  currentLocation: widget.currentLocation,
                ),
              CampusMapMarkerLayer(
                visibleBuildings: visibleBuildings,
                selectedBuilding: widget.selectedBuilding,
                projection: projection,
                onSelectBuilding: widget.onSelectBuilding,
              ),
              CampusMapLocationLayer(
                currentLocation: widget.currentLocation,
                projection: projection,
                route: widget.route,
                routePoints: routePoints,
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMapReady(CampusOverlayMeta meta, CampusProjection projection) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (widget.selectedBuilding case final selectedBuilding?) {
        _moveMap(resolveBuildingPoint(selectedBuilding, projection), zoom: 1);
        return;
      }

      if (widget.currentLocation case final currentLocation?) {
        _moveMap(
          projection.gpsToMapPoint(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude,
          ),
        );
      }
    });
  }

  void _moveMap(latlong.LatLng point, {double? zoom}) {
    _controller.move(point, zoom ?? _currentZoom(fallback: 0));
  }

  double _currentZoom({required double fallback}) {
    try {
      return _controller.camera.zoom;
    } on StateError {
      return fallback;
    }
  }
}
