import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/screens/map_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/ui_view_state_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/quick_switch_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Connector extends MeshCoreConnector {
  List<Contact> nodes = [];
  int contactUnread = 0;
  int channelUnread = 0;

  @override
  List<Contact> get allContacts => List.unmodifiable(nodes);

  @override
  List<Contact> get contacts => List.unmodifiable(nodes);

  @override
  int getTotalContactsUnreadCount() => contactUnread;

  @override
  int getTotalChannelsUnreadCount() => channelUnread;
}

class _UnusedCacheManager implements BaseCacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingTiles extends MapTileCacheService {
  _CountingTiles(AppSettingsService settings)
    : super(appSettingsService: settings, cacheManager: _UnusedCacheManager());

  int builds = 0;

  @override
  Widget buildTileLayer(BuildContext context, {double opacity = 1}) {
    builds++;
    return const SizedBox.shrink();
  }
}

Contact _node({double latitude = 35, DateTime? lastSeen}) => Contact(
  publicKey: Uint8List.fromList(List.filled(32, 1)),
  name: 'Repeater',
  type: advTypeRepeater,
  pathLength: 0,
  path: Uint8List(0),
  latitude: latitude,
  longitude: -112,
  lastSeen: lastSeen ?? DateTime.now(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Connector connector;
  late AppSettingsService settings;
  late _CountingTiles tiles;
  late PathHistoryService paths;
  late UiViewStateService viewState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    connector = _Connector();
    settings = AppSettingsService();
    tiles = _CountingTiles(settings);
    paths = PathHistoryService(StorageService());
    viewState = UiViewStateService();
  });

  tearDown(() {
    connector.dispose();
    settings.dispose();
    tiles.dispose();
    paths.dispose();
    viewState.dispose();
  });

  Future<void> openMap(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: paths),
          ChangeNotifierProvider.value(value: viewState),
          ChangeNotifierProvider<MapTileCacheService>.value(value: tiles),
        ],
        child: MaterialApp(
          theme: MeshTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
  }

  Iterable<LatLng> markerPoints(WidgetTester tester) => tester
      .widgetList<MarkerLayer>(find.byType(MarkerLayer))
      .expand((layer) => layer.markers)
      .map((marker) => marker.point);

  testWidgets('unread badges update without rebuilding the map', (
    tester,
  ) async {
    connector.nodes = [_node()];
    await openMap(tester);
    final originalBuilds = tiles.builds;

    connector.contactUnread = 3;
    connector.channelUnread = 5;
    connector.notifyListeners();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    final navigation = tester.widget<QuickSwitchBar>(
      find.byType(QuickSwitchBar),
    );
    expect(navigation.contactsUnreadCount, 3);
    expect(navigation.channelsUnreadCount, 5);
    expect(tiles.builds, originalBuilds);

    connector.notifyListeners();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(tiles.builds, originalBuilds);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('contact movement invalidates cached markers', (tester) async {
    connector.nodes = [_node()];
    await openMap(tester);
    expect(markerPoints(tester), contains(const LatLng(35, -112)));
    final originalBuilds = tiles.builds;

    connector.nodes = [connector.nodes.single.copyWith(latitude: 36)];
    connector.notifyListeners();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    expect(tiles.builds, greaterThan(originalBuilds));
    expect(markerPoints(tester), contains(const LatLng(36, -112)));
    expect(markerPoints(tester), isNot(contains(const LatLng(35, -112))));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('time filters invalidate the visible marker cache', (
    tester,
  ) async {
    connector.nodes = [
      _node(lastSeen: DateTime.now().subtract(const Duration(hours: 3))),
    ];
    await openMap(tester);
    expect(markerPoints(tester), contains(const LatLng(35, -112)));

    await settings.setMapTimeFilterHours(1);
    await tester.pump();
    expect(markerPoints(tester), isNot(contains(const LatLng(35, -112))));

    await settings.setMapTimeFilterHours(0);
    await tester.pump();
    expect(markerPoints(tester), contains(const LatLng(35, -112)));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
