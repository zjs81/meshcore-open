import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/image_codec_support.dart';
import '../utils/app_logger.dart';
import '../widgets/image_send_codec_binding.dart';
import 'app_settings_service.dart';
import 'image_codec_backend.dart' show kImageCodecBitstreamPathAvailable;
import 'image_codec_file_store.dart';
import 'image_codec_session.dart';
import 'image_codec_settings_store.dart';

/// Neural image codec (AEIC-SE) for sending photographs over the mesh.
///
/// Structurally a sibling of [TranslationService] — same model registry, same
/// `_runExclusive` serial lock, same load/unload lifecycle — with four
/// deliberate differences. Read `translation_service.dart` alongside this file:
///
///  1. The heavy work runs in a worker isolate this class owns
///     ([ImageCodecSession]) rather than inside a package that owns its own
///     thread. A 1385 GFLOP decode on the root isolate would stall the BLE
///     notify stream and drop mesh traffic.
///  2. [handleMemoryPressure] exists. The decode graph is ~886M parameters and
///     2.16 GiB peak resident; it must be evicted on background and on memory
///     warnings or Android's low-memory killer takes the whole app. Do NOT copy
///     the translation stack's hold-until-disconnect behaviour.
///  3. The download is **resumable and checksum-verified**, and fetches a *list*
///     of assets, because the model is an ONNX graph plus an 869 MiB
///     external-weights sibling. See the `---- download` section.
///  4. Preferences live in [ImageCodecSettingsStore] until the `imageCodec*`
///     fields land on `AppSettings` (see that file's doc comment).
///
/// ## Two sessions, two lifetimes
///
/// The installed model is a *bundle* ([ImageCodecBundle]): a ~2.16 GiB-peak
/// synthesis decoder, two fp32 entropy graphs (64 MB send-side, 58 MB
/// decode-side, ~0.35 GiB peak and only ever one of them resident) and 813 KB
/// of CDF tables. Encoding needs only the send-side entropy graph; decoding
/// needs the decode-side graph and then the synthesis decoder, one after the
/// other — both resident at once measures 2.44 GiB. The worker therefore
/// creates ORT sessions lazily and can drop either half on its own
/// ([releaseDecoderSession] / [releaseEntropySession]), so a send never pays
/// for the decoder and [handleMemoryPressure] can shed the expensive half while
/// leaving the send path warm.
///
/// ## What works today
///
/// [decodeLatent] — the real ONNX synthesis pass, latent to pixels — plus
/// whatever the backend's entropy path supports. While
/// [kImageCodecBitstreamPathAvailable] is false, [encode] and [decodeBitstream]
/// throw [ImageCodecEntropyPathMissing] and [availability] reports
/// `unavailable` with [unavailableReason] carrying the sentence to show the
/// user. A build where that gate is true but the *installed files* are
/// decoder-only is a different, recoverable state: `disabled` +
/// [needsModelUpgrade] + [ImageCodecBundleIncomplete].
///
/// It implements [ImageSendCodec] directly, so `ImageSendPreviewSheet` and
/// `pickAndPreviewImage` bind to it with no adapter — replace
/// `FakeImageSendCodec()` at the two call sites in `chat_screen.dart` /
/// `channel_chat_screen.dart` with `context.read<ImageCodecService>()`.
class ImageCodecService extends ChangeNotifier implements ImageSendCodec {
  final AppSettingsService _appSettingsService;
  final ImageCodecFileStore _fileStore;
  final ImageCodecSettingsStore _settingsStore;

  /// Creates a new [http.Client] per download attempt.
  ///
  /// Injectable so the download/resume/checksum logic can be tested against a
  /// `MockClient` — without this the only way to exercise an 872 MB two-file
  /// resumable transfer would be to actually perform one.
  final http.Client Function() _newClient;

  ImageCodecService(
    this._appSettingsService, {
    ImageCodecFileStore? fileStore,
    ImageCodecSettingsStore? settingsStore,
    http.Client Function()? clientFactory,
  }) : _fileStore = fileStore ?? ImageCodecFileStore(),
       _settingsStore = settingsStore ?? PrefsImageCodecSettingsStore(),
       _newClient = clientFactory ?? http.Client.new;

  // ---- state (naming/order mirrors TranslationService:50-62) ----------------
  bool _disposed = false;
  bool _isBusy = false;
  bool _isDownloading = false;
  bool _cancelDownloadRequested = false;
  String? _lastError;
  Future<void> _queue = Future<void>.value();
  ImageCodecSession? _session;
  ImageCodecBundle? _loadedBundle;
  ImageCodecBundle? _failedBundle;
  int _downloadedBytes = 0;
  int? _downloadTotalBytes;
  String? _downloadFileName;
  // codec-specific
  double? _codecProgress;
  String? _codecStage;

  // ---- getters (mirror translation_service.dart:64-76) ---------------------
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

  /// 0..1 while an encode or decode is running, null when idle.
  double? get codecProgress => _codecProgress;

  /// Short human label for the current codec phase, null when idle.
  String? get codecStage => _codecStage;

  bool get isModelLoaded => _loadedBundle != null;

  ImageCodecPreferences get preferences => _settingsStore.preferences;

  /// Composer default rate point.
  AeicRatePoint get defaultRatePoint => preferences.aeicRatePoint;

  // ---- availability --------------------------------------------------------

  /// The signal the compose UI binds to.
  ///
  /// Mapping decisions worth knowing:
  ///  * `unavailable` means "this build/device can never do this" — web, a build
  ///    whose inference backend failed to load, or (today, always) a build
  ///    without the rANS entropy path. Sending a picture needs bytes, and this
  ///    build can only turn a *latent* into a picture. See
  ///    [kImageCodecBitstreamPathAvailable] and [ImageCodecEntropyPathMissing];
  ///    [unavailableReason] carries the explanation for the UI.
  ///  * `disabled` covers "switched off in settings", "no model downloaded
  ///    yet" and "the installed model predates the entropy bundle", because the
  ///    sheet's remedy is the same in all three: send the user to settings.
  ///    [needsModelDownload] and [needsModelUpgrade] distinguish them, and
  ///    [statusReason] renders the difference as a sentence.
  @override
  ImageCodecAvailability get availability {
    if (unavailableReason != null) {
      return ImageCodecAvailability.unavailable;
    }
    if (!_appSettingsService.settings.imageMessagesEnabled ||
        !preferences.enabled) {
      return ImageCodecAvailability.disabled;
    }
    if (_isDownloading) {
      return ImageCodecAvailability.downloading;
    }
    final model = selectedModel;
    if (model == null || model.localPath.isEmpty) {
      return ImageCodecAvailability.disabled;
    }
    // A decoder-only install cannot encode, and a bundle-version-1 install can
    // encode but not decode; neither is "ready", so the compose UI must not say
    // so. `disabled` (not `unavailable`) because the remedy is a download —
    // see [needsModelUpgrade] and [statusReason]. Kept in step with
    // [needsModelUpgrade] on purpose: `ready` plus an upgrade prompt would be a
    // contradiction the sheet has no way to render.
    if (installedBundle?.supportsDecode != true) {
      return ImageCodecAvailability.disabled;
    }
    return ImageCodecAvailability.ready;
  }

