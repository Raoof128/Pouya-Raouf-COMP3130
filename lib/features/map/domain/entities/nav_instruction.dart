import 'package:flutter/foundation.dart';

@immutable
class NavInstruction {
  const NavInstruction({
    required this.text,
    required this.distanceMeters,
    this.maneuver,
  });

  final String text;
  final int distanceMeters;
  final String? maneuver;

  factory NavInstruction.fromJson(Map<String, dynamic> json) {
    // Directions API uses 'html_instructions'; Routes API v2 uses
    // 'navigationInstruction.instructions'.
    final rawHtml = json['html_instructions'] as String?;
    final navigationInstruction =
        json['navigationInstruction'] as Map<String, dynamic>?;
    final text = rawHtml != null
        ? _stripHtml(rawHtml)
        : (navigationInstruction?['instructions'] as String?) ??
              (json['instruction'] as String?) ??
              (json['instructions'] as String?) ??
              '';

    // Directions API nests distance in {value, text}; Routes API v2 uses
    // a flat 'distanceMeters' integer.
    final distanceMap = json['distance'] as Map<String, dynamic>?;
    final distanceMeters =
        (distanceMap?['value'] as num?)?.toInt() ??
        (json['distanceMeters'] as num?)?.toInt() ??
        0;

    return NavInstruction(
      text: text,
      distanceMeters: distanceMeters,
      maneuver: json['maneuver'] as String?,
    );
  }

  /// Remove HTML tags from Directions API instructions.
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }
}
