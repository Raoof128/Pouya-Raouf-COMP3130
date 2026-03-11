import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

class GoogleRoutesRemoteSource {
  const GoogleRoutesRemoteSource(this._client);

  final SupabaseClient _client;

  Future<MapRoute> getRoute({
    required LocationSample origin,
    required Building destination,
    required TravelMode travelMode,
  }) async {
    final destinationLatitude = destination.routingLatitude;
    final destinationLongitude = destination.routingLongitude;
    if (destinationLatitude == null || destinationLongitude == null) {
      throw StateError('Selected building is missing routing coordinates.');
    }

    final response = await _client.functions.invoke(
      'maps-routes',
      body: <String, dynamic>{
        'origin': <String, dynamic>{
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        },
        'destination': <String, dynamic>{
          'latitude': destinationLatitude,
          'longitude': destinationLongitude,
        },
        'travelMode': travelMode.apiValue,
      },
    );

    if (response.status >= 400) {
      throw StateError(response.data.toString());
    }

    return MapRoute.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      travelMode,
    );
  }
}

final googleRoutesRemoteSourceProvider = Provider<GoogleRoutesRemoteSource>((
  ref,
) {
  return GoogleRoutesRemoteSource(Supabase.instance.client);
});
