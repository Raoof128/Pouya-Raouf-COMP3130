import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/data/datasources/map_assets_source.dart';
import 'package:mq_navigation/features/map/data/mappers/campus_projection_impl.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/campus_projection.dart';
import 'package:mq_navigation/features/map/domain/services/geo_utils.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

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
  });

  final List<Building> searchResults;
  final String searchQuery;
  final Building? selectedBuilding;
  final MapRoute? route;
  final LocationSample? currentLocation;
  final bool isNavigating;
  final ValueChanged<Building> onSelectBuilding;

  @override
  ConsumerState<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends ConsumerState<CampusMapView> {
  final MapController _controller = MapController();
  late final Future<CampusOverlayMeta> _metaFuture;
  CampusProjection? _projection;
  double? _resolvedMinZoom;

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
        _resolveBuildingPoint(widget.selectedBuilding!, projection),
        zoom: 1,
      );
      return;
    }

    final newLocation = widget.currentLocation;
    final oldLocation = oldWidget.currentLocation;
    if (!widget.isNavigating &&
        newLocation != null &&
        (oldLocation == null ||
            newLocation.latitude != oldLocation.latitude ||
            newLocation.longitude != oldLocation.longitude)) {
      _moveMap(
        projection.gpsToMapPoint(
          latitude: newLocation.latitude,
          longitude: newLocation.longitude,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CampusOverlayMeta>(
      future: _metaFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MqCard(
            child: Text(
              'Campus overlay metadata is unavailable.',
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
                padding: EdgeInsets.all(meta.initialFitPadding),
                maxZoom: meta.maxZoom,
              ),
              minZoom: _resolvedMinZoom,
              maxZoom: meta.maxZoom,
              cameraConstraint: CameraConstraint.contain(bounds: bounds),
              onMapReady: () => _handleMapReady(meta, projection),
            ),
            children: [
              OverlayImageLayer(
                overlayImages: [
                  OverlayImage(
                    bounds: bounds,
                    imageProvider: AssetImage(meta.imageAsset),
                  ),
                ],
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: _buildCampusPolylines(routePoints, rawRoutePoints),
                ),
              MarkerLayer(
                markers: [
                  ...visibleBuildings.map((building) {
                    return Marker(
                      point: _resolveBuildingPoint(building, projection),
                      width: 110,
                      height: widget.selectedBuilding?.id == building.id
                          ? 74
                          : 54,
                      alignment: Alignment.bottomCenter,
                      child: _CampusBuildingMarker(
                        building: building,
                        isSelected: widget.selectedBuilding?.id == building.id,
                        onTap: () => widget.onSelectBuilding(building),
                      ),
                    );
                  }),
                  if (widget.currentLocation case final currentLocation?)
                    Marker(
                      point: projection.gpsToMapPoint(
                        latitude: currentLocation.latitude,
                        longitude: currentLocation.longitude,
                      ),
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MqColors.mapUserLocation,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: MqColors.mapUserLocation.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  latlong.LatLng _resolveBuildingPoint(
    Building building,
    CampusProjection projection,
  ) {
    final campusPoint = building.campusPoint;
    if (campusPoint != null) {
      return projection.buildingPixelToMapPoint(campusPoint);
    }

    return projection.gpsToMapPoint(
      latitude: building.routingLatitude ?? building.latitude!,
      longitude: building.routingLongitude ?? building.longitude!,
    );
  }

  void _handleMapReady(CampusOverlayMeta meta, CampusProjection projection) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final nextMinZoom = _currentZoom(fallback: 0) - meta.minZoomOffset;
      if (_resolvedMinZoom == null ||
          (_resolvedMinZoom! - nextMinZoom).abs() > 0.01) {
        setState(() {
          _resolvedMinZoom = nextMinZoom;
        });
      }

      if (widget.selectedBuilding case final selectedBuilding?) {
        _moveMap(_resolveBuildingPoint(selectedBuilding, projection), zoom: 1);
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

  List<Polyline> _buildCampusPolylines(
    List<latlong.LatLng> mapPoints,
    List<LocationSample> rawPoints,
  ) {
    final routeColor = _colorFor(widget.route!.travelMode);
    final polylines = <Polyline>[];

    if (widget.isNavigating &&
        widget.currentLocation != null &&
        rawPoints.length > 1) {
      final splitIdx = findClosestPointIndex(
        rawPoints,
        widget.currentLocation!,
      );

      if (splitIdx > 0) {
        polylines.add(
          Polyline(
            points: mapPoints.sublist(0, splitIdx + 1),
            strokeWidth: 5,
            color: const Color(0xFF94a3b8),
            borderStrokeWidth: 2,
            borderColor: Colors.white.withValues(alpha: 0.25),
          ),
        );
      }

      final remaining = splitIdx > 0 ? mapPoints.sublist(splitIdx) : mapPoints;
      polylines.add(
        Polyline(
          points: remaining,
          strokeWidth: 5,
          color: routeColor,
          borderStrokeWidth: 2,
          borderColor: Colors.white.withValues(alpha: 0.45),
        ),
      );
    } else {
      polylines.add(
        Polyline(
          points: mapPoints,
          strokeWidth: 5,
          color: routeColor,
          borderStrokeWidth: 2,
          borderColor: Colors.white.withValues(alpha: 0.45),
        ),
      );
    }

    return polylines;
  }

  Color _colorFor(TravelMode travelMode) {
    return switch (travelMode) {
      TravelMode.walk => MqColors.red,
      TravelMode.drive => const Color(0xFF6C757D),
      TravelMode.bike => const Color(0xFF2E8B57),
      TravelMode.transit => const Color(0xFFF57C00),
    };
  }
}

class _CampusBuildingMarker extends StatelessWidget {
  const _CampusBuildingMarker({
    required this.building,
    required this.isSelected,
    required this.onTap,
  });

  final Building building;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected ? MqColors.red : Colors.white;
    final foregroundColor = isSelected ? Colors.white : MqColors.charcoal900;

    return Semantics(
      button: true,
      label: building.name,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MqSpacing.space3,
                vertical: MqSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
                border: Border.all(
                  color: isSelected
                      ? MqColors.red
                      : MqColors.charcoal900.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                building.code,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
