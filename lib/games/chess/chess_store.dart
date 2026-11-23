import 'dart:convert';

import '../../storage/prefs_manager.dart';
import 'chess_game.dart';

/// Per-radio list of chess games in preferences, keyed by the first 10 hex
/// chars of the radio's public key.
class ChessStore {
  static const String _keyPrefix = 'chess_games_';

  Future<void> _pending = Future.value();

  static String keyFor(String scope) => '$_keyPrefix$scope';

  /// Games saved for [scope]; records that fail to decode are skipped.
  List<ChessGame> load(String scope) {
    if (scope.isEmpty) return [];
    try {
      final raw = PrefsManager.instance.getString(keyFor(scope));
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map(ChessGame.fromJson).whereType<ChessGame>().toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves [games] for [scope]. Writes are serialized.
  Future<void> save(String scope, List<ChessGame> games) {
    if (scope.isEmpty) return Future.value();
    final json = jsonEncode(games.map((g) => g.toJson()).toList());
    return _pending = _pending.then((_) async {
      try {
        await PrefsManager.instance.setString(keyFor(scope), json);
      } catch (_) {}
    });
  }

  Future<void> flush() => _pending;
}
