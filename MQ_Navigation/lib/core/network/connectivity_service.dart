import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

/// Whether the device currently has network connectivity.
enum ConnectivityStatus { online, offline }

/// Monitors device network state and exposes a reactive stream.
class ConnectivityService {
  ConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen(_update);
    // Perform an immediate check so status is accurate from the start.
    unawaited(check());
  }

  final _controller = StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _status = ConnectivityStatus.online;

  ConnectivityStatus get status => _status;
  Stream<ConnectivityStatus> get stream => _controller.stream;

  void _update(List<ConnectivityResult> results) {
    final newStatus = results.contains(ConnectivityResult.none)
        ? ConnectivityStatus.offline
        : ConnectivityStatus.online;

    if (newStatus != _status) {
      _status = newStatus;
      _controller.add(_status);
      AppLogger.info('Connectivity changed', _status.name);
    }
  }

  Future<ConnectivityStatus> check() async {
    final results = await Connectivity().checkConnectivity();
    _update(results);
    return _status;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

/// Global connectivity service provider.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// Reactive connectivity status provider.
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.stream;
});
