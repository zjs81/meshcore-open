import 'dart:async';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../hash_chain.dart';
import 'chess_game.dart';
import 'chess_link.dart';
import 'chess_packets.dart';
import 'chess_position_codec.dart';
import 'chess_store.dart';

/// Chess games played and watched on channels.
///
/// Packets arrive through [ChessLink.incoming]; every handler is idempotent,
/// so duplicates and repeats are harmless. Our own actions are sent first
/// and applied locally once the radio accepted them.
class ChessService extends ChangeNotifier {
  static const Duration inviteLifetime = Duration(hours: 24);
  static const Duration timeoutGrace = Duration(minutes: 10);
  static const Duration keepFinished = Duration(days: 7);
  static const Duration requestAnswerInterval = Duration(minutes: 1);
  static const int maxStoredGames = 50;

  final ChessLink link;
  final ChessStore store;
  final DateTime Function() _clock;
  final Random _random;
  final Duration _answerDelayMin;
  final Duration _answerDelayMax;

  final Map<String, ChessGame> _games = {};
  final Set<String> _sending = {};
  final Map<String, Timer> _pendingAnswers = {};
  StreamSubscription<ChessIncoming>? _sub;
  Timer? _housekeeping;
  String _scope = '';
  String? _viewingKey;
  bool _disposed = false;

  ChessService({
    required this.link,
    ChessStore? store,
    DateTime Function()? clock,
    Random? random,
    Duration answerDelayMin = const Duration(seconds: 2),
    Duration answerDelayMax = const Duration(seconds: 10),
    bool startHousekeeping = true,
  }) : store = store ?? ChessStore(),
       _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure(),
       _answerDelayMin = answerDelayMin,
       _answerDelayMax = answerDelayMax {
    _sub = link.incoming.listen(handleIncoming);
    link.addListener(_onLinkChanged);
    _loadScope(link.storageScope);
    if (startHousekeeping) {
      _housekeeping = Timer.periodic(
        const Duration(minutes: 1),
        (_) => housekeeping(),
      );
    }
  }

  int get _now => _clock().millisecondsSinceEpoch;

  // ---- queries ---------------------------------------------------------------

  /// Games on [channelId], newest activity first.
  List<ChessGame> gamesForChannel(String channelId) =>
      _games.values.where((g) => g.channelId == channelId).toList()
        ..sort((a, b) => b.lastActivityMs.compareTo(a.lastActivityMs));

  /// Live games plus open invites on [channelId].
  int openCountForChannel(String channelId) =>
      _games.values.where((g) => g.channelId == channelId && g.isOpen).length;

  ChessGame? game(String channelId, int gameId) =>
      _games[ChessGame.gameKey(channelId, gameId)];

  bool isSending(ChessGame game) => _sending.contains(game.key);

  bool get canSend => link.canSend;

  String get selfName => link.selfName;

  /// When the side to move runs out of time, or null without a deadline.
  DateTime? deadlineAt(ChessGame game) {
    final d = game.deadline.duration;
    if (d == null || game.status != ChessGameStatus.active) return null;
    return DateTime.fromMillisecondsSinceEpoch(game.lastMoveAtMs).add(d);
  }

  /// True when we may claim a win because the opponent let the deadline
  /// (plus grace) pass.
  bool canClaimTimeout(ChessGame game) {
    if (!game.isPlayer || game.isMyTurn) return false;
    if (game.status != ChessGameStatus.active) return false;
    final at = deadlineAt(game);
    return at != null && _clock().isAfter(at.add(timeoutGrace));
  }

  /// The screen showing [game] (no notifications for it), or null.
  set viewing(ChessGame? game) => _viewingKey = game?.key;

  // ---- our actions -----------------------------------------------------------

