import 'dart:ui';

import 'package:mq_navigation/features/map/domain/entities/map_overlay.dart';

class OverlayRegistry {
  static const overlays = <MapOverlay>[
    MapOverlay(
      id: 'parking',
      label: 'Parking',
      description: 'Campus parking areas and zones',
      imageAsset: 'assets/maps/overlay_parking.png',
      opacity: 0.95,
      color: Color(0xFF3B82F6), // blue-500
    ),
    MapOverlay(
      id: 'drinking_water',
      label: 'Drinking Water',
      description: 'Water fountain locations',
      imageAsset: 'assets/maps/overlay_water.png',
      opacity: 0.95,
      color: Color(0xFF06B6D4), // cyan-500
    ),
    MapOverlay(
      id: 'accessibility',
      label: 'Accessibility',
      description: 'Accessible routes and facilities',
      imageAsset: 'assets/maps/overlay_accessibility.png',
      opacity: 0.95,
      color: Color(0xFFA855F7), // purple-500
    ),
    MapOverlay(
      id: 'special_permits',
      label: 'Special Permits',
      description: 'Special permit and service vehicle areas',
      imageAsset: 'assets/maps/overlay_permits.png',
      opacity: 0.95,
      color: Color(0xFFF97316), // orange-500
    ),
  ];
}
