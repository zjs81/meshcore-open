import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/app_settings.dart';
import 'app_settings_service.dart';

enum MapRasterSourcePreset {
  osmAuto('osm_auto'),
  osmStandard('osm_standard'),
  osmDark('osm_dark'),
  stamenTerrain('stamen_terrain'),
  alidadeSmoothDark('alidade_smooth_dark'),
  outdoors('outdoors'),
  osmBright('osm_bright'),
  outdoorsDark('outdoors_dark'),
  osmBrightDark('osm_bright_dark');

  const MapRasterSourcePreset(this.id);

  final String id;

  static MapRasterSourcePreset fromId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return MapRasterSourcePreset.osmAuto;
  }
}

enum MapRasterEndpointPreset {
  standard('standard'),
  standard2x('standard_2x'),
  eu('eu'),
  eu2x('eu_2x');

  const MapRasterEndpointPreset(this.id);

  final String id;

  static MapRasterEndpointPreset fromId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return MapRasterEndpointPreset.standard;
  }
}

@immutable
class MapRasterSourceDefinition {
  const MapRasterSourceDefinition({
    required this.id,
    required this.label,
    required this.description,
    this.isStadia = false,
    this.allowsBulkDownload = false,
  });

  final String id;
  final String label;
  final String description;
  final bool isStadia;
  final bool allowsBulkDownload;
}

@immutable
class MapRasterEndpointDefinition {
  const MapRasterEndpointDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.host,
    this.scaleSuffix = '',
  });

  final String id;
  final String label;
  final String description;
  final String host;
  final String scaleSuffix;
}

class MapRasterSourceCatalog {
  static const MapRasterSourceDefinition osmAuto = MapRasterSourceDefinition(
    id: 'osm_auto',
    label: 'OpenStreetMap Auto',
    description:
        'Automatically uses OpenStreetMap Standard or Dark from the app theme',
  );
  static const MapRasterSourceDefinition osmStandard =
      MapRasterSourceDefinition(
        id: 'osm_standard',
        label: 'OpenStreetMap Standard',
        description: 'Direct tiles from tile.openstreetmap.org',
      );
  static const MapRasterSourceDefinition osmDark = MapRasterSourceDefinition(
    id: 'osm_dark',
    label: 'OpenStreetMap Dark',
    description: 'Standard OpenStreetMap tiles with an inverted dark filter',
  );
  static const MapRasterSourceDefinition stamenTerrain =
      MapRasterSourceDefinition(
        id: 'stamen_terrain',
        label: 'Stamen Terrain',
        description: 'Terrain-focused style with hill shading',
        isStadia: true,
        allowsBulkDownload: true,
      );
  static const MapRasterSourceDefinition alidadeSmoothDark =
      MapRasterSourceDefinition(
        id: 'alidade_smooth_dark',
        label: 'Alidade Smooth Dark',
        description: 'Dark basemap with smooth contrast',
        isStadia: true,
        allowsBulkDownload: true,
      );
  static const MapRasterSourceDefinition outdoors = MapRasterSourceDefinition(
    id: 'outdoors',
    label: 'Outdoors',
    description: 'Outdoor-focused map with trails and terrain context',
    isStadia: true,
    allowsBulkDownload: true,
  );
  static const MapRasterSourceDefinition osmBright = MapRasterSourceDefinition(
    id: 'osm_bright',
    label: 'OSM Bright',
    description: 'Bright general-purpose OpenStreetMap style',
    isStadia: true,
    allowsBulkDownload: true,
  );
  static const MapRasterSourceDefinition outdoorsDark =
      MapRasterSourceDefinition(
        id: 'outdoors',
        label: 'Outdoors Dark',
        description: 'Dark version of the Outdoors map style',
        isStadia: true,
        allowsBulkDownload: true,
      );
  static const MapRasterSourceDefinition osmBrightDark =
      MapRasterSourceDefinition(
        id: 'osm_bright',
        label: 'OSM Bright Dark',
        description: 'Dark version of the OSM Bright map style',
        isStadia: true,
        allowsBulkDownload: true,
      );

