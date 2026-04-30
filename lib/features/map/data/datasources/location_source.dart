import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
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

/// Native location service wrapper powered by `geolocator`.
///
/// Handles Android/iOS permission flows, current position retrieval, and
/// live coordinate streaming during active navigation.
class LocationSource {
  const LocationSource();

  // We explicitly disable native location services on unsupported platforms
  // (like Web or Desktop) to avoid crashes when calling platform channels.
  // Instead, these platforms transparently use the [_campusFallback] mock data.
  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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

    // Platform-specific settings give a substantially more accurate fix on
    // Android: `forceLocationManager: true` bypasses the Play-Services Fused
    // Location Provider (which often returns Wi-Fi-triangulated estimates
    // that can be hundreds of metres off the true position) and uses the raw
    // OS LocationManager + GPS provider directly.
    final LocationSettings locationSettings =
        defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            forceLocationManager: true,
            timeLimit: const Duration(seconds: 15),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
            activityType: ActivityType.fitness,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: false,
          );

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 15));
      return LocationSample(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      // Fresh fix failed (slow GPS lock, emulator without mock provider,
      // indoors with weak signal). Try the OS's last-known fix — for a
      // real device this is the user's actual most-recent location, not
      // a synthetic campus fallback. Only as a last resort do we return
      // null so the controller can show the "location unavailable" banner
      // instead of silently teleporting the user to the campus centre.
      debugPrint('LocationSource: fresh fix failed ($e), trying last known');
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return LocationSample(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
            accuracy: lastKnown.accuracy,
            timestamp: lastKnown.timestamp,
          );
        }
      } catch (e2) {
        debugPrint('LocationSource: last-known lookup failed ($e2)');
      }
      return null;
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

    // Same platform-specific tuning as `getCurrentLocation` — raw GPS on
    // Android avoids Wi-Fi-triangulation jitter that can pull the
    // navigation dot tens of metres off the route polyline.
    final LocationSettings locationSettings =
        defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
            forceLocationManager: true,
            intervalDuration: const Duration(seconds: 2),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
            activityType: ActivityType.fitness,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: false,
          );

    yield* Geolocator.getPositionStream(locationSettings: locationSettings).map(
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
