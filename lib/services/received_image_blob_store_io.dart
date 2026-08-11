/// File-backed [ReceivedImageBlobStore] for every platform that has `dart:io`.
///
/// Without this, `ReceivedImageStore` falls back to
/// [InMemoryReceivedImageBlobStore] and every received image is forgotten at
/// the next app launch — the sidecars go with the bytes, so even the "this
/// message was an image" record disappears.
///
/// ## Layout
///
/// ```
/// <application support>/received_images/
///     <streamId>.aeic   the ~156 B bitstream
///     <streamId>.png    the decoded 512x512 PNG (~400 KB)
///     <streamId>.json   the sidecar record (ReceivedImageEntry.toJson)
///     <streamId>.json.tmp   transient; only during an atomic sidecar write
/// ```
///
/// Application *support*, not documents: these are derived caches of a chat
/// message, not user documents, so they must not show up in the iOS Files app
/// or be swept into an iCloud backup.
///
/// ## Guarantees
///
///   * Sidecar writes are atomic (tmp file + rename). A kill mid-write can
///     leave `<id>.json.tmp` but never a truncated `<id>.json`, so
///     [readSidecars] never has to defend against half a JSON object.
///   * Every method is total: a missing file reads as null and deletes are
///     idempotent. I/O errors are swallowed and reported through the return
///     value, because a failed write must degrade the image, not crash the
///     receive path.
///   * [readSidecars] sweeps orphans — `.aeic`/`.png`/`.tmp` files with no
///     surviving `.json` — so a crash between "write bitstream" and "write
///     sidecar" cannot leak bytes that no budget accounts for.
///   * Stream ids are validated before they are ever concatenated into a path;
///     a hostile `../../` id cannot escape the directory.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';

import 'received_image_store.dart';

/// Persists received-image bytes under the application support directory.
class FileReceivedImageBlobStore implements ReceivedImageBlobStore {
  /// Only `[A-Za-z0-9_-]`, so a stream id can never contain `/`, `\` or `..`.
  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static const String _bitstreamExt = '.aeic';
  static const String _pngExt = '.png';
  static const String _sidecarExt = '.json';
  static const String _tmpExt = '.json.tmp';

  /// Overridable so tests (and any future "move my data" feature) can point the
  /// store at a temp directory instead of the real support directory.
  final Future<Directory> Function() _baseDirectory;

  final String directoryName;

  /// Resolved lazily and then cached, because [pngPath] has to be synchronous
  /// (the share sheet needs a path inside a build/callback) while
  /// `path_provider` is not.
  String? _dirPath;
  Future<String>? _pending;

  FileReceivedImageBlobStore({
    Future<Directory> Function()? baseDirectory,
    this.directoryName = 'received_images',
  }) : _baseDirectory = baseDirectory ?? getApplicationSupportDirectory;

  /// Resolves and creates the directory. Safe to call repeatedly; concurrent
  /// callers share one future so the directory is created exactly once.
  Future<String> ensureReady() {
    final cached = _dirPath;
    if (cached != null) return Future<String>.value(cached);
    final pending = _pending;
    if (pending != null) return pending;
    final started = _resolve();
    _pending = started;
    return started.whenComplete(() => _pending = null);
  }

  Future<String> _resolve() async {
    final base = await _baseDirectory();
    final dir = Directory(
      '${base.path}${Platform.pathSeparator}$directoryName',
    );
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _dirPath = dir.path;
    return dir.path;
  }

  Future<String?> _pathFor(String streamId, String extension) async {
    if (!_safeId.hasMatch(streamId)) return null;
    final dir = await ensureReady();
    return '$dir${Platform.pathSeparator}$streamId$extension';
  }

  Future<Uint8List?> _read(String streamId, String extension) async {
    try {
      final path = await _pathFor(streamId, extension);
      if (path == null) return null;
      final file = File(path);
      if (!file.existsSync()) return null;
      return await file.readAsBytes();
    } catch (error) {
      debugPrint('received_image_blob_store: read $streamId$extension: $error');
      return null;
    }
  }

  Future<void> _write(
    String streamId,
    String extension,
    Uint8List bytes,
  ) async {
    try {
      final path = await _pathFor(streamId, extension);
      if (path == null) {
        debugPrint('received_image_blob_store: refusing unsafe id "$streamId"');
        return;
      }
      await File(path).writeAsBytes(bytes, flush: true);
    } catch (error) {
      debugPrint(
        'received_image_blob_store: write $streamId$extension: $error',
      );
    }
  }