  /// Posts an open invite, or a direct challenge to [targetName].
  Future<ChessGame?> createInvite({
    required String channelId,
    ChessDeadline deadline = ChessDeadline.defaultValue,
    ChessColourPreference colour = ChessColourPreference.random,
    String? targetName,
  }) async {
    final chain = HashChain.generate(_random);
    final gameId = _newGameId(channelId);
    final packet = ChessInvitePacket(
      gameId: gameId,
      deadline: deadline,
      colour: colour,
      commitment: chain.commitment,
      inviterName: link.selfName,
      targetName: targetName,
    );
    final game = ChessGame(
      channelId: channelId,
      gameId: gameId,
      status: ChessGameStatus.invite,
      deadline: deadline,
      colourPreference: colour,
      inviter: ChessPlayer(name: link.selfName, commitment: chain.commitment),
      targetName: targetName,
      mySeedHex: bytesToHex(chain.seed),
      iAmInviter: true,
      createdAtMs: _now,
    );
    if (!await _send(game, packet)) return null;
    _games[game.key] = game;
    _changed();
    return game;
  }

  Future<bool> accept(ChessGame game) async {
    if (game.status != ChessGameStatus.invite || game.iAmInviter) return false;
    final chain = HashChain.generate(_random);
    final packet = ChessAcceptPacket(
      gameId: game.gameId,
      commitment: chain.commitment,
      accepterName: link.selfName,
    );
    if (!await _send(game, packet)) return false;
    game
      ..mySeedHex = bytesToHex(chain.seed)
      ..myNextChainIndex = 1
      ..status = ChessGameStatus.starting
      ..lastActivityMs = _now;
    _changed();
    return true;
  }

  /// Re-sends our accept while waiting for the inviter's confirmation.
  Future<bool> resendAccept(ChessGame game) async {
    if (game.status != ChessGameStatus.starting) return false;
    final chain = game.myChain;
    if (chain == null) return false;
    return _send(
      game,
      ChessAcceptPacket(
        gameId: game.gameId,
        commitment: chain.commitment,
        accepterName: link.selfName,
      ),
    );
  }

  Future<bool> decline(ChessGame game) async {
    if (game.status != ChessGameStatus.invite || game.iAmInviter) return false;
    final ok = await _send(
      game,
      ChessDeclinePacket(gameId: game.gameId, declinerName: link.selfName),
    );
    if (ok) {
      game.finish(ChessEndReason.declined);
      _touch(game);
    }
    return ok;
  }

  Future<bool> cancelInvite(ChessGame game) =>
      _sendAction(game, ChessPacketKind.cancel, (g, _) {
        g.finish(ChessEndReason.cancelled);
      }, allowedStatus: ChessGameStatus.invite);

  /// Plays [uci] (e.g. `e2e4`, `e7e8q`).
  Future<bool> makeMove(ChessGame game, String uci) async {
    if (!game.isMyTurn || isSending(game)) return false;
    final legal = game.legalUci();
    final index = legal.indexOf(uci);
    if (index < 0 || index > 255) return false;
    final value = game.takeMyChainValue();
    if (value == null) return false;
    // Work on a copy of the position so a failed send changes nothing.
    final probe = ChessGame.fromJson(game.toJson())!;
    probe.applyUci(uci);
    final packet = ChessMovePacket(
      gameId: game.gameId,
      ply: probe.ply & 0xFF,
      minutes: game.minutesSinceStart(_now),
      moveIndex: index,
      chainValue: value,
      position: probe.packedPosition(),
    );
    if (!await _send(game, packet)) {
      game.myNextChainIndex--;
      return false;
    }
    game.applyUci(uci);
    game.playerOf(game.mySide!)?.verifyAndAdvance(value);
    game
      ..lastMovePacket = packet.encode()
      ..lastMoveAtMs = _now;
    _touch(game);
    return true;
  }

  Future<bool> resign(ChessGame game) =>
      _sendAction(game, ChessPacketKind.resign, (g, side) {
        g.finish(ChessEndReason.resignation, winner: side.other);
      });

  Future<bool> offerDraw(ChessGame game) =>
      _sendAction(game, ChessPacketKind.drawOffer, (g, side) {
        g.drawOfferedBy = side;
      });

