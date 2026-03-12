import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/features/map/data/datasources/overlay_registry.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';

/// Renders additional overlay image layers (parking, water, etc.)
/// on top of the campus base image. Each active overlay uses the same
/// map-space bounds as the base campus image.
class CampusOverlayLayers extends StatelessWidget {
  const CampusOverlayLayers({
    super.key,
    required this.activeOverlayIds,
    required this.meta,
  });

  final Set<String> activeOverlayIds;
  final CampusOverlayMeta meta;

  @override
  Widget build(BuildContext context) {
    if (activeOverlayIds.isEmpty) return const SizedBox.shrink();

    final bounds = LatLngBounds(
      latlong.LatLng(meta.mapSouth, meta.mapWest),
      latlong.LatLng(meta.mapNorth, meta.mapEast),
    );

    final activeOverlays = OverlayRegistry.overlays
        .where((o) => activeOverlayIds.contains(o.id))
        .toList();

    return OverlayImageLayer(
      overlayImages: [
        for (final overlay in activeOverlays)
          OverlayImage(
            bounds: bounds,
            imageProvider: AssetImage(overlay.imageAsset),
            opacity: overlay.opacity,
          ),
      ],
    );
  }
}
