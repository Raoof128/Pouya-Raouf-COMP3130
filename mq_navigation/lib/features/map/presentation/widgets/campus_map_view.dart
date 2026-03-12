import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/map_polyline_codec.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';

class CampusMapView extends StatefulWidget {
  const CampusMapView({
    super.key,
    required this.searchResults,
    required this.searchQuery,
    required this.selectedBuilding,
    required this.route,
    required this.currentLocation,
    required this.onSelectBuilding,
  });

  final List<Building> searchResults;
  final String searchQuery;
  final Building? selectedBuilding;
  final MapRoute? route;
  final LocationSample? currentLocation;
  final ValueChanged<Building> onSelectBuilding;

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  final MapController _controller = MapController();

  @override
  void didUpdateWidget(covariant CampusMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate to a newly selected building.
    if (widget.selectedBuilding != null &&
        widget.selectedBuilding?.id != oldWidget.selectedBuilding?.id) {
      final target = widget.selectedBuilding!;
      final latitude = target.routingLatitude;
      final longitude = target.routingLongitude;
      if (latitude != null && longitude != null) {
        _controller.move(latlong.LatLng(latitude, longitude), 17);
      }
      return;
    }

    final newLoc = widget.currentLocation;
    final oldLoc = oldWidget.currentLocation;
    if (newLoc != null &&
        (oldLoc == null ||
            newLoc.latitude != oldLoc.latitude ||
            newLoc.longitude != oldLoc.longitude)) {
      _controller.move(latlong.LatLng(newLoc.latitude, newLoc.longitude), 17);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleBuildings = resolveVisibleBuildings(
      searchResults: widget.searchResults,
      searchQuery: widget.searchQuery,
      selectedBuilding: widget.selectedBuilding,
    );
    final routePoints = widget.route == null
        ? const <latlong.LatLng>[]
        : MapPolylineCodec.decode(widget.route!.encodedPolyline)
              .map((point) => latlong.LatLng(point.latitude, point.longitude))
              .toList();

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
        options: const MapOptions(
          initialCenter: latlong.LatLng(-33.7738, 151.1130),
          initialZoom: 15.9,
          minZoom: 14.2,
          maxZoom: 18.8,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'io.mqnavigation.mq_navigation',
          ),
          if (routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 5,
                  color: _colorFor(widget.route!.travelMode),
                  borderStrokeWidth: 2,
                  borderColor: Colors.white.withValues(alpha: 0.45),
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              ...visibleBuildings.map((building) {
                final latitude = building.latitude!;
                final longitude = building.longitude!;
                return Marker(
                  point: latlong.LatLng(latitude, longitude),
                  width: 110,
                  height: widget.selectedBuilding?.id == building.id ? 74 : 54,
                  alignment: Alignment.topCenter,
                  child: _CampusBuildingMarker(
                    building: building,
                    isSelected: widget.selectedBuilding?.id == building.id,
                    onTap: () => widget.onSelectBuilding(building),
                  ),
                );
              }),
              if (widget.currentLocation case final currentLocation?)
                Marker(
                  point: latlong.LatLng(
                    currentLocation.latitude,
                    currentLocation.longitude,
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
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
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
                building.id,
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
