import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

const campusOfflineStoreName = 'campus_offline_tiles';

final offlineMapsServiceProvider = Provider<OfflineMapsService>((ref) {
  return const OfflineMapsService();
});

class OfflineMapsService {
  const OfflineMapsService();

  Future<void> ensureStore() async {
    await const FMTCStore(campusOfflineStoreName).manage.create();
  }

  TileProvider tileProvider() {
    return FMTCTileProvider(stores: const {campusOfflineStoreName: null});
  }

  Future<void> downloadCampusTiles() async {
    await ensureStore();

    final tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'io.mqnavigation.mq_navigation',
    );
    final region = RectangleRegion(
      LatLngBounds(
        const LatLng(-33.792, 151.087),
        const LatLng(-33.756, 151.133),
      ),
    ).toDownloadable(minZoom: 15, maxZoom: 18, options: tileLayer);

    final streams = const FMTCStore(
      campusOfflineStoreName,
    ).download.startForeground(region: region, skipExistingTiles: true);
    await streams.downloadProgress.last;
  }

  Future<void> initializeBackend() async {
    try {
      await FMTCObjectBoxBackend().initialise();
    } catch (error, stackTrace) {
      AppLogger.warning('Offline map backend init skipped', error, stackTrace);
    }
  }
}
