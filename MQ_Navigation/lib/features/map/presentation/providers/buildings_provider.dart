import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/map/data/datasources/building_registry_source.dart';
import 'package:mq_navigation/features/map/data/datasources/sample_buildings.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';

/// All buildings from registry, falling back to sample data in dev.
final allBuildingsProvider = FutureProvider<List<Building>>((ref) async {
  final registry = await ref.watch(buildingRegistryProvider.future);
  if (registry.isNotEmpty) return registry;
  // Fallback to sample data when Supabase is unreachable or empty.
  return sampleBuildings;
});

/// Buildings filtered by [BuildingCategory].
final buildingsByCategoryProvider =
    FutureProvider.family<List<Building>, BuildingCategory?>(
  (ref, category) async {
    final buildings = await ref.watch(allBuildingsProvider.future);
    if (category == null) return buildings;
    return buildings.where((b) => b.category == category).toList();
  },
);

/// Current category filter selection.
final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, BuildingCategory?>(
  SelectedCategoryNotifier.new,
);

class SelectedCategoryNotifier extends Notifier<BuildingCategory?> {
  @override
  BuildingCategory? build() => null;

  void select(BuildingCategory? category) => state = category;
}

/// Search query state.
final buildingSearchQueryProvider =
    NotifierProvider<BuildingSearchQueryNotifier, String>(
  BuildingSearchQueryNotifier.new,
);

class BuildingSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

/// Buildings matching the current search query and category filter.
final filteredBuildingsProvider = FutureProvider<List<Building>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(buildingSearchQueryProvider);
  final buildings = await ref.watch(
    buildingsByCategoryProvider(category).future,
  );
  if (query.isEmpty) return buildings;
  return buildings.where((b) => b.matchesQuery(query)).toList();
});
