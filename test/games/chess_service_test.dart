import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/games/chess/chess_game.dart';
import 'package:meshcore_open/games/chess/chess_link.dart';
import 'package:meshcore_open/games/chess/chess_packets.dart';
import 'package:meshcore_open/games/chess/chess_service.dart';
import 'package:meshcore_open/games/chess/chess_store.dart';
import 'package:meshcore_open/games/hash_chain.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = 'abcdef0123456789';

/// A shared channel: whatever one link sends, every other link hears.
class _Mesh {
  final List<_FakeLink> links = [];

  /// Return false to drop a packet before it reaches [to].
  bool Function(_FakeLink from, _FakeLink to, Uint8List payload)? filter;

  void deliver(_FakeLink from, Uint8List payload) {
    for (final to in links) {
      if (identical(to, from)) continue;
      if (filter != null && !filter!(from, to, payload)) continue;
      to.controller.add(ChessIncoming(_channel, payload));
    }
  }
}

class _FakeLink extends ChangeNotifier implements ChessLink {
  final _Mesh mesh;
  @override
  final String selfName;
  @override
  final String storageScope;
  final StreamController<ChessIncoming> controller = StreamController.broadcast(
    sync: true,
  );
  final List<Uint8List> sent = [];
  final List<String> notifications = [];
  bool connected = true;

  /// The radio does not confirm the next send; [deliverFailed] says whether
  /// the packet went out anyway.
  bool failNext = false;
  bool deliverFailed = false;

  /// Lets other timers run while our send is in flight.
  bool slow = false;

  _FakeLink(this.mesh, this.selfName, this.storageScope) {
    mesh.links.add(this);
  }

  @override
  Stream<ChessIncoming> get incoming => controller.stream;

  @override
  Future<bool> send(String channelId, Uint8List payload) async {
    if (!connected) return false;
    if (failNext) {
      failNext = false;
      if (deliverFailed) mesh.deliver(this, payload);
      return false;
    }
    sent.add(payload);
    mesh.deliver(this, payload);
    if (slow) await Future<void>.delayed(Duration.zero);
    return true;
  }

  @override
  bool get canSend => connected;

  @override
  void notify(String channelId, String text) => notifications.add(text);

  @override
  AppLocalizations get l10n => lookupAppLocalizations(const Locale('en'));
}

class _Player {
  final _FakeLink link;
  final ChessService service;

  _Player(this.link, this.service);

  ChessGame? get game => service.gamesForChannel(_channel).firstOrNull;
}

