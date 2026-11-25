import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../screens/channels_screen.dart';
import '../screens/contacts_screen.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/coverage_service.dart';
import '../services/line_of_sight_service.dart';
import '../services/map_tile_cache_service.dart';
import '../utils/route_transitions.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../widgets/app_bar.dart';
import '../widgets/mesh_ui.dart';
import '../widgets/path_map_scaffold.dart';
import '../widgets/quick_switch_bar.dart';
import '../theme/mesh_theme.dart';

class CoverageEndpoint {
  final String label;
  final LatLng point;
  final Color color;
  final IconData icon;
  final double antennaHeightMeters;
  final bool enabled;

  const CoverageEndpoint({
    required this.label,
    required this.point,
    this.color = LosPalette.selected,
    this.icon = Icons.push_pin,
    this.antennaHeightMeters = 10.0,
    this.enabled = true,
  });

  CoverageEndpoint copyWith({
    String? label,
    double? antennaHeightMeters,
    bool? enabled,
  }) {
    return CoverageEndpoint(
      label: label ?? this.label,
      point: point,
      color: color,
      icon: icon,
      antennaHeightMeters: antennaHeightMeters ?? this.antennaHeightMeters,
      enabled: enabled ?? this.enabled,
    );
  }
}

class _CoveragePoint {
  _CoveragePoint(this.endpoint);

  CoverageEndpoint endpoint;
  CoverageResult? result;
  double? resultAntennaHeightMeters;

  bool get isStale =>
      result != null &&
      resultAntennaHeightMeters != endpoint.antennaHeightMeters;
}

class CoverageMapScreen extends StatefulWidget {
  final String title;

  const CoverageMapScreen({super.key, required this.title});

  @override
  State<CoverageMapScreen> createState() => _CoverageMapScreenState();
}

class _CoverageMapScreenState extends State<CoverageMapScreen> {
  static const double _metersToFeet = 3.28084;
  static const double _kmToMiles = 0.621371;
  static const double _maxAntennaFeet = 400.0;
  static const double _maxAntennaMeters = _maxAntennaFeet / _metersToFeet;
  static const double _labelZoomThreshold = kPathMapLabelZoomThreshold;
  static const Duration _antennaRerunDebounce = Duration(milliseconds: 400);

  final CoverageService _coverageService = CoverageService();
  final MapController _mapController = MapController();
  final DraggableScrollableController _panelController =
      DraggableScrollableController();

  final List<_CoveragePoint> _points = [];
  int _loadingCount = 0;
  String? _error;
  // True when the last failure looks like missing connectivity.
  bool _networkError = false;
  bool _showHud = true;
  bool _showMarkerLabels = true;
  bool _didReceivePositionUpdate = false;
  bool _showTerrainLayer = true;
  bool _showRepeaters = true;
  Timer? _antennaRerunTimer;

  @override
  void dispose() {
    _antennaRerunTimer?.cancel();
    _mapController.dispose();
    _panelController.dispose();
    _coverageService.dispose();
    super.dispose();
  }

  int get _enabledCount => _points.where((p) => p.endpoint.enabled).length;

  bool get _loading => _loadingCount > 0;

  Future<void> _computePoint(_CoveragePoint point) async {
    if (!point.endpoint.enabled) return;
    setState(() => _loadingCount++);
    try {
      final connector = context.read<MeshCoreConnector>();
      final frequencyMHz = _normalizeFrequencyMHz(connector.currentFreqHz);
      final result = await _coverageService.computeCoverage(
        point.endpoint.point,
        antennaHeightMeters: point.endpoint.antennaHeightMeters,
        frequencyMHz: frequencyMHz,
      );
      if (!mounted || !_points.contains(point)) return;
      setState(() {
        point.result = result;
        point.resultAntennaHeightMeters = point.endpoint.antennaHeightMeters;
        if (result.hasData) {
          _error = null;
          _networkError = false;
        } else {
          _error = context.l10n.losNoElevationData;
        }
      });
    } catch (e) {
      if (!mounted) return;
      final isNetwork = _isNetworkError(e);
      setState(() {
        _networkError = isNetwork;
        _error = isNetwork
            ? context.l10n.losErrorNoInternet
            : context.l10n.coverageRunFailed(e.toString());
      });
    } finally {
      if (mounted) setState(() => _loadingCount--);
    }
  }

  static bool _isNetworkError(Object error) {
    if (error is http.ClientException || error is TimeoutException) {
      return true;
    }
    // SocketException lives in dart:io, which is unavailable on web.
    final text = '${error.runtimeType} $error';
    return text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Network is unreachable');
  }