  Future<bool> acceptDraw(ChessGame game) {
    if (game.drawOfferedBy == null || game.drawOfferedBy == game.mySide) {
      return Future.value(false);
    }
    return _sendAction(game, ChessPacketKind.drawAccept, (g, _) {
      g.finish(ChessEndReason.drawAgreed);
    });
  }

  Future<bool> claimTimeout(ChessGame game) {
    if (!canClaimTimeout(game)) return Future.value(false);
    return _sendAction(game, ChessPacketKind.timeoutClaim, (g, side) {
      g.finish(ChessEndReason.timeout, winner: side);
    });
  }

  /// Asks the players for whatever we are missing: the game info when we
  /// cannot verify the players, the latest move otherwise.
  Future<bool> requestUpdate(ChessGame game) {
    if (game.status == ChessGameStatus.starting) return resendAccept(game);
    return _send(
      game,
      ChessRequestPacket(
        gameId: game.gameId,
        ply: game.ply & 0xFF,
        wantsInfo: !game.hasPlayers,
        wantsLatestMove: true,
      ),
    );
  }

  /// Forgets a finished game or an invite we only watched.
  void remove(ChessGame game) {
    if (_games.remove(game.key) != null) _changed();
  }

  Future<bool> _sendAction(
    ChessGame game,
    ChessPacketKind kind,
    void Function(ChessGame game, ChessSide side) apply, {
    ChessGameStatus allowedStatus = ChessGameStatus.active,
  }) async {
    if (game.status != allowedStatus || isSending(game)) return false;
    final side = game.mySide;
    if (side == null && !(kind == ChessPacketKind.cancel && game.iAmInviter)) {
      return false;
    }
    final value = game.takeMyChainValue();
    if (value == null) return false;
    final packet = ChessActionPacket(
      kind: kind,
      gameId: game.gameId,
      ply: game.ply & 0xFF,
      minutes: game.minutesSinceStart(_now),
      chainValue: value,
    );
    if (!await _send(game, packet)) {
      game.myNextChainIndex--;
      return false;
    }
    if (side != null) {
      game.playerOf(side)?.verifyAndAdvance(value);
      apply(game, side);
    } else {
      game.inviter?.verifyAndAdvance(value);
      apply(game, ChessSide.white);
    }
    _touch(game);
    return true;
  }

  Future<bool> _send(ChessGame game, ChessPacket packet) async {
    if (!link.canSend) return false;
    _sending.add(game.key);
    notifyListeners();
    try {
      return await link.send(game.channelId, packet.encode());
    } finally {
      _sending.remove(game.key);
      if (!_disposed) notifyListeners();
    }
  }

  int _newGameId(String channelId) {
    while (true) {
      final id = _random.nextInt(0x10000);
      if (!_games.containsKey(ChessGame.gameKey(channelId, id))) return id;
    }
  }

  // ---- incoming --------------------------------------------------------------

  @visibleForTesting
  void handleIncoming(ChessIncoming incoming) {
    final packet = ChessPacket.decode(incoming.payload);
    if (packet == null) return;
    final channelId = incoming.channelId;
    final existing = game(channelId, packet.gameId);
    final changed = switch (packet) {
      ChessInvitePacket p => _onInvite(channelId, existing, p),
      ChessAcceptPacket p => _onAccept(existing, p),
      ChessDeclinePacket p => _onDecline(existing, p),
      ChessMovePacket p => _onMove(channelId, existing, p, incoming.payload),
      ChessActionPacket p => _onAction(existing, p),
      ChessInfoPacket p => _onInfo(channelId, existing, p),
      ChessRequestPacket p => _onRequest(existing, p),
    };
    if ((packet is ChessInfoPacket || packet is ChessMovePacket) &&
        existing != null) {
      // Someone answered; our own pending answer is no longer needed.
      _pendingAnswers.remove(existing.key)?.cancel();
    }
    if (changed) _changed();
  }