  static MapRasterSourceDefinition fromPreset(MapRasterSourcePreset preset) {
    switch (preset) {
      case MapRasterSourcePreset.osmAuto:
        return osmAuto;
      case MapRasterSourcePreset.osmStandard:
        return osmStandard;
      case MapRasterSourcePreset.osmDark:
        return osmDark;
      case MapRasterSourcePreset.alidadeSmoothDark:
        return alidadeSmoothDark;
      case MapRasterSourcePreset.outdoors:
        return outdoors;
      case MapRasterSourcePreset.outdoorsDark:
        return outdoorsDark;
      case MapRasterSourcePreset.osmBright:
        return osmBright;
      case MapRasterSourcePreset.osmBrightDark:
        return osmBrightDark;
      case MapRasterSourcePreset.stamenTerrain:
        return stamenTerrain;
    }
  }

  static MapRasterSourceDefinition fromSettings(AppSettings settings) {
    return fromPreset(MapRasterSourcePreset.fromId(settings.mapRasterSourceId));
  }
}

class MapRasterEndpointCatalog {
  static const MapRasterEndpointDefinition standard =
      MapRasterEndpointDefinition(
        id: 'standard',
        label: 'Standard Endpoint',
        description: 'Global CDN routing to the fastest Stadia server',
        host: 'tiles.stadiamaps.com',
      );
  static const MapRasterEndpointDefinition standard2x =
      MapRasterEndpointDefinition(
        id: 'standard_2x',
        label: 'Standard Endpoint (@2x)',
        description: 'Global Stadia endpoint with HiDPI raster tiles',
        host: 'tiles.stadiamaps.com',
        scaleSuffix: '@2x',
      );
  static const MapRasterEndpointDefinition eu = MapRasterEndpointDefinition(
    id: 'eu',
    label: 'EU Endpoint',
    description: 'Route tile requests to Stadia EU servers',
    host: 'tiles-eu.stadiamaps.com',
  );
  static const MapRasterEndpointDefinition eu2x = MapRasterEndpointDefinition(
    id: 'eu_2x',
    label: 'EU Endpoint (@2x)',
    description: 'EU Stadia endpoint with HiDPI raster tiles',
    host: 'tiles-eu.stadiamaps.com',
    scaleSuffix: '@2x',
  );

  static const List<MapRasterEndpointDefinition> presets = [
    standard,
    standard2x,
    eu,
    eu2x,
  ];

  static MapRasterEndpointDefinition fromSettings(AppSettings settings) {
    final preset = MapRasterEndpointPreset.fromId(settings.mapTileEndpointId);
    switch (preset) {
      case MapRasterEndpointPreset.standard2x:
        return standard2x;
      case MapRasterEndpointPreset.eu:
        return eu;
      case MapRasterEndpointPreset.eu2x:
        return eu2x;
      case MapRasterEndpointPreset.standard:
        return standard;
    }
  }
}

class MapTileCacheProgress {
  final int completed;
  final int total;
  final int failed;

  const MapTileCacheProgress({
    required this.completed,
    required this.total,
    required this.failed,
  });
}

class MapTileCacheResult {
  final int total;
  final int downloaded;
  final int failed;

  const MapTileCacheResult({
    required this.total,
    required this.downloaded,
    required this.failed,
  });
}

class CachedTileInfo {
  final String key;
  final String host;
  final String sourceId;
  final int zoom;
  final int x;
  final int y;
  final int length;

  const CachedTileInfo({
    required this.key,
    required this.host,
    required this.sourceId,
    required this.zoom,
    required this.x,
    required this.y,
    required this.length,
  });
}

class CachedTileInventory {
  final List<CachedTileInfo> tiles;
  final int totalBytes;

  const CachedTileInventory({required this.tiles, required this.totalBytes});
}

class MapTileCacheService extends ChangeNotifier {
  static const String cacheKey = 'map_tile_cache';
  static const String userAgentPackageName = 'com.meshcore.open';
  static const int defaultMinZoom = 10;
  static const int defaultMaxZoom = 15;

  final AppSettingsService appSettingsService;
  final BaseCacheManager cacheManager;
  late final TileProvider tileProvider;

  MapTileCacheService({
    required this.appSettingsService,
    BaseCacheManager? cacheManager,
  }) : cacheManager =
           cacheManager ??
           CacheManager(
             Config(
               cacheKey,
               stalePeriod: const Duration(days: 365),
               maxNrOfCacheObjects: 200000,
             ),
           ) {
    tileProvider = CachedNetworkTileProvider(cacheManager: this.cacheManager);
    appSettingsService.addListener(_handleSettingsChanged);
  }

