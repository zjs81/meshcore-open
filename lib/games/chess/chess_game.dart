import 'dart:convert';
import 'dart:typed_data';

import 'package:chess/chess.dart' as rules;

import '../hash_chain.dart';
import 'chess_packets.dart';
import 'chess_position_codec.dart';

enum ChessSide {
  white,
  black;

  ChessSide get other => this == white ? black : white;

  /// Side that makes half-move [ply] (ply 1 is white's first move).
  static ChessSide moverOfPly(int ply) => ply.isOdd ? white : black;
}

enum ChessGameStatus {
  /// An invite nobody has accepted yet.
  invite,

  /// We accepted; waiting for the inviter's confirmation (a game info
  /// packet listing our commitment).
  starting,
  active,
  finished,
}

enum ChessEndReason {
  checkmate,
  resignation,
  timeout,
  drawAgreed,
  stalemate,
  insufficientMaterial,
  fiftyMoves,
  repetition,
  cancelled,
  declined,
  expired,

  /// Someone else's accept was confirmed for an invite we accepted.
  taken,
}

/// One player's identity in a game: their name (unauthenticated) and the
/// hash chain values verified so far.
class ChessPlayer {
  final String name;
  final Uint8List commitment;
  Uint8List lastValue;
  int lastIndex;

  ChessPlayer({
    required this.name,
    required this.commitment,
    Uint8List? lastValue,
    this.lastIndex = 0,
  }) : lastValue = lastValue ?? commitment;

  /// Accepts [value] when it extends this player's chain, returning true.
  bool verifyAndAdvance(Uint8List value) {
    final steps = hashChainDistance(value, lastValue);
    if (steps == null || steps == 0) return false;
    lastValue = value;
    lastIndex += steps;
    return true;
  }

  /// True when [value] is on this player's chain at or after the last
  /// verified value (a valid new value or an exact duplicate).
  bool owns(Uint8List value) => hashChainDistance(value, lastValue) != null;

  Map<String, dynamic> toJson() => {
    'name': name,
    'commitment': _hex(commitment),
    'last': _hex(lastValue),
    'index': lastIndex,
  };

  static ChessPlayer? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final commitment = _unhex(json['commitment']);
    if (name is! String || commitment == null) return null;
    return ChessPlayer(
      name: name,
      commitment: commitment,
      lastValue: _unhex(json['last']) ?? commitment,
      lastIndex: json['index'] is int ? json['index'] as int : 0,
    );
  }
}

/// State of one chess game on one channel, as seen from this radio.
class ChessGame {
  static const String startFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  final String channelId;
  final int gameId;

  ChessGameStatus status;
  ChessDeadline deadline;
  ChessColourPreference colourPreference;

  /// From the invite. Null when we only heard the game later.
  ChessPlayer? inviter;
  String? targetName;
  ChessPlayer? white;
  ChessPlayer? black;

  /// Our own chain seed (hex) when we are a player or the inviter.
  String? mySeedHex;
  int myNextChainIndex;

  /// Which side we play, or null when watching.
  ChessSide? mySide;

  /// True when we posted the invite.
  bool iAmInviter;

  /// Position the move history below starts from: the start position, or a
  /// position adopted after missed moves.
  String baseFen;
  List<String> uciSinceBase;

  /// SAN of each half-move so far; null for moves we never heard.
  List<String?> sanMoves;
  int ply;
  String fen;

  /// Whether [fen] is known. False for a game first heard through a game
  /// info packet, until a move arrives.
  bool hasPosition;
  String? lastMoveUci;

  /// Latest move packet heard or sent, kept so any holder can re-send it.
  Uint8List? lastMovePacket;

  ChessSide? drawOfferedBy;
  ChessSide? winner;
  ChessEndReason? endReason;

  int createdAtMs;
  int? startedAtMs;
  int lastMoveAtMs;
  int lastActivityMs;
  int? lastAnsweredRequestAtMs;

  rules.Chess? _board;

  ChessGame({
    required this.channelId,
    required this.gameId,
    required this.status,
    required this.deadline,
    this.colourPreference = ChessColourPreference.random,
    this.inviter,
    this.targetName,
    this.white,
    this.black,
    this.mySeedHex,
    this.myNextChainIndex = 1,
    this.mySide,
    this.iAmInviter = false,
    String? baseFen,
    List<String>? uciSinceBase,
    List<String?>? sanMoves,
    this.ply = 0,
    String? fen,
    this.hasPosition = true,
    this.lastMoveUci,
    this.lastMovePacket,
    this.drawOfferedBy,
    this.winner,
    this.endReason,
    required this.createdAtMs,
    this.startedAtMs,
    int? lastMoveAtMs,
    int? lastActivityMs,
    this.lastAnsweredRequestAtMs,
  }) : baseFen = baseFen ?? startFen,
       uciSinceBase = uciSinceBase ?? <String>[],
       sanMoves = sanMoves ?? <String?>[],
       fen = fen ?? startFen,
       lastMoveAtMs = lastMoveAtMs ?? createdAtMs,
       lastActivityMs = lastActivityMs ?? createdAtMs;

