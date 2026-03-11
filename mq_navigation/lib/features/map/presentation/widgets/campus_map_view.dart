import 'dart:async';

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
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CampusMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate to a newly selected building.
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
      return;
    }

    // Animate to the user's current location when it first appears or changes.
    final newLoc = widget.currentLocation;
    final oldLoc = oldWidget.currentLocation;
    if (_controller != null &&
        newLoc != null &&
        (oldLoc == null ||
            newLoc.latitude != oldLoc.latitude ||
            newLoc.longitude != oldLoc.longitude)) {
      unawaited(
        _controller!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(newLoc.latitude, newLoc.longitude),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!EnvConfig.hasGoogleMapsApiKey) {
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

    // Only show important buildings + selected building to keep the map clean.
    final visibleBuildings = widget.buildings.where((building) {
      if (building.latitude == null || building.longitude == null) return false;
      if (widget.selectedBuilding?.id == building.id) return true;
      return building.isHighTraffic;
    }).toList();

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-33.7738, 151.1130),
        zoom: 15.5,
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
      markers: visibleBuildings
          .map(
            (building) {
              final isSelected =
                  widget.selectedBuilding?.id == building.id;
              return Marker(
                markerId: MarkerId(building.id),
                position: LatLng(building.latitude!, building.longitude!),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  isSelected
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueOrange,
                ),
                alpha: isSelected ? 1.0 : 0.7,
                zIndexInt: isSelected ? 1 : 0,
                infoWindow: InfoWindow(
                  title: building.name,
                  snippet: building.id,
                ),
                onTap: () => widget.onSelectBuilding(building),
              );
            },
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
      var result = 0;
      var shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
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
