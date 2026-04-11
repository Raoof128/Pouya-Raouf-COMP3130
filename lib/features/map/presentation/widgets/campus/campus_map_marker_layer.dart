import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/services/campus_projection.dart';

/// Renders building markers on the campus map.
class CampusMapMarkerLayer extends StatelessWidget {
  const CampusMapMarkerLayer({
    super.key,
    required this.visibleBuildings,
    required this.selectedBuilding,
    required this.projection,
    required this.onSelectBuilding,
  });

  final List<Building> visibleBuildings;
  final Building? selectedBuilding;
  final CampusProjection projection;
  final ValueChanged<Building> onSelectBuilding;

  static const double _defaultMarkerWidth = 110.0;
  static const double _selectedMarkerHeight = 74.0;
  static const double _defaultMarkerHeight = 54.0;

  @override
  Widget build(BuildContext context) {
    if (visibleBuildings.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedId = selectedBuilding?.id;

    return MarkerLayer(
      markers: visibleBuildings.map((building) {
        final isSelected = selectedId == building.id;
        return Marker(
          point: resolveBuildingPoint(building, projection),
          width: _defaultMarkerWidth,
          height: isSelected ? _selectedMarkerHeight : _defaultMarkerHeight,
          alignment: Alignment.bottomCenter,
          child: CampusBuildingMarker(
            building: building,
            isSelected: isSelected,
            onTap: () => onSelectBuilding(building),
          ),
        );
      }).toList(),
    );
  }
}

/// Resolves the map-space point for a building, preferring campus pixel
/// coordinates when available and falling back to GPS projection.
latlong.LatLng resolveBuildingPoint(
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

/// A single building marker chip with a label and anchor dot.
class CampusBuildingMarker extends StatelessWidget {
  const CampusBuildingMarker({
    super.key,
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
    final borderColor = isSelected
        ? MqColors.red
        : MqColors.charcoal900.withValues(alpha: 0.12);

    return Semantics(
      button: true,
      label: building.name,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: MqSpacing.space3,
                vertical: MqSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: MqColors.charcoal900.withValues(alpha: 0.14),
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