  /// Why [availability] is `unavailable`, or null when it is not.
  ///
  /// EXACTLY THREE CAUSES, all of them permanent properties of the build or the
  /// platform, none of them fixable by the user:
  ///   * web, which has no native inference runtime;
  ///   * a build compiled without the entropy path
  ///     ([kImageCodecBitstreamPathAvailable]);
  ///   * a backend that failed to load.
  ///
  /// An incomplete or legacy install is deliberately NOT one of them: its
  /// remedy is a download, so it is `disabled` + [needsModelUpgrade]. Reporting
  /// it here would tell every user of the decoder-only build that their phone
  /// can never send a picture, which is false.
  @override
  String? get unavailableReason {
    if (kIsWeb) {
      return 'The image codec needs a native inference runtime, which the web '
          'build does not have.';
    }
    if (!kImageCodecBitstreamPathAvailable) {
      return 'This build ships the image decoder only. Encoding and decoding a '
          'bitstream also needs the entropy-side graph and the rANS coder, '
          'which are not included yet.';
    }
    if (_backendMissing) {
      return _lastError ?? 'The inference backend failed to load.';
    }
    return null;
  }

  /// One user-facing sentence for whatever non-ready state the codec is in, or
  /// null when it is ready.
  ///
  /// [unavailableReason] can only explain the three permanent causes, so a
  /// sheet that renders it alone falls back to a generic "not available" string
  /// for the two states the user can actually DO something about — the feature
  /// being switched off and the model not being installed. This getter covers
  /// every case and is what a "why can't I send?" banner should show; it is a
  /// superset, so `statusReason ?? unavailableReason` is never needed.
  String? get statusReason {
    final permanent = unavailableReason;
    if (permanent != null) {
      return permanent;
    }
    if (!_appSettingsService.settings.imageMessagesEnabled) {
      return 'Image messages are switched off. Turn them on in Settings to '
          'send and receive pictures.';
    }
    if (!preferences.enabled) {
      return 'The image codec is switched off in Settings.';
    }
    if (_isDownloading) {
      final name = _downloadFileName;
      return name == null
          ? 'The image codec model is downloading.'
          : 'The image codec model is downloading ($name).';
    }
    if (needsModelDownload) {
      return 'The image codec model is not downloaded yet. It is about '
          '${(kImageCodecBundleTotalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} '
          'GB and can be fetched from Settings.';
    }
    if (needsModelUpgrade) {
      return 'The installed image codec model is missing part of the current '
          'bundle, so it cannot send and receive pictures. Re-download it in '
          'Settings.';
    }
    if (_lastError != null && !canRunInference) {
      return _lastError;
    }
    return null;
  }

  /// True when the feature is on but no weights are on disk.
  bool get needsModelDownload {
    final model = selectedModel;
    return preferences.enabled && (model == null || model.localPath.isEmpty);
  }

  /// True when a model IS installed but it is missing part of the current
  /// bundle: a decoder-only (pre-bundle) install with no entropy graph and no
  /// CDF tables, or a bundle-version-1 install with the send-side entropy graph
  /// but no decode-side one.
  ///
  /// The remedy is a re-download, which is why this is not folded into
  /// [unavailableReason]. Keyed off both the recorded [kImageCodecBundleVersion]
  /// and the actual paths, so a record hand-edited to claim version 1 without
  /// the files still reports true.
  bool get needsModelUpgrade {
    final model = selectedModel;
    if (model == null || model.localPath.isEmpty) {
      return false;
    }
    if (model.bundleVersion < kImageCodecBundleVersion) {
      return true;
    }
    return installedBundle?.supportsDecode != true;
  }

  /// Paths of the installed model, or null when nothing is installed.
  ///
  /// The decoder graph is [ImageCodecModelRecord.localPath]; the two entropy
  /// graphs and the CDF tables are resolved BY ROLE, from
  /// [ImageCodecModelRecord.assetRoles] first and the registry spec second, so
  /// nothing here re-derives a filename by convention. A pre-bundle record
  /// simply yields an incomplete bundle.
  ImageCodecBundle? get installedBundle {
    final model = selectedModel;
    if (model == null || model.localPath.isEmpty) {
      return null;
    }
    final spec = _specForId(model.id);
    final directory = _directoryOf(model.localPath);

    String? pathFor(
      ImageCodecAssetRole role,
      bool Function(String) looksRight,
    ) {
      // 1. What the installer recorded this file AS. Exact, and the only source
      //    that can tell the two entropy graphs apart.
      final recorded = model.fileNameForRole(role);
      if (recorded != null) {
        return '$directory/$recorded';
      }
      // 2. The registry spec, for records written before assetRoles existed.
      final declared = spec?.maybeAssetFor(role)?.fileName;
      if (declared != null && model.assetFileNames.contains(declared)) {
        return '$directory/$declared';
      }
      // 3. Last resort for a custom-URL install or an old record: the recorded
      //    names, never a guess at a name that was never downloaded.
      for (final name in model.assetFileNames) {
        if (looksRight(name)) {
          return '$directory/$name';
        }
      }
      return null;
    }

    final decoderName = model.localPath.split('/').last;
    // The bundle now holds THREE `.onnx` files, so "any .onnx that is not the
    // decoder" no longer identifies the send-side graph on its own. The
    // heuristic is only ever reached for a record with no matching spec entry,
    // and it must not be allowed to hand the decode-side export to the encoder:
    // that graph has no `image` input and would fail at the first run.
    final decodeGraphName =
        model.fileNameForRole(ImageCodecAssetRole.entropyDecodeGraph) ??
        spec?.maybeAssetFor(ImageCodecAssetRole.entropyDecodeGraph)?.fileName;
    return ImageCodecBundle(
      decoderGraphPath: model.localPath,
      entropyGraphPath: pathFor(
        ImageCodecAssetRole.entropyGraph,
        (name) =>
            name.endsWith('.onnx') &&
            name != decoderName &&
            name != decodeGraphName,
      ),
      // Declared-name only, no heuristic. A record written before bundle
      // version 2 has no decode-side graph on disk at all, and inventing a
      // filename for it would trade a clean "re-download" prompt for an opaque
      // ORT session-creation failure.
      entropyDecodeGraphPath: pathFor(
        ImageCodecAssetRole.entropyDecodeGraph,
        (_) => false,
      ),
      tablesPath: pathFor(
        ImageCodecAssetRole.cdfTables,
        (name) => name.endsWith('.bin'),
      ),
      ratePoint: spec?.ratePoint ?? preferences.aeicRatePoint,
    );
  }