void main() {
  late _Mesh mesh;
  late DateTime now;
  final created = <_Player>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    mesh = _Mesh();
    now = DateTime(2026, 11, 21, 12);
  });

  tearDown(() {
    for (final p in created) {
      p.service.dispose();
    }
    created.clear();
  });

  var nextSeed = 100;
  _Player player(String name, {int? seed, bool Function()? isForeground}) {
    final link = _FakeLink(
      mesh,
      name,
      '${name.toLowerCase()}000000000'.substring(0, 10),
    );
    final service = ChessService(
      link: link,
      store: ChessStore(),
      clock: () => now,
      random: Random(seed ?? nextSeed++),
      answerDelayMin: Duration.zero,
      answerDelayMax: Duration.zero,
      startHousekeeping: false,
      isForeground: isForeground,
    );
    final p = _Player(link, service);
    created.add(p);
    return p;
  }

  /// Lets zero-delay answer timers fire.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<(_Player white, _Player black)> startGame(
    _Player alice,
    _Player bob, {
    ChessColourPreference colour = ChessColourPreference.white,
  }) async {
    final invite = await alice.service.createInvite(
      channelId: _channel,
      colour: colour,
    );
    expect(invite, isNotNull);
    expect(await bob.service.accept(bob.game!), isTrue);
    await settle(); // Alice's confirmation (game info).
    expect(alice.game!.status, ChessGameStatus.active);
    expect(bob.game!.status, ChessGameStatus.active);
    final aliceWhite = alice.game!.mySide == ChessSide.white;
    return aliceWhite ? (alice, bob) : (bob, alice);
  }

  test(
    'open invite, accept, and Scholar\'s mate seen by a spectator',
    () async {
      final alice = player('Alice', seed: 1);
      final bob = player('Bob', seed: 2);
      final carol = player('Carol', seed: 3);

      final (white, black) = await startGame(alice, bob);
      expect(white, same(alice));
      expect(carol.game!.status, ChessGameStatus.active);
      expect(carol.game!.isPlayer, isFalse);
      expect(carol.game!.hasPlayers, isTrue);
      expect(bob.link.notifications, isEmpty);

      const moves = ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6', 'h5f7'];
      for (var i = 0; i < moves.length; i++) {
        final mover = i.isEven ? white : black;
        expect(
          await mover.service.makeMove(mover.game!, moves[i]),
          isTrue,
          reason: moves[i],
        );
      }
      for (final p in [alice, bob, carol]) {
        final g = p.game!;
        expect(g.status, ChessGameStatus.finished);
        expect(g.endReason, ChessEndReason.checkmate);
        expect(g.winner, ChessSide.white);
        expect(g.sanMoves.last, 'Qxf7#');
      }
      expect(bob.link.notifications.last, contains('Alice'));
    },
  );

  test('random colour gives both sides the same answer', () async {
    final alice = player('Alice', seed: 4);
    final bob = player('Bob', seed: 5);
    await startGame(alice, bob, colour: ChessColourPreference.random);
    expect(alice.game!.mySide, isNotNull);
    expect(bob.game!.mySide, alice.game!.mySide!.other);
  });

  test('direct challenge notifies only the target, who can decline', () async {
    final alice = player('Alice');
    final bob = player('Bob');
    final carol = player('Carol');
    await alice.service.createInvite(channelId: _channel, targetName: 'bob');
    expect(bob.link.notifications.single, contains('Alice'));
    expect(carol.link.notifications, isEmpty);
    expect(await bob.service.decline(bob.game!), isTrue);
    expect(alice.game!.status, ChessGameStatus.finished);
    expect(alice.game!.endReason, ChessEndReason.declined);
  });

  test('only the first confirmed accept gets the game', () async {
    final alice = player('Alice');
    final bob = player('Bob');
    final carol = player('Carol');
    await alice.service.createInvite(
      channelId: _channel,
      colour: ChessColourPreference.white,
    );
    // Carol does not hear Bob's accept, and accepts too.
    mesh.filter = (from, to, _) => !(from == bob.link && to == carol.link);
    await bob.service.accept(bob.game!);
    mesh.filter = null;
    await carol.service.accept(carol.game!);
    await settle();
    expect(alice.game!.nameOf(ChessSide.black), 'Bob');
    expect(bob.game!.mySide, ChessSide.black);
    expect(carol.game!.isPlayer, isFalse);
    expect(carol.game!.status, ChessGameStatus.active);
  });

  test(
    'a spectator that missed moves takes the position from the next one',
    () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final (white, black) = await startGame(alice, bob);
      await white.service.makeMove(white.game!, 'd2d4');
      await black.service.makeMove(black.game!, 'd7d5');

      final dave = player('Dave');
      await white.service.makeMove(white.game!, 'c2c4');
      final g = dave.game!;
      expect(g.ply, 3);
      expect(g.fen, white.game!.fen);
      expect(g.sanMoves, [null, null, null]);
      expect(g.hasPlayers, isFalse);

      // Asking for an update fetches the players.
      await dave.service.requestUpdate(g);
      await settle();
      expect(dave.game!.hasPlayers, isTrue);
      await black.service.makeMove(black.game!, 'e7e6');
      expect(dave.game!.ply, 4);
      expect(dave.game!.sanMoves.last, 'e6');
    },
  );

  test('a player who missed a move gets it back by asking', () async {
    final alice = player('Alice');
    final bob = player('Bob');
    final (white, black) = await startGame(alice, bob);
    mesh.filter = (from, to, _) => !(from == white.link && to == black.link);
    await white.service.makeMove(white.game!, 'e2e4');
    mesh.filter = null;
    expect(black.game!.ply, 0);
    expect(black.game!.isMyTurn, isFalse);

    await black.service.requestUpdate(black.game!);
    await settle();
    expect(black.game!.ply, 1);
    expect(black.game!.isMyTurn, isTrue);
  });

  test('forged moves and conflicting duplicates are rejected', () async {
    final alice = player('Alice');
    final bob = player('Bob');
    final carol = player('Carol');
    final (white, black) = await startGame(alice, bob);
    await white.service.makeMove(white.game!, 'e2e4');
    final real = ChessPacket.decode(white.link.sent.last) as ChessMovePacket;

    // Mallory replays White's chain value with a different move as Black's.
    final forged = ChessMovePacket(
      gameId: real.gameId,
      ply: 2,
      moveIndex: 0,
      chainValue: real.chainValue,
      position: real.position,
    );
    carol.service.handleIncoming(ChessIncoming(_channel, forged.encode()));
    expect(carol.game!.ply, 1);
    // And a made-up chain value.
    final random = ChessMovePacket(
      gameId: real.gameId,
      ply: 2,
      moveIndex: 0,
      chainValue: Uint8List(16),
      position: real.position,
    );
    carol.service.handleIncoming(ChessIncoming(_channel, random.encode()));
    black.service.handleIncoming(ChessIncoming(_channel, random.encode()));
    expect(carol.game!.ply, 1);
    expect(black.game!.ply, 1);
  });

  test('resign, draw and timeout claims', () async {
    final alice = player('Alice');
    final bob = player('Bob');
    var (white, black) = await startGame(alice, bob);
    await white.service.offerDraw(white.game!);
    expect(black.game!.drawOfferedBy, ChessSide.white);
    await black.service.acceptDraw(black.game!);
    expect(white.game!.endReason, ChessEndReason.drawAgreed);

    final carol = player('Carol', seed: 8);
    final dan = player('Dan', seed: 9);
    (white, black) = await startGame(carol, dan);
    await black.service.resign(black.game!);
    expect(white.game!.winner, ChessSide.white);
    expect(white.game!.endReason, ChessEndReason.resignation);

    final erin = player('Erin', seed: 10);
    final finn = player('Finn', seed: 11);
    (white, black) = await startGame(erin, finn);
    await white.service.makeMove(white.game!, 'e2e4');
    expect(white.service.canClaimTimeout(white.game!), isFalse);
    now = now.add(const Duration(hours: 1, minutes: 11));
    expect(white.service.canClaimTimeout(white.game!), isTrue);
    expect(await white.service.claimTimeout(white.game!), isTrue);
    expect(black.game!.endReason, ChessEndReason.timeout);
    expect(black.game!.winner, ChessSide.white);
  });

  test('games persist per radio scope', () async {
    final alice = player('Alice');
    final bob = player('Bob');
    final (white, _) = await startGame(alice, bob);
    await white.service.makeMove(white.game!, 'g1f3');
    await alice.service.store.flush();

    final reloaded = ChessStore().load(alice.link.storageScope).single;
    expect(reloaded.ply, 1);
    expect(reloaded.mySide, alice.game!.mySide);
    expect(reloaded.mySeedHex, isNotNull);
    expect(ChessStore().load('other00000'), isEmpty);
  });

  test('invites expire after a day', () async {
    final alice = player('Alice');
    final bob = player('Bob');
    await alice.service.createInvite(channelId: _channel);
    now = now.add(const Duration(hours: 25));
    bob.service.housekeeping();
    expect(bob.game!.endReason, ChessEndReason.expired);
  });

  /// The packets [p] sent of type [T].
  List<T> sentOf<T extends ChessPacket>(_Player p) =>
      p.link.sent.map(ChessPacket.decode).whereType<T>().toList();

  void feed(_Player p, ChessPacket packet) =>
      p.service.handleIncoming(ChessIncoming(_channel, packet.encode()));

  /// A legal move on [game]'s board as the next half-move, carrying [value].
  ChessMovePacket craftMove(ChessGame game, String uci, Uint8List value) {
    final probe = ChessGame.fromJson(game.toJson())!;
    final index = probe.legalUci().indexOf(uci);
    probe.applyUci(uci);
    return ChessMovePacket(
      gameId: game.gameId,
      ply: probe.ply,
      moveIndex: index,
      chainValue: value,
      position: probe.packedPosition(),
    );
  }

  group('review regressions', () {
    test('a replayed chain value cannot carry a later move', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final carol = player('Carol');
      final (white, black) = await startGame(alice, bob);
      await white.service.makeMove(white.game!, 'e2e4');
      final first = sentOf<ChessMovePacket>(white).last;
      await black.service.makeMove(black.game!, 'e7e5');

      // White's ply-1 value with a legal ply-3 move.
      final replay = craftMove(black.game!, 'd1h5', first.chainValue);
      feed(black, replay);
      feed(carol, replay);
      expect(black.game!.ply, 2);
      expect(carol.game!.ply, 2);

      // A spectator two moves behind does not adopt it either.
      final dave = player('Dave');
      feed(dave, sentOf<ChessMovePacket>(black).last);
      final ahead = ChessMovePacket(
        gameId: first.gameId,
        ply: 5,
        moveIndex: 0,
        chainValue: first.chainValue,
        position: first.position,
      );
      feed(carol, ahead);
      expect(carol.game!.ply, 2);

      // The real move is accepted, and a different move with the same value
      // heard afterwards is not: the first one heard wins.
      await white.service.makeMove(white.game!, 'g1f3');
      final real = sentOf<ChessMovePacket>(white).last;
      final copy = craftMove(
        ChessGame.fromJson(carol.game!.toJson())!
          ..adoptPosition(black.game!.fen, 2),
        'd2d4',
        real.chainValue,
      );
      feed(carol, copy);
      expect(carol.game!.ply, 3);
      expect(carol.game!.sanMoves.last, 'Nf3');
    });

    test('a forged game info is ignored', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final carol = player('Carol');
      final mallory = HashChain(Uint8List(16)..[0] = 66);
      // Nobody hears Alice's confirmation.
      mesh.filter = (from, to, payload) =>
          !(from == alice.link &&
              ChessPacket.decode(payload) is ChessInfoPacket);
      await alice.service.createInvite(
        channelId: _channel,
        colour: ChessColourPreference.white,
      );
      await bob.service.accept(bob.game!);
      await settle();
      final real = sentOf<ChessInfoPacket>(alice).single;
      final inviter = alice.game!.inviter!.commitment;

      // Without the inviter's value: lists Mallory and swaps colours.
      ChessInfoPacket info({
        required Uint8List white,
        required Uint8List black,
        required Uint8List value,
      }) => ChessInfoPacket(
        gameId: real.gameId,
        ply: 0,
        startedAtUnix: 0,
        deadline: ChessDeadline.days3,
        whiteCommitment: white,
        blackCommitment: black,
        inviterValue: value,
        whiteName: 'Alice',
        blackName: 'Mallory',
      );
      final noValue = info(
        white: inviter,
        black: mallory.commitment,
        value: Uint8List(16),
      );
      feed(bob, noValue);
      feed(carol, noValue);
      expect(bob.game!.status, ChessGameStatus.starting);
      expect(bob.game!.mySeedHex, isNotNull);
      expect(carol.game!.status, ChessGameStatus.invite);

      // The real value, but colours the invite does not allow.
      final swapped = info(
        white: real.blackCommitment,
        black: inviter,
        value: real.inviterValue,
      );
      feed(bob, swapped);
      feed(carol, swapped);
      expect(bob.game!.status, ChessGameStatus.starting);
      expect(carol.game!.status, ChessGameStatus.invite);

      // A copied value listing Mallory: Bob watches but keeps his chain, and
      // asking again gets him the real game.
      final copied = info(
        white: inviter,
        black: mallory.commitment,
        value: real.inviterValue,
      );
      feed(bob, copied);
      expect(bob.game!.isPlayer, isFalse);
      expect(bob.game!.mySeedHex, isNotNull);
      mesh.filter = null;
      await bob.service.requestUpdate(bob.game!);
      await settle();
      expect(bob.game!.mySide, ChessSide.black);
      expect(bob.game!.nameOf(ChessSide.white), 'Alice');

      // A late joiner can't tie the info to an invite: not confirmed.
      final dave = player('Dave');
      feed(dave, real);
      expect(dave.game!.hasPlayers, isTrue);
      expect(dave.game!.playersConfirmed, isFalse);
      expect(carol.game!.playersConfirmed, isTrue);
    });

    test('a forged move never starts an invite', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final carol = player('Carol');
      await alice.service.createInvite(
        channelId: _channel,
        colour: ChessColourPreference.white,
      );
      final forged = craftMove(alice.game!, 'e2e4', Uint8List(16));
      feed(alice, forged);
      feed(carol, forged);
      expect(alice.game!.status, ChessGameStatus.invite);
      expect(carol.game!.status, ChessGameStatus.invite);

      // A real accept still starts the game, and a repeat is answered.
      await bob.service.accept(bob.game!);
      await settle();
      expect(alice.game!.mySide, ChessSide.white);
      feed(alice, sentOf<ChessAcceptPacket>(bob).single);
      await settle();
      expect(alice.game!.status, ChessGameStatus.active);

      // A spectator who missed the start follows the inviter's first move.
      final dave = player('Dave');
      feed(dave, sentOf<ChessInvitePacket>(alice).single);
      await alice.service.makeMove(alice.game!, 'e2e4');
      expect(dave.game!.status, ChessGameStatus.active);
      expect(dave.game!.ply, 1);
      expect(dave.game!.white, same(dave.game!.inviter));
    });

    test('a confirmation heard while our accept is sending counts', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      await alice.service.createInvite(channelId: _channel);
      bob.link.slow = true;
      await bob.service.accept(bob.game!);
      expect(bob.game!.status, ChessGameStatus.active);
      expect(bob.game!.isPlayer, isTrue);
    });

    test('a losing accepter who missed the info learns it by asking', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final carol = player('Carol');
      await alice.service.createInvite(channelId: _channel);
      mesh.filter = (from, to, _) => to != carol.link;
      await bob.service.accept(bob.game!);
      await settle();
      mesh.filter = (from, to, payload) =>
          !(to == carol.link && ChessPacket.decode(payload) is ChessInfoPacket);
      await carol.service.accept(carol.game!);
      await settle();
      expect(carol.game!.status, ChessGameStatus.starting);

      // Alice answered (unheard); she answers again after a minute.
      mesh.filter = null;
      now = now.add(ChessService.requestAnswerInterval);
      await carol.service.requestUpdate(carol.game!);
      await settle();
      expect(carol.game!.status, ChessGameStatus.active);
      expect(carol.game!.isPlayer, isFalse);
      expect(carol.game!.hasPlayers, isTrue);
    });

    test('repeated accepts are answered at most once a minute', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      await startGame(alice, bob);
      final before = sentOf<ChessInfoPacket>(alice).length;
      final accept = sentOf<ChessAcceptPacket>(bob).single;
      for (var i = 0; i < 5; i++) {
        feed(alice, accept);
        await settle();
      }
      expect(sentOf<ChessInfoPacket>(alice).length, before + 1);
    });

    test('a lost move followed by a draw offer still gets through', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final (white, black) = await startGame(alice, bob);
      mesh.filter = (from, to, payload) =>
          !(to == black.link && ChessPacket.decode(payload) is ChessMovePacket);
      await white.service.makeMove(white.game!, 'e2e4');
      mesh.filter = null;
      await white.service.offerDraw(white.game!);
      expect(black.game!.ply, 0);
      // The offer was for a position Black has not seen.
      expect(black.game!.drawOfferedBy, isNull);

      await black.service.requestUpdate(black.game!);
      await settle();
      expect(black.game!.ply, 1);
      expect(black.game!.isMyTurn, isTrue);
      await black.service.makeMove(black.game!, 'e7e5');
      expect(white.game!.ply, 2);
    });

    test('a move the radio did not confirm is kept and sent again', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final (white, black) = await startGame(alice, bob);
      final next = white.game!.myNextChainIndex;
      white.link.failNext = true;
      expect(await white.service.makeMove(white.game!, 'e2e4'), isFalse);
      // Applied, with its chain value used up.
      expect(white.game!.ply, 1);
      expect(white.game!.moveUnconfirmed, isTrue);
      expect(white.game!.myNextChainIndex, next + 1);
      expect(black.game!.ply, 0);

      await white.service.requestUpdate(white.game!);
      expect(black.game!.ply, 1);
      expect(white.game!.moveUnconfirmed, isFalse);

      // A failed action does not give its chain value back either.
      black.link.failNext = true;
      final before = black.game!.myNextChainIndex;
      expect(await black.service.offerDraw(black.game!), isFalse);
      expect(black.game!.myNextChainIndex, before + 1);
      expect(await black.service.makeMove(black.game!, 'e7e5'), isTrue);
      expect(white.game!.ply, 2);
    });

    test(
      'a move that went out despite a failed send is not replaced',
      () async {
        final alice = player('Alice');
        final bob = player('Bob');
        final (white, black) = await startGame(alice, bob);
        white.link
          ..failNext = true
          ..deliverFailed = true;
        await white.service.makeMove(white.game!, 'e2e4');
        expect(black.game!.ply, 1);
        expect(white.game!.isMyTurn, isFalse);
        expect(await white.service.makeMove(white.game!, 'd2d4'), isFalse);
        expect(white.game!.fen, black.game!.fen);
      },
    );

    test('draw accepts and timeout claims need their preconditions', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final carol = player('Carol');
      final (white, black) = await startGame(alice, bob);
      final whiteChain = white.game!.myChain!;
      var next = white.game!.myNextChainIndex;
      ChessActionPacket action(ChessPacketKind kind) => ChessActionPacket(
        kind: kind,
        gameId: white.game!.gameId,
        ply: white.game!.ply,
        chainValue: whiteChain.valueAt(next++),
      );

      // No draw offer pending.
      final accept = action(ChessPacketKind.drawAccept);
      feed(black, accept);
      feed(carol, accept);
      expect(black.game!.status, ChessGameStatus.active);
      expect(carol.game!.status, ChessGameStatus.active);

      // Black to move, but the hour is not up yet.
      white.game!.myNextChainIndex = next;
      await white.service.makeMove(white.game!, 'e2e4');
      next = white.game!.myNextChainIndex;
      now = now.add(const Duration(minutes: 30));
      feed(black, action(ChessPacketKind.timeoutClaim));
      expect(black.game!.status, ChessGameStatus.active);
      // Past the deadline it counts.
      now = now.add(const Duration(minutes: 31));
      feed(black, action(ChessPacketKind.timeoutClaim));
      expect(black.game!.endReason, ChessEndReason.timeout);

      // No deadline at all: never.
      final erin = player('Erin');
      final finn = player('Finn');
      final invite = await erin.service.createInvite(
        channelId: _channel,
        deadline: ChessDeadline.none,
        colour: ChessColourPreference.white,
      );
      await finn.service.accept(finn.service.game(_channel, invite!.gameId)!);
      await settle();
      final e = erin.service.game(_channel, invite.gameId)!;
      await erin.service.makeMove(e, 'e2e4');
      now = now.add(const Duration(days: 30));
      final claim = ChessActionPacket(
        kind: ChessPacketKind.timeoutClaim,
        gameId: e.gameId,
        ply: e.ply,
        chainValue: e.myChain!.valueAt(e.myNextChainIndex),
      );
      feed(finn, claim);
      expect(
        finn.service.game(_channel, invite.gameId)!.status,
        ChessGameStatus.active,
      );
    });

    test('notifications for the open game resume in the background', () async {
      var foreground = true;
      final alice = player('Alice');
      final bob = player('Bob', isForeground: () => foreground);
      final (white, black) = await startGame(alice, bob);
      expect(black, same(bob));
      bob.service.viewing = bob.game;
      await white.service.makeMove(white.game!, 'e2e4');
      expect(bob.link.notifications, isEmpty);
      await black.service.makeMove(black.game!, 'e7e5');
      foreground = false;
      await white.service.makeMove(white.game!, 'd2d4');
      expect(bob.link.notifications, hasLength(1));
    });

    test('the game cap keeps our own invites and accepts', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final mine = await alice.service.createInvite(channelId: _channel);
      final theirs = await bob.service.createInvite(channelId: _channel);
      await alice.service.accept(alice.service.game(_channel, theirs!.gameId)!);
      now = now.add(const Duration(minutes: 1));
      for (var i = 0; i < ChessService.maxStoredGames + 5; i++) {
        feed(
          alice,
          ChessInvitePacket(
            gameId: 1000 + i,
            deadline: ChessDeadline.hour1,
            colour: ChessColourPreference.random,
            commitment: Uint8List(16)..[0] = i,
            inviterName: 'Spam $i',
          ),
        );
      }
      alice.service.housekeeping();
      expect(alice.service.game(_channel, mine!.gameId), isNotNull);
      expect(alice.service.game(_channel, theirs.gameId), isNotNull);
    });

    test('only the inviter acts on a decline', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final carol = player('Carol');
      await alice.service.createInvite(channelId: _channel, targetName: 'Bob');
      feed(
        carol,
        ChessDeclinePacket(gameId: alice.game!.gameId, declinerName: 'Bob'),
      );
      expect(carol.game!.status, ChessGameStatus.invite);
      expect(bob.game!.status, ChessGameStatus.invite);
      // The challenge to Bob is neither listed nor counted for Carol.
      expect(carol.service.isListed(carol.game!), isFalse);
      expect(carol.service.openCountForChannel(_channel), 0);
      expect(bob.service.openCountForChannel(_channel), 1);
    });

    test('a late joiner keeps the full ply and takes the deadline from the '
        'game info', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final (white, _) = await startGame(alice, bob);
      final g = white.game!;
      final move = ChessMovePacket(
        gameId: g.gameId,
        ply: 301,
        moveIndex: 0,
        chainValue: Uint8List(16),
        position: g.packedPosition(),
      );
      final dave = player('Dave');
      feed(dave, move);
      expect(dave.game!.ply, 301);
      expect(dave.game!.deadline, ChessDeadline.none);
      feed(dave, sentOf<ChessInfoPacket>(alice).single);
      expect(dave.game!.hasPlayers, isTrue);
      expect(dave.game!.deadline, ChessDeadline.hour1);
    });

    test('a spectator who hears the game info mid-game takes the board from '
        'the latest move', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final (white, black) = await startGame(alice, bob);
      await white.service.makeMove(white.game!, 'e2e4');
      await black.service.makeMove(black.game!, 'e7e5');
      final dave = player('Dave');
      await dave.service.requestUpdate(
        ChessGame(
          channelId: _channel,
          gameId: alice.game!.gameId,
          status: ChessGameStatus.active,
          deadline: ChessDeadline.none,
          hasPosition: false,
          createdAtMs: 0,
        ),
      );
      await settle();
      expect(dave.game!.hasPlayers, isTrue);
      expect(dave.game!.ply, 2);
      expect(dave.game!.hasPosition, isTrue);
      expect(dave.game!.fen, alice.game!.fen);
    });

    test(
      'a lost checkmate reaches the opponent who sends their move again',
      () async {
        final alice = player('Alice');
        final bob = player('Bob');
        final (white, black) = await startGame(alice, bob);
        const moves = ['e2e4', 'e7e5', 'f1c4', 'b8c6', 'd1h5', 'g8f6'];
        for (var i = 0; i < moves.length; i++) {
          final mover = i.isEven ? white : black;
          await mover.service.makeMove(mover.game!, moves[i]);
        }
        mesh.filter = (from, to, _) =>
            !(from == white.link && to == black.link);
        await white.service.makeMove(white.game!, 'h5f7');
        mesh.filter = null;
        expect(white.game!.endReason, ChessEndReason.checkmate);
        expect(black.game!.status, ChessGameStatus.active);

        // Black's Ask for update re-sends g8f6; White answers with the mate.
        await black.service.requestUpdate(black.game!);
        await settle();
        expect(black.game!.status, ChessGameStatus.finished);
        expect(black.game!.endReason, ChessEndReason.checkmate);
        expect(black.game!.winner, ChessSide.white);

        // Rate-limited like other answers.
        final sent = white.link.sent.length;
        feed(white, sentOf<ChessMovePacket>(black).last);
        await settle();
        expect(white.link.sent.length, sent);
      },
    );

    test('a lost resignation is sent again with recovery answers', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final carol = player('Carol');
      final (white, black) = await startGame(alice, bob);
      await white.service.makeMove(white.game!, 'e2e4');
      await black.service.makeMove(black.game!, 'e7e5');
      mesh.filter = (from, to, payload) =>
          !(from == white.link &&
              ChessPacket.decode(payload) is ChessActionPacket);
      expect(await white.service.resign(white.game!), isTrue);
      expect(white.game!.finalActionPacket, isNotNull);
      expect(black.game!.status, ChessGameStatus.active);
      expect(carol.game!.status, ChessGameStatus.active);

      // Kept across a restart.
      await white.service.store.flush();
      final reloaded = ChessStore().load(white.link.storageScope).single;
      expect(reloaded.finalActionPacket, white.game!.finalActionPacket);

      // Black re-sends its move; White answers with the resignation. Carol
      // still misses it.
      mesh.filter = (from, to, payload) =>
          !(to == carol.link &&
              ChessPacket.decode(payload) is ChessActionPacket);
      await black.service.requestUpdate(black.game!);
      await settle();
      expect(black.game!.endReason, ChessEndReason.resignation);
      expect(black.game!.winner, black.game!.mySide);
      expect(carol.game!.status, ChessGameStatus.active);

      // Carol asks; a player answers with the resignation.
      mesh.filter = null;
      now = now.add(ChessService.requestAnswerInterval);
      await carol.service.requestUpdate(carol.game!);
      await settle();
      expect(carol.game!.endReason, ChessEndReason.resignation);
      expect(carol.game!.winner, ChessSide.black);

      // Hearing it again changes nothing.
      final resign = sentOf<ChessActionPacket>(white).first;
      final index = carol.game!.white!.lastIndex;
      feed(carol, resign);
      expect(carol.game!.white!.lastIndex, index);
      expect(carol.game!.endReason, ChessEndReason.resignation);
    });

    test('a draw accept or timeout claim that crosses a move does not '
        'apply', () async {
      final alice = player('Alice');
      final bob = player('Bob');
      final (white, black) = await startGame(alice, bob);
      await white.service.makeMove(white.game!, 'e2e4');
      now = now.add(const Duration(hours: 1, minutes: 11));
      expect(white.service.canClaimTimeout(white.game!), isTrue);

      // White's claim and Black's move cross on air.
      Uint8List? claim;
      mesh.filter = (from, to, payload) {
        if (from == white.link &&
            ChessPacket.decode(payload) is ChessActionPacket) {
          claim = payload;
          return false;
        }
        return true;
      };
      white.link.slow = true;
      Timer.run(() => black.service.makeMove(black.game!, 'e7e5'));
      expect(await white.service.claimTimeout(white.game!), isFalse);
      await settle();
      black.service.handleIncoming(ChessIncoming(_channel, claim!));
      for (final p in [white, black]) {
        expect(p.game!.status, ChessGameStatus.active);
        expect(p.game!.ply, 2);
      }
      // The claim's value is used up on both sides.
      final claimIndex = white.game!.myNextChainIndex - 1;
      expect(white.game!.playerOf(white.game!.mySide!)!.lastIndex, claimIndex);
      expect(black.game!.playerOf(ChessSide.white)!.lastIndex, claimIndex);

      // Same for a draw accept crossing a move.
      claim = null;
      await white.service.makeMove(white.game!, 'g1f3');
      await black.service.offerDraw(black.game!);
      expect(white.game!.drawOfferedBy, ChessSide.black);
      // Black then moves after all, while White accepts.
      Timer.run(() => black.service.makeMove(black.game!, 'b8c6'));
      expect(await white.service.acceptDraw(white.game!), isFalse);
      await settle();
      black.service.handleIncoming(ChessIncoming(_channel, claim!));
      for (final p in [white, black]) {
        expect(p.game!.status, ChessGameStatus.active);
        expect(p.game!.ply, 4);
      }
      mesh.filter = null;
      white.link.slow = false;
      expect(await white.service.makeMove(white.game!, 'f1c4'), isTrue);
      expect(black.game!.ply, 5);
    });

    test('a malformed position never throws out of the listener', () {
      final carol = player('Carol');
      final packet = Uint8List.fromList(
        ChessMovePacket(
          gameId: 5,
          ply: 1,
          moveIndex: 0,
          chainValue: Uint8List(16),
          position: Uint8List(10),
        ).encode(),
      );
      expect(
        () => carol.service.handleIncoming(ChessIncoming(_channel, packet)),
        returnsNormally,
      );
    });
  });
}
