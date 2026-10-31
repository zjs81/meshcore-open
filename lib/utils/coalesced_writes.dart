import 'dart:async';

import 'app_logger.dart';

/// Collapses repeated persistence requests for the same key into one write.
///
/// Busy meshes deliver many frames a second, and each one used to rewrite a
/// whole JSON blob (a channel's history, the contact list). Every write is a
/// full re-encode plus a SharedPreferences write: on Linux/Windows that
/// rewrites the entire prefs file synchronously, on Android/iOS it ships the
/// blob across the platform channel. Scheduling instead keeps only the latest
/// writer per key and runs them all once [delay] after the first request.
class CoalescedWrites {
  CoalescedWrites({this.delay = const Duration(milliseconds: 750)});

  final Duration delay;
  final Map<String, Future<void> Function()> _pending = {};
  Timer? _timer;

  bool get hasPending => _pending.isNotEmpty;

  /// Queues [write] under [key], replacing any write already queued for it.
  /// [write] should read the current state when it runs, not a snapshot.
  void schedule(String key, Future<void> Function() write) {
    _pending[key] = write;
    _timer ??= Timer(delay, () => unawaited(flush()));
  }

  /// Drops the queued write for [key], e.g. because an immediate write of
  /// newer state or a delete just superseded it.
  void cancel(String key) {
    _pending.remove(key);
  }

  /// Runs every queued write now. All writes are started synchronously before
  /// the first await, so a store that reads its scoped key on entry still sees
  /// the key that was current when the write was queued.
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    if (_pending.isEmpty) return Future<void>.value();
    final writes = _pending.values.toList();
    _pending.clear();
    // Callers fire and forget, so a failed write is logged rather than left
    // as an unhandled async error, and never stops the other writes.
    final futures = <Future<void>>[];
    for (final write in writes) {
      try {
        futures.add(write().catchError(_logFailure));
      } catch (error) {
        _logFailure(error);
      }
    }
    return Future.wait(futures).then((_) {});
  }

  static void _logFailure(Object error) {
    appLogger.warn('Coalesced write failed: $error', tag: 'Storage');
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending.clear();
  }
}
