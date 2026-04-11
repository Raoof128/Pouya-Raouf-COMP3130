import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/data/datasources/maps_routes_remote_source.dart';

class GoogleRoutesRemoteSource {
  const GoogleRoutesRemoteSource({
    required MapsRoutesRemoteSource mapsRoutesRemoteSource,
  }) : _mapsRoutesRemoteSource = mapsRoutesRemoteSource;

  final MapsRoutesRemoteSource _mapsRoutesRemoteSource;

  Future<MapRoute> getRoute({
    required LocationSample origin,
    required Building destination,
    required TravelMode travelMode,
  }) async {
    return _mapsRoutesRemoteSource.getRoute(
      renderer: MapRendererType.google,
      origin: origin,
      destination: destination,
      travelMode: travelMode,
    );
  }
}

final googleRoutesRemoteSourceProvider = Provider<GoogleRoutesRemoteSource>((
  ref,
) {
  return GoogleRoutesRemoteSource(
    mapsRoutesRemoteSource: ref.watch(mapsRoutesRemoteSourceProvider),
  );
});