  bool _onInvite(String channelId, ChessGame? existing, ChessInvitePacket p) {
    if (existing != null) return false;
    final game = ChessGame(
      channelId: channelId,
      gameId: p.gameId,
      status: ChessGameStatus.invite,
      deadline: p.deadline,
      colourPreference: p.colour,
      inviter: ChessPlayer(name: p.inviterName, commitment: p.commitment),
      targetName: p.targetName,
      createdAtMs: _now,
    );
    _games[game.key] = game;
    if (_isMe(p.targetName)) {
      _notify(game, link.l10n.chess_notifyChallenge(p.inviterName));
    }
    return true;
  }

  bool _onAccept(ChessGame? game, ChessAcceptPacket p) {
    if (game == null) return false;
    if (game.iAmInviter && game.status == ChessGameStatus.active) {
      // A repeated accept: the accepter may have missed our confirmation.
      final accepted = game.playerOf(game.mySide!.other);
      if (accepted != null && bytesEqual(accepted.commitment, p.commitment)) {
        _scheduleAnswer(
          game,
          info: true,
          latestMove: game.ply > 0,
          immediate: true,
        );
      }
      return false;
    }
    if (game.status != ChessGameStatus.invite) return false;
    final target = game.targetName;
    if (target != null && !_sameName(target, p.accepterName)) return false;
    final inviter = game.inviter;
    if (inviter == null) return false;

    if (game.iAmInviter) {
      final inviterWhite = _inviterIsWhite(
        game.colourPreference,
        inviter.commitment,
        p.commitment,
      );
      final accepter = ChessPlayer(
        name: p.accepterName,
        commitment: p.commitment,
      );
      _start(
        game,
        white: inviterWhite ? inviter : accepter,
        black: inviterWhite ? accepter : inviter,
        mySide: inviterWhite ? ChessSide.white : ChessSide.black,
      );
      // Confirm, so the accepter and spectators know whose accept won.
      _scheduleAnswer(game, info: true, latestMove: false, immediate: true);
      _notify(
        game,
        inviterWhite
            ? link.l10n.chess_notifyAcceptedYourMove(p.accepterName)
            : link.l10n.chess_notifyAccepted(p.accepterName),
      );
      return true;
    }
    // Spectators wait for the inviter's confirmation (a game info packet).
    game.lastActivityMs = _now;
    return true;
  }

  bool _onDecline(ChessGame? game, ChessDeclinePacket p) {
    if (game == null || game.status != ChessGameStatus.invite) return false;
    final target = game.targetName;
    if (target == null || !_sameName(target, p.declinerName)) return false;
    game.finish(ChessEndReason.declined);
    game.lastActivityMs = _now;
    if (game.iAmInviter) {
      _notify(game, link.l10n.chess_notifyDeclined(p.declinerName));
    }
    return true;
  }

  bool _onInfo(String channelId, ChessGame? game, ChessInfoPacket p) {
    if (game != null && game.iAmInviter) return false; // We send these.
    final inviter = game?.inviter;
    if (inviter != null &&
        !bytesEqual(inviter.commitment, p.whiteCommitment) &&
        !bytesEqual(inviter.commitment, p.blackCommitment)) {
      return false; // Not from this game's inviter.
    }
    final white = ChessPlayer(name: p.whiteName, commitment: p.whiteCommitment);
    final black = ChessPlayer(name: p.blackName, commitment: p.blackCommitment);

    if (game == null) {
      final created = ChessGame(
        channelId: channelId,
        gameId: p.gameId,
        status: ChessGameStatus.active,
        deadline: p.deadline,
        white: white,
        black: black,
        createdAtMs: _now,
        startedAtMs: p.startedAtUnix * 1000,
        hasPosition: p.ply == 0,
        ply: p.ply,
        sanMoves: List<String?>.filled(p.ply, null, growable: true),
      );
      _games[created.key] = created;
      return true;
    }

    switch (game.status) {
      case ChessGameStatus.invite:
        _start(game, white: white, black: black, mySide: null);
        game.startedAtMs = p.startedAtUnix * 1000;
        return true;
      case ChessGameStatus.starting:
        final mine = game.myChain?.commitment;
        ChessSide? side;
        if (mine != null && bytesEqual(mine, p.whiteCommitment)) {
          side = ChessSide.white;
        } else if (mine != null && bytesEqual(mine, p.blackCommitment)) {
          side = ChessSide.black;
        }
        if (side == null) {
          // Someone else's accept won. Keep watching the game.
          game.mySeedHex = null;
          _start(game, white: white, black: black, mySide: null);
          _notify(game, link.l10n.chess_notifyTaken);
        } else {
          _start(game, white: white, black: black, mySide: side);
          if (side == ChessSide.white) {
            _notify(game, link.l10n.chess_notifyGameStartedYourMove);
          }
        }
        game.startedAtMs = p.startedAtUnix * 1000;
        return true;
      case ChessGameStatus.active:
        if (game.hasPlayers) return false;
        game
          ..white = white
          ..black = black
          ..startedAtMs ??= p.startedAtUnix * 1000
          ..lastActivityMs = _now;
        return true;
      case ChessGameStatus.finished:
        return false;
    }
  }

