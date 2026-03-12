import 'package:mq_navigation/app/bootstrap/bootstrap.dart';
import 'package:mq_navigation/app/mq_navigation_app.dart';

/// Main entry point for the MQ Navigation application.
/// Delegates immediately to the bootstrap layer which handles all asynchronous
/// setup before the Flutter framework starts building widgets.
void main() {
  bootstrap(() => const MqNavigationApp());
}
