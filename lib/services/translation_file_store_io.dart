import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/translation_support.dart';

class TranslationFileStore {
  Future<String> modelDirectoryPath() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/translation_models');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<List<TranslationModelRecord>> scanDownloadedModels() async {
    final dir = Directory(await modelDirectoryPath());
    if (!dir.existsSync()) {
      return const [];
    }
    final models = <TranslationModelRecord>[];
    for (final entity in dir.listSync().whereType<File>()) {
      final name = entity.uri.pathSegments.last;
      // Skip hidden chunk files from interrupted parallel downloads.
      if (name.startsWith('.')) {
        await entity.delete();
        continue;
      }
      final stat = entity.statSync();
      models.add(
        TranslationModelRecord(
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

  Future<void> deleteModel(TranslationModelRecord model) async {
    await deleteFile(model.localPath);
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<DownloadedModelFile> writeModelBytes({
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
    return DownloadedModelFile(
      localPath: file.path,
      fileSizeBytes: fileSizeBytes,
    );
  }

  Future<String> chunkFilePath(String fileName, int index) async {
    final dir = await modelDirectoryPath();
    return '$dir/.${fileName}_chunk_$index';
  }

  Future<DownloadedModelFile> combineChunks({
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
      for (final chunkPath in chunkPaths) {
        final file = File(chunkPath);
        if (file.existsSync()) {
          await file.delete();
        }
      }
      if (!completed) {
        final finalFile = File(finalPath);
        if (finalFile.existsSync()) {
          await finalFile.delete();
        }
      }
    }
    return DownloadedModelFile(localPath: finalPath, fileSizeBytes: totalSize);
  }
}

class DownloadedModelFile {
  final String localPath;
  final int fileSizeBytes;

  const DownloadedModelFile({
    required this.localPath,
    required this.fileSizeBytes,
  });
}
