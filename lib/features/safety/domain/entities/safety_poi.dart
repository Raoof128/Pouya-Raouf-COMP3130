import 'package:flutter/foundation.dart';

enum SafetyPoiType { firstAid, defibrillator, securityOffice }

@immutable
class SafetyPoi {
  const SafetyPoi({
    required this.id,
    required this.type,
    required this.name,
    required this.buildingCode,
    this.description,
    this.latitude,
    this.longitude,
  });

  final String id;
  final SafetyPoiType type;
  final String name;
  final String buildingCode;
  final String? description;
  final double? latitude;
  final double? longitude;
}
