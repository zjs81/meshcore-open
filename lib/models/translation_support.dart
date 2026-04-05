enum MessageTranslationStatus { none, pending, completed, failed, skipped }

extension MessageTranslationStatusValue on MessageTranslationStatus {
  String get value {
    switch (this) {
      case MessageTranslationStatus.pending:
        return 'pending';
      case MessageTranslationStatus.completed:
        return 'completed';
      case MessageTranslationStatus.failed:
        return 'failed';
      case MessageTranslationStatus.skipped:
        return 'skipped';
      case MessageTranslationStatus.none:
        return 'none';
    }
  }
}

MessageTranslationStatus parseMessageTranslationStatus(dynamic value) {
  if (value is! String) {
    return MessageTranslationStatus.none;
  }
  for (final status in MessageTranslationStatus.values) {
    if (status.value == value) {
      return status;
    }
  }
  return MessageTranslationStatus.none;
}

class TranslationModelRecord {
  final String id;
  final String name;
  final String sourceUrl;
  final String localPath;
  final DateTime downloadedAt;
  final int fileSizeBytes;

  const TranslationModelRecord({
    required this.id,
    required this.name,
    required this.sourceUrl,
    required this.localPath,
    required this.downloadedAt,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source_url': sourceUrl,
      'local_path': localPath,
      'downloaded_at': downloadedAt.millisecondsSinceEpoch,
      'file_size_bytes': fileSizeBytes,
    };
  }

  factory TranslationModelRecord.fromJson(Map<String, dynamic> json) {
    return TranslationModelRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      localPath: json['local_path'] as String? ?? '',
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(
        json['downloaded_at'] as int? ?? 0,
      ),
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
    );
  }
}

String translationModelFriendlyName(TranslationModelRecord model) {
  switch (model.id) {
    case 'hy-mt1.5-1.8b-q4_k_m':
      return 'Tencent HY-MT 1.5 1.8B Q4_K_M';
    case 'hy-mt1.5-1.8b-q6_k':
      return 'Tencent HY-MT 1.5 1.8B Q6_K';
    default:
      final trimmed = model.name.trim();
      if (trimmed.endsWith('.gguf')) {
        return trimmed.substring(0, trimmed.length - 5);
      }
      return trimmed.isEmpty ? model.id : trimmed;
  }
}

class TranslationLanguageOption {
  final String code;
  final String label;

  const TranslationLanguageOption({required this.code, required this.label});
}

const List<TranslationLanguageOption> supportedTranslationLanguages = [
  TranslationLanguageOption(code: 'bg', label: 'Bulgarian'),
  TranslationLanguageOption(code: 'de', label: 'German'),
  TranslationLanguageOption(code: 'en', label: 'English'),
  TranslationLanguageOption(code: 'es', label: 'Spanish'),
  TranslationLanguageOption(code: 'fr', label: 'French'),
  TranslationLanguageOption(code: 'hu', label: 'Hungarian'),
  TranslationLanguageOption(code: 'it', label: 'Italian'),
  TranslationLanguageOption(code: 'ja', label: 'Japanese'),
  TranslationLanguageOption(code: 'ko', label: 'Korean'),
  TranslationLanguageOption(code: 'nl', label: 'Dutch'),
  TranslationLanguageOption(code: 'pl', label: 'Polish'),
  TranslationLanguageOption(code: 'pt', label: 'Portuguese'),
  TranslationLanguageOption(code: 'ru', label: 'Russian'),
  TranslationLanguageOption(code: 'sk', label: 'Slovak'),
  TranslationLanguageOption(code: 'sl', label: 'Slovenian'),
  TranslationLanguageOption(code: 'sv', label: 'Swedish'),
  TranslationLanguageOption(code: 'uk', label: 'Ukrainian'),
  TranslationLanguageOption(code: 'zh', label: 'Chinese'),
];

final List<TranslationModelRecord> translationPresetModels = [
  TranslationModelRecord(
    id: 'hy-mt1.5-1.8b-q4_k_m',
    name: 'HY-MT1.5-1.8B-Q4_K_M.gguf',
    sourceUrl:
        'https://huggingface.co/tencent/HY-MT1.5-1.8B-GGUF/resolve/main/HY-MT1.5-1.8B-Q4_K_M.gguf?download=true',
    localPath: '',
    downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
    fileSizeBytes: 0,
  ),
  TranslationModelRecord(
    id: 'hy-mt1.5-1.8b-q6_k',
    name: 'HY-MT1.5-1.8B-Q6_K.gguf',
    sourceUrl:
        'https://huggingface.co/tencent/HY-MT1.5-1.8B-GGUF/resolve/main/HY-MT1.5-1.8B-Q6_K.gguf?download=true',
    localPath: '',
    downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
    fileSizeBytes: 0,
  ),
];
