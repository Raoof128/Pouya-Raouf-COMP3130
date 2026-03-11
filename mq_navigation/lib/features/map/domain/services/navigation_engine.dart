import 'dart:async';

import 'package:mq_navigation/features/map/domain/entities/nav_session.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

abstract interface class NavigationEngine {
  Stream<NavSession> start(MapRoute route);
  void stop();
}

class NoopNavigationEngine implements NavigationEngine {
  final _controller = StreamController<NavSession>.broadcast();

  @override
  Stream<NavSession> start(MapRoute route) {
    _controller.add(NavSession(route: route));
    return _controller.stream;
  }

  @override
  void stop() {}
}
