import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../screens/channels_screen.dart';
import '../screens/contacts_screen.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/line_of_sight_service.dart';
import '../services/map_tile_cache_service.dart';
import '../utils/route_transitions.dart';
import '../connector/meshcore_connector.dart';
import '../widgets/app_bar.dart';
import '../widgets/quick_switch_bar.dart';
import '../icons/los_icon.dart';
import '../theme/mesh_theme.dart';

class LineOfSightEndpoint {
  final String label;
  final LatLng point;
  final Color color;
  final IconData icon;
  final bool isCustom;

  const LineOfSightEndpoint({
    required this.label,
    required this.point,
    this.color = LosPalette.clear,
    this.icon = Icons.location_on,
    this.isCustom = false,
  });
}

class LineOfSightMapScreen extends StatefulWidget {
  final String title;
  final List<LineOfSightEndpoint> candidates;

  const LineOfSightMapScreen({
    super.key,
    required this.title,
    required this.candidates,
  });

  @override
  State<LineOfSightMapScreen> createState() => _LineOfSightMapScreenState();
}

class _LineOfSightMapScreenState extends State<LineOfSightMapScreen> {
  static const String _errorSelectStartEnd = 'los_error_select_start_end';
  static const double _metersToFeet = 3.28084;
  static const double _kmToMiles = 0.621371;
  static const double _maxAntennaFeet = 400.0;
  static const double _maxAntennaMeters = _maxAntennaFeet / _metersToFeet;
  static const double _labelZoomThreshold = 8.5;
  static const double _mapMinZoom = 2.0;
  static const double _mapMaxZoom = 18.0;
  static const double _marginalClearanceMeters = 5.0;

  final LineOfSightService _lineOfSightService = LineOfSightService();
  final MapController _mapController = MapController();
  final DraggableScrollableController _panelController =
      DraggableScrollableController();

  bool _loading = false;
  String? _error;
  LineOfSightPathResult? _result;
  LineOfSightObstruction? _selectedObstruction;
  LineOfSightEndpoint? _start;
  LineOfSightEndpoint? _end;
  final List<LineOfSightEndpoint> _customEndpoints = [];
  double _startAntennaHeight = 5.0;
  double _endAntennaHeight = 5.0;
  bool _showHud = true;
  bool _menuExpanded = false;
  bool _showDisplayNodes = true;
  bool _showMarkerLabels = true;
  bool _didReceivePositionUpdate = false;
  int _losRequestNonce = 0;
  bool _initialLosScheduled = false;
  bool _showTerrainLayer = true;

  @override
  void initState() {
    super.initState();
    if (widget.candidates.isNotEmpty) {
      _start = widget.candidates.first;
      if (widget.candidates.length > 1) {
        _end = widget.candidates[1];
      }
    }
    _scheduleInitialRun();
  }

