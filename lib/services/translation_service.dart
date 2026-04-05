import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:llamadart/llamadart.dart';

import '../models/app_settings.dart';
import '../models/translation_support.dart';
import '../utils/app_logger.dart';
import 'app_settings_service.dart';
import 'translation_file_store.dart';

class TranslationResult {
  final String translatedText;
  final String targetLanguageCode;
  final String? detectedLanguageCode;
  final String? modelId;
  final MessageTranslationStatus status;

  const TranslationResult({
    required this.translatedText,
    required this.targetLanguageCode,
    required this.status,
    this.detectedLanguageCode,
    this.modelId,
  });
}

class TranslationDownloadCancelled implements Exception {
  const TranslationDownloadCancelled();

  @override
  String toString() => 'Download canceled.';
}

class TranslationService extends ChangeNotifier {
  final AppSettingsService _appSettingsService;
  final TranslationFileStore _fileStore;

  TranslationService(
    this._appSettingsService, {
    TranslationFileStore? fileStore,
  }) : _fileStore = fileStore ?? TranslationFileStore();

  bool _isBusy = false;
  bool _isDownloading = false;
  bool _cancelDownloadRequested = false;
  String? _lastError;
  Future<void> _queue = Future<void>.value();
  LlamaEngine? _engine;
  String? _loadedModelPath;
  String? _failedModelPath;
  int _downloadedBytes = 0;
  int? _downloadTotalBytes;
  String? _downloadFileName;

  bool get isBusy => _isBusy;
  bool get isDownloading => _isDownloading;
  String? get lastError => _lastError;
  int get downloadedBytes => _downloadedBytes;
  int? get downloadTotalBytes => _downloadTotalBytes;
  String? get downloadFileName => _downloadFileName;
  double? get downloadProgress {
    final total = _downloadTotalBytes;
    if (!_isDownloading || total == null || total <= 0) {
      return null;
    }
    return (_downloadedBytes / total).clamp(0.0, 1.0);
  }

  AppSettings get _settings => _appSettingsService.settings;

  String? resolvedTargetLanguageCode(String? fallbackLanguageCode) {
    return _settings.translationTargetLanguageCode ??
        _settings.languageOverride ??
        fallbackLanguageCode;
  }

  String? resolvedIncomingLanguageCode(String? fallbackLanguageCode) {
    return _settings.translationTargetLanguageCode ??
        _settings.languageOverride ??
        fallbackLanguageCode ??
        'en';
  }

  bool shouldTranslateIncoming({
    required String text,
    required bool isCli,
    required bool isOutgoing,
  }) {
    if (!_settings.translationEnabled || isCli || isOutgoing) {
      return false;
    }
    return _isPlainTextEligible(text);
  }

  bool shouldTranslateOutgoing({
    required String text,
    required String? targetLanguageCode,
  }) {
    return _settings.composerTranslationEnabled &&
        targetLanguageCode != null &&
        targetLanguageCode.isNotEmpty &&
        _isPlainTextEligible(text);
  }

  List<TranslationModelRecord> get availableModels =>
      _settings.translationDownloadedModels;

  TranslationModelRecord? get selectedModel {
    final selectedId = _settings.translationSelectedModelId;
    if (selectedId == null) {
      return availableModels.isNotEmpty ? availableModels.first : null;
    }
    for (final model in availableModels) {
      if (model.id == selectedId) {
        return model;
      }
    }
    return availableModels.isNotEmpty ? availableModels.first : null;
  }

  Future<void> refreshDownloadedModels() async {
    if (_isDownloading) return;
    final scanned = await _fileStore.scanDownloadedModels();
    if (scanned.isEmpty) {
      return;
    }
    final existingByPath = {
      for (final model in _settings.translationDownloadedModels)
        model.localPath: model,
    };
    final merged = scanned.map((model) {
      final existing = existingByPath[model.localPath];
      if (existing == null) {
        return model;
      }
      return TranslationModelRecord(
        id: existing.id,
        name: existing.name,
        sourceUrl: existing.sourceUrl,
        localPath: existing.localPath,
        downloadedAt: existing.downloadedAt,
        fileSizeBytes: model.fileSizeBytes,
      );
    }).toList();
    await _appSettingsService.setTranslationDownloadedModels(merged);
    _failedModelPath = null;
    if (_settings.translationSelectedModelId == null && merged.isNotEmpty) {
      await _appSettingsService.setTranslationSelectedModelId(merged.first.id);
    }
  }

