import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/map/data/datasources/maps_routes_remote_source.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

class CampusRoutesRemoteSource {
  const CampusRoutesRemoteSource({
    required MapsRoutesRemoteSource mapsRoutesRemoteSource,
  }) : _mapsRoutesRemoteSource = mapsRoutesRemoteSource;

  final MapsRoutesRemoteSource _mapsRoutesRemoteSource;

  Future<MapRoute> getRoute({
    required LocationSample origin,
    required Building destination,
    required TravelMode travelMode,
  }) {
    return _mapsRoutesRemoteSource.getRoute(
      renderer: MapRendererType.campus,
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
    mapsRoutesRemoteSource: ref.watch(mapsRoutesRemoteSourceProvider),
  );
});
