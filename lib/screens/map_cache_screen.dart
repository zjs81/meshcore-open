import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../theme/mesh_theme.dart';
import '../widgets/mesh_ui.dart';

class MapCacheScreen extends StatefulWidget {
  const MapCacheScreen({super.key});

  @override
  State<MapCacheScreen> createState() => _MapCacheScreenState();
}

class _MapCacheScreenState extends State<MapCacheScreen> {
  static const double _mapMinZoom = 2.0;
  static const double _mapMaxZoom = 18.0;

  final MapController _mapController = MapController();

  LatLngBounds? _selectedBounds;
  int _minZoom = MapTileCacheService.defaultMinZoom;
  int _maxZoom = MapTileCacheService.defaultMaxZoom;
  int _estimatedTiles = 0;
  bool _isDownloading = false;
  int _completedTiles = 0;
  int _failedTiles = 0;
  List<CachedTileInfo> _cachedTiles = const [];
  int _cachedTileBytes = 0;
  bool _isLoadingCachedTiles = false;
  double _overlayZoom = 2.0;
  LatLngBounds? _visibleBounds;
  MapTileDownloadCancelToken? _cancelToken;
  // Pending camera update for the cached-tile overlay; applied after the
  // camera settles instead of on every pan frame.
  Timer? _positionDebounce;
  MapCamera? _pendingCamera;

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
    _positionDebounce?.cancel();
    _cancelToken?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  bool get _useDarkOverlay => Theme.of(context).brightness == Brightness.dark;

  Color get _overlayPanelColor => _useDarkOverlay
      ? MapPalette.panelDark
      : Theme.of(
          context,
        ).colorScheme.surfaceContainerLow.withValues(alpha: 0.96);

  Color get _overlayBorderColor => _useDarkOverlay
      ? MapPalette.border
      : Theme.of(context).colorScheme.outlineVariant;

  Color get _overlayPrimaryTextColor => _useDarkOverlay
      ? MapPalette.textPrimary
      : Theme.of(context).colorScheme.onSurface;

  Color get _overlaySecondaryTextColor => _useDarkOverlay
      ? MapPalette.textSecondary
      : Theme.of(context).colorScheme.onSurfaceVariant;

  BoxDecoration get _overlayDecoration => BoxDecoration(
    color: _overlayPanelColor,
    borderRadius: BorderRadius.circular(MeshRadii.md),
    border: Border.all(color: _overlayBorderColor),
  );

  void _onCameraChanged(MapCamera camera) {
    _pendingCamera = camera;
    if (_positionDebounce?.isActive ?? false) return;
    _positionDebounce = Timer(const Duration(milliseconds: 150), () {
      final next = _pendingCamera;
      if (!mounted || next == null) return;
      final nextZoom = next.zoom;
      final nextBounds = next.visibleBounds;
      if (_overlayZoom != nextZoom ||
          _visibleBounds?.north != nextBounds.north ||
          _visibleBounds?.south != nextBounds.south ||
          _visibleBounds?.east != nextBounds.east ||
          _visibleBounds?.west != nextBounds.west) {
        setState(() {
          _overlayZoom = nextZoom;
          _visibleBounds = nextBounds;
        });
      }
    });
  }

  bool _isDesktopPlatform(TargetPlatform platform) {
    return platform == TargetPlatform.linux ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS;
  }