  void _togglePoint(_CoveragePoint point, bool enabled) {
    setState(() {
      point.endpoint = point.endpoint.copyWith(enabled: enabled);
      if (!enabled) {
        _error = null;
        _networkError = false;
      }
    });
    if (enabled && (point.result == null || point.isStale)) {
      _computePoint(point);
    }
  }

  void _addCustomPoint(LatLng mapPoint) {
    final point = _CoveragePoint(
      CoverageEndpoint(
        label: context.l10n.coverageCustomPointLabel(_points.length + 1),
        point: mapPoint,
      ),
    );
    setState(() {
      _points.add(point);
      _error = null;
    });
    _computePoint(point);
  }

  void _deletePoint(_CoveragePoint point) {
    setState(() {
      _points.remove(point);
      _error = null;
    });
  }

  void _clearAllPoints() {
    setState(() {
      _points.clear();
      _error = null;
    });
  }

  void _onAntennaChanged(_CoveragePoint point, double meters) {
    _antennaRerunTimer?.cancel();
    setState(() {
      point.endpoint = point.endpoint.copyWith(antennaHeightMeters: meters);
    });
    _scheduleAntennaRerun(point);
  }

  /// Antenna changes don't invalidate a run: its result is kept (marked
  /// stale) and a follow-up run is scheduled when the slider is released.
  void _scheduleAntennaRerun(_CoveragePoint point) {
    _antennaRerunTimer?.cancel();
    if (!point.endpoint.enabled || !point.isStale) return;
    _antennaRerunTimer = Timer(_antennaRerunDebounce, () {
      if (mounted && point.isStale) _computePoint(point);
    });
  }

  Future<void> _renamePoint(_CoveragePoint point) async {
    final newLabel = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _RenamePointDialog(initialLabel: point.endpoint.label),
    );

