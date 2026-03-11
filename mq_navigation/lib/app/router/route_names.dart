/// Named route constants used throughout the app.
abstract final class RouteNames {
  // Auth flow
  static const String splash = 'splash';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String verifyEmail = 'verify-email';
  static const String resetPassword = 'reset-password';
  static const String mfa = 'mfa';
  static const String onboarding = 'onboarding';
  static const String notifications = 'notifications';

  // Shell tabs
  static const String home = 'home';
  static const String calendar = 'calendar';
  static const String map = 'map';
  static const String feed = 'feed';
  static const String settings = 'settings';

  // Detail screens (pushed on top of shell)
  static const String unitDetail = 'unit-detail';
  static const String deadlineDetail = 'deadline-detail';
  static const String examDetail = 'exam-detail';
  static const String eventDetail = 'event-detail';
  static const String buildingDetail = 'building-detail';
  static const String profileEdit = 'profile-edit';
}
