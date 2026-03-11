import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

class GoogleRoutesRemoteSource {
  const GoogleRoutesRemoteSource();

  static const _routesUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';
  static const _fieldMask =
      'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps';

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

    final body = jsonEncode({
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destinationLatitude,
            'longitude': destinationLongitude,
          },
        },
      },
      'travelMode': travelMode.apiValue,
      'computeAlternativeRoutes': false,
      'languageCode': 'en',
      'units': 'METRIC',
    });

    final response = await http.post(
      Uri.parse(_routesUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: body,
    );

    if (response.statusCode >= 400) {
      debugPrint('Routes API error ${response.statusCode}: ${response.body}');
      throw StateError(
        'Google Routes API returned ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MapRoute.fromJson(json, travelMode);
  }
}

final googleRoutesRemoteSourceProvider = Provider<GoogleRoutesRemoteSource>((
  ref,
) {
  return const GoogleRoutesRemoteSource();
});
