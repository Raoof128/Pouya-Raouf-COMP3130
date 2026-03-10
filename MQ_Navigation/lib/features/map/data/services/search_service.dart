import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/presentation/providers/buildings_provider.dart';

/// Service for searching buildings by query string.
class SearchService {
  SearchService(this._ref);
  final Ref _ref;

  /// Search buildings matching [query] across name, aliases, tags, description.
  Future<List<Building>> searchBuildings(String query) async {
    if (query.trim().isEmpty) return [];
    final buildings = await _ref.read(allBuildingsProvider.future);
    return buildings.where((b) => b.matchesQuery(query)).toList();
  }

  /// Get buildings by category.
  Future<List<Building>> getBuildingsByCategory(
    BuildingCategory category,
  ) async {
    final buildings = await _ref.read(allBuildingsProvider.future);
    return buildings.where((b) => b.category == category).toList();
  }
}

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref);
});