  void _start(
    ChessGame game, {
    required ChessPlayer white,
    required ChessPlayer black,
    required ChessSide? mySide,
  }) {
    game
      ..white = white
      ..black = black
      ..mySide = mySide
      ..status = ChessGameStatus.active
      ..startedAtMs = _now
      ..lastMoveAtMs = _now
      ..lastActivityMs = _now;
  }

  bool _onMove(
    String channelId,
    ChessGame? game,
    ChessMovePacket p,
    Uint8List raw,
  ) {
    if (game == null) {
      // A game we never heard start: follow it from this position.
      final fullPly = p.ply == 0 ? 256 : p.ply;
      final fen = ChessPositionCodec.decodeToFen(
        p.position,
        fullMoveNumber: fullPly ~/ 2 + 1,
      );
      if (fen == null || !isValidFen(fen)) return false;
      final created = ChessGame(
        channelId: channelId,
        gameId: p.gameId,
        status: ChessGameStatus.active,
        deadline: ChessDeadline.none,
        createdAtMs: _now,
      )..adoptPosition(fen, fullPly);
      created
        ..lastMovePacket = raw
        ..lastMoveAtMs = _now;
      _games[created.key] = created;
      return true;
    }
    if (game.status == ChessGameStatus.invite) {
      // We missed the accept and confirmation; follow from here.
      game
        ..status = ChessGameStatus.active
        ..startedAtMs = _now;
    }
    if (game.status != ChessGameStatus.active) return false;

    final fullPly = _unwrapPly(game.ply, p.ply);
    if (fullPly <= game.ply) return false; // Old or duplicate.
    final mover = ChessSide.moverOfPly(fullPly);
    if (game.mySide == mover) return false; // Our own move echoed.

    final player = game.playerOf(mover);
    if (player != null && !player.owns(p.chainValue)) return false;

    final fen = ChessPositionCodec.decodeToFen(
      p.position,
      fullMoveNumber: fullPly ~/ 2 + 1,
    );
    if (fen == null) return false;

    var applied = false;
    if (fullPly == game.ply + 1 && game.hasPosition) {
      final legal = game.legalUci();
      if (p.moveIndex < legal.length) {
        final probe = ChessGame.fromJson(game.toJson())!;
        if (probe.applyUci(legal[p.moveIndex]) &&
            bytesEqual(probe.packedPosition(), p.position)) {
          game.applyUci(legal[p.moveIndex]);
          applied = true;
        }
      }
      if (!applied && game.isPlayer) return false; // Does not match our board.
    } else if (game.isPlayer && game.hasPosition) {
      return false; // Players cannot skip moves.
    }
    if (!applied) {
      if (!isValidFen(fen)) return false;
      game.adoptPosition(fen, fullPly);
    }
    player?.verifyAndAdvance(p.chainValue);
    game
      ..lastMovePacket = raw
      ..lastMoveAtMs = _now
      ..lastActivityMs = _now;

    if (game.isPlayer) {
      final opponent = game.nameOf(mover) ?? '';
      final san = game.sanMoves.isEmpty ? null : game.sanMoves.last;
      if (game.status == ChessGameStatus.finished) {
        _notify(game, link.l10n.chess_notifyGameOver(opponent));
      } else if (game.isMyTurn) {
        _notify(game, link.l10n.chess_notifyYourMove(opponent, san ?? ''));
      }
    }
    return true;
  }

