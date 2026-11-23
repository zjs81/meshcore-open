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

  _FakeLink(this.mesh, this.selfName, this.storageScope) {
    mesh.links.add(this);
  }

  @override
  Stream<ChessIncoming> get incoming => controller.stream;

  @override
  Future<bool> send(String channelId, Uint8List payload) async {
    if (!connected) return false;
    sent.add(payload);
    mesh.deliver(this, payload);
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
  _Player player(String name, {int? seed}) {
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
      minutes: 0,
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
      minutes: 0,
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
}
