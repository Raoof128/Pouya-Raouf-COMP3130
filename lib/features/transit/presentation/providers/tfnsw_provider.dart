import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/map/data/datasources/location_source.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/features/transit/domain/entities/metro_departure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tfnswMetroProvider = StreamProvider.autoDispose<List<MetroDeparture>>((
  ref,
) async* {
  while (true) {
    final preferences = await ref.read(settingsControllerProvider.future);
    final location = await ref
        .read(locationSourceProvider)
        .getCurrentLocation();
    yield await _fetchDepartures(
      favoriteRoute: preferences.favoriteRoute,
      mode: preferences.commuteMode,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );
    await Future<void>.delayed(const Duration(seconds: 60));
  }
});

Future<List<MetroDeparture>> _fetchDepartures({
  required String favoriteRoute,
  required String mode,
  required double? latitude,
  required double? longitude,
}) async {
  try {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final query = <String, String>{
      'mode': mode,
      if (favoriteRoute.trim().isNotEmpty) 'route': favoriteRoute.trim(),
      if (latitude != null) 'lat': latitude.toString(),
      if (longitude != null) 'lng': longitude.toString(),
    };
    final response = await http.get(
      Uri.parse(
        '${EnvConfig.supabaseUrl}/functions/v1/tfnsw-proxy',
      ).replace(queryParameters: query),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'apikey': EnvConfig.supabaseAnonKey,
      },
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final dynamic decoded = jsonDecode(response.body);
    final list = (decoded as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(MetroDeparture.fromJson)
        .toList();
    return list;
  } catch (error, stackTrace) {
    AppLogger.warning('TfNSW proxy request failed', error, stackTrace);
    return const [];
  }
}
