import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/screens/channels_screen.dart';
import 'package:meshcore_open/screens/contacts_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/ui_view_state_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/mesh_ui.dart';

/// Repeatable stand-in for profiling rapid scrolling on a phone: builds the
/// contacts list with 500 contacts and the channels list with 40 channels,
/// flings each list, and counts widget builds and rows that are not fully
/// drawn while scrolling. Run with `flutter test
/// test/screens/list_scroll_perf_test.dart` and read the printed lines.
/// See documentation/performance-profiling.md for the on-device check.

const _contactCount = 500;
const _channelCount = 40;

class _Connector extends MeshCoreConnector {
  List<Contact> nodes = [];
  List<Channel> slots = [];
  final Map<String, int> unread = {};
  final Map<int, ChannelMessage> latest = {};

  @override
  List<Contact> get contacts => List.unmodifiable(nodes);

  @override
  List<Channel> get channels => List.unmodifiable(slots);

  @override
  int getUnreadCountForContact(Contact contact) =>
      unread[contact.publicKeyHex] ?? 0;

  @override
  int getUnreadCountForChannel(Channel channel) => channel.unreadCount;

  @override
  ChannelMessage? latestVisibleChannelMessage(Channel channel) =>
      latest[channel.index];

  @override
  Future<void> getChannels({int? maxChannels, bool force = false}) async {}
}

Contact _contact(int i, DateTime now) {
  final key = Uint8List(32)
    ..[0] = i >> 8
    ..[1] = i & 0xff
    ..[2] = 0x5a;
  final type = i % 10 == 0
      ? advTypeRepeater
      : i % 25 == 0
      ? advTypeRoom
      : advTypeChat;
  return Contact(
    publicKey: key,
    name: 'Node ${i.toString().padLeft(3, '0')}',
    type: type,
    pathLength: i % 4,
    path: Uint8List.fromList(List.filled(i % 4, i & 0xff)),
    latitude: i.isEven ? 35.0 : null,
    longitude: i.isEven ? -112.0 : null,
    lastSeen: now.subtract(Duration(minutes: i * 7)),
  );
}

/// Counts element builds per widget type, via the framework's debug hook.
class _BuildCounter {
  final Map<String, int> counts = {};

  void start() {
    counts.clear();
    debugOnRebuildDirtyWidget = (element, _) {
      final name = element.widget.runtimeType.toString();
      counts[name] = (counts[name] ?? 0) + 1;
    };
  }

  void stop() => debugOnRebuildDirtyWidget = null;

  int operator [](String type) => counts[type] ?? 0;
  int get total => counts.values.fold(0, (a, b) => a + b);
}

/// Rows inside the visible list area whose entrance fade has not finished:
/// they are blank or partly transparent while the user scrolls.
int _rowsNotFullyDrawn(WidgetTester tester, Rect viewport) {
  final fades = find.descendant(
    of: find.byType(ListEntrance),
    matching: find.byType(FadeTransition),
  );
  var count = 0;
  for (final element in fades.evaluate()) {
    final fade = element.widget as FadeTransition;
    final box = element.renderObject as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!rect.overlaps(viewport)) continue;
    if (fade.opacity.value < 1) count++;
  }
  return count;
}

class _ScrollResult {
  int frames = 0;
  int notFullyDrawnRowFrames = 0;
  int maxNotFullyDrawn = 0;
  int notFullyDrawnAfterStop = 0;
}

