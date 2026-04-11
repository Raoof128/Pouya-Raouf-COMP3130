import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';

/// Renders the campus blueprint image as a [FlutterMap] overlay layer.
class CampusMapOverlay extends StatelessWidget {
  const CampusMapOverlay({super.key, required this.meta});

  final CampusOverlayMeta meta;

  @override
  Widget build(BuildContext context) {
    final bounds = LatLngBounds(
      latlong.LatLng(meta.mapSouth, meta.mapWest),
      latlong.LatLng(meta.mapNorth, meta.mapEast),
    );

    return OverlayImageLayer(
      overlayImages: [
        OverlayImage(
          bounds: bounds,
          imageProvider: AssetImage(meta.imageAsset),
        ),
      ],
    );
  }
}
