import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

class CampusMapView extends StatefulWidget {
  const CampusMapView({
    super.key,
    required this.buildings,
    required this.selectedBuilding,
    required this.route,
    required this.currentLocation,
    required this.onSelectBuilding,
  });

  final List<Building> buildings;
  final Building? selectedBuilding;
  final MapRoute? route;
  final LocationSample? currentLocation;
  final ValueChanged<Building> onSelectBuilding;

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant CampusMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedBuilding != null &&
        widget.selectedBuilding?.id != oldWidget.selectedBuilding?.id) {
      final target = widget.selectedBuilding!;
      final latitude = target.routingLatitude;
      final longitude = target.routingLongitude;
      if (_controller != null && latitude != null && longitude != null) {
        unawaited(
          _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 17),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) ||
        !EnvConfig.hasGoogleMapsApiKey) {
      return MqCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.mapFailedToLoad,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(widget.selectedBuilding?.name ?? l10n.mapLoadErrorDescription),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(-33.7738, 151.1130),
          zoom: 16.5,
        ),
        onMapCreated: (controller) {
          _controller = controller;
        },
        minMaxZoomPreference: const MinMaxZoomPreference(14, 20),
        cameraTargetBounds: CameraTargetBounds(_campusBounds),
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        myLocationEnabled: widget.currentLocation != null,
        myLocationButtonEnabled: false,
        markers: widget.buildings
            .where(
              (building) =>
                  building.latitude != null && building.longitude != null,
            )
            .map(
              (building) => Marker(
                markerId: MarkerId(building.id),
                position: LatLng(building.latitude!, building.longitude!),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  building.isHighTraffic
                      ? BitmapDescriptor.hueAzure
                      : BitmapDescriptor.hueRed,
                ),
                infoWindow: InfoWindow(
                  title: building.name,
                  snippet: building.id,
                ),
                onTap: () => widget.onSelectBuilding(building),
              ),
            )
            .toSet(),
        polylines: widget.route == null || widget.route!.encodedPolyline.isEmpty
            ? const <Polyline>{}
            : {
                Polyline(
                  polylineId: const PolylineId('campus_route'),
                  points: _decodePolyline(widget.route!.encodedPolyline),
                  width: 5,
                  color: _colorFor(widget.route!.travelMode),
                ),
              },
      ),
    );
  }

  Color _colorFor(TravelMode travelMode) {
    return switch (travelMode) {
      TravelMode.walk => const Color(0xFF005AA9),
      TravelMode.drive => const Color(0xFF6C757D),
      TravelMode.bike => const Color(0xFF2E8B57),
      TravelMode.transit => const Color(0xFFF57C00),
    };
  }

  List<LatLng> _decodePolyline(String encoded) {
    final coordinates = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var result = 1;
      var shift = 0;
      var byte = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63 - 1;
        result += byte << shift;
        shift += 5;
      } while (byte >= 0x1f);
      latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      result = 1;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63 - 1;
        result += byte << shift;
        shift += 5;
      } while (byte >= 0x1f);
      longitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      coordinates.add(LatLng(latitude / 1e5, longitude / 1e5));
    }

    return coordinates;
  }
}

final LatLngBounds _campusBounds = LatLngBounds(
  southwest: const LatLng(-33.778124, 151.103934),
  northeast: const LatLng(-33.769571, 151.122172),
);
