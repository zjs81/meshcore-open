import 'package:shared_preferences/shared_preferences.dart';

import 'history_store.dart';

/// Singleton wrapper for SharedPreferences to avoid redundant getInstance() calls.
///
/// BEFORE: Every storage operation called SharedPreferences.getInstance()
/// AFTER: Single getInstance() on app startup, reused throughout lifecycle
///
/// This eliminates 30+ redundant platform channel calls across the app.
class PrefsManager {
  PrefsManager._();

  static SharedPreferences? _instance;

  /// Initialize the cached instance. Call this once during app startup in main().
  static Future<void> initialize() async {
    _instance ??= await SharedPreferences.getInstance();
  }

  /// Get the cached SharedPreferences instance.
  /// Throws StateError if initialize() hasn't been called.
  static SharedPreferences get instance {
    if (_instance == null) {
      throw StateError(
        'PrefsManager not initialized. Call PrefsManager.initialize() in main() before use.',
      );
    }
    return _instance!;
  }

  /// For testing: reset the instance
  static void reset() {
    _instance = null;
    HistoryStore.reset();
  }
}
