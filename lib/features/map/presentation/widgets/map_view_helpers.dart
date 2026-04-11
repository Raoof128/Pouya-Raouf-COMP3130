import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/map_polyline_codec.dart';

List<Building> resolveVisibleBuildings({
  required List<Building> searchResults,
  required String searchQuery,
  required Building? selectedBuilding,
  bool requireCampusCoordinates = false,
}) {
  bool isRenderable(Building building) {
    return requireCampusCoordinates
        ? building.hasCampusCoordinates
        : building.hasGeographicCoordinates;
  }

  if (selectedBuilding != null) {
    final visibleBuildings = <Building>[
      if (isRenderable(selectedBuilding)) selectedBuilding,
    ];
    if (searchQuery.trim().isNotEmpty) {
      visibleBuildings.addAll(
        searchResults.where(
          (building) =>
              isRenderable(building) && building.id != selectedBuilding.id,
        ),
      );
    }
    return visibleBuildings;
  }

  if (searchQuery.trim().isNotEmpty) {
    return searchResults.where(isRenderable).toList();
  }

  return const <Building>[];
}

List<LocationSample> resolveRoutePoints(MapRoute route) {
  if (route.points.isNotEmpty) {
    return route.points;
  }
  if (route.encodedPolyline.isEmpty) {
    return const <LocationSample>[];
  }
  return MapPolylineCodec.decode(route.encodedPolyline)
      .map(
        (point) => LocationSample(
          latitude: point.latitude,
          longitude: point.longitude,
        ),
      )
      .toList();
}

LocationSample? resolveBuildingGeographicTarget(Building building) {
  final latitude = building.routingLatitude;
  final longitude = building.routingLongitude;
  if (latitude == null || longitude == null) {
    return null;
  }

  return LocationSample(latitude: latitude, longitude: longitude);
}
