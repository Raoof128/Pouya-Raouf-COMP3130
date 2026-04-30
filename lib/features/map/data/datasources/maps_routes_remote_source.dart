import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls the `maps-routes` Supabase Edge Function to compute a route.
///
/// This architecture keeps the Google Maps/Routes billing API keys strictly
/// server-side. The mobile app never sees the real Google Routes API key.
///
/// Authentication is optional by design — the app has no login requirement
/// (see AGENT.md: "No auth: App starts directly at /home"). Unauthenticated
/// requests are rate-limited by client IP (60 req / 60 s); authenticated
/// requests are rate-limited by user ID. If app-level auth is introduced
/// later, the Bearer token path below already supports it.
class MapsRoutesRemoteSource {
  const MapsRoutesRemoteSource({
    http.Client? httpClient,
    SupabaseClient? supabaseClient,
  }) : _httpClient = httpClient,
       _supabaseClient = supabaseClient;

  final http.Client? _httpClient;
  final SupabaseClient? _supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  static String get _routesUrl =>
      '${EnvConfig.supabaseUrl}/functions/v1/maps-routes';

  Future<MapRoute> getRoute({
    required MapRendererType renderer,
    required LocationSample origin,
    required Building destination,
    required TravelMode travelMode,
  }) async {
    final destinationLatitude = destination.routingLatitude;
    final destinationLongitude = destination.routingLongitude;
    if (destinationLatitude == null || destinationLongitude == null) {
      throw StateError('Selected building is missing routing coordinates.');
    }
    if (EnvConfig.supabaseUrl.isEmpty || EnvConfig.supabaseAnonKey.isEmpty) {
      throw StateError('Supabase routing endpoint is not configured.');
    }

    final session = _client.auth.currentSession;
    final accessToken = session?.accessToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': EnvConfig.supabaseAnonKey,
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final body = {
      'renderer': renderer.name,
      'origin': {'lat': origin.latitude, 'lng': origin.longitude},
      'destination': {
        'id': destination.id,
        'lat': destinationLatitude,
        'lng': destinationLongitude,
        'entranceLat': destination.entranceLatitude,
        'entranceLng': destination.entranceLongitude,
        'googlePlaceId': destination.googlePlaceId,
      },
      'travelMode': travelMode.apiValue,
      'languageCode': 'en-AU',
    };

    final client = _httpClient ?? http.Client();
    try {
      final response = await client
          .post(Uri.parse(_routesUrl), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 400) {
        if (kDebugMode) {
          debugPrint(
            'maps-routes error ${response.statusCode}: ${response.body}',
          );
        }
        Map<String, dynamic>? errorPayload;
        try {
          errorPayload = jsonDecode(response.body) as Map<String, dynamic>?;
        } on FormatException {
          errorPayload = null;
        }
        final message =
            errorPayload?['error'] as String? ??
            'maps-routes returned ${response.statusCode}';
        throw StateError(message);
      }

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw StateError('maps-routes returned invalid JSON: ${e.message}');
      }
      return MapRoute.fromJson(json, travelMode);
    } finally {
      if (_httpClient == null) {
        client.close();
      }
    }
  }
}

final mapsRoutesRemoteSourceProvider = Provider<MapsRoutesRemoteSource>((ref) {
  return const MapsRoutesRemoteSource();
});
