import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

import '../models/custom_theme.dart';
import 'platform_info.dart';

/// File extension for exported themes: JSON Lines, one theme per line, each
/// line the same JSON as a theme's share code.
const String kThemeFileExtension = 'jsonl';

const _typeGroup = XTypeGroup(
  label: 'MeshCore themes',
  extensions: [kThemeFileExtension, 'json', 'txt'],
  mimeTypes: [
    'application/jsonl',
    'application/x-ndjson',
    'application/json',
    'text/plain',
    'application/octet-stream',
  ],
  uniformTypeIdentifiers: ['public.json', 'public.plain-text', 'public.data'],
);

/// One theme per line, newline-terminated.
String encodeThemesJsonl(Iterable<CustomTheme> themes) {
  final buffer = StringBuffer();
  for (final theme in themes) {
    buffer.writeln(theme.toShareCode());
  }
  return buffer.toString();
}

/// Reads every valid theme in [text], giving each a fresh ID from [newId].
///
/// Accepts JSON Lines (blank and invalid lines are skipped), and for
/// convenience a single theme object spread over several lines, as a
/// hand-edited or pretty-printed file would be.
List<CustomTheme> decodeThemesJsonl(
  String text, {
  required String Function() newId,
}) {
  final themes = <CustomTheme>[];
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().isEmpty) continue;
    final theme = CustomTheme.fromShareCode(line, newId: newId());
    if (theme != null) themes.add(theme);
  }
  if (themes.isEmpty) {
    final whole = CustomTheme.fromShareCode(text, newId: newId());
    if (whole != null) themes.add(whole);
  }
  return themes;
}

/// A safe file name stem for [name] (letters, digits, dashes).
String themeFileStem(String name) {
  final stem = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return stem.isEmpty ? 'theme' : stem;
}

enum ThemeFileResult { saved, cancelled, failed }

/// Saves [themes] as a `.jsonl` file: a save dialog on desktop, a download
/// on web, and the share sheet on phones (which have no save dialog).
Future<ThemeFileResult> exportThemesFile(
  List<CustomTheme> themes, {
  required String fileStem,
  Rect? sharePositionOrigin,
}) async {
  final fileName = '$fileStem.$kThemeFileExtension';
  final bytes = Uint8List.fromList(utf8.encode(encodeThemesJsonl(themes)));
  final file = XFile.fromData(
    bytes,
    name: fileName,
    mimeType: 'application/jsonl',
  );
  try {
    if (PlatformInfo.isWeb) {
      await file.saveTo(fileName);
      return ThemeFileResult.saved;
    }
    if (PlatformInfo.isDesktop) {
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [_typeGroup],
      );
      if (location == null) return ThemeFileResult.cancelled;
      await file.saveTo(location.path);
      return ThemeFileResult.saved;
    }
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [fileName],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return result.status == ShareResultStatus.dismissed
        ? ThemeFileResult.cancelled
        : ThemeFileResult.saved;
  } catch (_) {
    return ThemeFileResult.failed;
  }
}

/// Lets the user pick a theme file and returns its text, or null when they
/// cancel. Throws when the file cannot be read.
Future<String?> pickThemesFile() async {
  final file = await openFile(acceptedTypeGroups: const [_typeGroup]);
  if (file == null) return null;
  return utf8.decode(await file.readAsBytes(), allowMalformed: true);
}
