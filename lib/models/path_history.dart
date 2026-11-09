class PathRecord {
  final int hopCount;
  final int tripTimeMs;
  final DateTime? timestamp;
  final bool wasFloodDiscovery;
  final List<int> pathBytes;
  final int successCount;
  final int failureCount;
  final double routeWeight;

  /// Deliveries and failures with older results faded out (see
  /// `routeDecayFactor`), as of [statsAt]. Auto routing samples from these so
  /// a route that worked last month but fails today loses its rank quickly.
  final double recentSuccess;
  final double recentFailure;
  final DateTime? statsAt;

  PathRecord({
    required this.hopCount,
    required this.tripTimeMs,
    required this.timestamp,
    required this.wasFloodDiscovery,
    required this.pathBytes,
    required this.successCount,
    required this.failureCount,
    this.routeWeight = 1.0,
    double? recentSuccess,
    double? recentFailure,
    DateTime? statsAt,
  }) : recentSuccess = recentSuccess ?? _seedRecent(successCount),
       recentFailure = recentFailure ?? _seedRecent(failureCount),
       statsAt = statsAt ?? timestamp;

  /// History saved before faded stats existed: start from the lifetime
  /// counts, capped so years of old results can't outvote new ones.
  static double _seedRecent(int count) => count.clamp(0, 5).toDouble();

  /// Bytes per hop, derived from the stored path.
  int get hashWidth => hopCount > 0 && pathBytes.length >= hopCount
      ? (pathBytes.length ~/ hopCount).clamp(1, 4)
      : 1;

  String get displayText =>
      '$hopCount ${hopCount == 1 ? 'hop' : 'hops'} - ${(tripTimeMs / 1000).toStringAsFixed(2)}s';

  Map<String, dynamic> toJson() {
    return {
      'hop_count': hopCount,
      'trip_time_ms': tripTimeMs,
      'timestamp': timestamp?.toIso8601String(),
      'was_flood': wasFloodDiscovery,
      'path_bytes': pathBytes,
      'success_count': successCount,
      'failure_count': failureCount,
      'route_weight': routeWeight,
      'recent_success': recentSuccess,
      'recent_failure': recentFailure,
      'stats_at': statsAt?.toIso8601String(),
    };
  }

  factory PathRecord.fromJson(Map<String, dynamic> json) {
    return PathRecord(
      hopCount: json['hop_count'] as int,
      tripTimeMs: json['trip_time_ms'] as int,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      wasFloodDiscovery: json['was_flood'] as bool,
      pathBytes:
          (json['path_bytes'] as List?)?.map((b) => b as int).toList() ?? [],
      successCount: json['success_count'] as int? ?? 0,
      failureCount: json['failure_count'] as int? ?? 0,
      routeWeight: (json['route_weight'] as num?)?.toDouble() ?? 1.0,
      recentSuccess: (json['recent_success'] as num?)?.toDouble(),
      recentFailure: (json['recent_failure'] as num?)?.toDouble(),
      statsAt: json['stats_at'] != null
          ? DateTime.tryParse(json['stats_at'] as String)
          : null,
    );
  }
}

class ContactPathHistory {
  final String contactPubKeyHex;
  final List<PathRecord> recentPaths;

  ContactPathHistory({
    required this.contactPubKeyHex,
    required this.recentPaths,
  });

  PathRecord? get fastest {
    if (recentPaths.isEmpty) return null;
    return recentPaths.reduce((a, b) => a.tripTimeMs < b.tripTimeMs ? a : b);
  }

  PathRecord? get mostRecent {
    if (recentPaths.isEmpty) return null;
    return recentPaths.first;
  }

  Map<String, dynamic> toJson() {
    return {'recent_paths': recentPaths.map((p) => p.toJson()).toList()};
  }

  factory ContactPathHistory.fromJson(
    String contactPubKeyHex,
    Map<String, dynamic> json,
  ) {
    final pathsList =
        (json['recent_paths'] as List?)
            ?.map((p) => PathRecord.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return ContactPathHistory(
      contactPubKeyHex: contactPubKeyHex,
      recentPaths: pathsList,
    );
  }
}
