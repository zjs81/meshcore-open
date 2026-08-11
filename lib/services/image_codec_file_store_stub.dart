import 'dart:typed_data';

import '../models/image_codec_support.dart';

class ImageCodecFileStore {
  Future<String> modelDirectoryPath() async {
    throw UnsupportedError(
      'Local codec model storage is not supported on web.',
    );
  }

  Future<List<ImageCodecModelRecord>> scanDownloadedModels() async {
    return const [];
  }

  Future<void> deleteModel(ImageCodecModelRecord model) async {}

  Future<void> deleteFile(String path) async {}

  Future<DownloadedCodecFile> writeModelBytes({
    required String fileName,
    required Stream<List<int>> chunks,
  }) async {
    throw UnsupportedError(
      'Local codec model storage is not supported on web.',
    );
  }

  Future<String> chunkFilePath(String fileName, int index) async {
    throw UnsupportedError(
      'Local codec model storage is not supported on web.',
    );
  }

  Future<String> modelFilePath(String fileName) async {
    throw UnsupportedError(
      'Local codec model storage is not supported on web.',
    );
  }

  Future<void> deletePartialDownloads(String fileName) async {}

  Future<int> fileSize(String path) async => 0;

  Future<int> appendBytes({
    required String path,
    required Stream<List<int>> chunks,
  }) async {
    throw UnsupportedError(
      'Local codec model storage is not supported on web.',
    );
  }

  Future<String> sha256OfFile(String path) async {
    throw UnsupportedError(
      'Local codec model storage is not supported on web.',
    );
  }

  Future<Uint8List> readFileBytes(String path) async {
    throw UnsupportedError('Local file reads are not supported on web.');
  }

  Future<DownloadedCodecFile> combineChunks({
    required String fileName,
    required List<String> chunkPaths,
  }) async {
    throw UnsupportedError(
      'Local codec model storage is not supported on web.',
    );
  }
}

class DownloadedCodecFile {
  final String localPath;
  final int fileSizeBytes;

  const DownloadedCodecFile({
    required this.localPath,
    required this.fileSizeBytes,
  });
}