/// Flings [list] like a rapid swipe and pumps 60 Hz frames until the list
/// stops, firing a connector notify partway through.
Future<_ScrollResult> _fling(
  WidgetTester tester,
  Finder list,
  _Connector connector, {
  required Offset offset,
}) async {
  final viewport = tester.getRect(list);
  final position = tester.state<ScrollableState>(
    find.descendant(of: list, matching: find.byType(Scrollable)).first,
  );
  final result = _ScrollResult();
  await tester.fling(list, offset, 6000);
  for (var i = 0; i < 400; i++) {
    if (i == 10) connector.notifyListeners();
    await tester.pump(const Duration(milliseconds: 16));
    result.frames++;
    final hidden = _rowsNotFullyDrawn(tester, viewport);
    result.notFullyDrawnRowFrames += hidden;
    if (hidden > result.maxNotFullyDrawn) result.maxNotFullyDrawn = hidden;
    if (i > 12 && !position.position.isScrollingNotifier.value) break;
  }
  result.notFullyDrawnAfterStop = _rowsNotFullyDrawn(tester, viewport);
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector connector;
  late AppSettingsService settings;
  late UiViewStateService viewState;
  final counter = _BuildCounter();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    connector = _Connector();
    settings = AppSettingsService();
    viewState = UiViewStateService();
  });

  tearDown(() {
    counter.stop();
    connector.dispose();
    settings.dispose();
    viewState.dispose();
  });

  /// Opens [home] and returns how many rows played the entrance animation.
  Future<int> open(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: viewState),
        ],
        child: MaterialApp(
          theme: MeshTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pump();
    final animatedRows = find
        .descendant(
          of: find.byType(ListEntrance),
          matching: find.byType(FadeTransition),
        )
        .evaluate()
        .length;
    // Let the first screen's entrance animations finish.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    return animatedRows;
  }

  Future<void> notifyAndSettle(WidgetTester tester) async {
    connector.notifyListeners();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    counter.stop();
    await tester.pumpWidget(const SizedBox.shrink());
    // Drain entrance-delay timers.
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('contacts list: rapid fling with 500 contacts', (tester) async {
    final now = DateTime.now();
    connector.nodes = [
      for (var i = 0; i < _contactCount; i++) _contact(i, now),
    ];
    for (var i = 1; i < _contactCount; i += 9) {
      connector.unread[connector.nodes[i].publicKeyHex] = i % 5 + 1;
    }
    final animatedRows = await open(tester, const ContactsScreen());
    final list = find.byType(ListView);
    expect(list, findsOneWidget);

    counter.start();
    final down = await _fling(
      tester,
      list,
      connector,
      offset: const Offset(0, -2500),
    );
    final flingBuilds = Map.of(counter.counts);
    final flingTotal = counter.total;

    counter.start();
    await notifyAndSettle(tester);
    final notifyTiles = counter['_ContactTile'];
    final notifyTotal = counter.total;

    // A live change still reaches the visible tile.
    final visible = tester
        .widgetList(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_ContactTile',
          ),
        )
        .map((w) => (w as dynamic).contact as Contact)
        .toList();
    final target = visible[visible.length ~/ 2];
    connector.unread[target.publicKeyHex] = 42;
    counter.start();
    await notifyAndSettle(tester);
    final changeTiles = counter['_ContactTile'];
    expect(find.text('42'), findsOneWidget);

    // So does a replaced contact.
    final renamedAt = connector.nodes.indexOf(visible.first);
    connector.nodes = List.of(connector.nodes)
      ..[renamedAt] = visible.first.copyWith(name: 'Renamed node');
    await notifyAndSettle(tester);
    expect(find.text('Renamed node'), findsOneWidget);

    // ignore: avoid_print
    print(
      '[list-perf] contacts fling: frames=${down.frames} '
      'itemBuilds=${flingBuilds['_ContactTileEntrance'] ?? 0} '
      'tileBuilds=${flingBuilds['_ContactTile'] ?? 0} '
      'entranceBuilds=${flingBuilds['ListEntrance'] ?? 0} '
      'allBuilds=$flingTotal '
      'rowFramesNotFullyDrawn=${down.notFullyDrawnRowFrames} '
      'maxRowsNotFullyDrawn=${down.maxNotFullyDrawn} '
      'rowsNotFullyDrawnAtStop=${down.notFullyDrawnAfterStop}\n'
      '[list-perf] contacts notify (no change): tileBuilds=$notifyTiles '
      'allBuilds=$notifyTotal; one unread change: tileBuilds=$changeTiles',
    );

    // The first screen still animates in; rows a fling brings in do not.
    expect(animatedRows, greaterThan(0));
    expect(down.notFullyDrawnRowFrames, 0);
    // A notify that changes nothing rebuilds no rows; a change rebuilds one.
    expect(notifyTiles, 0);
    expect(changeTiles, 1);

    await close(tester);
  });

  testWidgets('channels list: rapid fling with 40 channels', (tester) async {
    final now = DateTime.now();
    connector.slots = [
      for (var i = 0; i < _channelCount; i++)
        Channel(
          index: i,
          name: i == 0 ? 'Public' : '#topic-$i',
          psk: Uint8List.fromList(List.filled(16, i + 1)),
          unreadCount: i % 3 == 0 ? i : 0,
        ),
    ];
    for (var i = 0; i < _channelCount; i++) {
      connector.latest[i] = ChannelMessage(
        senderName: 'Sender $i',
        text: 'Message preview number $i on the mesh',
        timestamp: now.subtract(Duration(minutes: i * 13)),
        isOutgoing: false,
        status: ChannelMessageStatus.sent,
        channelIndex: i,
      );
    }
    viewState.setChannelsSortOption(ChannelSortOption.name);
    final animatedRows = await open(tester, const ChannelsScreen());
    final list = find.byType(ListView);
    expect(list, findsOneWidget);

    counter.start();
    final down = await _fling(
      tester,
      list,
      connector,
      offset: const Offset(0, -2500),
    );
    final flingBuilds = Map.of(counter.counts);
    final flingTotal = counter.total;

    counter.start();
    await notifyAndSettle(tester);
    final notifyTiles = counter['MeshCard'];

    // ignore: avoid_print
    print(
      '[list-perf] channels fling: frames=${down.frames} '
      'itemBuilds=${flingBuilds['ListEntrance'] ?? 0} '
      'cardBuilds=${flingBuilds['MeshCard'] ?? 0} '
      'allBuilds=$flingTotal '
      'rowFramesNotFullyDrawn=${down.notFullyDrawnRowFrames} '
      'maxRowsNotFullyDrawn=${down.maxNotFullyDrawn} '
      'rowsNotFullyDrawnAtStop=${down.notFullyDrawnAfterStop}\n'
      '[list-perf] channels notify (no change): cardBuilds=$notifyTiles',
    );

    expect(animatedRows, greaterThan(0));
    expect(down.notFullyDrawnRowFrames, 0);

    await close(tester);
  });
}