  Future<void> _delete(String streamId, String extension) async {
    try {
      final path = await _pathFor(streamId, extension);
      if (path == null) return;
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (error) {
      debugPrint(
        'received_image_blob_store: delete $streamId$extension: $error',
      );
    }
  }

  Future<int?> _size(String streamId, String extension) async {
    try {
      final path = await _pathFor(streamId, extension);
      if (path == null) return null;
      final file = File(path);
      if (!file.existsSync()) return null;
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeBitstream(String streamId, Uint8List bytes) =>
      _write(streamId, _bitstreamExt, bytes);

  @override
  Future<Uint8List?> readBitstream(String streamId) =>
      _read(streamId, _bitstreamExt);

  @override
  Future<void> deleteBitstream(String streamId) =>
      _delete(streamId, _bitstreamExt);

  @override
  Future<int?> bitstreamSize(String streamId) => _size(streamId, _bitstreamExt);

  @override
  Future<void> writePng(String streamId, Uint8List bytes) =>
      _write(streamId, _pngExt, bytes);

  @override
  Future<Uint8List?> readPng(String streamId) => _read(streamId, _pngExt);

  @override
  Future<void> deletePng(String streamId) => _delete(streamId, _pngExt);

  @override
  Future<int?> pngSize(String streamId) => _size(streamId, _pngExt);

  /// Atomic: write `<id>.json.tmp`, then rename over `<id>.json`. `rename` is
  /// atomic within a directory on every platform we ship, so a reader either
  /// sees the old record or the new one.
  @override
  Future<void> writeSidecar(String streamId, String json) async {
    try {
      final finalPath = await _pathFor(streamId, _sidecarExt);
      final tmpPath = await _pathFor(streamId, _tmpExt);
      if (finalPath == null || tmpPath == null) {
        debugPrint('received_image_blob_store: refusing unsafe id "$streamId"');
        return;
      }
      final tmp = File(tmpPath);
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(finalPath);
    } catch (error) {
      debugPrint('received_image_blob_store: sidecar $streamId: $error');
    }
  }

  @override
  Future<void> deleteSidecar(String streamId) async {
    await _delete(streamId, _sidecarExt);
    await _delete(streamId, _tmpExt);
  }

  /// Startup scan. Also the only place orphaned bytes are reaped: anything
  /// whose sidecar is gone is invisible to the store and therefore to the
  /// disk budget, so it would live forever.
  @override
  Future<Map<String, String>> readSidecars() async {
    final result = <String, String>{};
    late final String dirPath;
    try {
      dirPath = await ensureReady();
    } catch (error) {
      debugPrint('received_image_blob_store: no directory: $error');
      return result;
    }
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return result;

    final files = <File>[];
    try {
      files.addAll(dir.listSync().whereType<File>());
    } catch (error) {
      debugPrint('received_image_blob_store: list failed: $error');
      return result;
    }

    final orphans = <File>[];
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      if (name.endsWith(_tmpExt)) {
        // A kill during a sidecar write. The previous `.json` (if any) is
        // still authoritative.
        orphans.add(file);
        continue;
      }
      if (!name.endsWith(_sidecarExt)) continue;
      final id = name.substring(0, name.length - _sidecarExt.length);
      if (!_safeId.hasMatch(id)) continue;
      try {
        final raw = await file.readAsString();
        // Cheap sanity gate: the store's own jsonDecode would skip it anyway,
        // but a truncated record here means we should reap its bytes too.
        jsonDecode(raw);
        result[id] = raw;
      } catch (error) {
        debugPrint('received_image_blob_store: bad sidecar $id: $error');
      }
    }

    for (final file in files) {
      final name = file.uri.pathSegments.last;
      if (name.endsWith(_sidecarExt) || name.endsWith(_tmpExt)) continue;
      final dot = name.lastIndexOf('.');
      if (dot <= 0) continue;
      final id = name.substring(0, dot);
      final ext = name.substring(dot);
      if (ext != _bitstreamExt && ext != _pngExt) continue;
      if (result.containsKey(id)) continue;
      orphans.add(file);
    }

    for (final file in orphans) {
      try {
        if (file.existsSync()) await file.delete();
      } catch (_) {
        // Best effort; a locked file is retried on the next launch.
      }
    }
    return result;
  }

  /// Null until [ensureReady] (or any async method) has resolved the directory.
  /// In practice `ReceivedImageStore.load()` runs at startup and resolves it
  /// long before any bubble asks for a path.
  @override
  String? pngPath(String streamId) {
    final dir = _dirPath;
    if (dir == null) return null;
    if (!_safeId.hasMatch(streamId)) return null;
    return '$dir${Platform.pathSeparator}$streamId$_pngExt';
  }
}
