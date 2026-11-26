import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/platform_info.dart';
import 'notification_service.dart';

/// On Android the Flutter engine outlives its activity while the background
/// service runs (app swiped away). A new activity starts with fresh native
/// state, so the first resume after `detached` sets it up again.
class ActivityReattach {
  bool _detached = false;

  /// System UI mode the app uses, set at start and again after a reattach.
  static Future<void> applySystemUiMode() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!PlatformInfo.isAndroid) return;
    if (state == AppLifecycleState.detached) {
      _detached = true;
      return;
    }
    if (state != AppLifecycleState.resumed || !_detached) return;
    _detached = false;
    // A new activity starts with its back callback off, and the framework
    // only updates it on the next route change. On a root route Flutter
    // hands the back gesture to the system, so true is safe there too.
    unawaited(SystemNavigator.setFrameworkHandlesBack(true));
    unawaited(applySystemUiMode());
    await NotificationService().routeLaunchTap();
  }
}
