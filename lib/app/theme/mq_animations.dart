import 'package:flutter/material.dart';

/// Macquarie University animation timing tokens.
///
/// Provides consistent durations and curves across the app,
/// preventing magic-number animation values.
abstract final class MqAnimations {
  // ── Durations ────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration sheet = Duration(milliseconds: 350);

  // ── Curves ───────────────────────────────────────────────
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve sheetCurve = Curves.easeOutCubic;
}
