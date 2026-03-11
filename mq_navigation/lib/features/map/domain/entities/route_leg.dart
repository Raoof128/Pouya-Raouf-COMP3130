import 'package:flutter/foundation.dart';
import 'package:mq_navigation/features/map/domain/entities/nav_instruction.dart';

enum TravelMode {
  walk('WALK'),
  drive('DRIVE'),
  bike('BICYCLE'),
  transit('TRANSIT');

  const TravelMode(this.apiValue);

  final String apiValue;
}

@immutable
class LocationSample {
  const LocationSample({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? timestamp;
}

@immutable
class MapRoute {
  const MapRoute({
    required this.travelMode,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
    required this.instructions,
  });

  final TravelMode travelMode;
  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;
  final List<NavInstruction> instructions;

  factory MapRoute.fromJson(Map<String, dynamic> json, TravelMode travelMode) {
    final routes = (json['routes'] as List<dynamic>? ?? const <dynamic>[]);
    if (routes.isEmpty) {
      throw StateError('No routes were returned by the routing service.');
    }

    final route = routes.first as Map<String, dynamic>;
    final legs = (route['legs'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final steps =
        (legs.isNotEmpty
            ? legs.first['steps'] as List<dynamic>?
            : const <dynamic>[]) ??
        const <dynamic>[];

    return MapRoute(
      travelMode: travelMode,
      distanceMeters: (route['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: _parseDurationSeconds(route['duration'] as String?),
      encodedPolyline:
          (route['polyline'] as Map<String, dynamic>?)?['encodedPolyline']
              as String? ??
          '',
      instructions: steps
          .cast<Map<String, dynamic>>()
          .map(NavInstruction.fromJson)
          .where((instruction) => instruction.text.isNotEmpty)
          .toList(),
    );
  }

  static int _parseDurationSeconds(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty || !rawValue.endsWith('s')) {
      return 0;
    }
    return double.tryParse(rawValue.replaceAll('s', ''))?.round() ?? 0;
  }
}
