import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
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

/// 18 Wally's Walk entrance — used as fallback when GPS is unavailable
/// (e.g. emulators, web, or when location services fail).
const _campusFallback = LocationSample(
  latitude: -33.77388,
  longitude: 151.11275,
  accuracy: 100,
);

class LocationSource {
  const LocationSource();

  bool get _isSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<LocationPermissionState> ensurePermission() async {
    if (!_isSupported) {
      // On web/desktop, treat as "granted" so routing can use the fallback location.
      return LocationPermissionState.granted;
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
    if (!_isSupported) {
      // Web / desktop / unsupported platforms: return campus center.
      debugPrint('LocationSource: platform unsupported, using campus fallback');
      return _campusFallback;
    }

    final permission = await ensurePermission();
    if (permission != LocationPermissionState.granted) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).timeout(const Duration(seconds: 10));
      return LocationSample(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      // GPS failed (common on emulators) — fall back to campus center.
      debugPrint('LocationSource: GPS failed ($e), using campus fallback');
      return _campusFallback;
    }
  }

  Stream<LocationSample> watch() async* {
    if (!_isSupported) {
      // Web / desktop: no real-time location updates available.
      return;
    }

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

  Future<void> openLocationSettings() async {
    if (!_isSupported) return;
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    if (!_isSupported) return;
    await Geolocator.openAppSettings();
  }
}

final locationSourceProvider = Provider<LocationSource>((ref) {
  return const LocationSource();
});
