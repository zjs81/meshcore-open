import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';

import '../hash_chain.dart';
import 'chess_game.dart';
import 'chess_link.dart';
import 'chess_packets.dart';
import 'chess_position_codec.dart';
import 'chess_store.dart';

/// Chess games played and watched on channels.
///
/// Packets arrive through [ChessLink.incoming]; every handler is idempotent,
/// so duplicates and repeats are harmless. Each chain value counts once: the
/// first packet heard with it uses it up.
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
  final bool Function() _isForeground;

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
    bool Function()? isForeground,
  }) : store = store ?? ChessStore(),
       _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure(),
       _answerDelayMin = answerDelayMin,
       _answerDelayMax = answerDelayMax,
       _isForeground = isForeground ?? _appResumed {
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

  static bool _appResumed() {
    try {
      final state = WidgetsBinding.instance.lifecycleState;
      return state == null || state == AppLifecycleState.resumed;
    } catch (_) {
      return true;
    }
  }

  // ---- queries ---------------------------------------------------------------

  /// Games on [channelId], newest activity first.
  List<ChessGame> gamesForChannel(String channelId) =>
      _games.values.where((g) => g.channelId == channelId).toList()
        ..sort((a, b) => b.lastActivityMs.compareTo(a.lastActivityMs));

  /// Live games plus open invites on [channelId], as the games sheet lists
  /// them.
  int openCountForChannel(String channelId) => _games.values
      .where((g) => g.channelId == channelId && g.isOpen && isListed(g))
      .length;

  /// False for an open challenge between two other people, which the games
  /// sheet does not show.
  bool isListed(ChessGame game) =>
      game.status != ChessGameStatus.invite ||
      game.iAmInviter ||
      game.targetName == null ||
      _isMe(game.targetName);

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

  /// The screen showing [game] (no notifications for it while the app is in
  /// the foreground), or null.
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
      inviter: ChessPlayer.inviter(
        name: link.selfName,
        commitment: chain.commitment,
      ),
      targetName: targetName,
      mySeedHex: bytesToHex(chain.seed),
      // Value 1 is the game info's; actions start at 2.
      myNextChainIndex: 2,
      inviterInfoValue: chain.valueAt(1),
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
    if (isSending(game) || !link.canSend) return false;
    // Reuse the chain of an earlier attempt: that accept may have gone out.
    game.mySeedHex ??= bytesToHex(HashChain.generate(_random).seed);
    // Waiting from now on, so a confirmation heard mid-send is ours.
    game
      ..status = ChessGameStatus.starting
      ..lastActivityMs = _now;
    _changed();
    final ok = await _send(
      game,
      ChessAcceptPacket(
        gameId: game.gameId,
        commitment: game.myChain!.commitment,
        accepterName: link.selfName,
      ),
    );
    if (!ok && game.status == ChessGameStatus.starting) {
      game.status = ChessGameStatus.invite;
      _changed();
    }
    return ok;
  }

  /// Re-sends our accept while waiting for the inviter's confirmation, or
  /// after a game info listed someone else. The inviter answers with the
  /// game info, which lists us if ours was the accept that counted.
  Future<bool> resendAccept(ChessGame game) async {
    final chain = game.myChain;
    if (chain == null || game.iAmInviter) return false;
    final waiting =
        game.status == ChessGameStatus.starting ||
        (game.status == ChessGameStatus.active && !game.isPlayer);
    if (!waiting) return false;
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
  ///
  /// Returns false when the radio did not confirm the send. The move is
  /// still applied then, since it may have gone out; [requestUpdate] sends
  /// it again.
  Future<bool> makeMove(ChessGame game, String uci) async {
    if (!game.isMyTurn || isSending(game) || !link.canSend) return false;
    final legal = game.legalUci();
    final index = legal.indexOf(uci);
    if (index < 0 || index > 255) return false;
    final probe = ChessGame.fromJson(game.toJson())!;
    if (!probe.applyUci(uci)) return false;
    final chain = game.takeMyChainValue();
    if (chain == null) return false;
    final packet = ChessMovePacket(
      gameId: game.gameId,
      ply: probe.ply,
      moveIndex: index,
      chainValue: chain.value,
      position: probe.packedPosition(),
    );
    final plyBefore = game.ply;
    final ok = await _send(game, packet);
    if (game.status != ChessGameStatus.active || game.ply != plyBefore) {
      _changed();
      return ok;
    }
    game.applyUci(uci);
    game.playerOf(game.mySide!)?.use(chain.index);
    game
      ..lastMovePacket = packet.encode()
      ..lastMoveAtMs = _now
      ..moveUnconfirmed = !ok;
    _touch(game);
    return ok;
  }

  Future<bool> resign(ChessGame game) =>
      _sendAction(game, ChessPacketKind.resign, (g, side) {
        g.finish(ChessEndReason.resignation, winner: side!.other);
      });

  Future<bool> offerDraw(ChessGame game) =>
      _sendAction(game, ChessPacketKind.drawOffer, (g, side) {
        g.drawOfferedBy = side;
      });

  Future<bool> acceptDraw(ChessGame game) {
    final side = game.mySide;
    if (side == null || game.drawOfferedBy != side.other) {
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

  /// Gets a stuck game moving. While we wait for the opponent after our own
  /// move, sends that move again (the opponent answers with theirs if we
  /// missed it). Otherwise asks the players for what we are missing: the
  /// game info when we cannot verify the players, and the latest move.
  Future<bool> requestUpdate(ChessGame game) {
    if (game.status == ChessGameStatus.starting ||
        (game.status == ChessGameStatus.active &&
            !game.isPlayer &&
            game.isMine)) {
      return resendAccept(game);
    }
    if (_latestMoveIsMine(game) && game.status == ChessGameStatus.active) {
      return _resendLatestMove(game);
    }
    return _send(
      game,
      ChessRequestPacket(
        gameId: game.gameId,
        ply: game.ply,
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
    void Function(ChessGame game, ChessSide? side) apply, {
    ChessGameStatus allowedStatus = ChessGameStatus.active,
  }) async {
    if (game.status != allowedStatus || isSending(game)) return false;
    if (!link.canSend) return false;
    final side = game.mySide;
    final record = kind == ChessPacketKind.cancel
        ? (game.iAmInviter ? game.inviter : null)
        : (side == null ? null : game.playerOf(side));
    if (record == null) return false;
    final chain = game.takeMyChainValue();
    if (chain == null) return false;
    // Used up even if the send fails: the packet may have gone out.
    record.use(chain.index);
    final ok = await _send(
      game,
      ChessActionPacket(
        kind: kind,
        gameId: game.gameId,
        ply: game.ply,
        chainValue: chain.value,
      ),
    );
    if (!ok || game.status != allowedStatus) {
      _changed();
      return false;
    }
    apply(game, side);
    _touch(game);
    return true;
  }

  bool _latestMoveIsMine(ChessGame game) =>
      game.isPlayer &&
      game.ply > 0 &&
      ChessSide.moverOfPly(game.ply) == game.mySide &&
      game.lastMovePacket != null;

  /// Sends our latest move again. After we revealed a later chain value
  /// (a draw offer, say), receivers refuse the old value, so the move goes
  /// out with the next value instead.
  Future<bool> _resendLatestMove(ChessGame game) async {
    final raw = game.lastMovePacket;
    final chain = game.myChain;
    final old = raw == null ? null : ChessPacket.decode(raw);
    if (old is! ChessMovePacket || chain == null || !link.canSend) {
      return false;
    }
    var packet = raw!;
    final latest = chain.valueAt(game.myNextChainIndex - 1);
    if (!bytesEqual(old.chainValue, latest)) {
      final next = game.takeMyChainValue();
      if (next == null) return false;
      game.playerOf(game.mySide!)?.use(next.index);
      packet = old.withChainValue(next.value).encode();
      game.lastMovePacket = packet;
      _changed();
    }
    final ok = await _sendRaw(game, packet);
    if (ok && game.moveUnconfirmed) {
      game.moveUnconfirmed = false;
      _changed();
    }
    return ok;
  }

  Future<bool> _send(ChessGame game, ChessPacket packet) =>
      _sendRaw(game, packet.encode());

  Future<bool> _sendRaw(ChessGame game, Uint8List payload) async {
    if (!link.canSend) return false;
    _sending.add(game.key);
    notifyListeners();
    try {
      return await link.send(game.channelId, payload);
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
    try {
      _handle(incoming);
    } catch (e) {
      // A malformed packet must never break the stream listener.
      debugPrint('Chess: ignored packet: $e');
    }
  }

  void _handle(ChessIncoming incoming) {
    final packet = ChessPacket.decode(incoming.payload);
    if (packet == null) return;
    final channelId = incoming.channelId;
    final existing = game(channelId, packet.gameId);
    if (existing != null &&
        (packet is ChessInfoPacket ||
            (packet is ChessMovePacket && packet.ply >= existing.ply))) {
      // Someone answered; our own pending answer is no longer needed.
      _pendingAnswers.remove(existing.key)?.cancel();
    }
    final changed = switch (packet) {
      ChessInvitePacket p => _onInvite(channelId, existing, p),
      ChessAcceptPacket p => _onAccept(existing, p),
      ChessDeclinePacket p => _onDecline(existing, p),
      ChessMovePacket p => _onMove(channelId, existing, p, incoming.payload),
      ChessActionPacket p => _onAction(existing, p),
      ChessInfoPacket p => _onInfo(channelId, existing, p),
      ChessRequestPacket p => _onRequest(existing, p),
    };
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
      inviter: ChessPlayer.inviter(
        name: p.inviterName,
        commitment: p.commitment,
      ),
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
      // A repeated accept: the accepter missed our confirmation, or lost to
      // another accept without hearing it. The game info and the latest
      // move answer both. Rate-limited like any answer.
      _scheduleAnswer(game, info: true, latestMove: game.ply > 0);
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
    // Anyone can send a decline, so only the inviter acts on it.
    if (game == null || !game.iAmInviter) return false;
    if (game.status != ChessGameStatus.invite) return false;
    final target = game.targetName;
    if (target == null || !_sameName(target, p.declinerName)) return false;
    game
      ..finish(ChessEndReason.declined)
      ..lastActivityMs = _now;
    _notify(game, link.l10n.chess_notifyDeclined(p.declinerName));
    return true;
  }

  bool _onInfo(String channelId, ChessGame? game, ChessInfoPacket p) {
    if (game != null && game.iAmInviter) return false; // We send these.
    if (game?.status == ChessGameStatus.finished) return false;
    // Value 1 of the inviter's chain hashes to the inviter's commitment.
    final step = hashChainStep(p.inviterValue);
    final ChessSide inviterSide;
    if (bytesEqual(step, p.whiteCommitment)) {
      inviterSide = ChessSide.white;
    } else if (bytesEqual(step, p.blackCommitment)) {
      inviterSide = ChessSide.black;
    } else {
      return false;
    }
    final inviterWhite = inviterSide == ChessSide.white;
    final inviterCommitment = inviterWhite
        ? p.whiteCommitment
        : p.blackCommitment;
    final accepterCommitment = inviterWhite
        ? p.blackCommitment
        : p.whiteCommitment;
    final known = game?.inviter;
    if (known != null) {
      if (!bytesEqual(known.commitment, inviterCommitment)) return false;
      // Colours follow from the invite; don't take the packet's word.
      final expected = _inviterIsWhite(
        game!.colourPreference,
        inviterCommitment,
        accepterCommitment,
      );
      if (expected != inviterWhite) return false;
    }
    final inviter =
        known ??
        ChessPlayer.inviter(
          name: inviterWhite ? p.whiteName : p.blackName,
          commitment: inviterCommitment,
        );
    final accepter = ChessPlayer(
      name: inviterWhite ? p.blackName : p.whiteName,
      commitment: accepterCommitment,
    );
    final white = inviterWhite ? inviter : accepter;
    final black = inviterWhite ? accepter : inviter;
    final startedAtMs = p.startedAtUnix * 1000;

    if (game == null) {
      // We never heard the invite, so nothing ties these players to it.
      final created = ChessGame(
        channelId: channelId,
        gameId: p.gameId,
        status: ChessGameStatus.active,
        deadline: p.deadline,
        white: white,
        black: black,
        playersConfirmed: false,
        inviterInfoValue: p.inviterValue,
        createdAtMs: _now,
        startedAtMs: startedAtMs,
        hasPosition: p.ply == 0,
        ply: p.ply,
        sanMoves: List<String?>.filled(p.ply, null, growable: true),
      );
      _games[created.key] = created;
      return true;
    }

    final mine = game.myChain?.commitment;
    final listsMe = mine != null && bytesEqual(mine, accepterCommitment);
    switch (game.status) {
      case ChessGameStatus.invite:
      case ChessGameStatus.starting:
        final accepted = game.mySeedHex != null;
        _start(
          game,
          white: white,
          black: black,
          mySide: listsMe ? inviterSide.other : null,
        );
        game
          ..startedAtMs = startedAtMs
          ..inviterInfoValue = p.inviterValue;
        if (!listsMe && p.ply > 0) {
          // Watching a game already under way: the board comes with the
          // next move.
          game
            ..ply = p.ply
            ..hasPosition = false
            ..sanMoves = List<String?>.filled(p.ply, null, growable: true);
        }
        if (listsMe && inviterSide == ChessSide.black) {
          _notify(game, link.l10n.chess_notifyGameStartedYourMove);
        } else if (accepted && !listsMe) {
          // Someone else's accept won. Keep watching, and keep our chain in
          // case a later game info lists us after all.
          _notify(game, link.l10n.chess_notifyTaken);
        }
        return true;
      case ChessGameStatus.active:
        if (game.mySide == null && listsMe) {
          // An earlier game info listed someone else; this one lists us.
          // Whoever sent it, it puts us against the real inviter.
          game
            ..white = white
            ..black = black
            ..mySide = inviterSide.other
            ..playersConfirmed = true
            ..inviterInfoValue = p.inviterValue
            ..lastActivityMs = _now;
          return true;
        }
        if (game.hasPlayers) return false; // First heard wins.
        // Followed from a move. Our inviter record, if any, must stay on
        // the side we saw it move for.
        for (final side in ChessSide.values) {
          final seen = game.playerOf(side);
          if (seen != null && identical(seen, known) && side != inviterSide) {
            return false;
          }
        }
        game
          ..white = white
          ..black = black
          ..playersConfirmed = known != null
          ..deadline = p.deadline
          ..inviterInfoValue = p.inviterValue
          ..startedAtMs ??= startedAtMs
          ..lastActivityMs = _now;
        _useLastMoveValue(game);
        return true;
      case ChessGameStatus.finished:
        return false;
    }
  }

  /// Uses up the chain value of the move we followed before we knew the
  /// players.
  void _useLastMoveValue(ChessGame game) {
    final raw = game.lastMovePacket;
    final move = raw == null ? null : ChessPacket.decode(raw);
    if (move is! ChessMovePacket) return;
    final player = game.playerOf(ChessSide.moverOfPly(move.ply));
    final index = player?.freshIndex(move.chainValue);
    if (index != null) player!.use(index);
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
    final ply = p.ply;
    if (ply < 1) return false;
    final mover = ChessSide.moverOfPly(ply);
    if (game == null) {
      // A game we never heard start: follow it from this position.
      final fen = _decodePosition(p);
      if (fen == null || !isValidFen(fen)) return false;
      final created = ChessGame(
        channelId: channelId,
        gameId: p.gameId,
        status: ChessGameStatus.active,
        deadline: ChessDeadline.none,
        createdAtMs: _now,
      )..adoptPosition(fen, ply);
      created
        ..lastMovePacket = raw
        ..lastMoveAtMs = _now;
      _games[created.key] = created;
      return true;
    }
    switch (game.status) {
      case ChessGameStatus.finished:
      case ChessGameStatus.starting: // Wait for the inviter's confirmation.
        return false;
      case ChessGameStatus.invite:
        return _onMoveBeforeStart(game, p, raw);
      case ChessGameStatus.active:
        break;
    }
    if (game.mySide == mover) return false; // Our own move echoed.
    if (game.isPlayer && ply < game.ply) {
      // The opponent is behind (our reply got lost); they need our move.
      _scheduleAnswer(game, info: false, latestMove: true);
    }

    final player = game.playerOf(mover);
    int? index;
    if (player != null) {
      index = player.freshIndex(p.chainValue);
      if (index == null) return false; // Forged, replayed or already used.
    }
    if (ply < game.ply || (ply == game.ply && game.hasPosition)) {
      // A move we have, sent again with a new value: just use the value up.
      if (index != null) player!.use(index);
      return index != null;
    }

    final fen = _decodePosition(p);
    if (fen == null) return false;
    var applied = false;
    if (ply == game.ply + 1 && game.hasPosition) {
      final legal = game.legalUci();
      if (p.moveIndex < legal.length) {
        final probe = ChessGame.fromJson(game.toJson())!;
        if (probe.applyUci(legal[p.moveIndex]) &&
            bytesEqual(probe.packedPosition(), p.position)) {
          game.applyUci(legal[p.moveIndex]);
          applied = true;
        }
      }
      // Does not match our board. The value stays unused, so the real move
      // can still be accepted if this one was forged.
      if (!applied && game.isPlayer) return false;
    } else if (game.isPlayer && game.hasPosition) {
      return false; // Players cannot skip moves.
    }
    if (!applied) {
      if (!isValidFen(fen)) return false;
      game.adoptPosition(fen, ply);
    }
    if (index != null) player!.use(index);
    game
      ..lastMovePacket = raw
      ..lastMoveAtMs = _now
      ..lastActivityMs = _now;

    if (game.isPlayer) {
      game.moveUnconfirmed = false; // Their move answers ours.
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

  /// A move for an invite we watched but never saw start. Only the
  /// inviter's chain can prove the game began; the other player stays
  /// unknown until the game info.
  bool _onMoveBeforeStart(ChessGame game, ChessMovePacket p, Uint8List raw) {
    if (game.isMine) return false; // Ours, or waiting for our confirmation.
    final inviter = game.inviter;
    final index = inviter?.freshIndex(p.chainValue);
    if (index == null) return false;
    final fen = _decodePosition(p);
    if (fen == null || !isValidFen(fen)) return false;
    inviter!.use(index);
    if (ChessSide.moverOfPly(p.ply) == ChessSide.white) {
      game.white = inviter;
    } else {
      game.black = inviter;
    }
    game
      ..status = ChessGameStatus.active
      ..startedAtMs = _now
      ..adoptPosition(fen, p.ply);
    game
      ..lastMovePacket = raw
      ..lastMoveAtMs = _now
      ..lastActivityMs = _now;
    return true;
  }

  static String? _decodePosition(ChessMovePacket p) =>
      ChessPositionCodec.decodeToFen(
        p.position,
        fullMoveNumber: p.ply ~/ 2 + 1,
      );

  bool _onAction(ChessGame? game, ChessActionPacket p) {
    if (game == null) return false;
    if (p.kind == ChessPacketKind.cancel) {
      if (game.iAmInviter) return false;
      if (game.status != ChessGameStatus.invite &&
          game.status != ChessGameStatus.starting) {
        return false;
      }
      final inviter = game.inviter;
      final index = inviter?.freshIndex(p.chainValue);
      if (index == null) return false;
      inviter!.use(index);
      game
        ..finish(ChessEndReason.cancelled)
        ..lastActivityMs = _now;
      return true;
    }
    if (game.status != ChessGameStatus.active) return false;
    final found = game.freshSide(p.chainValue);
    if (found == null) return false;
    final (side, index) = found;
    if (side == game.mySide) return false;
    // The value is genuine and now used up, whether or not the action
    // applies to the game as we see it.
    game.playerOf(side)!.use(index);
    game.lastActivityMs = _now;
    final current = p.ply == game.ply;
    final name = game.nameOf(side) ?? '';
    switch (p.kind) {
      case ChessPacketKind.resign:
        game.finish(ChessEndReason.resignation, winner: side.other);
        if (game.isPlayer) _notify(game, link.l10n.chess_notifyResigned(name));
      case ChessPacketKind.drawOffer:
        if (!current) break;
        game.drawOfferedBy = side;
        if (game.isPlayer) {
          _notify(game, link.l10n.chess_notifyDrawOffered(name));
        }
      case ChessPacketKind.drawAccept:
        if (!current || game.drawOfferedBy != side.other) break;
        game.finish(ChessEndReason.drawAgreed);
        if (game.isPlayer) {
          _notify(game, link.l10n.chess_notifyDrawAccepted(name));
        }
      case ChessPacketKind.timeoutClaim:
        if (!current || !_deadlinePassed(game, side)) break;
        game.finish(ChessEndReason.timeout, winner: side);
        if (game.isPlayer) _notify(game, link.l10n.chess_notifyTimeout(name));
      default:
        break;
    }
    return true;
  }

  /// Whether [claimer]'s opponent is to move and the deadline has passed
  /// here since the last move. No grace: the claimer already waited it out,
  /// and our clock may run behind theirs.
  bool _deadlinePassed(ChessGame game, ChessSide claimer) {
    final d = game.deadline.duration;
    if (d == null || game.sideToMove == claimer) return false;
    return _now - game.lastMoveAtMs >= d.inMilliseconds;
  }

  bool _onRequest(ChessGame? game, ChessRequestPacket p) {
    if (game == null || !game.isPlayer) return false;
    _scheduleAnswer(
      game,
      info: p.wantsInfo,
      latestMove: p.wantsLatestMove && p.ply < game.ply,
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
      if (!latestMove) return;
      final move = game.lastMovePacket;
      if (_latestMoveIsMine(game)) {
        await _resendLatestMove(game);
      } else if (move != null) {
        await _sendRaw(game, move);
      }
    });
  }

  Future<void> _sendInfo(ChessGame game) async {
    final white = game.white;
    final black = game.black;
    final value = game.inviterInfoValue;
    if (white == null || black == null || value == null) return;
    await _send(
      game,
      ChessInfoPacket(
        gameId: game.gameId,
        ply: game.ply,
        startedAtUnix: (game.startedAtMs ?? game.createdAtMs) ~/ 1000,
        deadline: game.deadline,
        whiteCommitment: white.commitment,
        blackCommitment: black.commitment,
        inviterValue: value,
        whiteName: white.name,
        blackName: black.name,
      ),
    );
  }

  // ---- helpers ---------------------------------------------------------------

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

  /// Whether [name] is our advert name (case and spacing aside).
  bool isSelf(String name) =>
      link.selfName.isNotEmpty && _sameName(name, link.selfName);

  bool _isMe(String? name) => name != null && isSelf(name);

  static bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  void _notify(ChessGame game, String text) {
    if (game.key == _viewingKey && _isForeground()) return;
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
          // Our open games (including our invites) last.
          final ao = a.isOpen && a.isMine ? 1 : 0;
          final bo = b.isOpen && b.isMine ? 1 : 0;
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
