import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/core/security/secure_storage_service.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';

/// Versioned cache key. **Bump the suffix whenever `buildings.json`
/// changes shape (new tags, new aliases, schema changes)** — every
/// install will invalidate its previous cache on next launch and
/// re-hydrate from the bundled asset. The previous unversioned key
/// (`'building_registry'`) is intentionally never re-used so installs
/// upgrading from older builds never serve stale enrichment data.
///
/// Version history:
///   v2 — Open Day 2026 release: `faculty`, `campus hub`, and
///        `student services` tags, plus 66 cross-departmental aliases
///        and the Gale History Museum entry.
///   v3 — Campus tour script enrichment: aliases + searchTokens for
///        Service Connect, IT Service Desk, Learning Connect, Career
///        and Employment Service (18WW); Michael Kirby Building, Law
///        Commons, Moot Courts (17WW); Arts Precinct, Faculty of Arts
///        Offices, A/B/C aliases (25BWW); The Hub, student group
///        stalls (1CC); Lincoln Building, Research Office (16WW);
///        15-17 Gymnasium Road on Student Accommodation; Macquarie
///        Theatre under Campus Hub. Three duplicate sub-building
///        entries removed (17WWMICHAE, 18WWSERVIC, 16WWLINCOL).
///   v4 — Campus tour script pages 4–8: dual-address 14SCO ↔ 12WW;
///        Muslim Prayer Rooms, Macquarie International, MQ University
///        College, Numeracy Centre, Emergency Blue Help Point, Mason
///        Theatre on 14SCO; Walanga Muru Pavilion / Jannawi context
///        on WALU; Australian Hearing Hub + Student Wellbeing +
///        Accessibility + Counselling + Welfare on 16UA; Ainsworth /
///        Clinical Education on AINS; Frank the Bear on 6WW; T1 +
///        theatres on LOTUS and 29WW; MUSAC + sport-and-aquatic
///        aliases on SPORT; Macquarie University History Museum on
///        GALEHIST; Macquarie University Village on MQV; 2SER 107.3
///        on CHAP (10 Hadenfeld); Campus Security Office on LIB;
///        2 Technology Place on CLINIC; Biological Sciences Museum
///        aliases on BIODISC and 6SR; parking-on-campus tokens on
///        every parking entry. Four duplicate stubs removed (27WW,
///        16UAAUSTRA, 25CWW, 1WW).
const _cacheKey = 'building_registry.v4';
const _assetPath = 'assets/data/buildings.json';

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
      final cached = await _loadFromCache();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      // If network fails and no secure storage cache exists (e.g. fresh install
      // without internet), fall back to the bundled JSON asset exported at build time.
      return _loadFromAsset();
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
      return _loadFromAsset();
    }

    final data = response['value'] as List<dynamic>;
    return data
        .map((e) => Building.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Building>> _loadFromAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    final list = jsonDecode(raw) as List<dynamic>;
    final buildings = list
        .map((item) => Building.fromJson(item as Map<String, dynamic>))
        .toList();
    await _saveToCache(buildings);
    return buildings;
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
