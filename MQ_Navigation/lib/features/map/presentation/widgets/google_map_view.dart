import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/map_polyline_codec.dart';
import 'package:mq_navigation/features/map/presentation/widgets/map_view_helpers.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

class GoogleMapView extends StatefulWidget {
  const GoogleMapView({
    super.key,
    required this.searchResults,
    required this.searchQuery,
    required this.selectedBuilding,
    required this.route,
    required this.currentLocation,
    required this.onSelectBuilding,
  });

  final List<Building> searchResults;
  final String searchQuery;
  final Building? selectedBuilding;
  final MapRoute? route;
  final LocationSample? currentLocation;
  final ValueChanged<Building> onSelectBuilding;

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  GoogleMapController? _controller;

  @override
  void dispose() {
    // google_maps_flutter_web can assert during teardown if dispose runs before
    // the platform view has fully built. The widget lifecycle already releases
    // the web view; keep explicit controller disposal for native platforms only.
    if (!kIsWeb) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GoogleMapView oldWidget) {
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
      return;
    }

    final newLocation = widget.currentLocation;
    final oldLocation = oldWidget.currentLocation;
    if (_controller != null &&
        newLocation != null &&
        (oldLocation == null ||
            newLocation.latitude != oldLocation.latitude ||
            newLocation.longitude != oldLocation.longitude)) {
      unawaited(
        _controller!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(newLocation.latitude, newLocation.longitude),
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
              l10n.googleMapUnavailable,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(widget.selectedBuilding?.name ?? l10n.mapLoadErrorDescription),
          ],
        ),
      );
    }

    final visibleBuildings = resolveVisibleBuildings(
      searchResults: widget.searchResults,
      searchQuery: widget.searchQuery,
      selectedBuilding: widget.selectedBuilding,
    );

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-33.7738, 151.1130),
        zoom: 15.5,
      ),
      onMapCreated: (controller) {
        _controller = controller;
      },
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      myLocationEnabled: widget.currentLocation != null,
      myLocationButtonEnabled: false,
      markers: visibleBuildings.map((building) {
        final latitude = building.latitude!;
        final longitude = building.longitude!;
        final isSelected = widget.selectedBuilding?.id == building.id;
        return Marker(
          markerId: MarkerId(building.id),
          position: LatLng(latitude, longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
          ),
          alpha: isSelected ? 1.0 : 0.6,
          zIndexInt: isSelected ? 1 : 0,
          infoWindow: InfoWindow(title: building.name, snippet: building.id),
          onTap: () => widget.onSelectBuilding(building),
        );
      }).toSet(),
      polylines: widget.route == null || widget.route!.encodedPolyline.isEmpty
          ? const <Polyline>{}
          : {
              Polyline(
                polylineId: const PolylineId('shared_route'),
                points: MapPolylineCodec.decode(widget.route!.encodedPolyline)
                    .map((point) => LatLng(point.latitude, point.longitude))
                    .toList(),
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
}
