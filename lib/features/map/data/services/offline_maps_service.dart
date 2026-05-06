import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

const campusOfflineStoreName = 'campus_offline_tiles';

/// Set to true only after [FMTCObjectBoxBackend.initialise] completes
/// successfully. When false, [OfflineMapsService.tileProvider] uses
/// [NetworkTileProvider] so maps still load (sandboxed macOS often fails
/// ObjectBox init unless an application group is configured).
bool _fmtcObjectBoxBackendReady = false;

final offlineMapsServiceProvider = Provider<OfflineMapsService>((ref) {
  return const OfflineMapsService();
});

class OfflineMapsService {
  const OfflineMapsService();

  /// Whether tile caching via FMTC is available (native ObjectBox initialised).
  bool get isFmtcBackendReady => _fmtcObjectBoxBackendReady;

  Future<void> ensureStore() async {
    if (!_fmtcObjectBoxBackendReady) {
      return;
    }
    await const FMTCStore(campusOfflineStoreName).manage.create();
  }

  TileProvider tileProvider() {
    if (!_fmtcObjectBoxBackendReady) {
      return NetworkTileProvider();
    }
    return FMTCTileProvider(stores: const {campusOfflineStoreName: null});
  }

  Future<void> downloadCampusTiles() async {
    if (!_fmtcObjectBoxBackendReady) {
      AppLogger.warning(
        'Offline campus tile download skipped: FMTC ObjectBox backend is not '
        'initialised (e.g. macOS App Sandbox may need an application group).',
      );
      return;
    }
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
    _fmtcObjectBoxBackendReady = false;
    // FMTC's ObjectBox backend uses FFI and is not supported on web.
    if (kIsWeb) {
      return;
    }
    try {
      await FMTCObjectBoxBackend().initialise();
      _fmtcObjectBoxBackendReady = true;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Offline map backend init skipped — desktop OSM will use online tiles '
        'only until ObjectBox can start (check macOS sandbox / app group).',
        error,
        stackTrace,
      );
    }
  }
}
