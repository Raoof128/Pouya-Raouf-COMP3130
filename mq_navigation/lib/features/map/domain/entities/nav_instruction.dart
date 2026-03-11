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
    final navigationInstruction =
        json['navigationInstruction'] as Map<String, dynamic>?;
    return NavInstruction(
      text:
          (navigationInstruction?['instructions'] as String?) ??
          (json['instructions'] as String?) ??
          '',
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      maneuver: json['maneuver'] as String?,
    );
  }
}