  MapRasterSourceDefinition get source {
    final selectedSource = MapRasterSourceCatalog.fromSettings(
      appSettingsService.settings,
    );
    if (!selectedSource.allowsBulkDownload ||
        !appSettingsService.settings.usesstadiaDemo) {
      return selectedSource;
    }
    return MapRasterSourceDefinition(
      id: selectedSource.id,
      label: selectedSource.label,
      description: selectedSource.description,
      isStadia: selectedSource.isStadia,
      allowsBulkDownload: false, // Explicitly disable bulk download for demo.
    );
  }

  MapRasterEndpointDefinition get endpoint =>
      MapRasterEndpointCatalog.fromSettings(appSettingsService.settings);

  String get urlTemplate => _buildUrlTemplate(appSettingsService.settings);

  TileBuilder? get tileBuilder => null;

  static bool shouldApplyDarkFilterForSettings(
    AppSettings settings,
    Brightness brightness,
  ) {
    switch (MapRasterSourcePreset.fromId(settings.mapRasterSourceId)) {
      case MapRasterSourcePreset.osmDark:
      case MapRasterSourcePreset.outdoorsDark:
      case MapRasterSourcePreset.osmBrightDark:
        return true;
      case MapRasterSourcePreset.osmAuto:
        return brightness == Brightness.dark;
      case MapRasterSourcePreset.osmStandard:
      case MapRasterSourcePreset.stamenTerrain:
      case MapRasterSourcePreset.alidadeSmoothDark:
      case MapRasterSourcePreset.outdoors:
      case MapRasterSourcePreset.osmBright:
        return false;
    }
  }

  static const ColorFilter _darkMapFilter = ColorFilter.matrix([
    -0.0850,
    -0.2861,
    -0.0289,
    0,
    120,
    -0.0957,
    -0.3218,
    -0.0325,
    0,
    140,
    -0.1169,
    -0.3934,
    -0.0397,
    0,
    170,
    0,
    0,
    0,
    1,
    0,
  ]);

  CacheManager get _concreteCacheManager => cacheManager as CacheManager;

  Map<String, String> get defaultHeaders => {
    'User-Agent': 'flutter_map ($userAgentPackageName)',
  };

  Widget buildTileLayer(BuildContext context, {double opacity = 1}) {
    Widget layer = TileLayer(
      urlTemplate: urlTemplate,
      tileProvider: tileProvider,
      tileBuilder: tileBuilder,
      userAgentPackageName: userAgentPackageName,
      maxZoom: 19,
    );

    final shouldApplyDarkFilter = shouldApplyDarkFilterForSettings(
      appSettingsService.settings,
      Theme.of(context).brightness,
    );

    if (shouldApplyDarkFilter) {
      layer = ColorFiltered(colorFilter: _darkMapFilter, child: layer);
    }

    if (opacity < 1) {
      layer = Opacity(opacity: opacity, child: layer);
    }

    return layer;
  }

  Future<void> clearCache() async {
    await cacheManager.emptyCache();
  }

  Future<CachedTileInventory> getCachedTileInventory() async {
    final repo = _concreteCacheManager.config.repo;
    await repo.open();
    final objects = await repo.getAllObjects();
    final tiles = <CachedTileInfo>[];
    int totalBytes = 0;

    for (final object in objects) {
      totalBytes += object.length ?? 0;
      final tile = _parseCachedTile(object);
      if (tile != null) {
        tiles.add(tile);
      }
    }

    return CachedTileInventory(tiles: tiles, totalBytes: totalBytes);
  }

  List<CachedTileInfo> filterTilesForActiveSource(
    Iterable<CachedTileInfo> tiles,
  ) {
    final activeSource = source;
    if (!activeSource.isStadia) {
      return tiles
          .where(
            (tile) =>
                tile.sourceId == MapRasterSourceCatalog.osmStandard.id &&
                tile.host == 'tile.openstreetmap.org',
          )
          .toList();
    }

    final activeEndpoint = endpoint;
    return tiles
        .where(
          (tile) =>
              tile.sourceId == activeSource.id &&
              tile.host == activeEndpoint.host,
        )
        .toList();
  }

