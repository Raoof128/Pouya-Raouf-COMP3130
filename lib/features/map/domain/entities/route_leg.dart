import 'package:flutter/foundation.dart';
import 'package:mq_navigation/features/map/domain/entities/nav_instruction.dart';

enum TravelMode {
  walk('WALK', 'walking'),
  drive('DRIVE', 'driving'),
  bike('BICYCLE', 'bicycling'),
  transit('TRANSIT', 'transit');

  const TravelMode(this.apiValue, this.directionsApiValue);

  /// Value used by the Routes API v2 (computeRoutes).
  final String apiValue;

  /// Value used by the legacy Directions API.
  final String directionsApiValue;
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
  MapRoute({
    required this.travelMode,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
    this.points = const [],
    required this.instructions,
  }) : arrivalAt = DateTime.now().add(Duration(seconds: durationSeconds));

  final TravelMode travelMode;
  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;
  final List<LocationSample> points;
  final List<NavInstruction> instructions;
  final DateTime arrivalAt;

  factory MapRoute.fromJson(Map<String, dynamic> json, TravelMode travelMode) {
    if (json.containsKey('points')) {
      return MapRoute._fromNormalizedJson(json, travelMode);
    }

    final routes = (json['routes'] as List<dynamic>? ?? const <dynamic>[]);
    if (routes.isNotEmpty &&
        (routes.first as Map<String, dynamic>).containsKey('distanceMeters')) {
      return MapRoute._fromRoutesApiJson(json, travelMode);
    }

    return MapRoute._fromDirectionsJson(json, travelMode);
  }

  factory MapRoute._fromNormalizedJson(
    Map<String, dynamic> json,
    TravelMode travelMode,
  ) {
    final points = (json['points'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(
          (point) => LocationSample(
            latitude: ((point['lat'] ?? point['latitude']) as num).toDouble(),
            longitude: ((point['lng'] ?? point['longitude']) as num).toDouble(),
          ),
        )
        .toList();

    return MapRoute(
      travelMode: travelMode,
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: _parseDurationSeconds(
        json['durationSeconds'] ?? json['duration'],
      ),
      encodedPolyline: json['encodedPolyline'] as String? ?? '',
      points: points,
      instructions:
          (json['steps'] as List<dynamic>? ??
                  json['instructions'] as List<dynamic>? ??
                  const <dynamic>[])
              .cast<Map<String, dynamic>>()
              .map(NavInstruction.fromJson)
              .where((instruction) => instruction.text.isNotEmpty)
              .toList(),
    );
  }

  factory MapRoute._fromRoutesApiJson(
    Map<String, dynamic> json,
    TravelMode travelMode,
  ) {
    final routes = (json['routes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final route = routes.first;
    final legs = (route['legs'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();

    return MapRoute(
      travelMode: travelMode,
      distanceMeters: (route['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: _parseDurationSeconds(route['duration']),
      encodedPolyline:
          (route['polyline'] as Map<String, dynamic>?)?['encodedPolyline']
              as String? ??
          '',
      instructions: legs
          .expand(
            (leg) => (leg['steps'] as List<dynamic>? ?? const <dynamic>[])
                .cast<Map<String, dynamic>>(),
          )
          .map(NavInstruction.fromJson)
          .where((instruction) => instruction.text.isNotEmpty)
          .toList(),
    );
  }

  factory MapRoute._fromDirectionsJson(
    Map<String, dynamic> json,
    TravelMode travelMode,
  ) {
    // ── Directions API response parsing ──
    final status = json['status'] as String?;
    if (status != null && status != 'OK') {
      throw StateError(
        'No routes were returned by the routing service (status: $status).',
      );
    }

    final routes = (json['routes'] as List<dynamic>? ?? const <dynamic>[]);
    if (routes.isEmpty) {
      final errorInfo = json['error'] as Map<String, dynamic>?;
      final apiMessage =
          errorInfo?['message'] as String? ??
          'empty response (is Directions API enabled on the API key?)';
      throw StateError(
        'No routes were returned by the routing service: $apiMessage',
      );
    }

    final route = routes.first as Map<String, dynamic>;
    final legs = (route['legs'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();

    // Aggregate distance / duration from the first leg.
    final leg = legs.isNotEmpty ? legs.first : <String, dynamic>{};
    final distanceMeters =
        ((leg['distance'] as Map<String, dynamic>?)?['value'] as num?)
            ?.toInt() ??
        0;
    final durationSeconds =
        ((leg['duration'] as Map<String, dynamic>?)?['value'] as num?)
            ?.toInt() ??
        0;
    final encodedPolyline =
        (route['overview_polyline'] as Map<String, dynamic>?)?['points']
            as String? ??
        '';

    final steps =
        (legs.isNotEmpty
            ? legs.first['steps'] as List<dynamic>?
            : const <dynamic>[]) ??
        const <dynamic>[];

    return MapRoute(
      travelMode: travelMode,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      encodedPolyline: encodedPolyline,
      instructions: steps
          .cast<Map<String, dynamic>>()
          .map(NavInstruction.fromJson)
          .where((instruction) => instruction.text.isNotEmpty)
          .toList(),
    );
  }

  static int _parseDurationSeconds(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = num.tryParse(value.replaceAll('s', ''));
      return parsed?.round() ?? 0;
    }
    return 0;
  }
}