  bool _onAction(ChessGame? game, ChessActionPacket p) {
    if (game == null) return false;
    if (p.kind == ChessPacketKind.cancel) {
      final inviter = game.inviter;
      if (game.status != ChessGameStatus.invite || inviter == null) {
        return false;
      }
      if (!inviter.verifyAndAdvance(p.chainValue)) return false;
      game
        ..finish(ChessEndReason.cancelled)
        ..lastActivityMs = _now;
      return true;
    }
    if (game.status != ChessGameStatus.active) return false;
    final side = game.sideOwning(p.chainValue);
    if (side == null || side == game.mySide) return false;
    if (!game.playerOf(side)!.verifyAndAdvance(p.chainValue)) return false;
    final name = game.nameOf(side) ?? '';
    switch (p.kind) {
      case ChessPacketKind.resign:
        game.finish(ChessEndReason.resignation, winner: side.other);
        if (game.isPlayer) _notify(game, link.l10n.chess_notifyResigned(name));
      case ChessPacketKind.drawOffer:
        game.drawOfferedBy = side;
        if (game.isPlayer) {
          _notify(game, link.l10n.chess_notifyDrawOffered(name));
        }
      case ChessPacketKind.drawAccept:
        game.finish(ChessEndReason.drawAgreed);
        if (game.isPlayer) {
          _notify(game, link.l10n.chess_notifyDrawAccepted(name));
        }
      case ChessPacketKind.timeoutClaim:
        // Only the side waiting for a move can claim.
        if (game.hasPosition && game.sideToMove == side) return false;
        game.finish(ChessEndReason.timeout, winner: side);
        if (game.isPlayer) _notify(game, link.l10n.chess_notifyTimeout(name));
      default:
        return false;
    }
    game.lastActivityMs = _now;
    return true;
  }

  bool _onRequest(ChessGame? game, ChessRequestPacket p) {
    if (game == null || !game.isPlayer) return false;
    if (game.status == ChessGameStatus.starting) return false;
    final behind = _unwrapPly(game.ply, p.ply) < game.ply;
    _scheduleAnswer(
      game,
      info: p.wantsInfo,
      latestMove: p.wantsLatestMove && behind,
    );
    return false;
  }

  /// Answers a request after a random delay, unless someone else answers
  /// first. At most one answer per game per [requestAnswerInterval].
  void _scheduleAnswer(
    ChessGame game, {
    required bool info,
    required bool latestMove,
    bool immediate = false,
  }) {
    if (!info && !latestMove) return;
    if (_pendingAnswers.containsKey(game.key)) return;
    final last = game.lastAnsweredRequestAtMs;
    if (!immediate &&
        last != null &&
        _now - last < requestAnswerInterval.inMilliseconds) {
      return;
    }
    final spread = _answerDelayMax - _answerDelayMin;
    final delay = immediate
        ? Duration.zero
        : _answerDelayMin +
              Duration(
                milliseconds: spread.inMilliseconds <= 0
                    ? 0
                    : _random.nextInt(spread.inMilliseconds),
              );
    _pendingAnswers[game.key] = Timer(delay, () async {
      _pendingAnswers.remove(game.key);
      // Confirmations are not answers to a request; they don't count.
      if (!immediate) game.lastAnsweredRequestAtMs = _now;
      if (info) await _sendInfo(game);
      final move = game.lastMovePacket;
      if (latestMove && move != null && link.canSend) {
        await link.send(game.channelId, move);
      }
    });
  }

