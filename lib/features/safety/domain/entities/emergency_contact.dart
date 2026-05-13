import 'package:flutter/foundation.dart';

@immutable
class EmergencyContact {
  const EmergencyContact({
    required this.label,
    required this.phoneNumber,
    required this.isEmergency,
    this.description,
  });

  final String label;
  final String phoneNumber;
  final bool isEmergency;
  final String? description;
}
