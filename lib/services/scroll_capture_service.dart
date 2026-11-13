import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/platform_info.dart';

/// Dart half of Android's scrolling screenshot ("Capture more").
///
/// The native `FlutterScrollCapture` asks for the main scrollable on screen,
/// then has it scrolled strip by strip while it copies pixels. All sizes on
/// the channel are physical pixels in the Flutter view.
class ScrollCaptureService {
  ScrollCaptureService._();

  static const MethodChannel _channel = MethodChannel(
    'meshcore_open/scroll_capture',
  );

  static ScrollableState? _target;
  static double _startPixels = 0;

  static void initialize() {
    if (kIsWeb || !PlatformInfo.isAndroid) return;
    _channel.setMethodCallHandler(_handle);
  }

  static Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'search':
        return _search();
      case 'start':
        _startPixels = _target?.position.pixels ?? 0;
        return null;
      case 'scroll':
        final args = call.arguments as Map<Object?, Object?>;
        return _scrollTo((args['top'] as num).toDouble());
      case 'end':
        final target = _target;
        _target = null;
        if (target != null && target.mounted) {
          target.position.jumpTo(_startPixels);
        }
        return null;
    }
    return null;
  }

  static FlutterView? get _view =>
      WidgetsBinding.instance.platformDispatcher.implicitView;

  /// The largest vertically scrollable, user-visible list on the top route.
  static Map<String, int>? _search() {
    final view = _view;
    final root = WidgetsBinding.instance.rootElement;
    if (view == null || root == null) return null;
    final dpr = view.devicePixelRatio;
    final screen = Offset.zero & (view.physicalSize / dpr);

    ScrollableState? best;
    Rect? bestRect;
    void visit(Element element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final state = element.state as ScrollableState;
        final rect = _candidateRect(state, element.renderObject, screen, view);
        if (rect != null &&
            (bestRect == null ||
                rect.width * rect.height >=
                    bestRect!.width * bestRect!.height)) {
          best = state;
          bestRect = rect;
        }
      }
      element.visitChildren(visit);
    }

    root.visitChildren(visit);
    final rect = bestRect;
    _target = best;
    if (best == null || rect == null) return null;
    return {
      'left': (rect.left * dpr).round(),
      'top': (rect.top * dpr).round(),
      'right': (rect.right * dpr).round(),
      'bottom': (rect.bottom * dpr).round(),
    };
  }

  static Rect? _candidateRect(
    ScrollableState state,
    RenderObject? renderObject,
    Rect screen,
    FlutterView view,
  ) {
    if (axisDirectionToAxis(state.axisDirection) != Axis.vertical) return null;
    final position = state.position;
    if (!position.hasContentDimensions ||
        position.maxScrollExtent <= position.minScrollExtent) {
      return null;
    }
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    final rect = MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      Offset.zero & renderObject.size,
    ).intersect(screen);
    if (rect.isEmpty || rect.height < 100) return null;
    // Only a list the user can actually see: the topmost hit at its centre
    // must be inside it (rules out lists on routes underneath, or covered
    // by a sheet or dialog).
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, rect.center, view.viewId);
    if (!result.path.any((entry) => entry.target == renderObject)) return null;
    return rect;
  }

  /// Scrolls so the strip starting [top] physical px below the start
  /// position's top edge is at the top of the list, as far as the content
  /// allows. Returns how far it actually moved, in physical px.
  static Future<double> _scrollTo(double top) async {
    final target = _target;
    final view = _view;
    if (target == null || !target.mounted || view == null) return 0;
    final dpr = view.devicePixelRatio;
    final position = target.position;
    // In a reversed list (the chat transcript) moving down the screen means
    // smaller scroll offsets.
    final up = target.axisDirection == AxisDirection.up;
    final delta = top / dpr;
    final wanted = (up ? _startPixels - delta : _startPixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    position.jumpTo(wanted);
    // Bounded: if frames are not being produced (app no longer resumed),
    // waiting forever would leave the native capture request hanging.
    for (var i = 0; i < 2; i++) {
      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(milliseconds: 250),
        onTimeout: () {},
      );
    }
    if (!target.mounted) return 0;
    final moved = up
        ? _startPixels - position.pixels
        : position.pixels - _startPixels;
    return moved * dpr;
  }
}
