import 'dart:async';

import 'package:flutter/foundation.dart';

import '../storage/prefs_manager.dart';

/// Client-side accessibility/UI service that exposes a persistent shared text scale
/// factor. No MeshCoreConnector/RoomServer or protocol interaction occurs, and the
/// value is saved locally via SharedPreferences so it can be reused in Markdown
/// viewers, log panels, or other text-heavy widgets without redundant network
/// dependencies.
///
/// Widgets should scope rebuilds using the snippet below so only the scaled text
/// is rebuilt instead of the entire chat list:
/// ```dart
/// context.select<ChatTextScaleService, double>(
///   (service) => service.scale,
/// )
/// ```
class ChatTextScaleService extends ChangeNotifier {
  static const _prefKey = 'chat_text_scale';
  static const double _minScale = 0.8;
  static const double _maxScale = 1.8;

  double _scale = 1.0;
  Timer? _saveTimer;

  double get scale => _scale;

  Future<void> initialize() async {
    final stored = PrefsManager.instance.getDouble(_prefKey);
    if (stored != null) {
      _scale = _clamp(stored);
    }
  }

  void setScale(double value, {bool persistImmediately = false}) {
    final next = _clamp(value);
    if (next == _scale) return;
    _scale = next;
    notifyListeners();
    if (persistImmediately) {
      _commitScale();
    } else {
      _scheduleSave();
    }
  }

  void reset() {
    setScale(1.0, persistImmediately: true);
  }

  void persist() => _commitScale();

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), _commitScale);
  }

  void _commitScale() {
    _saveTimer?.cancel();
    unawaited(PrefsManager.instance.setDouble(_prefKey, _scale));
  }

  double _clamp(double value) => value.clamp(_minScale, _maxScale).toDouble();
}
