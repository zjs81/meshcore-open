import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';

void main() {
  Future<MapTileCacheService> serviceWithSource(String sourceId) async {
    SharedPreferences.setMockInitialValues({});
    await PrefsManager.initialize();
    final settings = AppSettingsService();
    await settings.setMapRasterSourceId(sourceId);
    return MapTileCacheService(
      appSettingsService: settings,
      cacheManager: _NoCache(),
    );
  }

  test('satellite tiles use the arcgisonline imagery host', () async {
    final service = await serviceWithSource('satellite');
    expect(
      service.urlTemplate,
      'https://server.arcgisonline.com/ArcGIS/rest/services/'
      'World_Imagery/MapServer/tile/{z}/{y}/{x}',
    );
  });

  test('osm presets keep the openstreetmap template', () async {
    final service = await serviceWithSource('osm_standard');
    expect(
      service.urlTemplate,
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
  });
}

/// Never touched: these tests only inspect the URL template.
class _NoCache implements BaseCacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
