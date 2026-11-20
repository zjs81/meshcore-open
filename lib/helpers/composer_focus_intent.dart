import 'dart:async';

import 'package:flutter/widgets.dart';

/// Tells the user focusing the chat composer apart from Flutter handing focus
/// back after an app switch or after a sheet, dialog or menu closes.
///
/// On desktop and web the focus manager takes focus off the composer when the
/// window goes inactive and puts it back on resume. That is not the user
/// starting to type, so the chat must not jump to the newest message and lose
/// the reading position. Mobile keeps focus across an app switch. On every
/// platform a sheet, dialog or menu opened over the chat takes focus and the
/// composer gets it back when that closes, which is not a tap either.
class ComposerFocusIntent with WidgetsBindingObserver {
  ComposerFocusIntent() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool _lostWhileAway = false;
  bool _lostToRoute = false;

  /// Call from the composer focus node's listener. Returns true when focus
  /// was just gained by a tap or by app code, false for a loss of focus or a
  /// focus restored on resume or when a route on top closes.
  ///
  /// [coveredByRoute] is whether the chat's route is no longer the current
  /// one (a sheet, dialog or menu is open on top).
  bool isUserFocusGain(bool hasFocus, {bool coveredByRoute = false}) {
    if (!hasFocus) {
      final state = WidgetsBinding.instance.lifecycleState;
      _lostWhileAway = state != null && state != AppLifecycleState.resumed;
      _lostToRoute = coveredByRoute;
      return false;
    }
    final restored = _lostWhileAway || _lostToRoute;
    _lostWhileAway = false;
    _lostToRoute = false;
    return !restored;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // The focus manager observes the lifecycle from app start, so its restore
    // is already queued and runs first. Clearing afterwards keeps a focus
    // that was not restored (the user clicked elsewhere) from swallowing the
    // next real tap on the composer.
    scheduleMicrotask(() => _lostWhileAway = false);
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