  Future<void> _sendInfo(ChessGame game) async {
    final white = game.white;
    final black = game.black;
    if (white == null || black == null) return;
    await _send(
      game,
      ChessInfoPacket(
        gameId: game.gameId,
        ply: game.ply & 0xFF,
        startedAtUnix: (game.startedAtMs ?? game.createdAtMs) ~/ 1000,
        deadline: game.deadline,
        whiteCommitment: white.commitment,
        blackCommitment: black.commitment,
        whiteName: white.name,
        blackName: black.name,
      ),
    );
  }

  // ---- helpers ---------------------------------------------------------------

  /// The full ply nearest [known] whose low byte is [wire].
  static int _unwrapPly(int known, int wire) {
    var delta = (wire - known) & 0xFF;
    if (delta >= 128) delta -= 256;
    return known + delta;
  }

  /// Colour rule for invites: a fixed preference wins, "random" uses bit 0
  /// of SHA-256(inviter commitment ‖ accepter commitment).
  static bool _inviterIsWhite(
    ChessColourPreference pref,
    Uint8List inviter,
    Uint8List accepter,
  ) {
    switch (pref) {
      case ChessColourPreference.white:
        return true;
      case ChessColourPreference.black:
        return false;
      case ChessColourPreference.random:
        return sha256.convert([...inviter, ...accepter]).bytes[0] & 1 == 0;
    }
  }

  bool _isMe(String? name) =>
      name != null &&
      link.selfName.isNotEmpty &&
      _sameName(name, link.selfName);

  static bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  void _notify(ChessGame game, String text) {
    if (game.key == _viewingKey) return;
    link.notify(game.channelId, text);
  }

  void _touch(ChessGame game) {
    game.lastActivityMs = _now;
    _changed();
  }

  void _changed() {
    if (_disposed) return;
    notifyListeners();
    unawaited(store.save(_scope, _games.values.toList()));
  }

  /// Expires stale invites and prunes old games. Runs every minute.
  @visibleForTesting
  void housekeeping() {
    final now = _now;
    var changed = false;
    for (final g in _games.values) {
      if ((g.status == ChessGameStatus.invite ||
              g.status == ChessGameStatus.starting) &&
          now - g.createdAtMs > inviteLifetime.inMilliseconds) {
        g.finish(ChessEndReason.expired);
        changed = true;
      }
    }
    final stale = _games.values
        .where(
          (g) =>
              (!g.isOpen || !g.isPlayer) &&
              now - g.lastActivityMs > keepFinished.inMilliseconds,
        )
        .map((g) => g.key)
        .toList();
    for (final key in stale) {
      _games.remove(key);
      changed = true;
    }
    if (_games.length > maxStoredGames) {
      final byAge = _games.values.toList()
        ..sort((a, b) {
          // Our open games last.
          final ao = a.isOpen && a.isPlayer ? 1 : 0;
          final bo = b.isOpen && b.isPlayer ? 1 : 0;
          if (ao != bo) return ao - bo;
          return a.lastActivityMs.compareTo(b.lastActivityMs);
        });
      for (final g in byAge.take(_games.length - maxStoredGames)) {
        _games.remove(g.key);
      }
      changed = true;
    }
    if (changed) {
      _changed();
    } else if (_games.values.any((g) => g.status == ChessGameStatus.active)) {
      notifyListeners(); // Deadline countdowns.
    }
  }

  void _onLinkChanged() {
    final scope = link.storageScope;
    if (scope != _scope) {
      _loadScope(scope);
    }
    notifyListeners();
  }

  void _loadScope(String scope) {
    _scope = scope;
    _games
      ..clear()
      ..addEntries(store.load(scope).map((g) => MapEntry(g.key, g)));
    for (final t in _pendingAnswers.values) {
      t.cancel();
    }
    _pendingAnswers.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _housekeeping?.cancel();
    for (final t in _pendingAnswers.values) {
      t.cancel();
    }
    link.removeListener(_onLinkChanged);
    super.dispose();
  }
}
