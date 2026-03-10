import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/presentation/pages/building_detail_page.dart';
import 'package:mq_navigation/features/map/presentation/providers/buildings_provider.dart';

/// Interactive campus map with building markers, category filters, and search.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  /// Macquarie University campus centre.
  static const LatLng _mqCenter = LatLng(-33.7738, 151.1130);

  GoogleMapController? _mapController;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<Building> buildings) {
    return buildings
        .where((b) => b.latitude != null && b.longitude != null)
        .map(
          (b) => Marker(
            markerId: MarkerId(b.id),
            position: LatLng(b.latitude!, b.longitude!),
            infoWindow: InfoWindow(
              title: b.name,
              snippet: b.category.label,
              onTap: () => _openBuildingDetail(b),
            ),
            icon: _markerIconForCategory(b.category),
            onTap: () => _onMarkerTap(b),
          ),
        )
        .toSet();
  }

  BitmapDescriptor _markerIconForCategory(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.academic:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        );
      case BuildingCategory.food:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case BuildingCategory.health:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        );
      case BuildingCategory.sports:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueCyan,
        );
      case BuildingCategory.services:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      case BuildingCategory.venue:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      case BuildingCategory.research:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );
      case BuildingCategory.residential:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueMagenta,
        );
      case BuildingCategory.other:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        );
    }
  }

  void _onMarkerTap(Building building) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(building.latitude!, building.longitude!),
      ),
    );
  }

  void _openBuildingDetail(Building building) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BuildingDetailPage(building: building),
      ),
    );
  }

  void _showSearchSheet() {
    setState(() => _isSearching = true);
  }

  void _closeSearch() {
    _searchController.clear();
    ref.read(buildingSearchQueryProvider.notifier).update('');
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredBuildings = ref.watch(filteredBuildingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search buildings...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(buildingSearchQueryProvider.notifier).update(value);
                },
              )
            : const Text('MQ Navigation'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _isSearching ? _closeSearch : _showSearchSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _CategoryFilterBar(),
          Expanded(
            child: filteredBuildings.when(
              data: (buildings) => _buildMap(buildings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<Building> buildings) {
    if (!EnvConfig.hasGoogleMapsKey) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Google Maps API key not configured',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Set GOOGLE_MAPS_API_KEY via --dart-define to enable the map.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _mqCenter,
        zoom: 16,
      ),
      markers: _buildMarkers(buildings),
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}

/// Horizontal list of category filter chips.
class _CategoryFilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              selectedColor: MqColors.red.withValues(alpha: 0.15),
              checkmarkColor: MqColors.red,
              onSelected: (_) {
                ref.read(selectedCategoryProvider.notifier).select(null);
              },
            ),
          ),
          ...BuildingCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.label),
                selected: selected == category,
                selectedColor: MqColors.red.withValues(alpha: 0.15),
                checkmarkColor: MqColors.red,
                onSelected: (isSelected) {
                  ref.read(selectedCategoryProvider.notifier).select(
                      isSelected ? category : null);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
