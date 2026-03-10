import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/map/data/services/directions_service.dart';
import 'package:mq_navigation/features/map/data/services/location_service.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';

/// Shows walking directions from the user's current location to [destination].
class DirectionsPage extends ConsumerStatefulWidget {
  const DirectionsPage({super.key, required this.destination});

  final Building destination;

  @override
  ConsumerState<DirectionsPage> createState() => _DirectionsPageState();
}

class _DirectionsPageState extends ConsumerState<DirectionsPage> {
  Position? _currentPosition;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _walkingMinutes;

  @override
  void initState() {
    super.initState();
    _loadDirections();
  }

  Future<void> _loadDirections() async {
    final locationService = ref.read(locationServiceProvider);

    final position = await locationService.getCurrentPosition();
    if (position == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not determine your location. '
            'Please enable location services.';
      });
      return;
    }

    setState(() => _currentPosition = position);

    final start = LatLng(position.latitude, position.longitude);
    final end = LatLng(
      widget.destination.routingLatitude!,
      widget.destination.routingLongitude!,
    );

    final route = await DirectionsService.getRoute(start, end);

    final distance = locationService.distanceBetween(
      position.latitude,
      position.longitude,
      widget.destination.routingLatitude!,
      widget.destination.routingLongitude!,
    );

    setState(() {
      _routePoints = route;
      _walkingMinutes = DirectionsService.estimateWalkingMinutes(distance);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;

    return Scaffold(
      appBar: AppBar(
        title: Text('Directions to ${dest.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadDirections();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildDirectionsMap(),
    );
  }

  Widget _buildDirectionsMap() {
    if (!EnvConfig.hasGoogleMapsKey) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Google Maps API key not configured',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Set GOOGLE_MAPS_API_KEY via --dart-define to enable directions.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final dest = widget.destination;
    final destLatLng = LatLng(dest.routingLatitude!, dest.routingLongitude!);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: destLatLng,
            zoom: 16,
          ),
          polylines: {
            if (_routePoints.isNotEmpty)
              Polyline(
                polylineId: const PolylineId('route'),
                points: _routePoints,
                color: MqColors.red,
                width: 5,
              ),
          },
          markers: {
            Marker(
              markerId: const MarkerId('destination'),
              position: destLatLng,
              infoWindow: InfoWindow(title: dest.name),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
            if (_currentPosition != null)
              Marker(
                markerId: const MarkerId('current'),
                position: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                infoWindow: const InfoWindow(title: 'You are here'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
        ),

        // Walking time card
        if (_walkingMinutes != null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.directions_walk, color: MqColors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_walkingMinutes min walk',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'to ${dest.name}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
