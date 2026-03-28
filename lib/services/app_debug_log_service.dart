import 'package:flutter/foundation.dart';

enum AppDebugLogLevel { info, warning, error }

class AppDebugLogEntry {
  final DateTime timestamp;
  final AppDebugLogLevel level;
  final String tag;
  final String message;

  AppDebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get levelLabel {
    switch (level) {
      case AppDebugLogLevel.info:
        return 'INFO';
      case AppDebugLogLevel.warning:
        return 'WARN';
      case AppDebugLogLevel.error:
        return 'ERROR';
    }
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
}

class AppDebugLogService extends ChangeNotifier {
  static const int maxEntries = 1000;
  final List<AppDebugLogEntry> _entries = [];
  bool _enabled = false;

  List<AppDebugLogEntry> get entries => List.unmodifiable(_entries);
  bool get enabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
    notifyListeners();
  }

  void log(
    String message, {
    String tag = 'App',
    AppDebugLogLevel level = AppDebugLogLevel.info,
    bool noNotify = false,
  }) {
    if (!_enabled && !kDebugMode) return;
    if (!_enabled) {
      // In debug mode, still print to console but don't store entries.
      debugPrint('[$tag] $message');
      return;
    }

    _entries.add(
      AppDebugLogEntry(
        timestamp: DateTime.now(),
        level: level,
        tag: tag,
        message: message,
      ),
    );

    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }

    if (!noNotify) {
      notifyListeners();
    }

    // Also print to console for development
    debugPrint('[$tag] $message');
  }

  void info(String message, {String tag = 'App', bool noNotify = false}) {
    log(message, tag: tag, level: AppDebugLogLevel.info, noNotify: noNotify);
  }

  void warn(String message, {String tag = 'App', bool noNotify = false}) {
    log(message, tag: tag, level: AppDebugLogLevel.warning, noNotify: noNotify);
  }

  void error(String message, {String tag = 'App', bool noNotify = false}) {
    log(message, tag: tag, level: AppDebugLogLevel.error, noNotify: noNotify);
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