  static const int _parallelChunks = 8;
  static const int _parallelMinBytes = 10 * 1024 * 1024; // 10 MB

  Future<TranslationModelRecord> downloadModel({
    required String sourceUrl,
    String? fileName,
    String? id,
  }) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || !uri.hasScheme) {
      throw ArgumentError('Invalid model URL.');
    }
    return _runExclusive(() async {
      _setBusy(true);
      _setDownloading(true);
      _lastError = null;
      try {
        final resolvedFileName =
            fileName ??
            _sanitizeFileName(
              uri.pathSegments.isNotEmpty
                  ? uri.pathSegments.last
                  : 'translation-model.gguf',
            );
        _downloadFileName = resolvedFileName;
        _downloadedBytes = 0;
        _cancelDownloadRequested = false;

        // HEAD request to check size and range support.
        final headClient = http.Client();
        int? totalSize;
        bool supportsRange = false;
        try {
          final headResponse = await headClient.send(http.Request('HEAD', uri));
          totalSize = headResponse.contentLength;
          supportsRange =
              headResponse.headers['accept-ranges']?.contains('bytes') == true;
          await headResponse.stream.drain<void>();
        } finally {
          headClient.close();
        }

        _downloadTotalBytes = totalSize;
        notifyListeners();

        DownloadedModelFile downloaded;
        if (supportsRange &&
            totalSize != null &&
            totalSize > _parallelMinBytes) {
          downloaded = await _downloadParallel(
            uri: uri,
            fileName: resolvedFileName,
            totalSize: totalSize,
          );
        } else {
          downloaded = await _downloadSingle(
            uri: uri,
            fileName: resolvedFileName,
          );
        }

        final record = TranslationModelRecord(
          id: id ?? resolvedFileName,
          name: resolvedFileName,
          sourceUrl: sourceUrl,
          localPath: downloaded.localPath,
          downloadedAt: DateTime.now(),
          fileSizeBytes: downloaded.fileSizeBytes,
        );
        final updated = [
          for (final existing in _settings.translationDownloadedModels)
            if (existing.id != record.id) existing,
          record,
        ];
        await _appSettingsService.setTranslationDownloadedModels(updated);
        await _appSettingsService.setTranslationSelectedModelId(record.id);
        await _appSettingsService.setTranslationModelSourceUrl(sourceUrl);
        _failedModelPath = null;
        return record;
      } finally {
        _setDownloading(false);
      }
    });
  }

  Future<DownloadedModelFile> _downloadSingle({
    required Uri uri,
    required String fileName,
  }) async {
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', uri));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Model download failed: HTTP ${response.statusCode}');
      }
      _downloadTotalBytes ??= response.contentLength;
      notifyListeners();
      final trackedStream = _trackDownloadProgress(response.stream);
      return await _fileStore.writeModelBytes(
        fileName: fileName,
        chunks: trackedStream,
      );
    } finally {
      client.close();
    }
  }

  Future<DownloadedModelFile> _downloadParallel({
    required Uri uri,
    required String fileName,
    required int totalSize,
  }) async {
    final chunkSize = (totalSize / _parallelChunks).ceil();
    final chunkPaths = <String>[];
    final clients = <http.Client>[];
    var combineReached = false;
    try {
      final futures = <Future<void>>[];
      for (var i = 0; i < _parallelChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize - 1).clamp(0, totalSize - 1);
        if (start >= totalSize) break;
        final chunkPath = await _fileStore.chunkFilePath(fileName, i);
        chunkPaths.add(chunkPath);
        final client = http.Client();
        clients.add(client);
        futures.add(
          _downloadRange(
            client: client,
            uri: uri,
            chunkPath: chunkPath,
            start: start,
            end: end,
          ),
        );
      }
      await Future.wait(futures);
      if (_cancelDownloadRequested) {
        throw const TranslationDownloadCancelled();
      }
      _downloadFileName = 'Merging chunks...';
      notifyListeners();
      combineReached = true;
      return await _fileStore.combineChunks(
        fileName: fileName,
        chunkPaths: chunkPaths,
      );
    } finally {
      for (final client in clients) {
        client.close();
      }
      if (!combineReached) {
        for (final chunkPath in chunkPaths) {
          await _fileStore.deleteFile(chunkPath);
        }
      }
    }
  }

  Future<void> _downloadRange({
    required http.Client client,
    required Uri uri,
    required String chunkPath,
    required int start,
    required int end,
  }) async {
    final request = http.Request('GET', uri);
    request.headers['Range'] = 'bytes=$start-$end';
    final response = await client.send(request);
    if (response.statusCode != 206) {
      await response.stream.drain<void>();
      throw StateError(
        'Range download failed: HTTP ${response.statusCode}'
        '${response.statusCode == 200 ? ' (server ignored Range header)' : ''}',
      );
    }
    final trackedStream = _trackDownloadProgress(response.stream);
    await _fileStore.writeModelBytes(
      fileName: chunkPath.split(RegExp(r'[/\\]')).last,
      chunks: trackedStream,
    );
  }

  void cancelDownload() {
    if (!_isDownloading) {
      return;
    }
    _cancelDownloadRequested = true;
    _lastError = 'Download stopped.';
    notifyListeners();
  }

  Future<void> removeModel(TranslationModelRecord model) async {
    await _runExclusive(() async {
      _setBusy(true);
      _lastError = null;
      await _fileStore.deleteModel(model);
      final updated = _settings.translationDownloadedModels
          .where((entry) => entry.id != model.id)
          .toList();
      await _appSettingsService.setTranslationDownloadedModels(updated);
      if (_settings.translationSelectedModelId == model.id) {
        await _appSettingsService.setTranslationSelectedModelId(
          updated.isNotEmpty ? updated.first.id : null,
        );
      }
    });
  }

  Future<TranslationResult?> translateIncomingText({
    required String text,
    required String? targetLanguageCode,
  }) async {
    if (targetLanguageCode == null || !_isPlainTextEligible(text)) {
      return null;
    }
    final detectedLanguageCode = await detectLanguage(text);
    if (detectedLanguageCode != null &&
        detectedLanguageCode == targetLanguageCode) {
      return const TranslationResult(
        translatedText: '',
        targetLanguageCode: '',
        status: MessageTranslationStatus.skipped,
      );
    }
    final translatedText = await _translateText(
      text: text,
      targetLanguageCode: targetLanguageCode,
      sourceLanguageCode: detectedLanguageCode,
    );
    if (translatedText == null || translatedText.trim().isEmpty) {
      return null;
    }
    // If translation is nearly identical, text was already in target language.
    if (translatedText.trim().toLowerCase() == text.trim().toLowerCase()) {
      return const TranslationResult(
        translatedText: '',
        targetLanguageCode: '',
        status: MessageTranslationStatus.skipped,
      );
    }
    return TranslationResult(
      translatedText: translatedText.trim(),
      targetLanguageCode: targetLanguageCode,
      detectedLanguageCode: detectedLanguageCode,
      modelId: selectedModel?.id,
      status: MessageTranslationStatus.completed,
    );
  }

  Future<TranslationResult?> translateOutgoingText({
    required String text,
    required String? targetLanguageCode,
  }) async {
    if (targetLanguageCode == null || !_isPlainTextEligible(text)) {
      return null;
    }
    final detectedLanguageCode = await detectLanguage(text);
    if (detectedLanguageCode != null &&
        detectedLanguageCode == targetLanguageCode) {
      return const TranslationResult(
        translatedText: '',
        targetLanguageCode: '',
        status: MessageTranslationStatus.skipped,
      );
    }
    final translatedText = await _translateText(
      text: text,
      targetLanguageCode: targetLanguageCode,
      sourceLanguageCode: detectedLanguageCode,
    );
    if (translatedText == null || translatedText.trim().isEmpty) {
      return null;
    }
    return TranslationResult(
      translatedText: translatedText.trim(),
      targetLanguageCode: targetLanguageCode,
      detectedLanguageCode: detectedLanguageCode,
      modelId: selectedModel?.id,
      status: MessageTranslationStatus.completed,
    );
  }

  Future<String?> detectLanguage(String text) async {
    return _heuristicLanguageCode(text);
  }

  Future<String?> _translateText({
    required String text,
    required String targetLanguageCode,
    String? sourceLanguageCode,
  }) async {
    if (!_hasUsableModel) {
      return null;
    }
    final model = selectedModel;
    if (model == null || model.localPath.isEmpty) {
      return null;
    }
    final targetLabel = _languageLabel(targetLanguageCode);
    final instruction = targetLanguageCode == 'zh'
        ? '将以下文本翻译为中文，注意只需要输出翻译后的结果，不要额外解释：\n\n$text'
        : 'Translate the following segment into $targetLabel, without additional explanation.\n\n$text';
    try {
      return await _runExclusive(() async {
        final engine = await _ensureContext(model.localPath);
        if (engine == null) {
          return null;
        }
        final messages = [
          LlamaChatMessage.fromText(
            role: LlamaChatRole.user,
            text: instruction,
          ),
        ];
        final output = StringBuffer();
        await for (final chunk in engine.create(
          messages,
          params: const GenerationParams(
            maxTokens: 256,
            temp: 0.7,
            topK: 20,
            topP: 0.6,
            penalty: 1.05,
            reusePromptPrefix: false,
          ),
          enableThinking: false,
          sourceLangCode: sourceLanguageCode,
          targetLangCode: targetLanguageCode,
        )) {
          final content = chunk.choices.firstOrNull?.delta.content;
          if (content != null) {
            output.write(content);
          }
          if (output.length >= text.length * 4 + 100) {
            break;
          }
        }
        return _sanitizeOutput(output.toString());
      });
    } catch (error) {
      _lastError = error.toString();
      appLogger.warn('Translation request failed: $error');
      notifyListeners();
      return null;
    }
  }

  bool get _hasUsableModel {
    final model = selectedModel;
    return !kIsWeb && model != null && model.localPath.isNotEmpty;
  }

  bool _isPlainTextEligible(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return !(trimmed.startsWith('g:') ||
        trimmed.startsWith('m:') ||
        trimmed.startsWith('V1|') ||
        trimmed.startsWith('r:'));
  }

  String? _heuristicLanguageCode(String text) {
    if (RegExp(r'[іїєґІЇЄҐ]').hasMatch(text)) {
      return 'uk';
    }
    if (RegExp(r'[а-яёА-ЯЁ]').hasMatch(text)) {
      return 'ru';
    }
    if (RegExp(r'[ぁ-んァ-ン]').hasMatch(text)) {
      return 'ja';
    }
    if (RegExp(r'[가-힣]').hasMatch(text)) {
      return 'ko';
    }
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
      return 'zh';
    }
    // Latin-script languages can't be reliably distinguished by characters
    // alone — return null so the translator always attempts translation.
    return null;
  }

  String _languageLabel(String code) {
    for (final option in supportedTranslationLanguages) {
      if (option.code == code) {
        return option.label;
      }
    }
    return code.toUpperCase();
  }

  String _sanitizeOutput(String raw) {
    var result = raw.trim();
    result = result.replaceAll(RegExp(r'\*\*'), '');
    result = result.replaceAll(RegExp(r'<[^>]+>'), '');
    return result.trim();
  }

  String _sanitizeFileName(String fileName) {
    final cleaned = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'translation-model.gguf' : cleaned;
  }

  Future<LlamaEngine?> _ensureContext(String modelPath) async {
    if (_engine != null && _loadedModelPath == modelPath) {
      return _engine;
    }
    if (modelPath == _failedModelPath) {
      return null;
    }
    if (_engine != null) {
      await _engine!.dispose();
      _engine = null;
      _loadedModelPath = null;
    }
    final engine = LlamaEngine(LlamaBackend());
    try {
      await engine.loadModel(
        modelPath,
        modelParams: const ModelParams(
          gpuLayers: 0,
          preferredBackend: GpuBackend.cpu,
        ),
      );
      _engine = engine;
      _loadedModelPath = modelPath;
      _failedModelPath = null;
      return _engine;
    } catch (_) {
      await engine.dispose();
      _failedModelPath = modelPath;
      rethrow;
    }
  }

  Future<void> releaseModel() async {
    await _runExclusive(() async {
      final engine = _engine;
      if (engine == null) {
        _loadedModelPath = null;
        return;
      }
      _engine = null;
      _loadedModelPath = null;
      await engine.dispose();
    });
  }

  Future<T> _runExclusive<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _setBusy(true);
    _queue = _queue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _setBusy(false);
      }
    });
    return completer.future;
  }

  Stream<List<int>> _trackDownloadProgress(Stream<List<int>> source) async* {
    await for (final chunk in source) {
      if (_cancelDownloadRequested) {
        throw const TranslationDownloadCancelled();
      }
      _downloadedBytes += chunk.length;
      notifyListeners();
      yield chunk;
    }
  }

  void _setBusy(bool value) {
    if (_isBusy == value) {
      return;
    }
    _isBusy = value;
    notifyListeners();
  }

  void _setDownloading(bool value) {
    _isDownloading = value;
    if (!value) {
      _cancelDownloadRequested = false;
      _downloadedBytes = 0;
      _downloadTotalBytes = null;
      _downloadFileName = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    final engine = _engine;
    _engine = null;
    _loadedModelPath = null;
    if (engine != null) {
      unawaited(engine.dispose());
    }
    super.dispose();
  }
}
