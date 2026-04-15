import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../services/map_tile_cache_service.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../helpers/snack_bar_builder.dart';

class MapCacheScreen extends StatefulWidget {
  const MapCacheScreen({super.key});

  @override
  State<MapCacheScreen> createState() => _MapCacheScreenState();
}

class _MapCacheScreenState extends State<MapCacheScreen> {
  final MapController _mapController = MapController();

  LatLngBounds? _selectedBounds;
  int _minZoom = MapTileCacheService.defaultMinZoom;
  int _maxZoom = MapTileCacheService.defaultMaxZoom;
  int _estimatedTiles = 0;
  bool _isDownloading = false;
  int _completedTiles = 0;
  int _failedTiles = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSettings();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final settings = context.read<AppSettingsService>().settings;
    final bounds = MapTileCacheService.boundsFromJson(settings.mapCacheBounds);
    final minZoom = settings.mapCacheMinZoom.clamp(3, 18);
    final maxZoom = settings.mapCacheMaxZoom.clamp(3, 18);
    final safeMin = minZoom <= maxZoom ? minZoom : maxZoom;
    final safeMax = minZoom <= maxZoom ? maxZoom : minZoom;
    setState(() {
      _minZoom = safeMin;
      _maxZoom = safeMax;
      _selectedBounds = bounds;
    });
    _updateEstimate();
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    }
  }

  void _updateEstimate() {
    if (_selectedBounds == null) {
      setState(() {
        _estimatedTiles = 0;
      });
      return;
    }
    final cacheService = context.read<MapTileCacheService>();
    final count = cacheService.estimateTileCount(
      _selectedBounds!,
      _minZoom,
      _maxZoom,
    );
    setState(() {
      _estimatedTiles = count;
    });
  }

  Future<void> _setBoundsFromView() async {
    final bounds = _mapController.camera.visibleBounds;
    await _saveBounds(bounds);
  }

  Future<void> _saveBounds(LatLngBounds bounds) async {
    setState(() {
      _selectedBounds = bounds;
    });
    final settings = context.read<AppSettingsService>();
    await settings.setMapCacheBounds(MapTileCacheService.boundsToJson(bounds));
    _updateEstimate();
  }

  Future<void> _clearBounds() async {
    setState(() {
      _selectedBounds = null;
      _estimatedTiles = 0;
    });
    final settings = context.read<AppSettingsService>();
    await settings.setMapCacheBounds(null);
  }

  Future<void> _saveZoomRange() async {
    final settings = context.read<AppSettingsService>();
    await settings.setMapCacheZoomRange(_minZoom, _maxZoom);
    _updateEstimate();
  }

  Future<void> _startDownload() async {
    final bounds = _selectedBounds;
    if (bounds == null) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.mapCache_selectAreaFirst),
      );
      return;
    }

    if (_estimatedTiles == 0) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.mapCache_noTilesToDownload),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.mapCache_downloadTilesTitle),
        content: Text(
          context.l10n.mapCache_downloadTilesPrompt(_estimatedTiles),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.mapCache_downloadAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cacheService = context.read<MapTileCacheService>();

    setState(() {
      _isDownloading = true;
      _completedTiles = 0;
      _failedTiles = 0;
    });

    final result = await cacheService.downloadRegion(
      bounds: bounds,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _completedTiles = progress.completed;
          _failedTiles = progress.failed;
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
      _completedTiles = result.downloaded + result.failed;
      _failedTiles = result.failed;
    });

    final message = result.failed > 0
        ? context.l10n.mapCache_cachedTilesWithFailed(
            result.downloaded,
            result.failed,
          )
        : context.l10n.mapCache_cachedTiles(result.downloaded);
    showDismissibleSnackBar(context, content: Text(message));
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.mapCache_clearOfflineCacheTitle),
        content: Text(context.l10n.mapCache_clearOfflineCachePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.common_clear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final cacheService = context.read<MapTileCacheService>();
    await cacheService.clearCache();
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.mapCache_offlineCacheCleared),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileCache = context.read<MapTileCacheService>();
    final selectedBounds = _selectedBounds;
    final l10n = context.l10n;
    final progressValue = _estimatedTiles == 0
        ? 0.0
        : (_completedTiles / _estimatedTiles).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.mapCache_title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(0, 0),
                    initialZoom: 2.0,
                    minZoom: 2.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: kMapTileUrlTemplate,
                      tileProvider: tileCache.tileProvider,
                      userAgentPackageName:
                          MapTileCacheService.userAgentPackageName,
                      maxZoom: 19,
                    ),
                    if (selectedBounds != null)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _boundsToPolygon(selectedBounds),
                            borderStrokeWidth: 2,
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderColor: Colors.blue,
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        selectedBounds == null
                            ? l10n.mapCache_noAreaSelected
                            : _formatBounds(selectedBounds, l10n),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.mapCache_cacheArea,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.crop_free),
                          label: Text(l10n.mapCache_useCurrentView),
                          onPressed: _isDownloading ? null : _setBoundsFromView,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _isDownloading || selectedBounds == null
                            ? null
                            : _clearBounds,
                        child: Text(l10n.common_clear),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.mapCache_zoomRange,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  RangeSlider(
                    values: RangeValues(
                      _minZoom.toDouble(),
                      _maxZoom.toDouble(),
                    ),
                    min: 3,
                    max: 18,
                    divisions: 15,
                    labels: RangeLabels('$_minZoom', '$_maxZoom'),
                    onChanged: _isDownloading
                        ? null
                        : (values) {
                            setState(() {
                              _minZoom = values.start.round();
                              _maxZoom = values.end.round();
                            });
                          },
                    onChangeEnd: _isDownloading
                        ? null
                        : (_) {
                            _saveZoomRange();
                          },
                  ),
                  Text(l10n.mapCache_estimatedTiles(_estimatedTiles)),
                  if (_isDownloading) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progressValue),
                    const SizedBox(height: 4),
                    Text(
                      l10n.mapCache_downloadedTiles(
                        _completedTiles,
                        _estimatedTiles,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: Text(l10n.mapCache_downloadTilesButton),
                          onPressed: _isDownloading || selectedBounds == null
                              ? null
                              : _startDownload,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isDownloading ? null : _clearCache,
                        child: Text(l10n.mapCache_clearCacheButton),
                      ),
                    ],
                  ),
                  if (_failedTiles > 0 && !_isDownloading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.mapCache_failedDownloads(_failedTiles),
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LatLng> _boundsToPolygon(LatLngBounds bounds) {
    return [
      bounds.northWest,
      bounds.northEast,
      bounds.southEast,
      bounds.southWest,
    ];
  }

  String _formatBounds(LatLngBounds bounds, AppLocalizations l10n) {
    return l10n.mapCache_boundsLabel(
      bounds.north.toStringAsFixed(4),
      bounds.south.toStringAsFixed(4),
      bounds.east.toStringAsFixed(4),
      bounds.west.toStringAsFixed(4),
    );
  }
}