  int countTilesForBounds(
    Iterable<CachedTileInfo> tiles, {
    LatLngBounds? bounds,
    required int minZoom,
    required int maxZoom,
  }) {
    if (bounds == null) return 0;
    final safeMin = math.min(minZoom, maxZoom);
    final safeMax = math.max(minZoom, maxZoom);
    return tiles.where((tile) {
      if (tile.zoom < safeMin || tile.zoom > safeMax) {
        return false;
      }
      final tileBounds = _tileBoundsForTile(tile.x, tile.y, tile.zoom);
      return _boundsIntersect(bounds, tileBounds);
    }).length;
  }

  List<Polygon> buildCachedTilePolygons(
    Iterable<CachedTileInfo> tiles, {
    required int zoom,
    LatLngBounds? visibleBounds,
    int limit = 250,
  }) {
    final polygons = <Polygon>[];
    for (final tile in tiles) {
      if (tile.zoom != zoom) continue;
      final tileBounds = _tileBoundsForTile(tile.x, tile.y, tile.zoom);
      if (visibleBounds != null &&
          !_boundsIntersect(visibleBounds, tileBounds)) {
        continue;
      }
      polygons.add(
        Polygon(
          points: [
            tileBounds.northWest,
            tileBounds.northEast,
            tileBounds.southEast,
            tileBounds.southWest,
          ],
          borderStrokeWidth: 0.6,
          color: const Color(0x5532A852),
          borderColor: const Color(0xCC2F8F46),
        ),
      );
      if (polygons.length >= limit) break;
    }
    return polygons;
  }

  int estimateTileCount(LatLngBounds bounds, int minZoom, int maxZoom) {
    final safeMin = math.min(minZoom, maxZoom);
    final safeMax = math.max(minZoom, maxZoom);
    int total = 0;

    for (int zoom = safeMin; zoom <= safeMax; zoom++) {
      final tileBounds = _tileBoundsForBounds(bounds, zoom);
      final xCount = tileBounds.maxX - tileBounds.minX + 1;
      final yCount = tileBounds.maxY - tileBounds.minY + 1;
      total += xCount * yCount;
    }
    return total;
  }

