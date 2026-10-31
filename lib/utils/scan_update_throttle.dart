import 'dart:async';

import 'package:flutter/foundation.dart';

class ScanUpdateThrottle {
  ScanUpdateThrottle({
    required this.onNotify,
    this.interval = const Duration(milliseconds: 250),
  });

  final VoidCallback onNotify;
  final Duration interval;
  final Stopwatch _clock = Stopwatch()..start();
  Timer? _timer;
  Duration? _lastNotifiedAt;
  bool _pending = false;

  void schedule() {
    _pending = true;
    if (_timer != null) return;

    final lastNotifiedAt = _lastNotifiedAt;
    if (lastNotifiedAt == null) {
      _publish();
      return;
    }

    final elapsed = _clock.elapsed - lastNotifiedAt;
    final remaining = interval - elapsed;
    if (remaining <= Duration.zero) {
      _publish();
    } else {
      _timer = Timer(remaining, _publish);
    }
  }

  void _publish() {
    _timer = null;
    if (!_pending) return;
    _pending = false;
    _lastNotifiedAt = _clock.elapsed;
    onNotify();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _lastNotifiedAt = null;
    _pending = false;
  }

  void dispose() {
    reset();
    _clock.stop();
  }
}
