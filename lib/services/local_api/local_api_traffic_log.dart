import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../utils/app_logger.dart';

/// One line per Local API send and received channel-data frame, for checking
/// field tests afterwards: ISO time in UTC, then `key=value` pairs.
///
/// Lines go to the app debug log (tag `LocalApiTraffic`, when it is on) and
/// to `local_api/traffic.log`, at most two files of [maxBytes]. On Android
/// the file is in the app's external files directory, so
/// `adb pull /sdcard/Android/data/<package>/files/local_api/traffic.log`
/// reads it from a release build. It holds no payloads or message texts.
class LocalApiTrafficLog {
  static const int maxBytes = 512 * 1024;

  final Future<Directory?> Function() _directory;
  Future<void> _tail = Future<void>.value();
  File? _file;

  LocalApiTrafficLog({Future<Directory?> Function()? directory})
    : _directory = directory ?? _defaultDirectory;

  static Future<Directory?> _defaultDirectory() async {
    Directory? base;
    try {
      if (Platform.isAndroid) base = await getExternalStorageDirectory();
      base ??= await getApplicationSupportDirectory();
    } catch (_) {
      return null;
    }
    return Directory('${base.path}/local_api');
  }

  /// Writes `<time> <event> <fields>`; null values are left out.
  void write(String event, Map<String, Object?> fields, {DateTime? at}) {
    final time = (at ?? DateTime.now()).toUtc().toIso8601String();
    final parts = [
      time,
      event,
      for (final entry in fields.entries)
        if (entry.value != null) '${entry.key}=${_value(entry.value!)}',
    ];
    final line = parts.join(' ');
    appLogger.info(line, tag: 'LocalApiTraffic', noNotify: true);
    _tail = _tail.then((_) => _append(line)).catchError((_) {});
  }

  static String _value(Object value) {
    final text = value.toString();
    return text.contains(RegExp(r'\s')) ? '"$text"' : text;
  }

  Future<void> _append(String line) async {
    var file = _file;
    if (file == null) {
      final dir = await _directory();
      if (dir == null) return;
      await dir.create(recursive: true);
      file = _file = File('${dir.path}/traffic.log');
    }
    if (await file.exists() && await file.length() > maxBytes) {
      await file.rename('${file.path}.1');
    }
    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
  }

  /// Completes when the lines written so far are on disk (tests).
  Future<void> flush() => _tail;
}
