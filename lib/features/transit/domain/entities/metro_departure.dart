class MetroDeparture {
  const MetroDeparture({
    required this.destination,
    required this.line,
    required this.minutesUntilDeparture,
    required this.mode,
    required this.platform,
    required this.stopId,
  });

  final String destination;
  final String line;
  final int minutesUntilDeparture;
  final String mode;
  final String platform;
  final String stopId;

  factory MetroDeparture.fromJson(Map<String, dynamic> json) {
    return MetroDeparture(
      destination: (json['destination'] as String?) ?? '',
      line: (json['line'] as String?) ?? '',
      minutesUntilDeparture:
          (json['minutesUntilDeparture'] as num?)?.toInt() ?? 0,
      mode: (json['mode'] as String?) ?? 'unknown',
      platform: (json['platform'] as String?) ?? '',
      stopId: (json['stopId'] as String?) ?? '',
    );
  }
}