  void _scheduleInitialRun() {
    if (_initialLosScheduled) return;
    _initialLosScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runLos();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _panelController.dispose();
    _lineOfSightService.dispose();
    super.dispose();
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

  void _resetMapView({
    required LatLng initialCenter,
    required double initialZoom,
    required LatLngBounds? bounds,
  }) {
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(64),
          maxZoom: 16,
        ),
      );
      return;
    }
    _mapController.move(initialCenter, initialZoom);
  }

  Future<void> _runLos() async {
    final start = _start;
    final end = _end;
    final startAntenna = _startAntennaHeight;
    final endAntenna = _endAntennaHeight;
    final requestId = ++_losRequestNonce;
    if (start == null || end == null) {
      setState(() {
        _result = null;
        _selectedObstruction = null;
        _error = _errorSelectStartEnd;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final connector = context.read<MeshCoreConnector>();
      final frequencyMHz = _normalizeFrequencyMHz(connector.currentFreqHz);
      final result = await _lineOfSightService.analyzePath(
        [start.point, end.point],
        startAntennaHeightMeters: startAntenna,
        endAntennaHeightMeters: endAntenna,
        frequencyMHz: frequencyMHz,
      );
      if (!mounted) return;
      if (!_isRunRequestCurrent(
        requestId: requestId,
        start: start,
        end: end,
        startAntenna: startAntenna,
        endAntenna: endAntenna,
      )) {
        return;
      }
      setState(() {
        _result = result;
        _selectedObstruction = _defaultObstructionFor(result);
        _menuExpanded = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!_isRunRequestCurrent(
        requestId: requestId,
        start: start,
        end: end,
        startAntenna: startAntenna,
        endAntenna: endAntenna,
      )) {
        return;
      }
      setState(() {
        _result = null;
        _selectedObstruction = null;
        _error = context.l10n.losRunFailed(e.toString());
      });
    } finally {
      if (mounted && requestId == _losRequestNonce) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  bool _isRunRequestCurrent({
    required int requestId,
    required LineOfSightEndpoint start,
    required LineOfSightEndpoint end,
    required double startAntenna,
    required double endAntenna,
  }) {
    return requestId == _losRequestNonce &&
        identical(_start, start) &&
        identical(_end, end) &&
        _startAntennaHeight == startAntenna &&
        _endAntennaHeight == endAntenna;
  }

  void _selectFromMap(LineOfSightEndpoint endpoint) {
    setState(() {
      _result = null;
      _selectedObstruction = null;
      _error = null;
      if (_start == null || (_start != null && _end != null)) {
        _start = endpoint;
        if (_end == endpoint) _end = null;
      } else {
        _end = endpoint;
        if (_start == endpoint) _start = null;
      }
    });

    if (_start != null && _end != null) {
      _runLos();
    }
  }

  void _addCustomPoint(LatLng point) {
    final endpoint = LineOfSightEndpoint(
      label: context.l10n.losCustomPointLabel(_customEndpoints.length + 1),
      point: point,
      color: LosPalette.marginal,
      icon: Icons.push_pin,
      isCustom: true,
    );
    setState(() {
      _customEndpoints.add(endpoint);
    });
    _selectFromMap(endpoint);
  }

  List<LineOfSightEndpoint> _visibleEndpoints() {
    return [if (_showDisplayNodes) ...widget.candidates, ..._customEndpoints];
  }

  bool _hasEndpoint(
    List<LineOfSightEndpoint> endpoints,
    LineOfSightEndpoint? e,
  ) {
    if (e == null) return false;
    return endpoints.any((item) => identical(item, e));
  }

  void _sanitizeSelection() {
    final visible = _visibleEndpoints();
    if (!_hasEndpoint(visible, _start)) {
      _start = null;
    }
    if (!_hasEndpoint(visible, _end)) {
      _end = null;
    }
  }

  void _clearAllPoints() {
    setState(() {
      _customEndpoints.clear();
      _start = null;
      _end = null;
      _result = null;
      _selectedObstruction = null;
      _error = _errorSelectStartEnd;
    });
  }

  void _deleteCustomPoint(LineOfSightEndpoint endpoint) {
    setState(() {
      _customEndpoints.removeWhere((e) => identical(e, endpoint));
      if (identical(_start, endpoint)) _start = null;
      if (identical(_end, endpoint)) _end = null;
      _result = null;
      _selectedObstruction = null;
    });
  }

  Future<void> _renameCustomPoint(LineOfSightEndpoint endpoint) async {
    final controller = TextEditingController(text: endpoint.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.losRenameCustomPoint),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: context.l10n.losPointName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              Navigator.pop(dialogContext, value);
            },
            child: Text(context.l10n.common_save),
          ),
        ],
      ),
    );

    if (newLabel == null || newLabel.isEmpty) return;
    final index = _customEndpoints.indexWhere((e) => identical(e, endpoint));
    if (index < 0) return;
    final renamed = LineOfSightEndpoint(
      label: newLabel,
      point: endpoint.point,
      color: endpoint.color,
      icon: endpoint.icon,
      isCustom: endpoint.isCustom,
    );
    setState(() {
      _customEndpoints[index] = renamed;
      if (identical(_start, endpoint)) _start = renamed;
      if (identical(_end, endpoint)) _end = renamed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsService>().settings;
    final isImperial = settings.unitSystem == UnitSystem.imperial;
    final tileCache = context.watch<MapTileCacheService>();
    final endpoints = _visibleEndpoints();
    final mapPoints = [
      if (_start != null) _start!.point,
      if (_end != null) _end!.point,
    ];
    final initialCenter = mapPoints.isNotEmpty
        ? mapPoints.first
        : const LatLng(0, 0);
    final bounds = mapPoints.length > 1
        ? LatLngBounds.fromPoints(mapPoints)
        : null;
    final initialZoom = mapPoints.length > 1 ? 13.0 : 2.0;
    final isDesktop = _isDesktopPlatform(defaultTargetPlatform);
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
                enabled: !_loading,
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline),
                    const SizedBox(width: 10),
                    Text(context.l10n.losClearAllPoints),
                  ],
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
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              initialCameraFit: bounds == null
                  ? null
                  : CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(64),
                      maxZoom: 16,
                    ),
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
              minZoom: _mapMinZoom,
              maxZoom: _mapMaxZoom,
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
              if (_result != null && _result!.segments.isNotEmpty)
                PolylineLayer(polylines: _buildSegmentPolylines(_result!)),
              MarkerLayer(
                markers: _buildMarkers(endpoints, _primaryObstructions()),
              ),
            ],
          ),
          _buildLinkBanner(isImperial),
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

  Widget _buildLinkBanner(bool isImperial) {
    final connector = context.watch<MeshCoreConnector>();
    final segment = _primarySegmentResult();
    final status = _losStatusFor(segment);
    final battery = connector.batteryPercent;
    final snr = connector.latestRadioStats?.lastSnrDb;
    return Positioned(
      top: 10,
      left: 12,
      right: 12,
      child: IgnorePointer(
        ignoring: false,
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
                    color: _statusColorFor(status).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: _statusColorFor(status)),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: _statusColorFor(status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_start?.label ?? 'A'}  →  ${_end?.label ?? 'B'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LosPalette.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        segment == null
                            ? _statusText()
                            : '${_statusLabel(status)} • '
                                  '${_formatDistanceValue(segment.totalDistanceMeters, isImperial)} '
                                  '${isImperial ? 'mi' : 'km'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LosPalette.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _headerMetric(
                  Icons.battery_5_bar,
                  battery == null ? '--' : '$battery%',
                ),
                const SizedBox(width: 10),
                _headerMetric(
                  Icons.network_cell,
                  snr == null ? '--' : '${snr.toStringAsFixed(1)} dB',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerMetric(IconData icon, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: LosPalette.textMuted, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: MeshTheme.mono(
            color: LosPalette.text,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
              onPressed: () => _zoomMapBy(1),
            ),
            IconButton(
              color: LosPalette.text,
              icon: const Icon(Icons.remove),
              tooltip: context.l10n.map_zoomOut,
              onPressed: () => _zoomMapBy(-1),
            ),
            IconButton(
              color: LosPalette.text,
              icon: const Icon(Icons.center_focus_strong),
              tooltip: context.l10n.map_centerMap,
              onPressed: () => _resetMapView(
                initialCenter: initialCenter,
                initialZoom: initialZoom,
                bounds: bounds,
              ),
            ),
            IconButton(
              color: _showTerrainLayer
                  ? LosPalette.selected
                  : LosPalette.textMuted,
              icon: const Icon(Icons.layers_outlined),
              tooltip: 'Map detail',
              onPressed: () =>
                  setState(() => _showTerrainLayer = !_showTerrainLayer),
            ),
            IconButton(
              color: LosPalette.text,
              icon: Text(
                isImperial ? 'ft' : 'm',
                style: const TextStyle(
                  color: LosPalette.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              tooltip: 'Units',
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
                  ? context.l10n.losHidePanelTooltip
                  : context.l10n.losShowPanelTooltip,
              onPressed: () => setState(() => _showHud = !_showHud),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary(LineOfSightResult? segment, bool isImperial) {
    final status = _losStatusFor(segment);
    final color = _statusColorFor(status);
    final distanceUnit = isImperial ? 'mi' : 'km';
    final heightUnit = isImperial ? 'ft' : 'm';
    final worst = _defaultObstructionFor(_result);
    final minClearance = segment == null || segment.samples.isEmpty
        ? null
        : segment.samples
              .map((sample) => sample.clearanceMeters)
              .reduce(math.min);
    final amount = segment == null
        ? '--'
        : segment.isClear
        ? '${_formatHeightValue(minClearance ?? 0, isImperial)} $heightUnit'
        : '${_formatHeightValue(segment.maxObstructionMeters, isImperial)} $heightUnit';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MeshRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_statusIcon(status), color: color, size: 24),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryMetric(
                'Distance',
                segment == null
                    ? '--'
                    : '${_formatDistanceValue(segment.totalDistanceMeters, isImperial)} $distanceUnit',
              ),
              _summaryMetric(
                segment?.isClear == true ? 'Clearance' : 'Blocked by',
                amount,
                valueColor: color,
              ),
              _summaryMetric(
                'Obstruction',
                worst == null
                    ? '--'
                    : '${_formatDistanceValue(worst.distanceMeters, isImperial)} $distanceUnit from A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: LosPalette.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MeshTheme.mono(
                color: valueColor ?? LosPalette.text,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObstructionCard(
    LineOfSightObstruction obstruction,
    bool isImperial, {
    required bool isWorst,
  }) {
    final selected =
        _selectedObstruction?.sampleIndex == obstruction.sampleIndex;
    final distanceUnit = isImperial ? 'mi' : 'km';
    final heightUnit = isImperial ? 'ft' : 'm';
    return InkWell(
      onTap: () => _centerOnObstruction(obstruction),
      borderRadius: BorderRadius.circular(MeshRadii.sm),
      child: Container(
        width: 154,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? LosPalette.selected.withValues(alpha: 0.18)
              : LosPalette.chartBackground,
          borderRadius: BorderRadius.circular(MeshRadii.sm),
          border: Border.all(
            color: selected ? LosPalette.selected : LosPalette.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: LosPalette.blocked,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${_formatDistanceValue(obstruction.distanceMeters, isImperial)} $distanceUnit',
                    style: const TextStyle(
                      color: LosPalette.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isWorst)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: LosPalette.blocked,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'WORST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              'Blocked ${_formatHeightValue(obstruction.obstructionMeters, isImperial)} $heightUnit',
              style: const TextStyle(
                color: LosPalette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedObstructionCard(
    LineOfSightObstruction obstruction,
    LineOfSightResult segment,
    bool isImperial,
  ) {
    final distanceUnit = isImperial ? 'mi' : 'km';
    final heightUnit = isImperial ? 'ft' : 'm';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LosPalette.selected.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MeshRadii.md),
        border: Border.all(color: LosPalette.selected),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected obstruction',
            style: TextStyle(
              color: LosPalette.text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _detailValue(
                'Blocked by',
                '${_formatHeightValue(obstruction.obstructionMeters, isImperial)} $heightUnit',
              ),
              _detailValue(
                'From A',
                '${_formatDistanceValue(obstruction.distanceMeters, isImperial)} $distanceUnit',
              ),
              _detailValue(
                'From B',
                '${_formatDistanceValue(segment.totalDistanceMeters - obstruction.distanceMeters, isImperial)} $distanceUnit',
              ),
              _detailValue(
                'Elevation',
                '${_formatHeightValue(obstruction.terrainMeters, isImperial)} $heightUnit',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _centerOnObstruction(obstruction),
              icon: const Icon(Icons.center_focus_strong, size: 17),
              label: const Text('Center on map'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailValue(String label, String value) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: LosPalette.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
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
    );
  }

  Widget _buildControlPanel(
    bool isImperial,
    ScrollController scrollController,
  ) {
    _sanitizeSelection();
    final segment = _primarySegmentResult();
    final connector = context.read<MeshCoreConnector>();
    final reportedFrequencyMHz = _normalizeFrequencyMHz(
      connector.currentFreqHz,
    );
    final displayFrequencyMHz = segment?.frequencyMHz ?? reportedFrequencyMHz;
    final kFactorUsed = segment?.usedKFactor;
    final obstructions =
        segment?.obstructions ?? const <LineOfSightObstruction>[];
    final endpoints = _visibleEndpoints();
    final distanceUnit = isImperial ? 'mi' : 'km';
    final heightUnit = isImperial ? 'ft' : 'm';
    final antennaAMeters = _startAntennaHeight;
    final antennaBMeters = _endAntennaHeight;
    final antennaADisplay = _toDisplayHeight(antennaAMeters, isImperial);
    final antennaBDisplay = _toDisplayHeight(antennaBMeters, isImperial);
    final antennaSliderMax = isImperial ? _maxAntennaFeet : _maxAntennaMeters;
    final antennaSliderDivisions = isImperial ? 400 : 122;
    final worst = _defaultObstructionFor(_result);
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
          _buildResultSummary(segment, isImperial),
          if (segment != null) ...[
            const SizedBox(height: 14),
            _buildProfileView(segment, distanceUnit, heightUnit, isImperial),
            const SizedBox(height: 10),
            _LosLegend(
              terrainLabel: context.l10n.losLegendTerrain,
              losBeamLabel: context.l10n.losLegendLosBeam,
              radioHorizonLabel: context.l10n.losLegendRadioHorizon,
            ),
          ],
          if (obstructions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              context.l10n.losBlockedSpotsTitle,
              style: const TextStyle(
                color: LosPalette.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.losBlockedSpotsHint,
              style: const TextStyle(color: LosPalette.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: obstructions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final obstruction = obstructions[index];
                  return _buildObstructionCard(
                    obstruction,
                    isImperial,
                    isWorst: obstruction.sampleIndex == worst?.sampleIndex,
                  );
                },
              ),
            ),
          ],
          if (_selectedObstruction != null && segment != null) ...[
            const SizedBox(height: 14),
            _buildSelectedObstructionCard(
              _selectedObstruction!,
              segment,
              isImperial,
            ),
          ],
          const SizedBox(height: 12),
          ExpansionTile(
            initiallyExpanded: _menuExpanded,
            onExpansionChanged: (value) =>
                setState(() => _menuExpanded = value),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            iconColor: LosPalette.text,
            collapsedIconColor: LosPalette.textMuted,
            title: Text(
              context.l10n.losMenuTitle,
              style: const TextStyle(
                color: LosPalette.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              context.l10n.losMenuSubtitle,
              style: const TextStyle(color: LosPalette.textMuted, fontSize: 11),
            ),
            children: [
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.l10n.losShowDisplayNodes,
                  style: const TextStyle(fontSize: 12),
                ),
                value: _showDisplayNodes,
                onChanged: (value) {
                  setState(() {
                    _showDisplayNodes = value;
                    _sanitizeSelection();
                    _result = null;
                    _selectedObstruction = null;
                  });
                },
              ),
              if (_customEndpoints.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  context.l10n.losCustomPoints,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                for (final point in _customEndpoints)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      point.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      '${point.point.latitude.toStringAsFixed(5)}, ${point.point.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _renameCustomPoint(point),
                          tooltip: context.l10n.common_edit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _deleteCustomPoint(point),
                          tooltip: context.l10n.common_delete,
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              _buildEndpointRow(
                label: context.l10n.losPointA,
                value: _start,
                candidates: endpoints,
                onChanged: (value) {
                  setState(() {
                    _start = value;
                    _result = null;
                    _selectedObstruction = null;
                  });
                  if (_start != null && _end != null) {
                    _runLos();
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildEndpointRow(
                label: context.l10n.losPointB,
                value: _end,
                candidates: endpoints,
                onChanged: (value) {
                  setState(() {
                    _end = value;
                    _result = null;
                    _selectedObstruction = null;
                  });
                  if (_start != null && _end != null) {
                    _runLos();
                  }
                },
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.losAntennaA(
                  antennaADisplay.toStringAsFixed(1),
                  heightUnit,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              Slider(
                value: antennaADisplay,
                min: 0,
                max: antennaSliderMax,
                divisions: antennaSliderDivisions,
                onChanged: (value) {
                  setState(() {
                    _startAntennaHeight = _toMetersHeight(value, isImperial);
                  });
                },
              ),
              Text(
                context.l10n.losAntennaB(
                  antennaBDisplay.toStringAsFixed(1),
                  heightUnit,
                ),
                style: const TextStyle(fontSize: 12),
              ),
              Slider(
                value: antennaBDisplay,
                min: 0,
                max: antennaSliderMax,
                divisions: antennaSliderDivisions,
                onChanged: (value) {
                  setState(() {
                    _endAntennaHeight = _toMetersHeight(value, isImperial);
                  });
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _runLos,
                  icon: const LosIcon(),
                  label: Text(context.l10n.losRun),
                ),
              ),
            ],
          ),
          if (displayFrequencyMHz != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${context.l10n.losFrequencyLabel}: '
                  '${displayFrequencyMHz.toStringAsFixed(3)} MHz'
                  '${kFactorUsed == null ? '' : '  k=${kFactorUsed.toStringAsFixed(3)}'}',
                  style: const TextStyle(
                    color: LosPalette.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (kFactorUsed != null)
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 17),
                    color: LosPalette.textMuted,
                    tooltip: context.l10n.losFrequencyInfoTooltip,
                    onPressed: () => _showFrequencyInfoDialog(
                      context,
                      displayFrequencyMHz,
                      kFactorUsed,
                    ),
                  ),
              ],
            ),
          ],
          Text(
            context.l10n.losElevationAttribution,
            style: const TextStyle(color: LosPalette.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointRow({
    required String label,
    required LineOfSightEndpoint? value,
    required List<LineOfSightEndpoint> candidates,
    required ValueChanged<LineOfSightEndpoint?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: DropdownButton<LineOfSightEndpoint>(
            value: value,
            isExpanded: true,
            items: candidates
                .map(
                  (e) => DropdownMenuItem<LineOfSightEndpoint>(
                    value: e,
                    child: Text(e.label, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  LineOfSightResult? _primarySegmentResult() {
    if (_result == null || _result!.segments.isEmpty) return null;
    return _result!.segments.first.result;
  }

  List<LineOfSightObstruction> _primaryObstructions() {
    return _primarySegmentResult()?.obstructions ?? const [];
  }

  LineOfSightObstruction? _defaultObstructionFor(
    LineOfSightPathResult? result,
  ) {
    if (result == null || result.segments.isEmpty) return null;
    final obstructions = result.segments.first.result.obstructions;
    if (obstructions.isEmpty) return null;
    return obstructions.reduce(
      (current, next) =>
          next.obstructionMeters > current.obstructionMeters ? next : current,
    );
  }

  void _selectObstruction(LineOfSightObstruction obstruction) {
    setState(() {
      _selectedObstruction = obstruction;
    });
  }

  void _centerOnObstruction(LineOfSightObstruction obstruction) {
    _selectObstruction(obstruction);
    _mapController.move(
      obstruction.point,
      math.max(_mapController.camera.zoom, 15),
    );
  }

  String _formatDistanceValue(double meters, bool isImperial) {
    final value = isImperial ? (meters / 1000.0) * _kmToMiles : meters / 1000.0;
    return value.toStringAsFixed(2);
  }

  String _formatHeightValue(double meters, bool isImperial) {
    final value = isImperial ? meters * _metersToFeet : meters;
    return value.toStringAsFixed(1);
  }

  String _obstructionChipLabel(
    LineOfSightObstruction obstruction,
    bool isImperial,
  ) {
    final distanceUnit = isImperial ? 'mi' : 'km';
    final heightUnit = isImperial ? 'ft' : 'm';
    return context.l10n.losBlockedSpotChip(
      _formatDistanceValue(obstruction.distanceMeters, isImperial),
      distanceUnit,
      _formatHeightValue(obstruction.obstructionMeters, isImperial),
      heightUnit,
    );
  }

  Widget _buildProfileView(
    LineOfSightResult segment,
    String distanceUnit,
    String heightUnit,
    bool isImperial,
  ) {
    if (segment.samples.length < 2) {
      return SizedBox(
        height: 190,
        width: double.infinity,
        child: CustomPaint(
          painter: _LosProfilePainter(
            samples: segment.samples,
            distanceUnit: distanceUnit,
            heightUnit: heightUnit,
            badgeTextStyle:
                Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: LosPalette.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  color: LosPalette.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
            terrainLabel: context.l10n.losLegendTerrain,
            losBeamLabel: context.l10n.losLegendLosBeam,
            radioHorizonLabel: context.l10n.losLegendRadioHorizon,
            selectedSampleIndex: _selectedObstruction?.sampleIndex,
          ),
        ),
      );
    }
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, 190);
          final geometry = _LosProfileGeometry(
            samples: segment.samples,
            size: size,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LosProfilePainter(
                    samples: segment.samples,
                    distanceUnit: distanceUnit,
                    heightUnit: heightUnit,
                    badgeTextStyle:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: LosPalette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          color: LosPalette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                    terrainLabel: context.l10n.losLegendTerrain,
                    losBeamLabel: context.l10n.losLegendLosBeam,
                    radioHorizonLabel: context.l10n.losLegendRadioHorizon,
                    selectedSampleIndex: _selectedObstruction?.sampleIndex,
                  ),
                ),
              ),
              for (final obstruction in segment.obstructions)
                Builder(
                  builder: (context) {
                    final sample = segment.samples[obstruction.sampleIndex];
                    final position = geometry.mapPoint(
                      sample.distanceMeters,
                      sample.terrainMeters,
                    );
                    final isSelected =
                        _selectedObstruction?.sampleIndex ==
                        obstruction.sampleIndex;
                    final markerSize = isSelected ? 18.0 : 14.0;
                    final left = (position.dx - markerSize / 2)
                        .clamp(0.0, math.max(0.0, size.width - markerSize))
                        .toDouble();
                    final top = (position.dy - markerSize / 2)
                        .clamp(0.0, math.max(0.0, size.height - markerSize))
                        .toDouble();
                    return Positioned(
                      left: left,
                      top: top,
                      child: Tooltip(
                        message: _obstructionChipLabel(obstruction, isImperial),
                        child: GestureDetector(
                          onTap: () => _centerOnObstruction(obstruction),
                          child: Container(
                            width: markerSize,
                            height: markerSize,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? LosPalette.selected
                                  : LosPalette.blocked,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? LosPalette.text
                                    : LosPalette.chartBackground,
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: LosPalette.shadow,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  List<Polyline> _buildSegmentPolylines(LineOfSightPathResult result) {
    final polylines = <Polyline>[];
    for (final segment in result.segments) {
      final color = !segment.result.hasData
          ? LosPalette.textMuted
          : _statusColorFor(_losStatusFor(segment.result));
      polylines.add(
        Polyline(
          points: [segment.start, segment.end],
          strokeWidth: 5,
          color: color,
          borderStrokeWidth: 2,
          borderColor: Colors.white,
        ),
      );
    }
    return polylines;
  }

  List<Marker> _buildMarkers(
    List<LineOfSightEndpoint> endpoints,
    List<LineOfSightObstruction> obstructions,
  ) {
    return [
      for (final obstruction in obstructions)
        Marker(
          point: obstruction.point,
          width: 52,
          height: 52,
          child: GestureDetector(
            onTap: () => _centerOnObstruction(obstruction),
            child: Center(
              child: Container(
                width:
                    _selectedObstruction?.sampleIndex == obstruction.sampleIndex
                    ? 36
                    : 24,
                height:
                    _selectedObstruction?.sampleIndex == obstruction.sampleIndex
                    ? 36
                    : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color:
                        _selectedObstruction?.sampleIndex ==
                            obstruction.sampleIndex
                        ? LosPalette.selected
                        : LosPalette.blocked,
                    width:
                        _selectedObstruction?.sampleIndex ==
                            obstruction.sampleIndex
                        ? 4
                        : 3,
                  ),
                  boxShadow: [
                    const BoxShadow(
                      color: LosPalette.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      for (final endpoint in endpoints)
        Marker(
          point: endpoint.point,
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => _selectFromMap(endpoint),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (endpoint == _start || endpoint == _end)
                    ? endpoint.color
                    : LosPalette.panelDark,
                border: Border.all(
                  color: (endpoint == _start || endpoint == _end)
                      ? Colors.white
                      : endpoint.color.withValues(alpha: 0.75),
                  width: (endpoint == _start || endpoint == _end) ? 2.5 : 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: LosPalette.shadow,
                    blurRadius: 7,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      endpoint.icon,
                      color: endpoint == _start || endpoint == _end
                          ? Colors.white
                          : endpoint.color,
                      size: 17,
                    ),
                  ),
                  if (endpoint == _start || endpoint == _end)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: LosPalette.chartBackground,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: endpoint.color, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          endpoint == _start ? 'A' : 'B',
                          style: MeshTheme.mono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: endpoint.color,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      for (final endpoint in endpoints)
        if (_showMarkerLabels)
          Marker(
            point: endpoint.point,
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
                      endpoint.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MeshTheme.mono(
                        fontSize: 10,
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

  String _statusText() {
    if (_loading) return context.l10n.losStatusChecking;
    if (_error == _errorSelectStartEnd) {
      return context.l10n.losSelectStartEnd;
    }
    if (_error != null) return _error!;
    if (_result == null) return context.l10n.losStatusNoData;
    final total = _result!.segments.length;
    return context.l10n.losStatusSummary(
      _result!.clearSegments,
      total,
      _result!.blockedSegments,
      _result!.unknownSegments,
    );
  }

  _LosDisplayStatus _losStatusFor(LineOfSightResult? result) {
    if (result == null || !result.hasData) return _LosDisplayStatus.unknown;
    if (!result.isClear) return _LosDisplayStatus.blocked;
    if (result.samples.isEmpty) return _LosDisplayStatus.clear;
    final minClearance = result.samples
        .map((sample) => sample.clearanceMeters)
        .reduce(math.min);
    return minClearance <= _marginalClearanceMeters
        ? _LosDisplayStatus.marginal
        : _LosDisplayStatus.clear;
  }

  String _statusLabel(_LosDisplayStatus status) {
    switch (status) {
      case _LosDisplayStatus.clear:
        return 'Clear';
      case _LosDisplayStatus.marginal:
        return 'Marginal';
      case _LosDisplayStatus.blocked:
        return 'Blocked';
      case _LosDisplayStatus.unknown:
        return _loading ? 'Checking' : 'No result';
    }
  }

  Color _statusColorFor(_LosDisplayStatus status) {
    switch (status) {
      case _LosDisplayStatus.clear:
        return LosPalette.clear;
      case _LosDisplayStatus.marginal:
        return LosPalette.marginal;
      case _LosDisplayStatus.blocked:
        return LosPalette.blocked;
      case _LosDisplayStatus.unknown:
        return LosPalette.textMuted;
    }
  }

  IconData _statusIcon(_LosDisplayStatus status) {
    switch (status) {
      case _LosDisplayStatus.clear:
        return Icons.check_circle;
      case _LosDisplayStatus.marginal:
        return Icons.warning_amber_rounded;
      case _LosDisplayStatus.blocked:
        return Icons.block;
      case _LosDisplayStatus.unknown:
        return Icons.help_outline;
    }
  }

  double _toDisplayHeight(double meters, bool isImperial) {
    return isImperial ? meters * _metersToFeet : meters;
  }

  double _toMetersHeight(double displayHeight, bool isImperial) {
    return isImperial ? displayHeight / _metersToFeet : displayHeight;
  }

  void _handleQuickSwitch(int index, BuildContext context) {
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

  void _showFrequencyInfoDialog(
    BuildContext context,
    double frequencyMHz,
    double kFactor,
  ) {
    final baselineFreq = LineOfSightService.baselineFrequencyMHz;
    final baselineK = LineOfSightService.baselineKFactor;
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

enum _LosDisplayStatus { clear, marginal, blocked, unknown }

class _LosProfileGeometry {
  static const leftPadding = 38.0;
  static const rightPadding = 14.0;
  static const topPadding = 20.0;
  static const bottomPadding = 28.0;

  final List<LineOfSightSample> samples;
  final Size size;
  late final double minY = samples
      .map(
        (s) => math.min(
          math.min(s.terrainMeters, s.lineHeightMeters),
          s.refractedHeightMeters,
        ),
      )
      .reduce(math.min);
  late final double maxY = samples
      .map(
        (s) => math.max(
          math.max(s.terrainMeters, s.lineHeightMeters),
          s.refractedHeightMeters,
        ),
      )
      .reduce(math.max);
  late final double ySpan = math.max(1.0, maxY - minY);
  late final double maxDist = math.max(1.0, samples.last.distanceMeters);
  late final double chartWidth = math.max(
    1.0,
    size.width - leftPadding - rightPadding,
  );
  late final double chartHeight = math.max(
    1.0,
    size.height - topPadding - bottomPadding,
  );

  _LosProfileGeometry({required this.samples, required this.size});

  Offset mapPoint(double distanceMeters, double elevationMeters) {
    final px = leftPadding + (distanceMeters / maxDist) * chartWidth;
    final py =
        size.height -
        bottomPadding -
        ((elevationMeters - minY) / ySpan) * chartHeight;
    return Offset(px, py);
  }
}

class _LosProfilePainter extends CustomPainter {
  final List<LineOfSightSample> samples;
  final String distanceUnit;
  final String heightUnit;
  final TextStyle badgeTextStyle;
  final String terrainLabel;
  final String losBeamLabel;
  final String radioHorizonLabel;
  final int? selectedSampleIndex;

  const _LosProfilePainter({
    required this.samples,
    required this.distanceUnit,
    required this.heightUnit,
    required this.badgeTextStyle,
    required this.terrainLabel,
    required this.losBeamLabel,
    required this.radioHorizonLabel,
    this.selectedSampleIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = LosPalette.chartBackground;
    canvas.drawRect(Offset.zero & size, bg);
    _drawUnitBadge(canvas, size);

    if (samples.length < 2) return;

    final minY = samples
        .map(
          (s) => math.min(
            math.min(s.terrainMeters, s.lineHeightMeters),
            s.refractedHeightMeters,
          ),
        )
        .reduce(math.min);
    final maxY = samples
        .map(
          (s) => math.max(
            math.max(s.terrainMeters, s.lineHeightMeters),
            s.refractedHeightMeters,
          ),
        )
        .reduce(math.max);
    final ySpan = math.max(1.0, maxY - minY);
    final maxDist = math.max(1.0, samples.last.distanceMeters);
    const leftPadding = _LosProfileGeometry.leftPadding;
    const rightPadding = _LosProfileGeometry.rightPadding;
    const topPadding = _LosProfileGeometry.topPadding;
    const bottomPadding = _LosProfileGeometry.bottomPadding;
    final chartWidth = math.max(1.0, size.width - leftPadding - rightPadding);
    final chartHeight = math.max(1.0, size.height - topPadding - bottomPadding);

    Offset mapPoint(double x, double y) {
      final px = leftPadding + (x / maxDist) * chartWidth;
      final py =
          size.height - bottomPadding - ((y - minY) / ySpan) * chartHeight;
      return Offset(px, py);
    }

    final gridPaint = Paint()
      ..color = LosPalette.textMuted.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final x = leftPadding + chartWidth * i / 4;
      final y = topPadding + chartHeight * i / 4;
      canvas.drawLine(
        Offset(x, topPadding),
        Offset(x, size.height - bottomPadding),
        gridPaint,
      );
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
      final distance = maxDist * i / 4;
      _paintLabel(
        canvas,
        _displayDistance(distance).toStringAsFixed(i == 0 ? 0 : 1),
        Offset(x, size.height - bottomPadding + 7),
        center: true,
      );
      final elevation = maxY - ySpan * i / 4;
      _paintLabel(
        canvas,
        _displayHeight(elevation).toStringAsFixed(0),
        Offset(leftPadding - 6, y - 6),
        alignRight: true,
      );
    }

    final firstTerrainPoint = mapPoint(
      samples.first.distanceMeters,
      samples.first.terrainMeters,
    );
    final lastTerrainPoint = mapPoint(
      samples.last.distanceMeters,
      samples.last.terrainMeters,
    );

    double distanceForCanvasX(double x) {
      final normalized = ((x - leftPadding) / chartWidth).clamp(0.0, 1.0);
      return normalized * maxDist;
    }

    double elevationToPixel(double elevation) {
      final normalized = ((elevation - minY) / ySpan).clamp(0.0, 1.0);
      return size.height - bottomPadding - normalized * chartHeight;
    }

    double extrapolateTerrain(double distance, bool isLeft) {
      final samplesForSlope = isLeft
          ? samples.sublist(0, math.min(2, samples.length))
          : samples.sublist(samples.length - math.min(2, samples.length));
      if (samplesForSlope.length < 2) {
        return samplesForSlope.first.terrainMeters;
      }
      final a = samplesForSlope.first;
      final b = samplesForSlope.last;
      final dx = b.distanceMeters - a.distanceMeters;
      if (dx.abs() < 1e-6) return a.terrainMeters;
      final slope = (b.terrainMeters - a.terrainMeters) / dx;
      return a.terrainMeters + slope * (distance - a.distanceMeters);
    }

    final leftDistance = distanceForCanvasX(0.0);
    final rightDistance = distanceForCanvasX(size.width);
    final leftEdgeTerrain = extrapolateTerrain(leftDistance, true);
    final rightEdgeTerrain = extrapolateTerrain(rightDistance, false);
    final leftEdgePoint = Offset(0.0, elevationToPixel(leftEdgeTerrain));
    final rightEdgePoint = Offset(
      size.width,
      elevationToPixel(rightEdgeTerrain),
    );

    final terrainPath = ui.Path()
      ..moveTo(0, size.height)
      ..lineTo(leftEdgePoint.dx, leftEdgePoint.dy)
      ..lineTo(firstTerrainPoint.dx, firstTerrainPoint.dy);
    for (final sample in samples) {
      final p = mapPoint(sample.distanceMeters, sample.terrainMeters);
      terrainPath.lineTo(p.dx, p.dy);
    }
    terrainPath
      ..lineTo(lastTerrainPoint.dx, lastTerrainPoint.dy)
      ..lineTo(rightEdgePoint.dx, rightEdgePoint.dy)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      terrainPath,
      Paint()..color = LosPalette.terrain.withValues(alpha: 0.18),
    );

    final terrainLine = ui.Path()..moveTo(leftEdgePoint.dx, leftEdgePoint.dy);
    for (final sample in samples) {
      final p = mapPoint(sample.distanceMeters, sample.terrainMeters);
      terrainLine.lineTo(p.dx, p.dy);
    }
    terrainLine.lineTo(rightEdgePoint.dx, rightEdgePoint.dy);
    canvas.drawPath(
      terrainLine,
      Paint()
        ..color = LosPalette.terrain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final losLine = ui.Path();
    for (int i = 0; i < samples.length; i++) {
      final p = mapPoint(
        samples[i].distanceMeters,
        samples[i].lineHeightMeters,
      );
      if (i == 0) {
        losLine.moveTo(p.dx, p.dy);
      } else {
        losLine.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      losLine,
      Paint()
        ..color = LosPalette.beam
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final refractedLine = ui.Path();
    for (int i = 0; i < samples.length; i++) {
      final p = mapPoint(
        samples[i].distanceMeters,
        samples[i].refractedHeightMeters,
      );
      if (i == 0) {
        refractedLine.moveTo(p.dx, p.dy);
      } else {
        refractedLine.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      refractedLine,
      Paint()
        ..color = LosPalette.horizon
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final capPath = ui.Path();
    for (int i = 0; i < samples.length; i++) {
      final p = mapPoint(
        samples[i].distanceMeters,
        samples[i].refractedHeightMeters,
      );
      if (i == 0) {
        capPath.moveTo(p.dx, p.dy);
      } else {
        capPath.lineTo(p.dx, p.dy);
      }
    }
    for (int i = samples.length - 1; i >= 0; i--) {
      final p = mapPoint(
        samples[i].distanceMeters,
        samples[i].lineHeightMeters,
      );
      capPath.lineTo(p.dx, p.dy);
    }
    capPath.close();
    canvas.drawPath(
      capPath,
      Paint()
        ..color = LosPalette.horizon.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );

    for (var i = 0; i < samples.length - 1; i++) {
      if (samples[i].clearanceMeters >= 0 &&
          samples[i + 1].clearanceMeters >= 0) {
        continue;
      }
      final terrainA = mapPoint(
        samples[i].distanceMeters,
        samples[i].terrainMeters,
      );
      final terrainB = mapPoint(
        samples[i + 1].distanceMeters,
        samples[i + 1].terrainMeters,
      );
      final lineB = mapPoint(
        samples[i + 1].distanceMeters,
        samples[i + 1].lineHeightMeters,
      );
      final lineA = mapPoint(
        samples[i].distanceMeters,
        samples[i].lineHeightMeters,
      );
      final blockedArea = ui.Path()
        ..moveTo(terrainA.dx, terrainA.dy)
        ..lineTo(terrainB.dx, terrainB.dy)
        ..lineTo(lineB.dx, lineB.dy)
        ..lineTo(lineA.dx, lineA.dy)
        ..close();
      canvas.drawPath(
        blockedArea,
        Paint()..color = LosPalette.blocked.withValues(alpha: 0.42),
      );
    }

    _paintEndpoint(canvas, mapPoint(0, samples.first.lineHeightMeters), 'A');
    _paintEndpoint(
      canvas,
      mapPoint(maxDist, samples.last.lineHeightMeters),
      'B',
    );

    if (selectedSampleIndex != null &&
        selectedSampleIndex! >= 0 &&
        selectedSampleIndex! < samples.length) {
      final selectedSample = samples[selectedSampleIndex!];
      final selectedPoint = mapPoint(
        selectedSample.distanceMeters,
        selectedSample.terrainMeters,
      );
      canvas.drawLine(
        Offset(selectedPoint.dx, topPadding),
        Offset(selectedPoint.dx, size.height - bottomPadding),
        Paint()
          ..color = LosPalette.selected
          ..strokeWidth = 2,
      );
      canvas.drawCircle(selectedPoint, 7, Paint()..color = LosPalette.selected);
      canvas.drawCircle(
        selectedPoint,
        8.5,
        Paint()
          ..color = LosPalette.text
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final labelY = math.max(topPadding + 2, selectedPoint.dy - 27);
      _paintPill(
        canvas,
        'Selected',
        Offset(
          selectedPoint.dx.clamp(42.0, size.width - 42).toDouble(),
          labelY,
        ),
      );
    }
  }

  double _displayDistance(double meters) {
    return distanceUnit == 'mi'
        ? (meters / 1000.0) * 0.621371
        : meters / 1000.0;
  }

  double _displayHeight(double meters) {
    return heightUnit == 'ft' ? meters * 3.28084 : meters;
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    bool center = false,
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: LosPalette.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = offset.dx;
    if (center) dx -= painter.width / 2;
    if (alignRight) dx -= painter.width;
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  void _paintEndpoint(Canvas canvas, Offset point, String label) {
    canvas.drawCircle(point, 9, Paint()..color = LosPalette.chartBackground);
    canvas.drawCircle(
      point,
      9,
      Paint()
        ..color = LosPalette.beam
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _paintLabel(canvas, label, Offset(point.dx, point.dy - 5), center: true);
  }

  void _paintPill(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: LosPalette.text,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: painter.width + 12, height: 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, Paint()..color = LosPalette.selected);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _LosProfilePainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.distanceUnit != distanceUnit ||
        oldDelegate.heightUnit != heightUnit ||
        oldDelegate.badgeTextStyle != badgeTextStyle ||
        oldDelegate.terrainLabel != terrainLabel ||
        oldDelegate.losBeamLabel != losBeamLabel ||
        oldDelegate.radioHorizonLabel != radioHorizonLabel ||
        oldDelegate.selectedSampleIndex != selectedSampleIndex;
  }

  void _drawUnitBadge(Canvas canvas, Size size) {
    final span = TextSpan(
      text: '$heightUnit / $distanceUnit',
      style: badgeTextStyle,
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    painter.paint(canvas, Offset(size.width - painter.width - 8, 8));
  }
}

class _LosLegend extends StatelessWidget {
  final String terrainLabel;
  final String losBeamLabel;
  final String radioHorizonLabel;

  const _LosLegend({
    required this.terrainLabel,
    required this.losBeamLabel,
    required this.radioHorizonLabel,
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
      _LegendEntry(terrainLabel, LosPalette.terrain),
      _LegendEntry(losBeamLabel, LosPalette.beam),
      _LegendEntry(radioHorizonLabel, LosPalette.horizon),
      const _LegendEntry('Blocked', LosPalette.blocked),
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
                    color: entry.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(entry.label, style: textStyle),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _LegendEntry {
  final String label;
  final Color color;

  const _LegendEntry(this.label, this.color);
}
