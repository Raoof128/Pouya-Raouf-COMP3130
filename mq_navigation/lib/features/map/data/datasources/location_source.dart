import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

enum LocationPermissionState {
  granted,
  denied,
  deniedForever,
  servicesDisabled,
  unsupported,
}

class LocationSource {
  const LocationSource();

  bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  Future<LocationPermissionState> ensurePermission() async {
    if (!_isSupported) {
      return LocationPermissionState.unsupported;
    }

    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      return LocationPermissionState.servicesDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionState.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationPermissionState.denied;
    }

    return LocationPermissionState.granted;
  }

  Future<LocationSample?> getCurrentLocation() async {
    final permission = await ensurePermission();
    if (permission != LocationPermissionState.granted) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
    return LocationSample(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  Stream<LocationSample> watch() async* {
    final permission = await ensurePermission();
    if (permission != LocationPermissionState.granted) {
      return;
    }

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map(
      (position) => LocationSample(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      ),
    );
  }

  Future<void> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() {
    return Geolocator.openAppSettings();
  }
}

final locationSourceProvider = Provider<LocationSource>((ref) {
  return const LocationSource();
});
