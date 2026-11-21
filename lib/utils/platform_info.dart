import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'browser_detection.dart';

/// Utility class to safely check the current platform across web and native.
///
/// Using `Platform` from `dart:io` directly on Web causes a crash.
/// This class handles the `kIsWeb` check first to avoid those crashes.
class PlatformInfo {
  /// Whether the app is running in a web browser.
  static bool get isWeb => kIsWeb;

  /// Whether the app is running in the Chrome browser (only relevant if [isWeb] is true).
  static bool get isChrome => isWeb && BrowserDetection.isChrome;

  /// Whether the app is running on Android.
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Whether the app is running on iOS.
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Whether the app is running on macOS.
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Whether the app is running on Windows.
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Whether the app is running on Linux.
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Whether the app is running on a mobile platform (Android or iOS).
  static bool get isMobile => isAndroid || isIOS;

  /// Whether the app is running on a desktop platform (macOS, Windows, or Linux).
  static bool get isDesktop =>
      debugIsDesktopOverride ?? (isMacOS || isWindows || isLinux);

  /// Lets widget tests exercise the mobile layout on a desktop test host.
  @visibleForTesting
  static bool? debugIsDesktopOverride;

  /// Whether the current platform supports a native USB serial backend.
  static bool get supportsNativeUsbSerial =>
      isAndroid || isWindows || isLinux || isMacOS;

  /// Whether the current browser supports the Web Serial backend.
  static bool get supportsWebSerial => isWeb && isChrome;

  /// Whether USB serial is expected to be available on the current platform.
  static bool get supportsUsbSerial =>
      supportsNativeUsbSerial || supportsWebSerial;
}
