import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart' show AccumulatorSink;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../models/image_codec_support.dart';

/// On-disk storage for image-codec weights.
///
/// Mirrors `translation_file_store_io.dart` 1:1. It is a separate class rather
/// than a reuse of `TranslationFileStore` only because the directory name and
/// the record type differ; see the report for the (small) change that would
/// make the translation store generic enough to share.
class ImageCodecFileStore {
  static final RegExp _chunkFilePattern = RegExp(r'^\..+_chunk_\d+$');

  Future<String> modelDirectoryPath() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/image_codec_models');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<List<ImageCodecModelRecord>> scanDownloadedModels() async {
    final dir = Directory(await modelDirectoryPath());
    if (!dir.existsSync()) {
      return const [];
    }
    final models = <ImageCodecModelRecord>[];
    for (final entity in dir.listSync().whereType<File>()) {
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('.')) {
        // Hidden `.<file>_chunk_<n>` files are the resume state of an
        // interrupted download and MUST survive a restart — reaping them here
        // (as this used to) is what made an 872 MB transfer restart from zero
        // whenever the app was reopened. Anything else hidden is junk.
        if (!_chunkFilePattern.hasMatch(name)) {
          await entity.delete();
        }
        continue;
      }
      final stat = entity.statSync();
      models.add(
        ImageCodecModelRecord(
          id: name,
          name: name,
          sourceUrl: '',
          localPath: entity.path,
          downloadedAt: stat.modified,
          fileSizeBytes: stat.size,
        ),
      );
    }
    return models;
  }

  Future<void> deleteModel(ImageCodecModelRecord model) async {
    await deleteFile(model.localPath);
    await deletePartialDownloads(model.name);
  }

  /// Removes any resume state for [fileName].
  ///
  /// Called after a successful download and when a model is removed. Without it
  /// the chunk files, which [scanDownloadedModels] now deliberately preserves,
  /// would never be collected.
  Future<void> deletePartialDownloads(String fileName) async {
    if (fileName.isEmpty) return;
    final dir = Directory(await modelDirectoryPath());
    if (!dir.existsSync()) return;
    // `.<fileName>[.<totalSize>]_chunk_<n>`. The optional size segment is what
    // `ImageCodecService` appends so resume can never splice offsets computed
    // for one upstream length onto a file of another. Anchored on both ends so
    // sweeping `model.onnx` cannot take `model.onnx.data`'s chunks with it.
    final pattern = RegExp(
      '^\\.${RegExp.escape(fileName)}(\\.\\d+)?_chunk_\\d+\$',
    );
    for (final entity in dir.listSync().whereType<File>()) {
      if (pattern.hasMatch(entity.uri.pathSegments.last)) {
        await entity.delete();
      }
    }
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<DownloadedCodecFile> writeModelBytes({
    required String fileName,
    required Stream<List<int>> chunks,
  }) async {
    final directoryPath = await modelDirectoryPath();
    final file = File('$directoryPath/$fileName');
    final sink = file.openWrite();
    var fileSizeBytes = 0;
    var completed = false;
    try {
      await for (final chunk in chunks) {
        sink.add(chunk);
        fileSizeBytes += chunk.length;
      }
      completed = true;
    } finally {
      await sink.close();
      if (!completed && file.existsSync()) {
        await file.delete();
      }
    }
    return DownloadedCodecFile(
      localPath: file.path,
      fileSizeBytes: fileSizeBytes,
    );
  }

  Future<String> chunkFilePath(String fileName, int index) async {
    final dir = await modelDirectoryPath();
    return '$dir/.${fileName}_chunk_$index';
  }

  Future<String> modelFilePath(String fileName) async {
    final dir = await modelDirectoryPath();
    return '$dir/$fileName';
  }

  /// Size of [path] in bytes, or 0 when it does not exist.
  ///
  /// This is the whole basis of resume: a chunk file's length *is* its progress
  /// marker, so no separate state file can go stale or disagree with the bytes.
  Future<int> fileSize(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return 0;
    }
    return file.length();
  }

  /// Appends [chunks] to [path], creating it if absent.
  ///
  /// Unlike [writeModelBytes] this does NOT delete the file when the stream
  /// fails part-way: the partial bytes are exactly what the next attempt
  /// resumes from. Returns the file's total size afterwards.
  Future<int> appendBytes({
    required String path,
    required Stream<List<int>> chunks,
  }) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final sink = file.openWrite(mode: FileMode.append);
    try {
      await for (final chunk in chunks) {
        sink.add(chunk);
      }
    } finally {
      // flush() inside close(); the bytes written before a failure survive on
      // purpose, so the next Range request can pick up from file.length().
      await sink.close();
    }
    return file.length();
  }

  /// Streaming SHA-256 of [path] as lowercase hex.
  ///
  /// Streamed, not `readAsBytes`: the data sibling is 869 MiB and reading it into
  /// a Uint8List to hash it would defeat the point of downloading it to disk.
  Future<String> sha256OfFile(String path) async {
    final accumulator = AccumulatorSink<Digest>();
    final converter = sha256.startChunkedConversion(accumulator);
    try {
      await for (final chunk in File(path).openRead()) {
        converter.add(chunk);
      }
    } finally {
      converter.close();
    }
    return accumulator.events.single.toString();
  }

  /// Reads an arbitrary file (a picked photo, not a model) as bytes.
  ///
  /// Lives here so `ImageCodecService` never has to import `dart:io` and can
  /// therefore still be constructed on web.
  Future<Uint8List> readFileBytes(String path) => File(path).readAsBytes();

  Future<DownloadedCodecFile> combineChunks({
    required String fileName,
    required List<String> chunkPaths,
  }) async {
    final dir = await modelDirectoryPath();
    final finalPath = '$dir/$fileName';
    final sink = File(finalPath).openWrite();
    var totalSize = 0;
    var completed = false;
    try {
      for (final chunkPath in chunkPaths) {
        final chunkFile = File(chunkPath);
        await sink.addStream(chunkFile.openRead());
        totalSize += await chunkFile.length();
      }
      completed = true;
    } finally {
      await sink.close();
      if (completed) {
        for (final chunkPath in chunkPaths) {
          final file = File(chunkPath);
          if (file.existsSync()) {
            await file.delete();
          }
        }
      } else {
        // Keep the chunk files: they are the resume state. Only the half-written
        // merge target is thrown away. (The previous version deleted the chunks
        // unconditionally, which is why an interrupted 872 MB download restarted
        // from zero.)
        final finalFile = File(finalPath);
        if (finalFile.existsSync()) {
          await finalFile.delete();
        }
      }
    }
    return DownloadedCodecFile(localPath: finalPath, fileSizeBytes: totalSize);
  }

  /// Free bytes are not queryable without a platform channel, so callers that
  /// need a pre-flight space check must supply their own. Kept here as the
  /// documented seam rather than a silent omission: an 833 MB download that
  /// dies at 90% full is the most likely field failure for this feature.
  // TODO(disk): add a free-space pre-flight (needs a platform channel or the
  // `disk_space_plus` package) before enabling the download button.
}

class DownloadedCodecFile {
  final String localPath;
  final int fileSizeBytes;

  const DownloadedCodecFile({
    required this.localPath,
    required this.fileSizeBytes,
  });
}
