class DeliveryObservation {
  final String contactKey;
  final int pathLength;
  final int messageBytes;
  final int secondsSinceLastRx;
  final bool isFlood;
  final int deliveryMs;
  final DateTime timestamp;

  DeliveryObservation({
    required this.contactKey,
    required this.pathLength,
    required this.messageBytes,
    required this.secondsSinceLastRx,
    required this.isFlood,
    required this.deliveryMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'contact_key': contactKey,
      'path_length': pathLength,
      'message_bytes': messageBytes,
      'seconds_since_last_rx': secondsSinceLastRx,
      'is_flood': isFlood,
      'delivery_ms': deliveryMs,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DeliveryObservation.fromJson(Map<String, dynamic> json) {
    return DeliveryObservation(
      contactKey: json['contact_key'] as String,
      pathLength: json['path_length'] as int,
      messageBytes: json['message_bytes'] as int,
      secondsSinceLastRx: json['seconds_since_last_rx'] as int? ?? 0,
      isFlood: json['is_flood'] as bool,
      deliveryMs: json['delivery_ms'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
