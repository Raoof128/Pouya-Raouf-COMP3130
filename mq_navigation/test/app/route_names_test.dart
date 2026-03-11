import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/app/router/route_names.dart';

void main() {
  group('RouteNames', () {
    test('auth routes are defined', () {
      expect(RouteNames.splash, 'splash');
      expect(RouteNames.login, 'login');
      expect(RouteNames.signup, 'signup');
      expect(RouteNames.verifyEmail, 'verify-email');
      expect(RouteNames.resetPassword, 'reset-password');
      expect(RouteNames.mfa, 'mfa');
      expect(RouteNames.onboarding, 'onboarding');
      expect(RouteNames.notifications, 'notifications');
    });

    test('shell tab routes are defined', () {
      expect(RouteNames.home, 'home');
      expect(RouteNames.calendar, 'calendar');
      expect(RouteNames.map, 'map');
      expect(RouteNames.feed, 'feed');
      expect(RouteNames.settings, 'settings');
    });

    test('detail routes are defined', () {
      expect(RouteNames.unitDetail, 'unit-detail');
      expect(RouteNames.deadlineDetail, 'deadline-detail');
      expect(RouteNames.examDetail, 'exam-detail');
      expect(RouteNames.eventDetail, 'event-detail');
      expect(RouteNames.buildingDetail, 'building-detail');
      expect(RouteNames.profileEdit, 'profile-edit');
    });
  });
}
