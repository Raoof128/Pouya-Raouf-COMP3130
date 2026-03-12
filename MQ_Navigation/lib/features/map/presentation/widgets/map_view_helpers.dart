import 'package:mq_navigation/features/map/domain/entities/building.dart';

List<Building> resolveVisibleBuildings({
  required List<Building> searchResults,
  required String searchQuery,
  required Building? selectedBuilding,
}) {
  if (selectedBuilding != null) {
    final visibleBuildings = <Building>[
      if (selectedBuilding.hasGeographicCoordinates) selectedBuilding,
    ];
    if (searchQuery.trim().length >= 2) {
      visibleBuildings.addAll(
        searchResults.where(
          (building) =>
              building.hasGeographicCoordinates &&
              building.id != selectedBuilding.id,
        ),
      );
    }
    return visibleBuildings;
  }

  if (searchQuery.trim().length >= 2) {
    return searchResults
        .where((building) => building.hasGeographicCoordinates)
        .toList();
  }

  return const <Building>[];
}
