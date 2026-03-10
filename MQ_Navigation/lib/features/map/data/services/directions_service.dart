import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

/// Walking directions via the OpenRouteService API.
class DirectionsService {
  static const String _baseUrl =
      'https://api.openrouteservice.org/v2/directions/foot-walking';

  /// Fetch a walking route between [start] and [end].
  ///
  /// Returns an ordered list of [LatLng] points for the polyline.
  /// Throws on network or API errors.
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final apiKey = EnvConfig.orsApiKey;

    // If no ORS key is configured, return a direct line as fallback.
    if (apiKey.isEmpty) {
      AppLogger.warning(
        'ORS_API_KEY not set — returning straight-line route.',
      );
      return [start, end];
    }

    final url = Uri.parse(
      '$_baseUrl'
      '?start=${start.longitude},${start.latitude}'
      '&end=${end.longitude},${end.latitude}',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': apiKey},
      );

      if (response.statusCode != 200) {
        AppLogger.error(
          'Directions API returned ${response.statusCode}',
          response.body,
        );
        return [start, end];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>;
      if (features.isEmpty) return [start, end];

      final geometry =
          features[0]['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      return coordinates
          .map<LatLng>(
            (coord) => LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            ),
          )
          .toList();
    } catch (e, s) {
      AppLogger.error('Failed to fetch directions', e, s);
      return [start, end];
    }
  }

  /// Estimate walking time in minutes between two points.
  static int estimateWalkingMinutes(double distanceMetres) {
    // Average walking speed ~5 km/h = ~83 m/min
    return (distanceMetres / 83).ceil().clamp(1, 999);
  }
}
