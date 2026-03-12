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

  /// Supabase Edge Function that proxies the Directions API.
  /// Used on web because the browser cannot call the Directions API directly
  /// (Google does not set CORS headers on that endpoint).
  static String get _proxyUrl =>
      '${EnvConfig.supabaseUrl}/functions/v1/directions-proxy';

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

    final originStr = '${origin.latitude},${origin.longitude}';
    final destinationStr = '$destinationLatitude,$destinationLongitude';
    final mode = travelMode.directionsApiValue;

    late final http.Response response;

    if (kIsWeb) {
      // On web, route through the Supabase proxy to avoid CORS issues.
      response = await http
          .post(
            Uri.parse(_proxyUrl),
            headers: {
              'Content-Type': 'application/json',
              'apikey': EnvConfig.supabaseAnonKey,
            },
            body: jsonEncode({
              'origin': originStr,
              'destination': destinationStr,
              'mode': mode,
              'language': 'en',
              'units': 'metric',
            }),
          )
          .timeout(const Duration(seconds: 15));
    } else {
      // On mobile, call the Directions API directly (no CORS restrictions).
      final uri = Uri.parse(_directionsUrl).replace(queryParameters: {
        'origin': originStr,
        'destination': destinationStr,
        'mode': mode,
        'language': 'en',
        'units': 'metric',
        'key': apiKey,
      });
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    }

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
