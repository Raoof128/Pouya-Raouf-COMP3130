import 'package:flutter/foundation.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_point.dart';

/// A campus building with its metadata and GPS coordinates.
@immutable
class Building {
  const Building({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.category = BuildingCategory.other,
    this.latitude,
    this.longitude,
    this.entranceLatitude,
    this.entranceLongitude,
    this.googlePlaceId,
    this.levels,
    this.wheelchair = false,
    this.tags = const [],
    this.aliases = const [],
    this.gridRef,
    this.campusX,
    this.campusY,
  });

  final String id;
  final String name;
  final String? description;
  final String? address;
  final BuildingCategory category;
  final double? latitude;
  final double? longitude;
  final double? entranceLatitude;
  final double? entranceLongitude;
  final String? googlePlaceId;
  final int? levels;
  final bool wheelchair;
  final List<String> tags;
  final List<String> aliases;
  final String? gridRef;
  final double? campusX;
  final double? campusY;

  factory Building.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final entrance = json['entranceLocation'] as Map<String, dynamic>?;
    final campusLocation = json['campusLocation'] as Map<String, dynamic>?;

    return Building(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      category: BuildingCategory.fromString(
        json['category'] as String? ?? 'other',
      ),
      latitude: (location?['lat'] as num?)?.toDouble(),
      longitude: (location?['lng'] as num?)?.toDouble(),
      entranceLatitude: (entrance?['lat'] as num?)?.toDouble(),
      entranceLongitude: (entrance?['lng'] as num?)?.toDouble(),
      googlePlaceId: json['googlePlaceId'] as String?,
      levels: (json['levels'] as num?)?.toInt(),
      wheelchair: json['wheelchair'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      aliases: (json['aliases'] as List<dynamic>?)?.cast<String>() ?? [],
      gridRef: json['gridRef'] as String?,
      campusX:
          (campusLocation?['x'] as num?)?.toDouble() ??
          (json['campusX'] as num?)?.toDouble(),
      campusY:
          (campusLocation?['y'] as num?)?.toDouble() ??
          (json['campusY'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'address': address,
    'category': category.name,
    'location': latitude != null ? {'lat': latitude, 'lng': longitude} : null,
    'entranceLocation': entranceLatitude != null
        ? {'lat': entranceLatitude, 'lng': entranceLongitude}
        : null,
    'googlePlaceId': googlePlaceId,
    'levels': levels,
    'wheelchair': wheelchair,
    'tags': tags,
    'aliases': aliases,
    'gridRef': gridRef,
    'campusLocation': hasCampusCoordinates
        ? {'x': campusX, 'y': campusY}
        : null,
  };

  /// Best coordinate for routing: entrance if available, otherwise building center.
  double? get routingLatitude => entranceLatitude ?? latitude;
  double? get routingLongitude => entranceLongitude ?? longitude;
  bool get hasGeographicCoordinates => latitude != null && longitude != null;
  bool get hasCampusCoordinates => campusX != null && campusY != null;
  CampusPoint? get campusPoint =>
      hasCampusCoordinates ? CampusPoint(x: campusX!, y: campusY!) : null;

  bool get isHighTraffic {
    return const <String>{
      'LIB',
      '18WW',
      '1CC',
      'MUSE',
      '14SCO',
      '12WW',
    }.contains(id.toUpperCase());
  }

  /// Whether this building matches a search query.
  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return id.toLowerCase().contains(q) ||
        name.toLowerCase().contains(q) ||
        category.name.toLowerCase().contains(q) ||
        (description?.toLowerCase().contains(q) ?? false) ||
        (address?.toLowerCase().contains(q) ?? false) ||
        aliases.any((a) => a.toLowerCase().contains(q)) ||
        tags.any((t) => t.toLowerCase().contains(q));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Building && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Building($id, $name)';
}

enum BuildingCategory {
  academic,
  services,
  health,
  food,
  sports,
  venue,
  research,
  residential,
  other;

  static BuildingCategory fromString(String value) {
    return BuildingCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BuildingCategory.other,
    );
  }
}
