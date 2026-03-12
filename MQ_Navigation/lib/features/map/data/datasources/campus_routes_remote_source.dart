import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/map/data/datasources/google_routes_remote_source.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

/// Phase-1 campus routing adapter.
///
/// The dual-renderer foundation is now in place, but the raster campus route
/// backend is not checked into this repository yet. Until the edge-function
/// campus service lands, campus mode reuses the same route source so the app
/// keeps a single route contract.
class CampusRoutesRemoteSource {
  const CampusRoutesRemoteSource({
    required GoogleRoutesRemoteSource googleRoutesRemoteSource,
  }) : _googleRoutesRemoteSource = googleRoutesRemoteSource;

  final GoogleRoutesRemoteSource _googleRoutesRemoteSource;

  Future<MapRoute> getRoute({
    required LocationSample origin,
    required Building destination,
    required TravelMode travelMode,
  }) {
    AppLogger.info(
      'Campus routing fallback active; using shared Google route source',
    );
    return _googleRoutesRemoteSource.getRoute(
      origin: origin,
      destination: destination,
      travelMode: travelMode,
    );
  }
}

final campusRoutesRemoteSourceProvider = Provider<CampusRoutesRemoteSource>((
  ref,
) {
  return CampusRoutesRemoteSource(
    googleRoutesRemoteSource: ref.watch(googleRoutesRemoteSourceProvider),
  );
});
