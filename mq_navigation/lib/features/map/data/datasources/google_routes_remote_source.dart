import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

class GoogleRoutesRemoteSource {
  const GoogleRoutesRemoteSource();

  static const _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

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

    final apiKey = EnvConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      throw StateError('Google Maps API key is not configured.');
    }

    final uri = Uri.parse(_directionsUrl).replace(queryParameters: {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '$destinationLatitude,$destinationLongitude',
      'mode': travelMode.directionsApiValue,
      'language': 'en',
      'units': 'metric',
      'key': apiKey,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode >= 400) {
      if (kDebugMode) {
        debugPrint(
          'Directions API error ${response.statusCode}: ${response.body}',
        );
      }
      throw StateError(
        'Google Directions API returned ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (kDebugMode) {
      debugPrint(
        'Directions API response (${response.statusCode}): status=${json['status']}',
      );
      debugPrint(
        'Directions API request: mode=${travelMode.directionsApiValue}',
      );
    }

    return MapRoute.fromJson(json, travelMode);
  }
}

final googleRoutesRemoteSourceProvider = Provider<GoogleRoutesRemoteSource>((
  ref,
) {
  return const GoogleRoutesRemoteSource();
});
