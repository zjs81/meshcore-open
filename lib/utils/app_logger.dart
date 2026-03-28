import '../services/app_debug_log_service.dart';

/// Global app logger instance
/// Usage: appLogger.info('Message', tag: 'MyClass');
class AppLogger {
  AppDebugLogService? _service;
  bool _enabled = false;

  /// Initialize the logger with the debug log service
  void initialize(AppDebugLogService service, {bool enabled = false}) {
    _service = service;
    _enabled = enabled;
    _service?.setEnabled(enabled);
  }

  /// Update whether logging is enabled
  void setEnabled(bool enabled) {
    _enabled = enabled;
    _service?.setEnabled(enabled);
  }

  /// Check if logging is currently enabled
  bool get isEnabled => _enabled;

  /// Log an info message
  void info(String message, {String tag = 'App', bool noNotify = false}) {
    if (_enabled && _service != null) {
      _service!.info(message, tag: tag, noNotify: noNotify);
    }
  }

  /// Log a warning message
  void warn(String message, {String tag = 'App', bool noNotify = false}) {
    if (_enabled && _service != null) {
      _service!.warn(message, tag: tag, noNotify: noNotify);
    }
  }

  /// Log an error message
  void error(String message, {String tag = 'App', bool noNotify = false}) {
    if (_enabled && _service != null) {
      _service!.error(message, tag: tag, noNotify: noNotify);
    }
  }

  /// Log a message with custom level
  void log(
    String message, {
    String tag = 'App',
    AppDebugLogLevel level = AppDebugLogLevel.info,
    bool noNotify = false,
  }) {
    if (_enabled && _service != null) {
      _service!.log(message, tag: tag, level: level, noNotify: noNotify);
    }
  }
}

/// Global logger instance
final appLogger = AppLogger();