    if (newLabel == null || newLabel.isEmpty) return;
    if (!_points.contains(point)) return;
    setState(() {
      point.endpoint = point.endpoint.copyWith(label: newLabel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsService>().settings;
    final isImperial = settings.unitSystem == UnitSystem.imperial;
    final tileCache = context.watch<MapTileCacheService>();
    final mapPoints = [for (final p in _points) p.endpoint.point];
    final initialCenter = mapPoints.isNotEmpty
        ? mapPoints.first
        : const LatLng(0, 0);
    final bounds = mapPoints.length > 1
        ? LatLngBounds.fromPoints(mapPoints)
        : null;
    final initialZoom = mapPoints.length > 1
        ? 13.0
        : (mapPoints.length == 1 ? 11.0 : 2.0);
    if (!_didReceivePositionUpdate) {
      _showMarkerLabels = initialZoom >= _labelZoomThreshold;
    }

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(widget.title),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _clearAllPoints();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                enabled: _points.isNotEmpty,
                child: MeshMenuItemRow(
                  icon: Icons.delete_outline,
                  label: context.l10n.losClearAllPoints,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: buildPathMapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              bounds: bounds,
              onLongPress: (_, point) => _addCustomPoint(point),
              onSecondaryTap: (_, point) => _addCustomPoint(point),
              onPositionChanged: (camera, hasGesture) {
                final shouldShow = camera.zoom >= _labelZoomThreshold;
                if (!_didReceivePositionUpdate ||
                    shouldShow != _showMarkerLabels) {
                  setState(() {
                    _didReceivePositionUpdate = true;
                    _showMarkerLabels = shouldShow;
                  });
                }
              },
            ),
            children: [
              tileCache.buildTileLayer(
                context,
                opacity: _showTerrainLayer ? 1 : 0.72,
              ),
              PolygonLayer(polygons: _buildCoveragePolygons()),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          _buildStatusBanner(isImperial),
          _buildMapControlRail(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            bounds: bounds,
            isImperial: isImperial,
          ),
          if (_showHud)
            DraggableScrollableSheet(
              controller: _panelController,
              initialChildSize: 0.43,
              minChildSize: 0.14,
              maxChildSize: 0.88,
              snap: true,
              snapSizes: const [0.14, 0.43, 0.88],
              builder: (context, scrollController) => Theme(
                data: MeshTheme.dark(),
                child: _buildControlPanel(isImperial, scrollController),
              ),
            ),
          if (_loading)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                color: LosPalette.selected,
                backgroundColor: LosPalette.chartBackground,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: QuickSwitchBar(
          selectedIndex: 2,
          onDestinationSelected: (index) => _handleQuickSwitch(index, context),
          contactsUnreadCount: context
              .watch<MeshCoreConnector>()
              .getTotalContactsUnreadCount(),
          channelsUnreadCount: context
              .watch<MeshCoreConnector>()
              .getTotalChannelsUnreadCount(),
          highContrast: true,
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isImperial) {
    final connector = context.watch<MeshCoreConnector>();
    final battery = connector.batteryPercent;
    final snr = connector.latestRadioStats?.lastSnrDb;
    return Positioned(
      top: 10,
      left: 12,
      right: 12,
      child: Material(
        color: LosPalette.panelDark,
        borderRadius: BorderRadius.circular(MeshRadii.md),
        shadowColor: LosPalette.shadow,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: LosPalette.clear.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: LosPalette.clear),
                ),
                child: const Icon(
                  Icons.wifi_tethering,
                  color: LosPalette.clear,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusText(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LosPalette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_networkError && !_loading) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _retryFailedPoints,
                  style: TextButton.styleFrom(
                    foregroundColor: LosPalette.selected,
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(context.l10n.common_retry),
                ),
              ],
              _headerMetric(
                Icons.battery_5_bar,
                battery == null ? '--' : '$battery%',
              ),
              const SizedBox(width: 10),
              _headerMetric(
                Icons.network_cell,
                snr == null
                    ? '--'
                    : context.l10n.losSnrValue(snr.toStringAsFixed(1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retryFailedPoints() {
    for (final point in _points) {
      if (point.endpoint.enabled && point.result == null) {
        _computePoint(point);
      }
    }
  }

  String _statusText() {
    if (_loading) return context.l10n.coverageComputing;
    if (_error != null) return _error!;
    if (_enabledCount > 0) return context.l10n.coverageSummary(_enabledCount);
    return context.l10n.coverageAddHint;
  }

  Widget _headerMetric(IconData icon, String value) {
    // Capped so very large text scales shrink the reading instead of pushing
    // the panel off a narrow screen.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 80),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: LosPalette.textMuted, size: 16),
            const SizedBox(height: 2),
            Text(
              value,
              style: MeshTheme.mono(
                color: LosPalette.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControlRail({
    required LatLng initialCenter,
    required double initialZoom,
    required LatLngBounds? bounds,
    required bool isImperial,
  }) {
    return Positioned(
      right: 12,
      top: 92,
      child: Material(
        color: LosPalette.panelDark,
        borderRadius: BorderRadius.circular(MeshRadii.md),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shadowColor: LosPalette.shadow,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              color: LosPalette.text,
              icon: const Icon(Icons.add),
              tooltip: context.l10n.map_zoomIn,
              onPressed: () => zoomMapBy(_mapController, 1),
            ),
            IconButton(
              color: LosPalette.text,
              icon: const Icon(Icons.remove),
              tooltip: context.l10n.map_zoomOut,
              onPressed: () => zoomMapBy(_mapController, -1),
            ),
            IconButton(
              color: LosPalette.text,
              icon: const Icon(Icons.center_focus_strong),
              tooltip: context.l10n.map_centerMap,
              onPressed: () => resetMapView(
                _mapController,
                bounds: bounds,
                center: initialCenter,
                zoom: initialZoom,
              ),
            ),
            IconButton(
              color: _showTerrainLayer
                  ? LosPalette.selected
                  : LosPalette.textMuted,
              icon: const Icon(Icons.layers_outlined),
              tooltip: context.l10n.losMapDetailTooltip,
              onPressed: () =>
                  setState(() => _showTerrainLayer = !_showTerrainLayer),
            ),
            IconButton(
              color: _showRepeaters
                  ? MapPalette.repeater
                  : LosPalette.textMuted,
              icon: const Icon(Icons.cell_tower),
              tooltip: _showRepeaters
                  ? context.l10n.coverageHideRepeaters
                  : context.l10n.coverageShowRepeaters,
              onPressed: () => setState(() => _showRepeaters = !_showRepeaters),
            ),
            IconButton(
              color: LosPalette.text,
              icon: Text(
                _heightUnit(isImperial),
                style: const TextStyle(
                  color: LosPalette.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              tooltip: context.l10n.losUnitsTooltip,
              onPressed: () => context.read<AppSettingsService>().setUnitSystem(
                isImperial ? UnitSystem.metric : UnitSystem.imperial,
              ),
            ),
            IconButton(
              color: _showHud ? LosPalette.selected : LosPalette.text,
              icon: Icon(
                _showHud ? Icons.keyboard_arrow_down : Icons.analytics_outlined,
              ),
              tooltip: _showHud
                  ? context.l10n.coverageHidePanelTooltip
                  : context.l10n.coverageShowPanelTooltip,
              onPressed: () => setState(() => _showHud = !_showHud),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(
    bool isImperial,
    ScrollController scrollController,
  ) {
    final connector = context.read<MeshCoreConnector>();
    final frequencyMHz = _normalizeFrequencyMHz(connector.currentFreqHz);
    return Material(
      color: LosPalette.panelDark,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(MeshRadii.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: LosPalette.textMuted.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _CoverageLegend(
            excellentLabel: context.l10n.coverageLegendExcellent,
            goodLabel: context.l10n.coverageLegendGood,
            marginalLabel: context.l10n.coverageLegendMarginal,
            noneLabel: context.l10n.coverageLegendNone,
          ),
          const SizedBox(height: 10),
          for (final point in _points) _buildPointControls(point, isImperial),
          if (frequencyMHz != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${context.l10n.losFrequencyLabel}: '
                    '${context.l10n.losFrequencyValue(frequencyMHz.toStringAsFixed(3))}'
                    '  ${context.l10n.losKFactorValue(LineOfSightService.kFactorForFrequency(frequencyMHz).toStringAsFixed(3))}',
                    style: const TextStyle(
                      color: LosPalette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 17),
                  color: LosPalette.textMuted,
                  tooltip: context.l10n.losFrequencyInfoTooltip,
                  onPressed: () =>
                      _showFrequencyInfoDialog(context, frequencyMHz),
                ),
              ],
            ),
          ],
          Text(
            context.l10n.losElevationAttribution,
            style: const TextStyle(color: LosPalette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPointControls(_CoveragePoint point, bool isImperial) {
    final endpoint = point.endpoint;
    final result = point.result;
    final heightUnit = _heightUnit(isImperial);
    final antennaDisplay = _toDisplayHeight(
      endpoint.antennaHeightMeters,
      isImperial,
    );
    final antennaSliderMax = isImperial ? _maxAntennaFeet : _maxAntennaMeters;
    final antennaSliderDivisions = isImperial ? 400 : 122;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: endpoint.enabled,
                activeColor: LosPalette.clear,
                onChanged: (value) => _togglePoint(point, value ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endpoint.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LosPalette.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _pointSubtitle(point, result, isImperial),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LosPalette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _renamePoint(point),
                tooltip: context.l10n.common_edit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deletePoint(point),
                tooltip: context.l10n.common_delete,
              ),
            ],
          ),
          Text(
            context.l10n.coverageAntenna(
              antennaDisplay.toStringAsFixed(1),
              heightUnit,
            ),
            style: const TextStyle(fontSize: 12),
          ),
          Slider(
            value: antennaDisplay,
            min: 0,
            max: antennaSliderMax,
            divisions: antennaSliderDivisions,
            onChanged: (value) =>
                _onAntennaChanged(point, _toMetersHeight(value, isImperial)),
            onChangeEnd: (_) => _scheduleAntennaRerun(point),
          ),
        ],
      ),
    );
  }

  String _pointSubtitle(
    _CoveragePoint point,
    CoverageResult? result,
    bool isImperial,
  ) {
    final coords =
        '${point.endpoint.point.latitude.toStringAsFixed(5)}, '
        '${point.endpoint.point.longitude.toStringAsFixed(5)}';
    if (result == null) return coords;
    return '$coords • '
        '${context.l10n.coverageHorizon(_formatDistanceValue(result.horizonMeters, isImperial), _distanceUnit(isImperial))}';
  }

  List<Polygon> _buildCoveragePolygons() {
    final polygons = <Polygon>[];
    for (final point in _points) {
      final result = point.result;
      if (result == null || !point.endpoint.enabled) continue;
      for (final ring in result.rings) {
        final color = _levelColor(ring.level);
        polygons.add(
          Polygon(
            points: ring.points,
            color: color.withValues(alpha: _levelAlpha(ring.level)),
            borderStrokeWidth: 1,
            borderColor: color.withValues(alpha: 0.85),
          ),
        );
      }
    }
    return polygons;
  }

  static Color _levelColor(CoverageLevel level) {
    switch (level) {
      case CoverageLevel.excellent:
        return LosPalette.clear;
      case CoverageLevel.good:
        return LosPalette.horizon;
      case CoverageLevel.marginal:
        return LosPalette.marginal;
    }
  }

  static double _levelAlpha(CoverageLevel level) {
    switch (level) {
      case CoverageLevel.excellent:
        return 0.38;
      case CoverageLevel.good:
        return 0.30;
      case CoverageLevel.marginal:
        return 0.22;
    }
  }

  List<Marker> _buildMarkers() {
    return [
      if (_showRepeaters)
        for (final repeater in context.read<MeshCoreConnector>().contacts.where(
          (c) => c.type == advTypeRepeater && c.hasLocation,
        ))
          Marker(
            point: LatLng(repeater.latitude!, repeater.longitude!),
            width: 36,
            height: 36,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LosPalette.panelDark.withValues(alpha: 0.85),
                    border: Border.all(color: MapPalette.repeater),
                  ),
                  child: const Icon(
                    Icons.cell_tower,
                    color: MapPalette.repeater,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
      for (final point in _points)
        Marker(
          point: point.endpoint.point,
          width: 48,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _togglePoint(point, !point.endpoint.enabled),
            child: Center(child: _buildPointMarker(point)),
          ),
        ),
      for (final point in _points)
        if (_showMarkerLabels)
          Marker(
            point: point.endpoint.point,
            width: 120,
            height: 24,
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: LosPalette.panelDark,
                      borderRadius: BorderRadius.circular(MeshRadii.xs),
                      border: Border.all(color: LosPalette.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      point.endpoint.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MeshTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LosPalette.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    ];
  }

  Widget _buildPointMarker(_CoveragePoint point) {
    final endpoint = point.endpoint;
    final enabled = endpoint.enabled;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? endpoint.color : LosPalette.panelDark,
        border: Border.all(
          color: enabled
              ? MapPalette.markerOutline
              : endpoint.color.withValues(alpha: 0.75),
          width: enabled ? 2.5 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: LosPalette.shadow,
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        endpoint.icon,
        color: enabled ? LosPalette.text : endpoint.color,
        size: 20,
      ),
    );
  }

  String _distanceUnit(bool isImperial) =>
      isImperial ? context.l10n.units_mi : context.l10n.units_km;

  String _heightUnit(bool isImperial) =>
      isImperial ? context.l10n.units_ft : context.l10n.units_m;

  String _formatDistanceValue(double meters, bool isImperial) {
    final value = isImperial ? (meters / 1000.0) * _kmToMiles : meters / 1000.0;
    return value.toStringAsFixed(2);
  }

  double _toDisplayHeight(double meters, bool isImperial) {
    return isImperial ? meters * _metersToFeet : meters;
  }

  double _toMetersHeight(double displayHeight, bool isImperial) {
    return isImperial ? displayHeight / _metersToFeet : displayHeight;
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == 2) {
      Navigator.pop(context);
      return;
    }
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const ContactsScreen(hideBackButton: true)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const ChannelsScreen(hideBackButton: true)),
        );
        break;
    }
  }

  void _showFrequencyInfoDialog(BuildContext context, double frequencyMHz) {
    final baselineFreq = LineOfSightService.baselineFrequencyMHz;
    final baselineK = LineOfSightService.baselineKFactor;
    final kFactor = LineOfSightService.kFactorForFrequency(frequencyMHz);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.losFrequencyDialogTitle),
        content: Text(
          context.l10n.losFrequencyDialogDescription(
            baselineK,
            baselineFreq,
            frequencyMHz,
            kFactor,
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
  }

  double? _normalizeFrequencyMHz(int? frequencyKHz) {
    if (frequencyKHz == null || frequencyKHz <= 0) return null;
    return frequencyKHz / 1000.0;
  }
}

class _CoverageLegend extends StatelessWidget {
  final String excellentLabel;
  final String goodLabel;
  final String marginalLabel;
  final String noneLabel;

  const _CoverageLegend({
    required this.excellentLabel,
    required this.goodLabel,
    required this.marginalLabel,
    required this.noneLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(
          color: LosPalette.text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          color: LosPalette.text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        );

    final entries = [
      (excellentLabel, LosPalette.clear),
      (goodLabel, LosPalette.horizon),
      (marginalLabel, LosPalette.marginal),
      (noneLabel, LosPalette.textMuted),
    ];

    const swatchSize = 12.0;

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: entries
          .map(
            (entry) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: swatchSize,
                  height: swatchSize,
                  decoration: BoxDecoration(
                    color: entry.$2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(entry.$1, style: textStyle),
              ],
            ),
          )
          .toList(),
    );
  }
}

/// Rename dialog that owns (and disposes) its text controller.
class _RenamePointDialog extends StatefulWidget {
  final String initialLabel;

  const _RenamePointDialog({required this.initialLabel});

  @override
  State<_RenamePointDialog> createState() => _RenamePointDialogState();
}

class _RenamePointDialogState extends State<_RenamePointDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialLabel,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.losRenameCustomPoint),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: context.l10n.losPointName,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(context.l10n.common_save),
        ),
      ],
    );
  }
}