  static String _directoryOf(String path) {
    final index = path.lastIndexOf('/');
    return index <= 0 ? path : path.substring(0, index);
  }

  ImageCodecModelSpec? _specForId(String id) {
    for (final spec in imageCodecPresetModels) {
      if (spec.id == id) return spec;
    }
    return null;
  }

  /// Set once a session load has failed with [ImageCodecUnimplemented], i.e.
  /// this build has no inference runtime. Sticky: retrying cannot help.
  bool _backendMissing = false;

  // ---- registry (mirror translation_service.dart:129-174) ------------------
  List<ImageCodecModelRecord> get availableModels =>
      preferences.downloadedModels;

  ImageCodecModelRecord? get selectedModel {
    final selectedId = preferences.selectedModelId;
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

  /// Loads persisted preferences and reconciles them with what is on disk.
  ///
  /// Call once at startup, next to
  /// `await translationService.refreshDownloadedModels();` in `main.dart`.
  Future<void> refreshDownloadedModels() async {
    if (_isDownloading) return;
    await _settingsStore.load();
    if (kIsWeb) {
      _notify();
      return;
    }
    final scanned = await _fileStore.scanDownloadedModels();
    if (scanned.isEmpty) {
      _notify();
      return;
    }
    // The file store reports one record per FILE, which is no longer one record
    // per model: a bundle is four files, and taking them at face value would
    // list `aeic_cdf_ft32.bin` as an installed codec. Reconcile against the
    // registry here, so this survives whatever the store does.
    final onDisk = {for (final model in scanned) model.name: model};
    final existingByPath = {
      for (final model in preferences.downloadedModels) model.localPath: model,
    };
    final merged = <ImageCodecModelRecord>[];
    // Every filename the registry knows about, so a half-installed bundle's
    // leftovers are never mistaken for standalone models.
    final claimed = <String>{
      for (final spec in imageCodecPresetModels)
        for (final asset in spec.assets) asset.fileName,
    };

    for (final spec in imageCodecPresetModels) {
      final graphFile = onDisk[spec.fileName];
      if (graphFile == null) continue;
      final present = [
        for (final asset in spec.assets)
          if (onDisk.containsKey(asset.fileName)) asset.fileName,
      ];
      final existing = existingByPath[graphFile.localPath];
      final complete = spec.assets.every(
        (asset) => onDisk.containsKey(asset.fileName),
      );
      merged.add(
        ImageCodecModelRecord(
          id: spec.id,
          name: spec.fileName,
          sourceUrl: existing?.sourceUrl ?? spec.graph.sourceUrl,
          localPath: graphFile.localPath,
          downloadedAt: existing?.downloadedAt ?? graphFile.downloadedAt,
          fileSizeBytes: [
            for (final name in present) onDisk[name]!.fileSizeBytes,
          ].fold<int>(0, (sum, size) => sum + size),
          assetFileNames: present,
          assetRoles: {
            for (final asset in spec.assets)
              if (onDisk.containsKey(asset.fileName))
                asset.fileName: asset.role,
          },
          bundleVersion: complete ? kImageCodecBundleVersion : 0,
        ),
      );
    }

    // Anything not part of a registry bundle is a custom-URL install; keep it
    // as its own single-file record so a hand-fetched graph is not deleted.
    for (final model in scanned) {
      if (claimed.contains(model.name)) continue;
      final existing = existingByPath[model.localPath];
      merged.add(
        existing?.copyWith(fileSizeBytes: model.fileSizeBytes) ?? model,
      );
    }

    var updated = preferences.copyWith(downloadedModels: merged);
    _failedBundle = null;
    if (updated.selectedModelId == null && merged.isNotEmpty) {
      updated = updated.copyWith(selectedModelId: merged.first.id);
    }
    await _settingsStore.save(updated);
    _notify();
  }

  Future<void> setEnabled(bool value) async {
    await _settingsStore.save(preferences.copyWith(enabled: value));
    if (!value) {
      await releaseModel();
    }
    _notify();
  }

  Future<void> setSelectedModelId(String? id) async {
    await _settingsStore.save(preferences.copyWith(selectedModelId: id));
    // The cached session belongs to the previous model.
    await releaseModel();
    _notify();
  }

  Future<void> setDefaultRatePoint(AeicRatePoint ratePoint) async {
    await _settingsStore.save(
      preferences.copyWith(ratePoint: ratePoint.wireValue),
    );
    _notify();
  }

  // ---- gating --------------------------------------------------------------

  /// Whether a model file is present and a session could be loaded.
  ///
  /// This is the ONNX-only capability: it gates [decodeLatentToRgb], which
  /// works. [canEncode]/[canDecode] additionally require the entropy path.
  bool get canRunInference {
    final model = selectedModel;
    return !kIsWeb &&
        !_backendMissing &&
        model != null &&
        model.localPath.isNotEmpty;
  }

  /// Whether a picture can be turned into bytes on this device right now.
  ///
  /// Three independent facts, all required: a model is installed and the
  /// backend loads ([canRunInference]), the build contains the entropy path
  /// ([kImageCodecBitstreamPathAvailable]), and the *installed* bundle carries
  /// the entropy graph and the CDF tables.
  bool get canEncode =>
      canRunInference &&
      kImageCodecBitstreamPathAvailable &&
      installedBundle?.isComplete == true;

  /// Everything [canEncode] needs, PLUS the decode-side entropy graph.
  ///
  /// Not an alias for [canEncode] any more. Decoding re-runs the entropy model
  /// to reproduce the encoder's symbol probabilities, but it has to do it one
  /// stage at a time, which the send-side export cannot do — so a bundle-
  /// version-1 install can send a picture and not open one. Treating the two as
  /// the same fact would let the receive path start a decode that fails
  /// halfway.
  bool get canDecode =>
      canRunInference &&
      kImageCodecBitstreamPathAvailable &&
      installedBundle?.supportsDecode == true;

  /// Whether a reassembled chunk set is complete enough to attempt a decode.
  ///
  /// A truncated AEIC bitstream does not decode to a degraded picture — the
  /// rANS decoder desynchronises and produces garbage without raising — so the
  /// answer is strictly "all data chunks present". Single-loss recovery is the
  /// parity chunk's job in `image_chunk_transport.dart`, upstream of here.
  bool canDecodeChunkSet(int received, int total) {
    if (!canDecode || total <= 0) return false;
    return received >= total;
  }

  // ---- download -------------------------------------------------------------
  //
  // Derived from translation_service.dart:176-366, then changed in three ways
  // that matter at 872 MB across two files:
  //
  //  1. RESUMABLE. Each of the 8 range chunks is its own file whose *length is
  //     its progress marker*, so a dropped connection resumes with
  //     `Range: bytes=<start+have>-<end>` instead of restarting from zero. The
  //     chunk filenames embed the total size, so a re-download of a file whose
  //     length changed upstream can never resume onto stale offsets.
  //  2. VERIFIED. A completed file is SHA-256'd against the expected digest
  //     before it is recorded. Without this, corruption arrived as an opaque
  //     session-load failure that got poisoned into `_failedModelPath` — a dead
  //     feature with no diagnostic and no way back except clearing app data.
  //  3. MULTI-FILE. A model is a list of assets (graph + external weights), all
  //     of which must land in one directory under exact names. See
  //     `ImageCodecModelSpec`.

  static const int _parallelChunks = 8;
  static const int _parallelMinBytes = 10 * 1024 * 1024; // 10 MB

  /// Downloads every asset of a declared preset model.
  ///
  /// Refuses a spec whose URLs are placeholders — see
  /// [ImageCodecModelSpec.urlsArePlaceholders] and the banner on
  /// [imageCodecPresetModels]. That refusal is the guard against shipping the
  /// invented HuggingFace paths.
  Future<ImageCodecModelRecord> downloadPresetModel(
    ImageCodecModelSpec spec,
  ) async {
    if (spec.urlsArePlaceholders) {
      throw StateError(
        'Model "${spec.id}" has placeholder URLs that have never been fetched. '
        'Publish the weights and update imageCodecPresetModels first.',
      );
    }
    if (!spec.isComplete) {
      throw StateError(
        'Model "${spec.id}" is missing one of the four bundle roles; it would '
        'install a codec that cannot encode or decode.',
      );
    }
    return _downloadAssets(
      id: spec.id,
      assets: spec.assets,
      declaredTotalBytes: spec.totalSizeBytes,
      // Role-resolved, not positional: the graph handed to ORT is the decoder,
      // which is the smallest of the four files and would never be assets.first
      // if anyone sorted the list by size.
      primary: spec.assetFor(ImageCodecAssetRole.decoderGraph),
      bundleVersion: kImageCodecBundleVersion,
    );
  }

  /// Downloads a single-file model from an arbitrary URL.
  ///
  /// Kept for the settings screen's "custom URL" affordance. A model with
  /// external weights cannot be expressed this way; use [downloadPresetModel].
  Future<ImageCodecModelRecord> downloadModel({
    required String sourceUrl,
    String? fileName,
    String? id,
  }) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || !uri.hasScheme) {
      throw ArgumentError('Invalid model URL.');
    }
    final resolvedFileName =
        fileName ??
        _sanitizeFileName(
          uri.pathSegments.isNotEmpty
              ? uri.pathSegments.last
              : 'image-codec-model.onnx',
        );
    return _downloadAssets(
      id: id ?? resolvedFileName,
      assets: [
        ImageCodecModelAsset(
          role: ImageCodecAssetRole.decoderGraph,
          fileName: resolvedFileName,
          sourceUrl: sourceUrl,
          sizeBytes: 0,
        ),
      ],
      declaredTotalBytes: 0,
      // A single-file install is by definition decoder-only.
      bundleVersion: 0,
    );
  }

  Future<ImageCodecModelRecord> _downloadAssets({
    required String id,
    required List<ImageCodecModelAsset> assets,
    required int declaredTotalBytes,
    required int bundleVersion,
    ImageCodecModelAsset? primary,
  }) async {
    for (final asset in assets) {
      final uri = Uri.tryParse(asset.sourceUrl);
      if (uri == null || !uri.hasScheme) {
        throw ArgumentError('Invalid model URL: ${asset.sourceUrl}');
      }
    }
    return _runExclusive(() async {
      _setBusy(true);
      _setDownloading(true);
      _lastError = null;
      try {
        _downloadedBytes = 0;
        _downloadTotalBytes = declaredTotalBytes > 0
            ? declaredTotalBytes
            : null;
        _cancelDownloadRequested = false;

        // One progress bar across the whole set: `_downloadedBytes` accumulates
        // over every asset and `_downloadTotalBytes` is the sum of all four, so
        // a 900 MB bundle shows one monotonic bar rather than four that each
        // snap back to zero. `_downloadFileName` names the file in flight.
        final graphAsset = primary ?? assets.first;
        final downloadedFiles = <String, DownloadedCodecFile>{};
        for (final asset in assets) {
          downloadedFiles[asset.fileName] = await _downloadAsset(asset);
        }

        final graph = downloadedFiles[graphAsset.fileName]!;
        final record = ImageCodecModelRecord(
          id: id,
          name: graphAsset.fileName,
          sourceUrl: graphAsset.sourceUrl,
          localPath: graph.localPath,
          downloadedAt: DateTime.now(),
          // The whole bundle, not just the graph: this is what the settings
          // screen shows next to the installed model, and 3 MB would be a lie
          // about 900 MB of storage.
          fileSizeBytes: downloadedFiles.values.fold<int>(
            0,
            (sum, file) => sum + file.fileSizeBytes,
          ),
          assetFileNames: [for (final asset in assets) asset.fileName],
          // The only place the role of each downloaded file is known for
          // certain. Recorded now so nothing downstream has to infer it from a
          // filename — see [ImageCodecModelRecord.assetRoles].
          assetRoles: {for (final asset in assets) asset.fileName: asset.role},
          bundleVersion: bundleVersion,
        );
        final updated = [
          for (final existing in preferences.downloadedModels)
            if (existing.id != record.id) existing,
          record,
        ];
        await _settingsStore.save(
          preferences.copyWith(
            downloadedModels: updated,
            selectedModelId: record.id,
            modelSourceUrl: graphAsset.sourceUrl,
          ),
        );
        _failedBundle = null;
        return record;
      } finally {
        _setDownloading(false);
      }
    });
  }

  Future<DownloadedCodecFile> _downloadAsset(ImageCodecModelAsset asset) async {
    final uri = Uri.parse(asset.sourceUrl);
    _downloadFileName = asset.fileName;
    _notify();

    final finalPath = await _fileStore.modelFilePath(asset.fileName);

    // Already here and intact? Credit its bytes to the progress bar and move on.
    // This is what makes retrying after a failure on asset 2 of 2 cheap.
    final existing = await _fileStore.fileSize(finalPath);
    if (existing > 0 &&
        (asset.sizeBytes == 0 || existing == asset.sizeBytes) &&
        await _checksumMatches(asset, finalPath)) {
      _downloadedBytes += existing;
      _notify();
      return DownloadedCodecFile(localPath: finalPath, fileSizeBytes: existing);
    }
    if (existing > 0) {
      await _fileStore.deleteFile(finalPath);
    }

    final head = await _probe(uri);
    final totalSize = head.contentLength ?? asset.sizeBytes;

    final DownloadedCodecFile downloaded;
    if (head.supportsRange && totalSize > _parallelMinBytes) {
      downloaded = await _downloadRanged(
        uri: uri,
        fileName: asset.fileName,
        totalSize: totalSize,
      );
    } else {
      downloaded = await _downloadSingle(uri: uri, fileName: asset.fileName);
    }

    await _verifyChecksum(asset, downloaded.localPath);
    await _fileStore.deletePartialDownloads(asset.fileName);
    return downloaded;
  }

  Future<_HeadResult> _probe(Uri uri) async {
    final client = _newClient();
    try {
      final response = await client.send(http.Request('HEAD', uri));
      await response.stream.drain<void>();
      return _HeadResult(
        contentLength: response.contentLength,
        supportsRange:
            response.headers['accept-ranges']?.contains('bytes') == true,
      );
    } finally {
      client.close();
    }
  }

  /// Non-resumable fallback: used when the server will not honour Range, or the
  /// file is small enough that resume is pointless.
  Future<DownloadedCodecFile> _downloadSingle({
    required Uri uri,
    required String fileName,
  }) async {
    final client = _newClient();
    try {
      final response = await client.send(http.Request('GET', uri));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Model download failed: HTTP ${response.statusCode}');
      }
      _downloadTotalBytes ??= response.contentLength;
      _notify();
      final trackedStream = _trackDownloadProgress(response.stream);
      return await _fileStore.writeModelBytes(
        fileName: fileName,
        chunks: trackedStream,
      );
    } finally {
      client.close();
    }
  }

  /// 8-way parallel, per-chunk resumable.
  Future<DownloadedCodecFile> _downloadRanged({
    required Uri uri,
    required String fileName,
    required int totalSize,
  }) async {
    final chunkSize = (totalSize / _parallelChunks).ceil();
    final chunkPaths = <String>[];
    final clients = <http.Client>[];
    try {
      final futures = <Future<void>>[];
      for (var i = 0; i < _parallelChunks; i++) {
        final start = i * chunkSize;
        if (start >= totalSize) break;
        final end = (start + chunkSize - 1).clamp(0, totalSize - 1);
        final expected = end - start + 1;

        // The chunk key carries totalSize so a file that changed length upstream
        // cannot resume onto offsets computed for the old length. Silent
        // cross-version splicing is the one failure mode a naive resume has that
        // no-resume does not, and it produces a corrupt model with a valid size.
        final chunkPath = await _fileStore.chunkFilePath(
          '$fileName.$totalSize',
          i,
        );
        chunkPaths.add(chunkPath);

        var have = await _fileStore.fileSize(chunkPath);
        if (have > expected) {
          // Only reachable if a previous run wrote past its range. Distrust it.
          await _fileStore.deleteFile(chunkPath);
          have = 0;
        }
        _downloadedBytes += have;
        if (have == expected) {
          continue; // Complete from a previous attempt.
        }

        final client = _newClient();
        clients.add(client);
        futures.add(
          _downloadRange(
            client: client,
            uri: uri,
            chunkPath: chunkPath,
            start: start + have,
            end: end,
          ),
        );
      }
      _notify();
      await Future.wait(futures);
      if (_cancelDownloadRequested) {
        throw const ImageCodecDownloadCancelled();
      }
      return await _fileStore.combineChunks(
        fileName: fileName,
        chunkPaths: chunkPaths,
      );
    } finally {
      for (final client in clients) {
        client.close();
      }
      // Chunk files are deliberately NOT deleted on failure — they are the
      // resume state. `combineChunks` reaps them once the merge succeeds, and
      // `deletePartialDownloads` sweeps them after verification.
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
    await _fileStore.appendBytes(
      path: chunkPath,
      chunks: _trackDownloadProgress(response.stream),
    );
  }

  /// True when [path] matches [asset]'s digest, or when there is no digest.
  Future<bool> _checksumMatches(ImageCodecModelAsset asset, String path) async {
    if (!asset.hasChecksum) {
      return true;
    }
    try {
      final actual = await _fileStore.sha256OfFile(path);
      return actual == asset.sha256.toLowerCase();
    } catch (_) {
      return false;
    }
  }

  /// Verifies [path] and deletes it if the digest is wrong.
  ///
  /// A no-op when the asset has no digest — which is the case for every preset
  /// today, because nothing has been published to hash. That is a real hole:
  /// see the note on [ImageCodecModelAsset.sha256].
  Future<void> _verifyChecksum(ImageCodecModelAsset asset, String path) async {
    if (!asset.hasChecksum) {
      appLogger.warn(
        'No SHA-256 for ${asset.fileName}; integrity unverified',
        tag: 'ImageCodec',
      );
      return;
    }
    _downloadFileName = 'Verifying ${asset.fileName}';
    _notify();
    final actual = await _fileStore.sha256OfFile(path);
    if (actual != asset.sha256.toLowerCase()) {
      await _fileStore.deleteFile(path);
      throw ImageCodecIntegrityFailure(
        fileName: asset.fileName,
        expected: asset.sha256.toLowerCase(),
        actual: actual,
      );
    }
  }

  void cancelDownload() {
    if (!_isDownloading) {
      return;
    }
    _cancelDownloadRequested = true;
    _lastError = 'Download stopped.';
    _notify();
  }

  Future<void> removeModel(ImageCodecModelRecord model) async {
    // Free the isolate first: on Android the file cannot be deleted while the
    // native session still has it mapped.
    await releaseModel();
    await _runExclusive(() async {
      _setBusy(true);
      _lastError = null;
      await _fileStore.deleteModel(model);
      // deleteModel only knows about `localPath` (the 3 MB graph) unless the
      // store has been taught about bundles, so sweep the recorded siblings
      // here too. Without this, "Remove model" leaves 940 MB on the device.
      final directory = _directoryOf(model.localPath);
      for (final name in model.assetFileNames) {
        final path = '$directory/$name';
        if (path == model.localPath) continue;
        await _fileStore.deleteFile(path);
        await _fileStore.deletePartialDownloads(name);
      }
      final updated = preferences.downloadedModels
          .where((entry) => entry.id != model.id)
          .toList();
      var next = preferences.copyWith(downloadedModels: updated);
      if (next.selectedModelId == model.id) {
        next = next.copyWith(
          selectedModelId: updated.isNotEmpty ? updated.first.id : null,
        );
      }
      await _settingsStore.save(next);
    });
  }

  // ---- codec API -----------------------------------------------------------

  /// [ImageSendCodec] entry point used by `ImageSendPreviewSheet`.
  ///
  /// Takes the raw picked file (JPEG/PNG/HEIC/…), centre-crops and scales it to
  /// [kImageCodecSquareSize] square, then encodes. Throws on failure so the
  /// sheet can surface it — unlike the nullable service-level methods below,
  /// whose contract is "null means not available".
  @override
  Future<Uint8List> encode(
    Uint8List imageBytes,
    ImageCodecRatePoint rate,
  ) async {
    if (!kImageCodecBitstreamPathAvailable) {
      // Fail here rather than after a 512x512 raster and a session load, and
      // fail with the specific exception so the sheet can say why.
      throw const ImageCodecEntropyPathMissing();
    }
    if (installedBundle?.isComplete != true) {
      // A different failure with a different remedy: the build can do this, the
      // installed files cannot. Do not collapse the two.
      throw const ImageCodecBundleIncomplete();
    }
    final result = await encodeImage(
      rgbBytes: await _toSquareRgb(imageBytes),
      ratePoint: aeicRatePointForUi(rate),
    );
    final bitstream = result?.bitstream;
    if (bitstream == null) {
      throw StateError(_lastError ?? 'Image codec is not available.');
    }
    return bitstream;
  }

  /// Encodes an already-decoded RGB image.
  ///
  /// [rgbBytes] must be exactly `512 * 512 * 3` packed 8-bit RGB. Anything else
  /// is rejected: the decoder's SD-Turbo UNet needs a 64x64 latent, so 512 is a
  /// hard floor, not a default.
  Future<ImageCodecResult?> encodeImage({
    required Uint8List rgbBytes,
    required AeicRatePoint ratePoint,
  }) async {
    if (!canEncode) return null;
    const expected =
        kImageCodecSquareSize * kImageCodecSquareSize * _bytesPerPixel;
    if (rgbBytes.length != expected) {
      throw ArgumentError.value(
        rgbBytes.length,
        'rgbBytes',
        'expected $expected bytes of ${kImageCodecSquareSize}x'
            '$kImageCodecSquareSize RGB',
      );
    }
    return _runCodecJob(
      stage: 'Encoding…',
      ratePoint: ratePoint,
      action: (session) => session.encode(
        rgbBytes,
        ratePoint,
        kImageCodecSquareSize,
        onProgress: _reportCodecProgress,
      ),
      wrap: (bytes, elapsed) => ImageCodecResult(
        bitstream: bytes,
        ratePoint: ratePoint,
        resolution: kImageCodecSquareSize,
        durationMs: elapsed,
        status: ImageCodecStatus.completed,
      ),
    );
  }

  /// Encodes a source file, resizing to 512x512 first.
  ///
  /// Returns null when [canEncode] is false.
  Future<ImageCodecResult?> encodeImageFile({
    required String path,
    AeicRatePoint? ratePoint,
  }) async {
    if (!canEncode) return null;
    final bytes = await _fileStore.readFileBytes(path);
    return encodeImage(
      rgbBytes: await _toSquareRgb(bytes),
      ratePoint: ratePoint ?? defaultRatePoint,
    );
  }

  /// Decodes a reassembled bitstream back to PNG bytes.
  ///
  /// [resolution] comes from the chunk-0 metadata byte; a stream announcing a
  /// resolution this build cannot decode is rejected rather than guessed at.
  Future<ImageCodecResult?> decodeBitstream({
    required Uint8List bitstream,
    required AeicRatePoint ratePoint,
    required int resolution,
  }) async {
    if (!kImageCodecBitstreamPathAvailable) {
      // A received image cannot be silently dropped: the receive path has to be
      // able to tell the user why nothing rendered.
      throw const ImageCodecEntropyPathMissing();
    }
    // `supportsDecode`, not `isComplete`: a bundle-version-1 install has the
    // send-side entropy graph and can encode, but the decode-side graph is what
    // turns bytes back into a latent. Same remedy either way — re-download.
    if (installedBundle?.supportsDecode != true) {
      throw const ImageCodecBundleIncomplete();
    }
    if (!canDecode) return null;
    if (bitstream.isEmpty) return null;
    if (resolution != kImageCodecSquareSize) {
      _lastError = 'Unsupported image resolution: $resolution.';
      _notify();
      return ImageCodecResult(
        ratePoint: ratePoint,
        resolution: resolution,
        durationMs: 0,
        status: ImageCodecStatus.failed,
      );
    }
    // The tables are per-checkpoint. Decoding an ft16 stream against ft32
    // tables does not fail — it desynchronises rANS and yields a sharp,
    // plausible, wrong picture — so a rate mismatch is refused up front. It is
    // a failed *result*, not a throw: it is a property of the received message,
    // not a programming error.
    final installedRate = installedBundle?.ratePoint;
    if (installedRate != null && installedRate != ratePoint) {
      _lastError =
          'This picture was sent at ${ratePoint.name}, but the installed model '
          'is ${installedRate.name}.';
      _notify();
      return ImageCodecResult(
        ratePoint: ratePoint,
        resolution: resolution,
        durationMs: 0,
        status: ImageCodecStatus.failed,
      );
    }
    final result = await _runCodecJob(
      stage: 'Decoding…',
      ratePoint: ratePoint,
      action: (session) => session.decode(
        bitstream,
        ratePoint,
        resolution,
        onProgress: _reportCodecProgress,
      ),
      // The worker returns packed RGB, exactly like decodeLatent. Labelling it
      // `pngBytes` (as this used to) hands the receive path bytes that are not
      // a PNG under a name that says they are; `Image.memory` then fails on a
      // decode that actually succeeded.
      wrap: (bytes, elapsed) => ImageCodecResult(
        rgbBytes: bytes,
        ratePoint: ratePoint,
        resolution: resolution,
        durationMs: elapsed,
        status: ImageCodecStatus.completed,
      ),
    );
    final rgb = result?.rgbBytes;
    if (result == null || rgb == null) {
      return result;
    }
    // Both forms: RGB for anything that wants pixels, PNG for `Image.memory`.
    return ImageCodecResult(
      rgbBytes: rgb,
      pngBytes: await rgbToPng(rgb, result.resolution),
      ratePoint: result.ratePoint,
      resolution: result.resolution,
      durationMs: result.durationMs,
      status: result.status,
    );
  }

  /// Runs the synthesis half of the decoder: latent -> packed 8-bit RGB.
  ///
  /// **This is the only inference path that works in this build.** It is what a
  /// device smoke test should call: dump a `y_hat` from
  /// `aic/exp/aeic_runner.py`, ship the 65,536 float32s to the phone, and
  /// compare the result against the desktop ONNX output. Everything from a
  /// bitstream to `y_hat` needs the entropy path — see
  /// [ImageCodecEntropyPathMissing].
  ///
  /// Returns null when no model is available; the returned result carries
  /// [ImageCodecResult.rgbBytes].
  Future<ImageCodecResult?> decodeLatent(Float32List yHat) async {
    if (!canRunInference) return null;
    if (yHat.length != kImageCodecLatentElements) {
      throw ArgumentError.value(
        yHat.length,
        'yHat',
        'expected $kImageCodecLatentElements float32 latents '
            '(shape $kImageCodecLatentShape)',
      );
    }
    return _runCodecJob(
      stage: 'Rendering…',
      ratePoint: kShippingAeicRatePoint,
      action: (session) =>
          session.decodeLatent(yHat, onProgress: _reportCodecProgress),
      wrap: (bytes, elapsed) => ImageCodecResult(
        rgbBytes: bytes,
        ratePoint: kShippingAeicRatePoint,
        resolution: kImageCodecSquareSize,
        durationMs: elapsed,
        status: ImageCodecStatus.completed,
      ),
    );
  }

  /// [decodeLatent] followed by PNG encoding, for anything that renders an
  /// `Image.memory`.
  Future<ImageCodecResult?> decodeLatentToPng(Float32List yHat) async {
    final result = await decodeLatent(yHat);
    final rgb = result?.rgbBytes;
    if (result == null || rgb == null) {
      return result;
    }
    return ImageCodecResult(
      rgbBytes: rgb,
      pngBytes: await rgbToPng(rgb, result.resolution),
      ratePoint: result.ratePoint,
      resolution: result.resolution,
      durationMs: result.durationMs,
      status: result.status,
    );
  }

  /// Packed 8-bit RGB -> PNG, via `dart:ui` so this adds no dependency.
  ///
  /// Runs on the calling isolate. A single 512x512 raster is four orders of
  /// magnitude cheaper than the 1385 GFLOP decode that produced it.
  static Future<Uint8List> rgbToPng(Uint8List rgb, int side) async {
    final pixels = side * side;
    if (rgb.length != pixels * _bytesPerPixel) {
      throw ArgumentError.value(
        rgb.length,
        'rgb',
        'expected ${pixels * _bytesPerPixel} bytes for ${side}x$side RGB',
      );
    }
    final rgba = Uint8List(pixels * 4);
    for (var i = 0, s = 0, d = 0; i < pixels; i++, s += 3, d += 4) {
      rgba[d] = rgb[s];
      rgba[d + 1] = rgb[s + 1];
      rgba[d + 2] = rgb[s + 2];
      rgba[d + 3] = 0xFF;
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: side,
      height: side,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await descriptor.instantiateCodec();
      image = (await codec.getNextFrame()).image;
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw StateError('Could not PNG-encode the decoded image.');
      }
      return png.buffer.asUint8List();
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor.dispose();
    }
  }

  /// Cooperative cancel for a long encode/decode, mirroring [cancelDownload].
  ///
  /// The worker polls a flag between backend stages; a backend stuck inside one
  /// blocking native call will not notice until that call returns. For a hard
  /// stop use [handleMemoryPressure] / [releaseModel], which kill the isolate.
  void cancelCodecJob() {
    final session = _session;
    if (session == null || _codecStage == null) return;
    _lastError = 'Image processing stopped.';
    session.cancel();
    _notify();
  }

  Future<ImageCodecResult?> _runCodecJob({
    required String stage,
    required AeicRatePoint ratePoint,
    required Future<Uint8List> Function(ImageCodecSession session) action,
    required ImageCodecResult Function(Uint8List bytes, int elapsedMs) wrap,
  }) async {
    final bundle = installedBundle;
    if (bundle == null) return null;
    final started = DateTime.now();
    try {
      return await _runExclusive(() async {
        _setCodecStage('Loading model…', 0);
        final session = await _ensureSession(bundle);
        if (session == null) {
          return null;
        }
        _setCodecStage(stage, 0);
        final bytes = await action(session);
        return wrap(bytes, DateTime.now().difference(started).inMilliseconds);
      });
    } catch (error) {
      _lastError = error.toString();
      appLogger.warn('Image codec job failed: $error', tag: 'ImageCodec');
      return ImageCodecResult(
        ratePoint: ratePoint,
        resolution: kImageCodecSquareSize,
        durationMs: DateTime.now().difference(started).inMilliseconds,
        status: ImageCodecStatus.failed,
      );
    } finally {
      _setCodecStage(null, null);
    }
  }

  // ---- pixel preparation ---------------------------------------------------

  static const int _bytesPerPixel = 3;

  /// Centre-crops [imageBytes] to a square and scales it to
  /// [kImageCodecSquareSize], returning packed 8-bit RGB.
  ///
  /// Uses `dart:ui` rather than a decode package so this adds no dependency.
  /// It runs on the root isolate, which is acceptable: it is a single 512x512
  /// raster, three orders of magnitude cheaper than the 1385 GFLOP inference
  /// that follows in the worker.
  Future<Uint8List> _toSquareRgb(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final source = frame.image;
    ui.Image? scaled;
    try {
      // The WHOLE frame, stretched to the square — not a centre crop.
      // Aspect ratio is deliberately not preserved: the codec's graph is
      // statically 512x512, so something has to give, and losing 25% of a 4:3
      // photo (44% of 16:9, or the subject's head in a portrait) is worse than
      // distorting it. Nothing outside the frame is discarded this way.
      // NOTE: the aspect ratio is NOT transmitted, so the receiver cannot undo
      // the stretch — see the note in image_chunk_transport.dart on the
      // metadata byte.
      final src = ui.Rect.fromLTWH(
        0,
        0,
        source.width.toDouble(),
        source.height.toDouble(),
      );
      final dstSize = kImageCodecSquareSize.toDouble();
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        source,
        src,
        ui.Rect.fromLTWH(0, 0, dstSize, dstSize),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      final picture = recorder.endRecording();
      try {
        scaled = await picture.toImage(
          kImageCodecSquareSize,
          kImageCodecSquareSize,
        );
      } finally {
        picture.dispose();
      }
      final rgba = await scaled.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) {
        throw StateError('Could not rasterise the image.');
      }
      return _rgbaToRgb(rgba.buffer.asUint8List());
    } finally {
      scaled?.dispose();
      source.dispose();
      codec.dispose();
    }
  }

  static Uint8List _rgbaToRgb(Uint8List rgba) {
    final pixels = rgba.length ~/ 4;
    final rgb = Uint8List(pixels * _bytesPerPixel);
    for (var i = 0, o = 0; i < rgba.length; i += 4, o += _bytesPerPixel) {
      rgb[o] = rgba[i];
      rgb[o + 1] = rgba[i + 1];
      rgb[o + 2] = rgba[i + 2];
    }
    return rgb;
  }

  // ---- model memory (mirrors translation_service.dart:586-629) -------------

  Future<ImageCodecSession?> _ensureSession(ImageCodecBundle bundle) async {
    if (_session != null && _loadedBundle == bundle) {
      return _session;
    }
    if (bundle == _failedBundle) {
      return null;
    }
    final previous = _session;
    if (previous != null) {
      _session = null;
      _loadedBundle = null;
      await previous.dispose();
    }
    try {
      final session = await ImageCodecSession.spawn(bundle);
      _session = session;
      _loadedBundle = bundle;
      _failedBundle = null;
      return session;
    } on ImageCodecUnimplemented catch (error) {
      // No inference runtime in this build; retrying can never help, so poison
      // the whole feature rather than just this path.
      _backendMissing = true;
      _failedBundle = bundle;
      _lastError = error.toString();
      appLogger.warn('Image codec unavailable: $error', tag: 'ImageCodec');
      _notify();
      return null;
    } catch (_) {
      _failedBundle = bundle;
      rethrow;
    }
  }

  Future<void> releaseModel() async {
    await _runExclusive(() async {
      final session = _session;
      if (session == null) {
        _loadedBundle = null;
        return;
      }
      _session = null;
      _loadedBundle = null;
      await session.dispose();
    });
  }

  /// Drops the ~2.16 GiB image decoder session, keeping the isolate and the
  /// ~0.35 GiB entropy session alive.
  ///
  /// This is the cheap eviction: measured, 2.44 GiB resident falls to 0.35 GiB,
  /// and it leaves the send path warm because encoding never touches the image
  /// decoder. Safe to call when nothing is loaded.
  Future<void> releaseDecoderSession() async {
    final session = _session;
    if (session == null) return;
    await session.release(decoder: true);
    appLogger.info('Image codec decoder session released', tag: 'ImageCodec');
  }

  /// Drops the entropy session (whichever direction is resident), keeping the
  /// image decoder.
  ///
  /// Rarely what you want on its own — `decode()` does it internally between
  /// the entropy half and the synthesis half — and it is the WRONG half to shed
  /// under memory pressure: it frees 0.35 GiB and costs the send path its warm
  /// session. Exposed only so a host that knows no send is coming can shed it.
  Future<void> releaseEntropySession() async {
    final session = _session;
    if (session == null) return;
    await session.release(entropy: true);
  }

  /// Sheds codec memory under pressure.
  ///
  /// Not present in [TranslationService], and required here: the decode graph
  /// peaks around 2.16 GiB resident, far above what Android will let a
  /// backgrounded app keep. Wire it to an app-level [WidgetsBindingObserver] —
  /// `didChangeAppLifecycleState` (paused/hidden) and `didHaveMemoryPressure`.
  /// Idempotent and safe when nothing is loaded.
  ///
  /// Order matters: the IMAGE DECODER goes first, always. Measured, it is
  /// 2.16 GiB of a 2.44 GiB peak — 89% of the resident set — and it is the half
  /// the *send* path does not need. On a soft eviction ([keepEntropySession])
  /// the 0.35 GiB entropy graph is deliberately kept, so a user who backgrounds
  /// the app and comes back to send a photo pays nothing while the big half is
  /// already gone. Never invert this: dropping the entropy graph first would
  /// free an eighth of the memory and cost the only path that was warm.
  ///
  /// The default is still the hard stop — kill the isolate — because that also
  /// returns ORT's arena and any native allocation the plugin is holding, which
  /// closing sessions alone does not.
  Future<void> handleMemoryPressure({bool keepEntropySession = false}) async {
    final session = _session;
    if (session == null && _loadedBundle == null) {
      return;
    }
    // Deliberately does NOT go through _runExclusive: memory pressure arrives
    // while a decode may be mid-flight and holding the lock, and that decode is
    // exactly what has to die. Killing the isolate fails its pending futures,
    // which _runCodecJob reports as a failed result.
    if (keepEntropySession && session != null) {
      await session.release(decoder: true);
      appLogger.info(
        'Image codec decoder evicted (entropy session kept)',
        tag: 'ImageCodec',
      );
      _notify();
      return;
    }
    _session = null;
    _loadedBundle = null;
    _codecProgress = null;
    _codecStage = null;
    if (session != null) {
      // Ask for the big half back before the shutdown handshake, so the peak
      // does not have to wait on isolate teardown.
      await session.release(decoder: true);
      await session.dispose();
    }
    appLogger.info('Image codec model evicted', tag: 'ImageCodec');
    _notify();
  }

  // ---- plumbing (copied from translation_service.dart:631-698) ------------

  Future<T> _runExclusive<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _setBusy(true);
    _queue = _queue.then((_) async {
      if (_disposed) {
        completer.completeError(StateError('ImageCodecService disposed.'));
        return;
      }
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
        throw const ImageCodecDownloadCancelled();
      }
      _downloadedBytes += chunk.length;
      _notify();
      yield chunk;
    }
  }

  void _reportCodecProgress(double value) {
    _codecProgress = value.clamp(0.0, 1.0);
    _notify();
  }

  void _setCodecStage(String? stage, double? progress) {
    _codecStage = stage;
    _codecProgress = progress;
    _notify();
  }

  void _notify() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  void _setBusy(bool value) {
    if (_isBusy == value) {
      return;
    }
    _isBusy = value;
    _notify();
  }

  void _setDownloading(bool value) {
    _isDownloading = value;
    if (!value) {
      _cancelDownloadRequested = false;
      _downloadedBytes = 0;
      _downloadTotalBytes = null;
      _downloadFileName = null;
    }
    _notify();
  }

  /// Sweeps resume state for a model the user is no longer downloading.
  ///
  /// Spec-shaped rather than filename-shaped: a bundle leaves chunk files for
  /// up to four assets, and sweeping only the graph's would strand ~900 MB of
  /// hidden resume state that nothing ever collects.
  Future<void> discardPartialDownload(ImageCodecModelSpec spec) async {
    for (final asset in spec.assets) {
      await _fileStore.deletePartialDownloads(asset.fileName);
    }
  }

  /// Sweeps resume state for one file, for the custom-URL install path.
  Future<void> discardPartialDownloadFile(String fileName) =>
      _fileStore.deletePartialDownloads(fileName);

  String _sanitizeFileName(String fileName) {
    final cleaned = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'image-codec-model.onnx' : cleaned;
  }

  @override
  void dispose() {
    _disposed = true;
    final session = _session;
    _session = null;
    _loadedBundle = null;
    if (session != null) {
      unawaited(session.dispose());
    }
    super.dispose();
  }
}

/// What a HEAD probe told us about a model asset.
class _HeadResult {
  final int? contentLength;
  final bool supportsRange;

  const _HeadResult({required this.contentLength, required this.supportsRange});
}