  Future<MapTileCacheResult> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    int concurrentDownloads = 8,
    Map<String, String>? headers,
    void Function(MapTileCacheProgress progress)? onProgress,
  }) async {
    final safeMin = math.min(minZoom, maxZoom);
    final safeMax = math.max(minZoom, maxZoom);
    final total = estimateTileCount(bounds, safeMin, safeMax);
    final authHeaders = headers ?? defaultHeaders;
    final safeConcurrency = math.max(1, concurrentDownloads);
    final currentTemplate = urlTemplate;
    int completed = 0;
    int failed = 0;

    final pending = <Future<void>>[];
    Future<void> queueDownload(String url) async {
      final future = cacheManager
          .downloadFile(url, key: url, authHeaders: authHeaders)
          .then((_) {
            completed += 1;
          })
          .catchError((_) {
            completed += 1;
            failed += 1;
          })
          .whenComplete(() {
            onProgress?.call(
              MapTileCacheProgress(
                completed: completed,
                total: total,
                failed: failed,
              ),
            );
          });

      pending.add(future);
      if (pending.length >= safeConcurrency) {
        await Future.wait(pending);
        pending.clear();
      }
    }

    for (int zoom = safeMin; zoom <= safeMax; zoom++) {
      final tileBounds = _tileBoundsForBounds(bounds, zoom);
      for (int x = tileBounds.minX; x <= tileBounds.maxX; x++) {
        for (int y = tileBounds.minY; y <= tileBounds.maxY; y++) {
          final url = _buildTileUrl(x, y, zoom, urlTemplate: currentTemplate);
          await queueDownload(url);
        }
      }
    }

    if (pending.isNotEmpty) {
      await Future.wait(pending);
    }

    return MapTileCacheResult(
      total: total,
      downloaded: completed - failed,
      failed: failed,
    );
  }

  static Map<String, double> boundsToJson(LatLngBounds bounds) {
    return {
      'north': bounds.north,
      'south': bounds.south,
      'east': bounds.east,
      'west': bounds.west,
    };
  }

  static LatLngBounds? boundsFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final north = (json['north'] as num?)?.toDouble();
    final south = (json['south'] as num?)?.toDouble();
    final east = (json['east'] as num?)?.toDouble();
    final west = (json['west'] as num?)?.toDouble();
    if (north == null || south == null || east == null || west == null) {
      return null;
    }
    return LatLngBounds.unsafe(
      north: north,
      south: south,
      east: east,
      west: west,
    );
  }

  void _handleSettingsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    appSettingsService.removeListener(_handleSettingsChanged);
    super.dispose();
  }

  _TileBounds _tileBoundsForBounds(LatLngBounds bounds, int zoom) {
    final north = _clampLatitude(bounds.north);
    final south = _clampLatitude(bounds.south);
    final maxIndex = (1 << zoom) - 1;

    final minX = _lonToTileX(bounds.west, zoom, maxIndex);
    final maxX = _lonToTileX(bounds.east, zoom, maxIndex);
    final minY = _latToTileY(north, zoom, maxIndex);
    final maxY = _latToTileY(south, zoom, maxIndex);

    return _TileBounds(
      minX: math.min(minX, maxX),
      maxX: math.max(minX, maxX),
      minY: math.min(minY, maxY),
      maxY: math.max(minY, maxY),
    );
  }

  String _buildUrlTemplate(AppSettings settings) {
    final source = MapRasterSourceCatalog.fromSettings(settings);
    if (!source.isStadia) {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
    final endpoint = MapRasterEndpointCatalog.fromSettings(settings);
    final apiKey = settings.effectiveMapTileApiKey;
    final base =
        'https://${endpoint.host}/tiles/${source.id}/{z}/{x}/{y}${endpoint.scaleSuffix}.png';
    final query = Uri(queryParameters: {'api_key': apiKey}).query;
    return '$base?$query';
  }

  CachedTileInfo? _parseCachedTile(CacheObject object) {
    final uri = Uri.tryParse(object.key);
    if (uri == null) return null;
    final segments = uri.pathSegments;

    if (segments.length >= 3 &&
        segments[segments.length - 3].isNotEmpty &&
        segments[segments.length - 2].isNotEmpty) {
      final zoom = int.tryParse(segments[segments.length - 3]);
      final x = int.tryParse(segments[segments.length - 2]);
      final ySegment = segments.last;
      final yString = ySegment.split('.').first.replaceAll('@2x', '');
      final y = int.tryParse(yString);

      if (zoom == null || x == null || y == null) {
        return null;
      }

      var sourceId = MapRasterSourceCatalog.osmStandard.id;
      if (segments.length >= 5 && segments[0] == 'tiles') {
        sourceId = segments[1];
      }

      return CachedTileInfo(
        key: object.key,
        host: uri.host,
        sourceId: sourceId,
        zoom: zoom,
        x: x,
        y: y,
        length: object.length ?? 0,
      );
    }

    return null;
  }

  int _lonToTileX(double lon, int zoom, int maxIndex) {
    final n = 1 << zoom;
    final value = ((lon + 180.0) / 360.0 * n).floor();
    return value.clamp(0, maxIndex);
  }

  int _latToTileY(double lat, int zoom, int maxIndex) {
    final n = 1 << zoom;
    final rad = lat * math.pi / 180.0;
    final value =
        ((1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n)
            .floor();
    return value.clamp(0, maxIndex);
  }

  double _clampLatitude(double lat) {
    const maxLat = 85.05112878;
    return lat.clamp(-maxLat, maxLat);
  }

  LatLngBounds _tileBoundsForTile(int x, int y, int zoom) {
    return LatLngBounds.unsafe(
      north: _tileYToLat(y, zoom),
      south: _tileYToLat(y + 1, zoom),
      east: _tileXToLon(x + 1, zoom),
      west: _tileXToLon(x, zoom),
    );
  }

  double _tileXToLon(int x, int zoom) {
    final n = 1 << zoom;
    return x / n * 360.0 - 180.0;
  }

  double _tileYToLat(int y, int zoom) {
    final n = math.pi - (2.0 * math.pi * y) / (1 << zoom);
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  bool _boundsIntersect(LatLngBounds a, LatLngBounds b) {
    return a.west <= b.east &&
        a.east >= b.west &&
        a.south <= b.north &&
        a.north >= b.south;
  }

  String _buildTileUrl(int x, int y, int zoom, {required String urlTemplate}) {
    return urlTemplate
        .replaceAll('{z}', zoom.toString())
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString());
  }
}

class CachedNetworkTileProvider extends TileProvider {
  final BaseCacheManager cacheManager;

  CachedNetworkTileProvider({required this.cacheManager, super.headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedNetworkImageProvider(
      url,
      cacheManager: cacheManager,
      headers: headers,
    );
  }
}

class _TileBounds {
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  const _TileBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}
