import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/map/domain/entities/nav_session.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/domain/services/navigation_engine.dart';

@immutable
class NavigationState {
  const NavigationState({this.session});

  final NavSession? session;
}

final navigationControllerProvider =
    NotifierProvider<NavigationController, NavigationState>(
      NavigationController.new,
    );

class NavigationController extends Notifier<NavigationState> {
  StreamSubscription<NavSession>? _subscription;

  @override
  NavigationState build() => const NavigationState();

  void start(MapRoute route) {
    _subscription?.cancel();
    final engine = NoopNavigationEngine();
    _subscription = engine.start(route).listen((session) {
      state = NavigationState(session: session);
    });
  }

  void stop() {
    _subscription?.cancel();
    state = const NavigationState();
  }
}
