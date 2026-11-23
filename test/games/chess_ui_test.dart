import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/games/chess/chess_game.dart';
import 'package:meshcore_open/games/chess/chess_link.dart';
import 'package:meshcore_open/games/chess/chess_packets.dart';
import 'package:meshcore_open/games/chess/chess_service.dart';
import 'package:meshcore_open/games/chess/ui/chess_board.dart';
import 'package:meshcore_open/games/chess/ui/chess_game_screen.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/games/chess/ui/chess_games_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _l10n = lookupAppLocalizations(const Locale('en'));

class _ConnectedConnector extends MeshCoreConnector {
  @override
  bool get isConnected => true;
}

class _Link extends ChangeNotifier implements ChessLink {
  final controller = StreamController<ChessIncoming>.broadcast(sync: true);
  final sent = <Uint8List>[];

  @override
  Stream<ChessIncoming> get incoming => controller.stream;
  @override
  Future<bool> send(String channelId, Uint8List payload) async {
    sent.add(payload);
    return true;
  }

  @override
  String get selfName => 'Me';
  @override
  String get storageScope => 'ui00000000';
  @override
  bool get canSend => true;
  @override
  void notify(String channelId, String text) {}
  @override
  AppLocalizations get l10n => _l10n;
}

void main() {
  late Channel channel;
  late String channelId;
  late _Link link;
  late ChessService service;
  late ChessGame myGame;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    channel = Channel(index: 0, name: 'Public', psk: Uint8List(16)..[0] = 9);
    channelId = channel.storageId!;
    link = _Link();
    service = ChessService(link: link, startHousekeeping: false);
    // Our own invite, accepted by Bob, so we play white.
    myGame = (await service.createInvite(
      channelId: channelId,
      colour: ChessColourPreference.white,
    ))!;
    link.controller.add(
      ChessIncoming(
        channelId,
        ChessAcceptPacket(
          gameId: myGame.gameId,
          commitment: Uint8List(16)..[3] = 7,
          accepterName: 'Bob',
        ).encode(),
      ),
    );
    link.controller.add(
      ChessIncoming(
        channelId,
        ChessInvitePacket(
          gameId: 4242,
          deadline: ChessDeadline.day1,
          colour: ChessColourPreference.random,
          commitment: Uint8List(16)..[1] = 1,
          inviterName: 'Carol',
        ).encode(),
      ),
    );
  });

  tearDown(() => service.dispose());

  Widget app(Widget home) => MultiProvider(
    providers: [
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: _ConnectedConnector(),
      ),
      ChangeNotifierProvider.value(value: service),
    ],
    child: MaterialApp(
      theme: MeshTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  testWidgets('sheet lists our game and the open invite', (tester) async {
    // A cancelled invite of ours, listed under Finished.
    final cancelled = await tester.runAsync(
      () => service.createInvite(channelId: channelId),
    );
    await tester.runAsync(() => service.cancelInvite(cancelled!));
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showChessGamesSheet(context, channel),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.chess_sectionYourGames.toUpperCase()), findsOne);
    expect(find.text(_l10n.chess_vs('Me', 'Bob')), findsOne);
    expect(find.text(_l10n.chess_rowOpenInvite('Carol')), findsOne);
    expect(find.text(_l10n.chess_accept), findsOne);
    expect(find.text(_l10n.chess_rowYourOpenInvite), findsOne);
    expect(find.text(_l10n.chess_endCancelled), findsOne);
    expect(find.text(_l10n.chess_vs('Unknown', 'Unknown')), findsNothing);
  });

  testWidgets('tapping a piece and a target sends the move', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(ChessGameScreen(channelId: channelId, gameId: myGame.gameId)),
    );
    await tester.pump();
    expect(find.byType(ChessBoardView), findsOne);
    expect(find.text(_l10n.chess_statusYourMove), findsWidgets);

    await tester.tap(
      find.bySemanticsLabel(
        _l10n.chess_squareWhitePiece('e2', _l10n.chess_piecePawn),
      ),
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('e4'));
    await tester.pumpAndSettle();

    final move = ChessPacket.decode(link.sent.last);
    expect(move, isA<ChessMovePacket>());
    expect(myGame.sanMoves, ['e4']);
    expect(find.text(_l10n.chess_statusWaiting('Bob')), findsOne);
  });
}