  void _zoomMapBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta)
        .clamp(_mapMinZoom, _mapMaxZoom)
        .toDouble();
    _mapController.move(camera.center, nextZoom);
  }

  void _resetMapView() {
    final bounds = _selectedBounds;
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
      return;
    }
    _mapController.move(const LatLng(0, 0), 2.0);
  }

  Widget _buildDesktopMapControls() {
    return Positioned(
      top: 12,
      left: 12,
      child: DecoratedBox(
        decoration: _overlayDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MeshRadii.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                color: _overlayPrimaryTextColor,
                tooltip: context.l10n.map_zoomIn,
                onPressed: () => _zoomMapBy(1),
              ),
              IconButton(
                icon: const Icon(Icons.remove),
                color: _overlayPrimaryTextColor,
                tooltip: context.l10n.map_zoomOut,
                onPressed: () => _zoomMapBy(-1),
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                color: _overlayPrimaryTextColor,
                tooltip: context.l10n.map_centerMap,
                onPressed: _resetMapView,
              ),
            ],
          ),
        ),
      ),
    );
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
      _visibleBounds = bounds;
    });
    _updateEstimate();
    _refreshCachedTiles();
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    }
  }

  void _updateEstimate() {
    if (!mounted) return;
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
    final cacheService = context.read<MapTileCacheService>();
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

    if (!cacheService.source.allowsBulkDownload) {
      showDismissibleSnackBar(
        context,
        content: Text(
          context.l10n.mapCache_bulkDownloadDisabledInConfig(
            cacheService.source.label,
          ),
        ),
      );
      return;
    }

    if (_estimatedTiles > MapTileCacheService.maxBulkDownloadTiles) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.mapCache_tooManyTilesTitle),
          content: Text(
            context.l10n.mapCache_tooManyTiles(
              _estimatedTiles,
              MapTileCacheService.maxBulkDownloadTiles,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.common_ok),
            ),
          ],
        ),
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

    final cancelToken = MapTileDownloadCancelToken();
    setState(() {
      _isDownloading = true;
      _completedTiles = 0;
      _failedTiles = 0;
      _cancelToken = cancelToken;
    });

    final result = await cacheService.downloadRegion(
      bounds: bounds,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      cancelToken: cancelToken,
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
      _cancelToken = null;
      _completedTiles = result.downloaded + result.failed;
      _failedTiles = result.failed;
    });

    final message = result.cancelled
        ? context.l10n.mapCache_downloadCancelled(result.downloaded)
        : result.failed > 0
        ? context.l10n.mapCache_cachedTilesWithFailed(
            result.downloaded,
            result.failed,
          )
        : context.l10n.mapCache_cachedTiles(result.downloaded);
    await _refreshCachedTiles();
    if (!mounted) return;
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
    await _refreshCachedTiles();
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.mapCache_offlineCacheCleared),
    );
  }

  Future<void> _refreshCachedTiles() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCachedTiles = true;
    });
    final cacheService = context.read<MapTileCacheService>();
    final inventory = await cacheService.getCachedTileInventory();
    if (!mounted) return;
    setState(() {
      _cachedTiles = inventory.tiles;
      _cachedTileBytes = inventory.totalBytes;
      _isLoadingCachedTiles = false;
    });
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {});
  }

  String _formatBytes(int bytes, AppLocalizations l10n) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes < kb) return l10n.mapCache_sizeBytes('$bytes');
    if (bytes < mb) {
      return l10n.mapCache_sizeKilobytes((bytes / kb).toStringAsFixed(1));
    }
    if (bytes < gb) {
      return l10n.mapCache_sizeMegabytes((bytes / mb).toStringAsFixed(1));
    }
    return l10n.mapCache_sizeGigabytes((bytes / gb).toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final tileCache = context.watch<MapTileCacheService>();
    final source = tileCache.source;
    final selectedBounds = _selectedBounds;
    final activeCachedTiles = tileCache.filterTilesForActiveSource(
      _cachedTiles,
    );
    final cachedInSelection = tileCache.countTilesForBounds(
      activeCachedTiles,
      bounds: selectedBounds,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
    );
    final overlayPolygons = tileCache.buildCachedTilePolygons(
      activeCachedTiles,
      zoom: _overlayZoom.round().clamp(0, 19).toInt(),
      visibleBounds: _visibleBounds,
    );
    final cacheSummary =
        '${context.l10n.mapCache_summarySource(source.label)}\n'
        '${context.l10n.mapCache_summaryCachedTilesForSource(activeCachedTiles.length)}\n'
        '${context.l10n.mapCache_summaryCachedInSelection(cachedInSelection)}\n'
        '${context.l10n.mapCache_summaryApproxCacheSize(_formatBytes(_cachedTileBytes, context.l10n))}';
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDesktop = _isDesktopPlatform(defaultTargetPlatform);
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
                  options: MapOptions(
                    initialCenter: const LatLng(0, 0),
                    initialZoom: 2.0,
                    minZoom: _mapMinZoom,
                    maxZoom: _mapMaxZoom,
                    interactionOptions: InteractionOptions(
                      flags: ~InteractiveFlag.rotate,
                      scrollWheelVelocity: isDesktop ? 0.012 : 0.005,
                      cursorKeyboardRotationOptions:
                          CursorKeyboardRotationOptions.disabled(),
                      keyboardOptions: isDesktop
                          ? const KeyboardOptions(
                              enableArrowKeysPanning: true,
                              enableWASDPanning: true,
                              enableRFZooming: true,
                            )
                          : const KeyboardOptions.disabled(),
                    ),
                    onPositionChanged: (camera, hasGesture) =>
                        _onCameraChanged(camera),
                  ),
                  children: [
                    tileCache.buildTileLayer(context),
                    if (selectedBounds != null)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _boundsToPolygon(selectedBounds),
                            borderStrokeWidth: 2,
                            color: MapPalette.selected.withValues(alpha: 0.2),
                            borderColor: MapPalette.selected,
                          ),
                        ],
                      ),
                    if (overlayPolygons.isNotEmpty)
                      PolygonLayer(polygons: overlayPolygons),
                  ],
                ),
                if (isDesktop) _buildDesktopMapControls(),
                Positioned(
                  top: 12,
                  left: isDesktop ? 84 : 12,
                  child: DecoratedBox(
                    decoration: _overlayDecoration,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Text(
                        l10n.mapCache_zoomLevel(_overlayZoom.round()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _overlayPrimaryTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  left: isDesktop ? 200 : 130,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: DecoratedBox(
                      decoration: _overlayDecoration,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          selectedBounds == null
                              ? l10n.mapCache_noAreaSelected
                              : _formatBounds(selectedBounds, l10n),
                          style: MeshTheme.mono(
                            fontSize: 13,
                            color: _overlaySecondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              // Cap the panel so the map keeps room in landscape; the controls
              // scroll inside it.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SectionHeader(
                        l10n.mapCache_cacheArea,
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.crop_free),
                              label: Text(l10n.mapCache_useCurrentView),
                              onPressed: _isDownloading
                                  ? null
                                  : _setBoundsFromView,
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
                      SectionHeader(
                        l10n.mapCache_zoomRange,
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
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
                      Text(
                        l10n.mapCache_estimatedTiles(_estimatedTiles),
                        style: MeshTheme.mono(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_estimatedTiles >
                          MapTileCacheService.maxBulkDownloadTiles) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.mapCache_tooManyTiles(
                            _estimatedTiles,
                            MapTileCacheService.maxBulkDownloadTiles,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: MeshPalette.alert,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        _isLoadingCachedTiles
                            ? l10n.mapCache_cachedTilesLabel
                            : l10n.mapCache_cachedTileSummaryLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      MeshCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          child: SelectableText(
                            cacheSummary,
                            style: MeshTheme.mono(
                              fontSize: 13,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      if (!source.allowsBulkDownload) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.mapCache_bulkDownloadDisabledForSource(
                            source.label,
                          ),
                          style: MeshTheme.mono(
                            fontSize: 12,
                            color: MeshPalette.alert,
                          ),
                        ),
                      ],
                      if (_isDownloading) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progressValue,
                          color: MeshPalette.blue,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.mapCache_downloadedTiles(
                            _completedTiles,
                            _estimatedTiles,
                          ),
                          style: MeshTheme.mono(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _isDownloading
                                ? OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.stop_circle_outlined,
                                    ),
                                    label: Text(l10n.common_cancel),
                                    onPressed:
                                        (_cancelToken?.isCancelled ?? true)
                                        ? null
                                        : _cancelDownload,
                                  )
                                : ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: Text(
                                      l10n.mapCache_downloadTilesButton,
                                    ),
                                    onPressed:
                                        selectedBounds == null ||
                                            !source.allowsBulkDownload
                                        ? null
                                        : _startDownload,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Flexible lets the label wrap instead of pushing
                          // the row past the screen edge at large text sizes.
                          Flexible(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MeshPalette.alert,
                                side: const BorderSide(
                                  color: MeshPalette.alertLine,
                                ),
                              ),
                              onPressed: _isDownloading ? null : _clearCache,
                              child: Text(
                                l10n.mapCache_clearCacheButton,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_failedTiles > 0 && !_isDownloading)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.mapCache_failedDownloads(_failedTiles),
                            style: MeshTheme.mono(
                              fontSize: 12,
                              color: MeshPalette.alert,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
