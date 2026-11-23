import '../../../l10n/app_localizations.dart';
import '../chess_game.dart';
import '../chess_packets.dart';

/// Localized labels shared by the chess sheet and screen.
extension ChessText on AppLocalizations {
  String chessDeadlineLabel(ChessDeadline d) => switch (d) {
    ChessDeadline.none => chess_deadlineNone,
    ChessDeadline.min15 => chess_deadline15m,
    ChessDeadline.hour1 => chess_deadline1h,
    ChessDeadline.hours6 => chess_deadline6h,
    ChessDeadline.day1 => chess_deadline1d,
    ChessDeadline.days3 => chess_deadline3d,
  };

  String chessColourLabel(ChessColourPreference c) => switch (c) {
    ChessColourPreference.random => chess_colourRandom,
    ChessColourPreference.white => chess_colourWhite,
    ChessColourPreference.black => chess_colourBlack,
  };

  String chessEndReason(ChessEndReason r) => switch (r) {
    ChessEndReason.checkmate => chess_endCheckmate,
    ChessEndReason.resignation => chess_endResignation,
    ChessEndReason.timeout => chess_endTimeout,
    ChessEndReason.drawAgreed => chess_endDrawAgreed,
    ChessEndReason.stalemate => chess_endStalemate,
    ChessEndReason.insufficientMaterial => chess_endInsufficient,
    ChessEndReason.fiftyMoves => chess_endFiftyMoves,
    ChessEndReason.repetition => chess_endRepetition,
    ChessEndReason.cancelled => chess_endCancelled,
    ChessEndReason.declined => chess_endDeclined,
    ChessEndReason.expired => chess_endExpired,
    ChessEndReason.taken => chess_endTaken,
  };

  /// "Alice vs Bob", with placeholders for unknown players.
  String chessPlayers(ChessGame game) => chess_vs(
    game.nameOf(ChessSide.white) ?? chess_unknownPlayer,
    game.nameOf(ChessSide.black) ?? chess_unknownPlayer,
  );

  /// Result line of a finished game: "Bob won · Checkmate" or "Draw · …".
  String chessResult(ChessGame game) {
    final reason = game.endReason;
    final reasonText = reason == null ? '' : chessEndReason(reason);
    final winner = game.winner;
    final noGame = {
      ChessEndReason.cancelled,
      ChessEndReason.declined,
      ChessEndReason.expired,
      ChessEndReason.taken,
    }.contains(reason);
    if (noGame) return reasonText;
    final head = winner == null
        ? chess_resultDraw
        : chess_resultWon(game.nameOf(winner) ?? chess_unknownPlayer);
    return reasonText.isEmpty ? head : chess_resultWithReason(head, reasonText);
  }

  /// Compact remaining time: "43 min", "5 h 10 min", "2 d 3 h".
  String chessDuration(Duration d) {
    if (d.inDays >= 1) return chess_timeDays(d.inDays, d.inHours % 24);
    if (d.inHours >= 1) return chess_timeHours(d.inHours, d.inMinutes % 60);
    return chess_timeMinutes(d.inMinutes < 1 ? 1 : d.inMinutes);
  }
}
