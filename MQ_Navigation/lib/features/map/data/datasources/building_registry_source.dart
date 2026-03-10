import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/core/security/secure_storage_service.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';

const _cacheKey = 'building_registry';

/// Data source for the campus building registry.
/// Fetches from Supabase and caches locally in secure storage.
class BuildingRegistrySource {
  BuildingRegistrySource({required this.secureStorage});

  final SecureStorageService secureStorage;

  /// Load buildings: try cache first, then fetch from Supabase.
  Future<List<Building>> getBuildings({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _loadFromCache();
      if (cached != null && cached.isNotEmpty) {
        AppLogger.debug('Building registry loaded from cache', cached.length);
        return cached;
      }
    }

    try {
      final buildings = await _fetchFromSupabase();
      await _saveToCache(buildings);
      AppLogger.info(
        'Building registry fetched from Supabase',
        buildings.length,
      );
      return buildings;
    } catch (e, s) {
      AppLogger.error('Failed to fetch building registry', e, s);
      // Fall back to cache on network error
      final cached = await _loadFromCache();
      return cached ?? [];
    }
  }

  Future<List<Building>> _fetchFromSupabase() async {
    // Query the building data from Supabase.
    // This assumes a `buildings` table or RPC exists, or falls back to app_config.
    // For now, try app_config where key = 'building_registry'.
    final response = await Supabase.instance.client
        .from('app_config')
        .select('value')
        .eq('key', 'building_registry')
        .maybeSingle();

    if (response == null || response['value'] == null) {
      return [];
    }

    final data = response['value'] as List<dynamic>;
    return data
        .map((e) => Building.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Building>?> _loadFromCache() async {
    try {
      final cached = await secureStorage.read(_cacheKey);
      if (cached == null) return null;
      final list = jsonDecode(cached) as List<dynamic>;
      return list
          .map((e) => Building.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warning('Failed to load building cache', e);
      return null;
    }
  }

  Future<void> _saveToCache(List<Building> buildings) async {
    try {
      final json = jsonEncode(buildings.map((b) => b.toJson()).toList());
      await secureStorage.write(_cacheKey, json);
    } catch (e) {
      AppLogger.warning('Failed to save building cache', e);
    }
  }
}

final buildingRegistrySourceProvider = Provider<BuildingRegistrySource>((ref) {
  return BuildingRegistrySource(
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

/// Provides the cached building list.
final buildingRegistryProvider = FutureProvider<List<Building>>((ref) {
  return ref.watch(buildingRegistrySourceProvider).getBuildings();
});