  String get key => gameKey(channelId, gameId);

  static String gameKey(String channelId, int gameId) => '$channelId:$gameId';

  bool get isPlayer => mySide != null;
  bool get isOpen => status != ChessGameStatus.finished;

  /// Players are known (we can verify their actions).
  bool get hasPlayers => white != null && black != null;

  ChessSide get sideToMove => ChessSide.moverOfPly(ply + 1);

  bool get isMyTurn =>
      status == ChessGameStatus.active && hasPosition && mySide == sideToMove;

  ChessPlayer? playerOf(ChessSide side) =>
      side == ChessSide.white ? white : black;

  String? nameOf(ChessSide side) => playerOf(side)?.name;

  /// Which side's chain [value] belongs to, if any.
  ChessSide? sideOwning(Uint8List value) {
    if (white?.owns(value) ?? false) return ChessSide.white;
    if (black?.owns(value) ?? false) return ChessSide.black;
    return null;
  }

  HashChain? get myChain {
    final seed = _unhex(mySeedHex);
    return seed == null ? null : HashChain(seed);
  }

  /// The next value of our chain, advancing the counter.
  Uint8List? takeMyChainValue() {
    final chain = myChain;
    if (chain == null || myNextChainIndex > HashChain.length) return null;
    return chain.valueAt(myNextChainIndex++);
  }

  /// Rules engine at the current position, with as much history as we have
  /// (needed for repetition).
  rules.Chess get board {
    final cached = _board;
    if (cached != null) return cached;
    final b = rules.Chess.fromFEN(baseFen, check_validity: false);
    for (final uci in uciSinceBase) {
      final move = findLegalMove(b, uci);
      if (move == null) break;
      b.move(move);
    }
    if (b.fen != fen) {
      // History did not replay cleanly; fall back to the position alone.
      return _board = rules.Chess.fromFEN(fen, check_validity: false);
    }
    return _board = b;
  }

  /// Legal moves in the current position as UCI strings, sorted. A move's
  /// index in this list is what a move packet carries.
  List<String> legalUci() => sortedLegalUci(board);

  /// Applies the move with UCI [uci] by [side] as half-move [ply] + 1.
  /// Returns false when it is not legal.
  bool applyUci(String uci) {
    final b = board;
    final move = findLegalMove(b, uci);
    if (move == null) return false;
    final san = b.move_to_san(move);
    b.move(move);
    ply++;
    sanMoves.add(san);
    uciSinceBase.add(uci);
    fen = b.fen;
    lastMoveUci = uci;
    drawOfferedBy = null;
    _checkGameOver(b);
    return true;
  }

  /// Takes [newFen] as the position after half-move [newPly], marking the
  /// moves in between as unknown.
  void adoptPosition(String newFen, int newPly) {
    while (sanMoves.length < newPly) {
      sanMoves.add(null);
    }
    if (sanMoves.length > newPly) sanMoves.removeRange(newPly, sanMoves.length);
    ply = newPly;
    baseFen = newFen;
    fen = newFen;
    uciSinceBase = <String>[];
    lastMoveUci = null;
    hasPosition = true;
    drawOfferedBy = null;
    _board = null;
    _checkGameOver(board);
  }

  void _checkGameOver(rules.Chess b) {
    if (status != ChessGameStatus.active) return;
    ChessEndReason? reason;
    if (b.in_checkmate) {
      reason = ChessEndReason.checkmate;
      winner = ChessSide.moverOfPly(ply);
    } else if (b.in_stalemate) {
      reason = ChessEndReason.stalemate;
    } else if (b.insufficient_material) {
      reason = ChessEndReason.insufficientMaterial;
    } else if (b.half_moves >= 100) {
      reason = ChessEndReason.fiftyMoves;
    } else if (b.in_threefold_repetition) {
      reason = ChessEndReason.repetition;
    }
    if (reason != null) finish(reason, winner: winner);
  }

  void finish(ChessEndReason reason, {ChessSide? winner}) {
    status = ChessGameStatus.finished;
    endReason = reason;
    this.winner = winner;
    drawOfferedBy = null;
  }

  /// The packed position for the current [fen].
  Uint8List packedPosition() => ChessPositionCodec.encodeFen(fen);

