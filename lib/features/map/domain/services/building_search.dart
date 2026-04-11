import 'package:mq_navigation/features/map/domain/entities/building.dart';

typedef RankedBuilding = ({Building building, int score});

String normalizeMapSearch(String value) {
  return value.toLowerCase().trim();
}

List<Building> searchCampusBuildings(List<Building> buildings, String query) {
  final normalizedQuery = normalizeMapSearch(query);
  if (normalizedQuery.isEmpty) {
    return [...buildings]..sort((left, right) => left.id.compareTo(right.id));
  }

  final ranked =
      buildings.map((building) {
        return (
          building: building,
          score: scoreBuildingMatch(building, normalizedQuery),
        );
      }).toList()..sort((left, right) {
        final scoreCompare = right.score.compareTo(left.score);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        return left.building.id.compareTo(right.building.id);
      });

  return ranked.map((entry) => entry.building).toList();
}

/// Scores a building's relevance to a search query.
///
/// Returns a score from 0-120:
/// - 120: Exact ID match
/// - 110: Exact alias/token match
/// - 100: Exact field match (name, description, etc.)
/// - 90: Starts with ID
/// - 80: Starts with alias
/// - 70: Starts with any field
/// - 50: Contains query in any field
/// - 0: No match
int scoreBuildingMatch(Building building, String normalizedQuery) {
  final searchableFields = <String>[
    building.id,
    building.code,
    building.name,
    if (building.description != null) building.description!,
    if (building.gridRef != null) building.gridRef!,
    if (building.address != null) building.address!,
    ...building.aliases,
    ...building.searchTokens,
    ...building.tags,
  ].map(normalizeMapSearch).toList();

  final aliases = <String>[
    ...building.aliases,
    ...building.searchTokens,
  ].map(normalizeMapSearch).toList();
  final id = normalizeMapSearch(building.id);

  if (id == normalizedQuery) return 120;
  if (aliases.contains(normalizedQuery)) return 110;
  if (searchableFields.any((field) => field == normalizedQuery)) return 100;
  if (id.startsWith(normalizedQuery)) return 90;
  if (aliases.any((alias) => alias.startsWith(normalizedQuery))) return 80;
  if (searchableFields.any((field) => field.startsWith(normalizedQuery))) {
    return 70;
  }
  if (searchableFields.any((field) => field.contains(normalizedQuery))) {
    return 50;
  }

  return 0;
}

bool isStrongCampusMatch(Building building, String query) {
  final normalizedQuery = normalizeMapSearch(query);
  return scoreBuildingMatch(building, normalizedQuery) >= 100;
}
