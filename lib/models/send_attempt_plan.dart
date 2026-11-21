/// How many times a direct message is sent, split by route kind.
///
/// Direct attempts use a known route. Flood attempts ask the mesh to flood.
/// With [rotateRoutes] on (and no manual path), the direct attempts run first
/// and the flood attempts follow. With it off, every attempt stays on the
/// contact's current path and only that path's limit applies.
class SendAttemptPlan {
  static const int minDirectRetries = 0;
  static const int maxDirectRetries = 15;
  static const int defaultDirectRetries = 4;

  static const int minFloodRetries = 0;
  static const int maxFloodRetries = 10;

  /// One flood, matching the previous single limit of 5 whose last attempt
  /// flooded when auto route rotation was on (4 direct + 1 flood).
  static const int defaultFloodRetries = 1;

  static const int minLoginAttempts = 1;
  static const int maxLoginAttempts = 10;
  static const int defaultLoginAttempts = 5;

  final int directRetries;
  final int floodRetries;

  /// When true, direct attempts may change route and are followed by floods.
  final bool rotateRoutes;

  const SendAttemptPlan({
    required this.directRetries,
    required this.floodRetries,
    required this.rotateRoutes,
  });

  static int clampDirect(int value) =>
      value.clamp(minDirectRetries, maxDirectRetries);

  static int clampFlood(int value) =>
      value.clamp(minFloodRetries, maxFloodRetries);

  static int clampLogin(int value) =>
      value.clamp(minLoginAttempts, maxLoginAttempts);

  /// Reads the split limits, or derives them from the old single
  /// `max_message_retries` value. That value was a total: every attempt but
  /// the last used a route, then one attempt flooded.
  static ({int direct, int flood}) retriesFromJson(Map<String, dynamic> json) {
    final direct = json['max_direct_retries'];
    final flood = json['max_flood_retries'];
    if (direct is num || flood is num) {
      return (
        direct: clampDirect(
          direct is num ? direct.toInt() : defaultDirectRetries,
        ),
        flood: clampFlood(flood is num ? flood.toInt() : defaultFloodRetries),
      );
    }
    final legacy = json['max_message_retries'];
    if (legacy is num) {
      return (
        direct: clampDirect(legacy.toInt() - 1),
        flood: defaultFloodRetries,
      );
    }
    return (direct: defaultDirectRetries, flood: defaultFloodRetries);
  }

  /// How many times to send before giving up.
  ///
  /// [floodPath] is the contact's fixed path. It is ignored while rotating,
  /// because those sends spend [directRetries] then [floodRetries]. A plan
  /// with both limits at 0 still sends once, on the current path.
  int attemptLimit({required bool floodPath}) {
    if (rotateRoutes) {
      final total = directRetries + floodRetries;
      return total < 1 ? 1 : total;
    }
    final count = floodPath ? floodRetries : directRetries;
    return count < 1 ? 1 : count;
  }

  /// First attempt index that should flood, or null when this plan never
  /// switches onto a flood (rotation off, or no flood attempts configured).
  int? get floodFromAttempt {
    if (!rotateRoutes || floodRetries < 1) return null;
    return directRetries;
  }
}
