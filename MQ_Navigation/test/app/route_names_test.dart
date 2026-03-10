import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/app/router/route_names.dart';

void main() {
  group('RouteNames', () {
    test('splash route is defined', () {
      expect(RouteNames.splash, 'splash');
    });

    test('shell tab routes are defined', () {
      expect(RouteNames.home, 'home');
      expect(RouteNames.map, 'map');
      expect(RouteNames.settings, 'settings');
    });

    test('detail routes are defined', () {
      expect(RouteNames.buildingDetail, 'building-detail');
      expect(RouteNames.directions, 'directions');
    });
  });
}
