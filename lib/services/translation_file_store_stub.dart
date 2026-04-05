import '../models/translation_support.dart';

class TranslationFileStore {
  Future<String> modelDirectoryPath() async {
    throw UnsupportedError('Local model storage is not supported on web.');
  }

  Future<List<TranslationModelRecord>> scanDownloadedModels() async {
    return const [];
  }

  Future<void> deleteModel(TranslationModelRecord model) async {}

  Future<void> deleteFile(String path) async {}

  Future<DownloadedModelFile> writeModelBytes({
    required String fileName,
    required Stream<List<int>> chunks,
  }) async {
    throw UnsupportedError('Local model downloads are not supported on web.');
  }

  Future<String> chunkFilePath(String fileName, int index) async {
    throw UnsupportedError('Local model downloads are not supported on web.');
  }

  Future<DownloadedModelFile> combineChunks({
    required String fileName,
    required List<String> chunkPaths,
  }) async {
    throw UnsupportedError('Local model downloads are not supported on web.');
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