  /// Minutes since the game started, for move packets.
  int minutesSinceStart(int nowMs) {
    final start = startedAtMs ?? createdAtMs;
    return ((nowMs - start) ~/ 60000).clamp(0, 0xFFFF);
  }

  Map<String, dynamic> toJson() => {
    'channel': channelId,
    'id': gameId,
    'status': status.name,
    'deadline': deadline.code,
    'colour': colourPreference.code,
    if (inviter != null) 'inviter': inviter!.toJson(),
    if (targetName != null) 'target': targetName,
    if (white != null) 'white': white!.toJson(),
    if (black != null) 'black': black!.toJson(),
    if (mySeedHex != null) 'seed': mySeedHex,
    'nextChain': myNextChainIndex,
    if (mySide != null) 'side': mySide!.name,
    'inviterSelf': iAmInviter,
    'baseFen': baseFen,
    'uci': uciSinceBase,
    'san': sanMoves,
    'ply': ply,
    'fen': fen,
    'hasPosition': hasPosition,
    if (lastMoveUci != null) 'lastUci': lastMoveUci,
    if (lastMovePacket != null) 'lastPacket': base64Encode(lastMovePacket!),
    if (drawOfferedBy != null) 'draw': drawOfferedBy!.name,
    if (winner != null) 'winner': winner!.name,
    if (endReason != null) 'end': endReason!.name,
    'created': createdAtMs,
    if (startedAtMs != null) 'started': startedAtMs,
    'lastMove': lastMoveAtMs,
    'activity': lastActivityMs,
  };

  static ChessGame? fromJson(Object? json) {
    if (json is! Map) return null;
    try {
      final channel = json['channel'];
      final id = json['id'];
      final created = json['created'];
      if (channel is! String || id is! int || created is! int) return null;
      final packet = json['lastPacket'];
      return ChessGame(
        channelId: channel,
        gameId: id,
        status: _enumByName(
          ChessGameStatus.values,
          json['status'],
          ChessGameStatus.finished,
        ),
        deadline: ChessDeadline.fromCode(_int(json['deadline']) ?? 0),
        colourPreference: ChessColourPreference.fromCode(
          _int(json['colour']) ?? 0,
        ),
        inviter: ChessPlayer.fromJson(json['inviter']),
        targetName: json['target'] as String?,
        white: ChessPlayer.fromJson(json['white']),
        black: ChessPlayer.fromJson(json['black']),
        mySeedHex: json['seed'] as String?,
        myNextChainIndex: _int(json['nextChain']) ?? 1,
        mySide: _enumByNameOrNull(ChessSide.values, json['side']),
        iAmInviter: json['inviterSelf'] == true,
        baseFen: json['baseFen'] as String?,
        uciSinceBase: (json['uci'] as List?)?.whereType<String>().toList(),
        sanMoves: (json['san'] as List?)?.map((e) => e as String?).toList(),
        ply: _int(json['ply']) ?? 0,
        fen: json['fen'] as String?,
        hasPosition: json['hasPosition'] != false,
        lastMoveUci: json['lastUci'] as String?,
        lastMovePacket: packet is String ? base64Decode(packet) : null,
        drawOfferedBy: _enumByNameOrNull(ChessSide.values, json['draw']),
        winner: _enumByNameOrNull(ChessSide.values, json['winner']),
        endReason: _enumByNameOrNull(ChessEndReason.values, json['end']),
        createdAtMs: created,
        startedAtMs: _int(json['started']),
        lastMoveAtMs: _int(json['lastMove']),
        lastActivityMs: _int(json['activity']),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Legal moves of [board] as sorted UCI strings.
List<String> sortedLegalUci(rules.Chess board) {
  final moves = board.moves({'asObjects': true}).cast<rules.Move>();
  return moves.map(moveToUci).toList()..sort();
}

String moveToUci(rules.Move m) =>
    '${m.fromAlgebraic}${m.toAlgebraic}${m.promotion?.name ?? ''}';

rules.Move? findLegalMove(rules.Chess board, String uci) {
  for (final m in board.moves({'asObjects': true}).cast<rules.Move>()) {
    if (moveToUci(m) == uci) return m;
  }
  return null;
}

/// Whether [fen] describes a position the rules engine accepts.
bool isValidFen(String fen) => rules.Chess.validate_fen(fen)['valid'] == true;

int? _int(Object? v) => v is int ? v : null;

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    _enumByNameOrNull(values, name) ?? fallback;

T? _enumByNameOrNull<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List? _unhex(Object? hex) {
  if (hex is! String || hex.length.isOdd) return null;
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    final v = int.tryParse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    if (v == null) return null;
    out[i] = v;
  }
  return out;
}

String bytesToHex(List<int> bytes) => _hex(bytes);
