import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class MapOverlay {
  const MapOverlay({
    required this.id,
    required this.label,
    required this.description,
    required this.imageAsset,
    this.opacity = 0.95,
    this.color,
  });

  final String id;
  final String label;
  final String description;
  final String imageAsset;
  final double opacity;
  final Color? color;
}
