import 'package:flutter/foundation.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

@immutable
class NavSession {
  const NavSession({required this.route, this.currentInstructionIndex = 0});

  final MapRoute route;
  final int currentInstructionIndex;
}
