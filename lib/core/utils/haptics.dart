import 'package:flutter/services.dart';

/// Macquarie University haptic feedback wrapper.
///
/// Respects the user's "Haptic Feedback" preference.
abstract final class MqHaptics {
  /// Triggers a light impact vibration if [isEnabled] is true.
  static Future<void> light(bool isEnabled) async {
    if (isEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  /// Triggers a medium impact vibration if [isEnabled] is true.
  static Future<void> medium(bool isEnabled) async {
    if (isEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Triggers a heavy impact vibration if [isEnabled] is true.
  static Future<void> heavy(bool isEnabled) async {
    if (isEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Triggers a selection click vibration if [isEnabled] is true.
  static Future<void> selection(bool isEnabled) async {
    if (isEnabled) {
      await HapticFeedback.selectionClick();
    }
  }
}
