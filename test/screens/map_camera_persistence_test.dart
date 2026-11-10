import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/screens/map_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/ui_view_state_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cameraKey = 'flutter.map_last_camera';
const _preferencesChannel = MethodChannel(
  'plugins.flutter.io/shared_preferences',
);

class _UnusedCacheManager implements BaseCacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MapWithoutTiles extends MapTileCacheService {
  _MapWithoutTiles(AppSettingsService settings)
    : super(appSettingsService: settings, cacheManager: _UnusedCacheManager());

  @override
  Widget buildTileLayer(BuildContext context, {double opacity = 1}) =>
      const SizedBox.shrink();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, Object> persisted;
  late List<List<String>> cameraWrites;

  setUp(() async {
    persisted = {};
    cameraWrites = [];
    SharedPreferences.resetStatic();
    PrefsManager.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_preferencesChannel, (call) async {
          if (call.method == 'getAll') return persisted;
          final args = call.arguments as Map<dynamic, dynamic>;
          final key = args['key'] as String;
          if (call.method == 'remove') {
            persisted.remove(key);
          } else {
            persisted[key] = args['value'] as Object;
            if (key == _cameraKey) {
              cameraWrites.add(List<String>.from(args['value'] as List));
            }
          }
          return true;
        });
    await PrefsManager.initialize();
  });

  Future<MapController> openMap(WidgetTester tester) async {
    final settings = AppSettingsService();
    final connector = MeshCoreConnector();
    final paths = PathHistoryService(StorageService());
    final tiles = _MapWithoutTiles(settings);
    addTearDown(() {
      connector.dispose();
      paths.dispose();
      tiles.dispose();
      settings.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: connector),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: paths),
          ChangeNotifierProvider.value(value: UiViewStateService()),
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
    return tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
  }

  testWidgets('camera movements persist once after interaction settles', (
    tester,
  ) async {
    final controller = await openMap(tester);
    controller.move(const LatLng(35, -112), 9);
    await tester.pump(const Duration(milliseconds: 300));
    controller.move(const LatLng(36, -113), 10);
    await tester.pump(const Duration(milliseconds: 300));
    expect(cameraWrites, isEmpty);
    await tester.pump(const Duration(milliseconds: 201));
    expect(cameraWrites, [
      ['36.0', '-113.0', '10.0'],
    ]);

    // Duplicate end events and disposal must not rewrite an unchanged camera.
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    map.options.onMapEvent!(
      MapEventMoveEnd(
        source: MapEventSource.mapController,
        camera: controller.camera,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(cameraWrites, hasLength(1));
  });

  testWidgets(
    'leaving the map flushes the latest camera and cancels its timer',
    (tester) async {
      final controller = await openMap(tester);
      controller.move(const LatLng(37, -114), 11);
      await tester.pump(const Duration(milliseconds: 100));
      expect(cameraWrites, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(cameraWrites, [
        ['37.0', '-114.0', '11.0'],
      ]);
      await tester.pump(const Duration(seconds: 1));
      expect(cameraWrites, hasLength(1));
    },
  );

  testWidgets('backgrounding the app flushes without waiting for debounce', (
    tester,
  ) async {
    final controller = await openMap(tester);
    controller.move(const LatLng(38, -115), 12);
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(cameraWrites, [
      ['38.0', '-115.0', '12.0'],
    ]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(cameraWrites, hasLength(1));
  });
}
