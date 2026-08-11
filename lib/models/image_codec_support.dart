import 'dart:typed_data';

import '../widgets/image_send_codec_binding.dart';

/// Model registry + value types for the neural image codec (AEIC-SE).
///
/// Mirrors `lib/models/translation_support.dart` field-for-field so the
/// settings screen, the file store and the download machinery can be copied
/// from the translation stack with no structural changes.

enum ImageCodecStatus { none, pending, completed, failed, skipped }

extension ImageCodecStatusValue on ImageCodecStatus {
  String get value {
    switch (this) {
      case ImageCodecStatus.pending:
        return 'pending';
      case ImageCodecStatus.completed:
        return 'completed';
      case ImageCodecStatus.failed:
        return 'failed';
      case ImageCodecStatus.skipped:
        return 'skipped';
      case ImageCodecStatus.none:
        return 'none';
    }
  }
}

ImageCodecStatus parseImageCodecStatus(dynamic value) {
  if (value is! String) {
    return ImageCodecStatus.none;
  }
  for (final status in ImageCodecStatus.values) {
    if (status.value == value) {
      return status;
    }
  }
  return ImageCodecStatus.none;
}

/// Shape of the decoder's only input tensor: `y_hat`, float32,
/// `[1, 256, 16, 16]`. Static — the export has no dynamic axes and no batching.
const List<int> kImageCodecLatentShape = <int>[1, 256, 16, 16];

/// Element count implied by [kImageCodecLatentShape] (65,536).
const int kImageCodecLatentElements = 256 * 16 * 16;

/// Graph input/output names in the promoted export. Used as a preference when
/// binding tensors; the backend falls back to the graph's sole input/output if
/// a future re-export renames them.
const String kImageCodecDecoderInputName = 'y_hat';
const String kImageCodecDecoderOutputName = 'image';

/// Rate point = which `AEIC_SE_ft*.pkl` the encoder was fine-tuned from.
///
/// **ft32 IS THE ONLY SHIPPING RATE POINT** ([kShippingAeicRatePoint]). One
/// checkpoint ships, so [aeicRatePointForUi] is constant and the UI has no
/// quality selector to honour. The other members are retained *only* because
/// their ordinals are already persisted in `image_codec_rate_point` and cross
/// the isolate boundary, and because the measured byte counts below are real
/// data worth keeping. Do not reorder, do not add a second shipping entry
/// without a second model in [imageCodecPresetModels].
///
/// NOTE ON THE WIRE VALUE. This enum's ordinal is NOT the on-air rate nibble.
/// The on-air chunk-0 metadata byte is defined by `ImageStreamMetadata` in
/// `lib/services/image_chunk_transport.dart` and carries
/// [ImageCodecRatePoint.index], because the transport only ever exposes UI rate
/// points. [AeicRatePointValue]'s `wireValue` is the *model-selection ordinal*:
/// it is what gets persisted in settings and what crosses the isolate boundary
/// to pick a checkpoint. Convert with [aeicRatePointForUi] /
/// [uiRatePointForAeic]; never assume they are the same integer.
///
/// Measured real rANS bitstream sizes at 512x512 over 26 images
/// (Kodak 24 + 2 custom). `ft2`/`ft4` have not been measured on this corpus.
enum AeicRatePoint { ft2, ft4, ft8, ft16, ft32 }

/// The one rate point this build encodes and decodes at.
///
/// ft32: mean 155.8 B, min 110 B, max 209 B over the 26-image corpus, i.e. 1-2
/// data chunks plus one XOR parity chunk. ft16 was dropped: it needs 2-3 data
/// chunks and leaves only 79 B of headroom under the 3-chunk ceiling.
const AeicRatePoint kShippingAeicRatePoint = AeicRatePoint.ft32;

extension AeicRatePointValue on AeicRatePoint {
  int get wireValue => index;

  /// Mean measured bitstream size in bytes, or `null` where unmeasured.
  int? get meanBytes {
    switch (this) {
      case AeicRatePoint.ft2:
      case AeicRatePoint.ft4:
        return null;
      case AeicRatePoint.ft8:
        return 507;
      case AeicRatePoint.ft16:
        return 288;
      case AeicRatePoint.ft32:
        return 156;
    }
  }

  /// Largest bitstream observed on the measurement corpus, or `null`.
  int? get maxBytes {
    switch (this) {
      case AeicRatePoint.ft2:
      case AeicRatePoint.ft4:
        return null;
      case AeicRatePoint.ft8:
        return 732;
      case AeicRatePoint.ft16:
        return 409;
      case AeicRatePoint.ft32:
        return 209;
    }
  }

  /// `'ft32 (~156 B)'`. Uses the enum's own `name` for the prefix — do not add
  /// a `name` getter here, it would collide with `dart:core`'s `EnumName`.
  String get label {
    final mean = meanBytes;
    return mean == null ? name : '$name (~$mean B)';
  }
}

AeicRatePoint parseAeicRatePoint(int wireValue) {
  if (wireValue < 0 || wireValue >= AeicRatePoint.values.length) {
    return kShippingAeicRatePoint;
  }
  return AeicRatePoint.values[wireValue];
}

/// Maps the UI-level rate selector onto the codec's rate points.
///
/// ft32-only, so this is deliberately constant and ignores [rate]. It is kept
/// as a function (rather than inlining [kShippingAeicRatePoint] at the call
/// sites) so that adding a second checkpoint is a one-function change, and so
/// this file never names an [ImageCodecRatePoint] member — that enum is owned by
/// `image_send_codec_binding.dart` and its membership is the UI's to shrink.
AeicRatePoint aeicRatePointForUi(ImageCodecRatePoint rate) =>
    kShippingAeicRatePoint;

/// Inverse of [aeicRatePointForUi]. Constant for the same reason: every rate
/// point this build can produce is the standard one.
ImageCodecRatePoint uiRatePointForAeic(AeicRatePoint rate) =>
    ImageCodecRatePoint.standard;

/// Bundle layout revision written into [ImageCodecModelRecord.bundleVersion].
///
/// 0 means "installed before the entropy bundle existed", i.e. a decoder-only
/// install that can render a latent but cannot encode or decode a bitstream.
/// Bump this only when the *set of files* a model needs changes; it is what
/// `ImageCodecService.needsModelUpgrade` keys off.
///
/// 1 -> 2: the bundle gained the **decode-side** entropy graph
/// (`aeic_entropy_decode_fp32_op17.onnx`). A version-1 install has the
/// send-side graph only, so it can encode but cannot decode a bitstream; the
/// remedy is a re-download, which is exactly what `needsModelUpgrade` asks for.
const int kImageCodecBundleVersion = 2;

/// Same shape and field order as `TranslationModelRecord`, plus the two fields
/// a multi-asset install needs.
class ImageCodecModelRecord {
  final String id;
  final String name;
  final String sourceUrl;

  /// Path of the **decoder graph** — the file ONNX Runtime is handed. The other
  /// assets are its siblings in the same directory; see [assetFileNames].
  final String localPath;

  final DateTime downloadedAt;
  final int fileSizeBytes;

  /// Every file that was installed for this model, by exact on-disk name.
  ///
  /// Recorded rather than re-derived so the service can locate the entropy
  /// graph and the CDF tables without guessing filenames, and so `deleteModel`
  /// can remove all ~1.0 GB instead of just the 3 MB graph.
  final List<String> assetFileNames;

  /// What each installed file IS, keyed by its exact on-disk name.
  ///
  /// Recorded at install time because [assetFileNames] alone stopped being
  /// enough at bundle version 2: the bundle now holds THREE `.onnx` files —
  /// the synthesis decoder, the send-side entropy graph and the decode-side
  /// entropy graph — and no property of a filename distinguishes the last two.
  /// Handing the decode-side export to the encoder fails at the first run;
  /// handing the send-side one to the decoder would feed rANS the wrong
  /// probabilities, which is the silent-corruption failure mode.
  ///
  /// Empty for records written before this field existed. Consumers fall back
  /// to the registry spec, and only then to a filename heuristic.
  final Map<String, ImageCodecAssetRole> assetRoles;

  /// [kImageCodecBundleVersion] at install time; 0 for a pre-bundle install.
  final int bundleVersion;

  const ImageCodecModelRecord({
    required this.id,
    required this.name,
    required this.sourceUrl,
    required this.localPath,
    required this.downloadedAt,
    required this.fileSizeBytes,
    this.assetFileNames = const [],
    this.assetRoles = const {},
    this.bundleVersion = 0,
  });

  /// The installed file recorded as [role], or null when none was.
  String? fileNameForRole(ImageCodecAssetRole role) {
    for (final entry in assetRoles.entries) {
      if (entry.value == role && assetFileNames.contains(entry.key)) {
        return entry.key;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source_url': sourceUrl,
      'local_path': localPath,
      'downloaded_at': downloadedAt.millisecondsSinceEpoch,
      'file_size_bytes': fileSizeBytes,
      'asset_file_names': assetFileNames,
      // Role NAMES, not ordinals: appending a member to ImageCodecAssetRole
      // must never re-label files already on disk.
      'asset_roles': <String, String>{
        for (final entry in assetRoles.entries) entry.key: entry.value.name,
      },
      'bundle_version': bundleVersion,
    };
  }

  factory ImageCodecModelRecord.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['asset_file_names'];
    final rawRoles = json['asset_roles'];
    return ImageCodecModelRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      localPath: json['local_path'] as String? ?? '',
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(
        json['downloaded_at'] as int? ?? 0,
      ),
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      assetFileNames: rawAssets is List
          ? [
              for (final entry in rawAssets)
                if (entry is String && entry.isNotEmpty) entry,
            ]
          : const [],
      assetRoles: rawRoles is Map
          ? <String, ImageCodecAssetRole>{
              for (final entry in rawRoles.entries)
                if (entry.key is String && entry.value is String)
                  entry.key as String: ?parseImageCodecAssetRole(
                    entry.value as String,
                  ),
            }
          : const {},
      bundleVersion: json['bundle_version'] as int? ?? 0,
    );
  }

  ImageCodecModelRecord copyWith({
    String? id,
    String? name,
    String? sourceUrl,
    String? localPath,
    DateTime? downloadedAt,
    int? fileSizeBytes,
    List<String>? assetFileNames,
    Map<String, ImageCodecAssetRole>? assetRoles,
    int? bundleVersion,
  }) {
    return ImageCodecModelRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      localPath: localPath ?? this.localPath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      assetFileNames: assetFileNames ?? this.assetFileNames,
      assetRoles: assetRoles ?? this.assetRoles,
      bundleVersion: bundleVersion ?? this.bundleVersion,
    );
  }
}

String imageCodecModelFriendlyName(ImageCodecModelRecord model) {
  for (final spec in imageCodecPresetModels) {
    if (spec.id == model.id || spec.fileName == model.name) {
      return spec.label;
    }
  }
  final trimmed = model.name.trim();
  if (trimmed.endsWith('.onnx')) {
    return trimmed.substring(0, trimmed.length - 5);
  }
  return trimmed.isEmpty ? model.id : trimmed;
}

/// What a downloaded file *is*, so nothing has to infer it from position or
/// filename.
///
/// This exists because the bundle stopped being "graph, then its data sibling".
/// `assets.first` is a decoder graph today and would silently become the
/// entropy graph the moment anyone reordered the list; the ONNX session would
/// then load 67 MB of entropy model and fail on an input named `y_hat`.
enum ImageCodecAssetRole {
  /// The synthesis graph handed to ORT: `y_hat -> image`.
  decoderGraph,

  /// `<decoderGraph>.data`. ORT resolves it by the literal filename recorded
  /// inside the graph, so it MUST sit beside [decoderGraph] under that name.
  decoderWeights,

  /// The fp32 **send-side** entropy graph: one input `image [1,3,512,512]`,
  /// outputs `z_q`, `yq0..3`, `sc0..3`. Kept fp32 deliberately — see the
  /// bit-exactness note in `image_codec_backend.dart`.
  ///
  /// This is the ENCODE half only. It emits every stage at once, which is valid
  /// because the encoder already knows `y`; a decoder cannot use it at all.
  entropyGraph,

  /// Reserved. The 67 MB entropy export is self-contained today and carries no
  /// external-data sibling; the role exists so a future re-export that does is
  /// a registry change rather than a schema change.
  entropyWeights,

  /// The quantised CDF tables the rANS coder indexes. A *wrong* table set
  /// desynchronises rANS and yields a sharp, plausible, wrong image with no
  /// error, which is why this asset must carry a SHA-256 before ship.
  cdfTables,

  /// The fp32 **decode-side** entropy graph, added in bundle version 2.
  ///
  /// Decoding is inherently sequential — the symbols of stage `i` must be
  /// decoded before stage `i+1`'s context exists — so the receiver cannot use
  /// the emit-everything-at-once [entropyGraph]. This export is the same
  /// sub-networks behind an ONNX `If` on a `stage` selector, so the app can
  /// call it five times per image:
  ///
  ///   inputs : `z_q [1,128,4,4]`, `base [1,256,16,16]`, `stage int32 [1]`
  ///   outputs: `base0`, `means`, `scales`, all `[1,256,16,16]`
  ///
  /// `stage < 0` runs the hyper-synthesis branch and fills `base0`;
  /// `stage 0..3` runs the context branch and fills `means`/`scales`, already
  /// multiplied by that stage's mask. The branch not taken emits zeros.
  ///
  /// Appended after [cdfTables] rather than beside [entropyGraph] so no
  /// existing enum ordinal moves.
  entropyDecodeGraph,
}

/// Parses a role written by [ImageCodecModelRecord.toJson], or null when the
/// string names no role this build knows.
///
/// Null rather than a default: a record from a NEWER build may name a role that
/// does not exist here, and silently filing it under some other role would be
/// worse than admitting the file's purpose is unknown.
ImageCodecAssetRole? parseImageCodecAssetRole(String value) {
  for (final role in ImageCodecAssetRole.values) {
    if (role.name == value) {
      return role;
    }
  }
  return null;
}

/// One downloadable file belonging to a model.
///
/// A model is not always one file. The promoted decoder is an ONNX graph plus an
/// external-weights sibling (`<name>.onnx.data`, referenced by relative filename
/// from inside the graph), and ONNX Runtime will not load the graph unless the
/// sibling sits next to it under exactly that name. Downloading only the 2.8 MB
/// graph produces an `ORT_INVALID_PROTOBUF`-class failure at session creation,
/// which is indistinguishable from a corrupt download — hence [sha256].
class ImageCodecModelAsset {
  /// Name the file must have on disk. Not derived from the URL: the external
  /// data reference inside the graph is a literal filename.
  final String fileName;

  final String sourceUrl;

  /// Expected size in bytes. Advisory — the download re-reads it from the HEAD
  /// response — but it is what the UI shows before the first byte arrives.
  final int sizeBytes;

  /// Lowercase hex SHA-256 of the file, or `''` when no digest is known.
  ///
  /// An empty value **skips verification**; see [hasChecksum]. That is the state
  /// today, deliberately: nothing has been uploaded, so no digest of a
  /// *published* file exists and a hard-failing guess would block the feature.
  final String sha256;

  /// What this file is for. See [ImageCodecAssetRole].
  final ImageCodecAssetRole role;

  const ImageCodecModelAsset({
    required this.fileName,
    required this.sourceUrl,
    required this.sizeBytes,
    required this.role,
    this.sha256 = '',
  });

  bool get hasChecksum => sha256.length == 64;
}

/// A declared preset model: its identity plus every file it needs on disk.
///
/// Mirrors the role of `translationPresetModels` (translation_support.dart:117)
/// but is a *spec*, not an [ImageCodecModelRecord]. Records describe what is
/// actually on this device (path, mtime, real size); specs describe what could
/// be fetched. Conflating them is what made the translation stack unable to
/// express a two-file model.
class ImageCodecModelSpec {
  final String id;
  final String label;

  /// Every file the model needs, tagged by [ImageCodecAssetRole]. Downloaded in
  /// list order into one directory; the order is a download preference only —
  /// nothing resolves an asset by position.
  final List<ImageCodecModelAsset> assets;

  /// True while [assets] carry URLs that have never been fetched by anybody.
  /// The UI must not offer a download for a spec with this set unless the user
  /// has supplied their own URL. See the note on [imageCodecPresetModels].
  final bool urlsArePlaceholders;

  /// Which checkpoint these graphs and tables belong to.
  ///
  /// Tables and graphs are per-checkpoint and are not interchangeable: decoding
  /// an ft32 bitstream with ft16 tables desynchronises rANS. The bundle's rate
  /// point is checked against the bitstream's chunk-0 metadata before a decode.
  final AeicRatePoint ratePoint;

  const ImageCodecModelSpec({
    required this.id,
    required this.label,
    required this.assets,
    this.ratePoint = kShippingAeicRatePoint,
    this.urlsArePlaceholders = false,
  });

  /// The one asset with [role], or throws when the spec omits it.
  ImageCodecModelAsset assetFor(ImageCodecAssetRole role) =>
      assets.firstWhere((asset) => asset.role == role);

  ImageCodecModelAsset? maybeAssetFor(ImageCodecAssetRole role) {
    for (final asset in assets) {
      if (asset.role == role) return asset;
    }
    return null;
  }

  /// The decoder graph — the path handed to ONNX Runtime.
  ///
  /// Defined by role, not by position. Kept under the old name so the settings
  /// screen and [imageCodecModelFriendlyName] keep working.
  ImageCodecModelAsset get graph => assetFor(ImageCodecAssetRole.decoderGraph);

  String get fileName => graph.fileName;

  int get totalSizeBytes =>
      assets.fold<int>(0, (sum, asset) => sum + asset.sizeBytes);

  /// True when this spec describes a bundle that can encode AND decode.
  ///
  /// All five roles, not four: without [ImageCodecAssetRole.entropyDecodeGraph]
  /// the install could send a picture and never open one.
  bool get isComplete =>
      maybeAssetFor(ImageCodecAssetRole.decoderGraph) != null &&
      maybeAssetFor(ImageCodecAssetRole.decoderWeights) != null &&
      maybeAssetFor(ImageCodecAssetRole.entropyGraph) != null &&
      maybeAssetFor(ImageCodecAssetRole.entropyDecodeGraph) != null &&
      maybeAssetFor(ImageCodecAssetRole.cdfTables) != null;
}

/// The set of on-disk paths a codec session needs, replacing the bare
/// `String modelPath` that used to cross the isolate boundary.
///
/// [entropyGraphPath], [entropyDecodeGraphPath] and [tablesPath] are nullable
/// because a build that was installed before the entropy bundle existed has
/// none of them, and that install must keep working for latent synthesis rather
/// than becoming unloadable.
class ImageCodecBundle {
  /// `*.onnx`; its `*.onnx.data` sibling must be in the same directory under
  /// the exact filename the graph records.
  final String decoderGraphPath;

  /// fp32 **send-side** entropy graph (`image -> z_q, yq*, sc*`), or null on a
  /// pre-bundle install. Encoding needs this one and only this one.
  final String? entropyGraphPath;

  /// fp32 **decode-side** entropy graph (`z_q, base, stage -> base0, means,
  /// scales`), or null on a bundle-version-1 (or pre-bundle) install.
  ///
  /// Separate from [entropyGraphPath] because they are two different exports of
  /// the same weights: the send side emits all four stages at once, which a
  /// decoder cannot use, and a decoder needs the `If`-branched graph it can call
  /// five times per image. See [ImageCodecAssetRole.entropyDecodeGraph].
  final String? entropyDecodeGraphPath;

  /// CDF tables binary, or null on a pre-bundle install.
  final String? tablesPath;

  /// Checkpoint the graphs and tables belong to.
  final AeicRatePoint ratePoint;

  const ImageCodecBundle({
    required this.decoderGraphPath,
    this.entropyGraphPath,
    this.entropyDecodeGraphPath,
    this.tablesPath,
    this.ratePoint = kShippingAeicRatePoint,
  });

  /// True when this install can run the **send** half of the entropy path.
  ///
  /// Deliberately does NOT require [entropyDecodeGraphPath]: a version-1 install
  /// can still encode, and reporting it as unable to do anything would be wrong.
  /// Use [supportsDecode] to gate a decode.
  bool get isComplete => entropyGraphPath != null && tablesPath != null;

  /// True when this install can also turn a bitstream back into a picture.
  bool get supportsDecode => isComplete && entropyDecodeGraphPath != null;

  @override
  bool operator ==(Object other) =>
      other is ImageCodecBundle &&
      other.decoderGraphPath == decoderGraphPath &&
      other.entropyGraphPath == entropyGraphPath &&
      other.entropyDecodeGraphPath == entropyDecodeGraphPath &&
      other.tablesPath == tablesPath &&
      other.ratePoint == ratePoint;

  @override
  int get hashCode => Object.hash(
    decoderGraphPath,
    entropyGraphPath,
    entropyDecodeGraphPath,
    tablesPath,
    ratePoint,
  );

  @override
  String toString() =>
      'ImageCodecBundle(decoder: $decoderGraphPath, entropy: $entropyGraphPath, '
      'entropyDecode: $entropyDecodeGraphPath, tables: $tablesPath, '
      'rate: ${ratePoint.name})';
}

/// Published bundle: https://huggingface.co/zjs81/aeic-se-onnx
///
/// URL shape matches `translation_support.dart`:
/// `https://huggingface.co/<repo>/resolve/main/<file>?download=true`.
///
/// Sizes and digests below are of the published bytes, verified against the
/// local exports under `/Users/Zach/Documents/mycode/aic`. The CDF digest is
/// not optional: a table set that disagrees with the checkpoint desynchronises
/// rANS and produces a sharp, plausible, WRONG image with no error anywhere.
///
/// EXACTLY ONE ENTRY, and it is ONE bundle rather than a send-only and a
/// receive-capable download: encode needs the entropy graph + tables, decode
/// needs those *and* the decoder, so splitting them only creates an install
/// that can do half the feature.
///
/// WHY `qdq_conv_pct` AND NOT `qdq_conv_pct_novae`. The `novae` variant leaves
/// the VAE decoder in fp32, and the VAE is the only part that runs at full
/// 512x512, so its activations dominate: 872 MB on disk and 2.99 GiB peak RSS
/// against 835 MB / 2.16 GiB here, for 0.17 dB against the ORIGINAL image.
/// 830 MB of phone RAM is the wrong price for that on the platform where RAM,
/// not quality, is the binding constraint.
final List<ImageCodecModelSpec> imageCodecPresetModels = [
  const ImageCodecModelSpec(
    id: 'aeic-se-ft32-bundle-v1',
    label: 'AEIC-SE 512 image codec (ft32)',
    ratePoint: AeicRatePoint.ft32,
    urlsArePlaceholders: false,
    assets: [
      ImageCodecModelAsset(
        role: ImageCodecAssetRole.decoderGraph,
        fileName: 'aeic_decoder_qdq_conv_pct.onnx',
        sourceUrl:
            'https://huggingface.co/zjs81/aeic-se-onnx/resolve/main/aeic_decoder_qdq_conv_pct.onnx?download=true',
        sizeBytes: 3066597,
        sha256:
            'fa1ca65c52ecb9e1ec43c05ef792ac8b95ecab21dcb6ab89a825b4dad6a5a571',
      ),
      ImageCodecModelAsset(
        role: ImageCodecAssetRole.decoderWeights,
        fileName: 'aeic_decoder_qdq_conv_pct.onnx.data',
        sourceUrl:
            'https://huggingface.co/zjs81/aeic-se-onnx/resolve/main/aeic_decoder_qdq_conv_pct.onnx.data?download=true',
        sizeBytes: 872896480,
        sha256:
            'f7714df0ec8cc495be1fb4bad3be0458c186c8a61d87b8487f2e8e6b84b8242a',
      ),
      ImageCodecModelAsset(
        role: ImageCodecAssetRole.entropyGraph,
        fileName: 'aeic_entropy_side_fp32_op17.onnx',
        sourceUrl:
            'https://huggingface.co/zjs81/aeic-se-onnx/resolve/main/aeic_entropy_side_fp32_op17.onnx?download=true',
        sizeBytes: 67262167,
        sha256:
            'b7b55b0f6a8a02ec2e8f6e85820c064c741c870c226d276c78df45e83ca1a9d6',
      ),
      //   Local digest, for the uploader to confirm the bytes match:
      //   efcbbc4829a0029f487f17b7b52373c6af339d7f74a6417463981d0778d6d444
      ImageCodecModelAsset(
        role: ImageCodecAssetRole.entropyDecodeGraph,
        fileName: 'aeic_entropy_decode_fp32_op17.onnx',
        sourceUrl:
            'https://huggingface.co/zjs81/aeic-se-onnx/resolve/main/aeic_entropy_decode_fp32_op17.onnx?download=true',
        sizeBytes: 60509540,
        sha256:
            'efcbbc4829a0029f487f17b7b52373c6af339d7f74a6417463981d0778d6d444',
      ),
      ImageCodecModelAsset(
        role: ImageCodecAssetRole.cdfTables,
        fileName: 'aeic_cdf_ft32.bin',
        sourceUrl:
            'https://huggingface.co/zjs81/aeic-se-onnx/resolve/main/aeic_cdf_ft32.bin?download=true',
        sizeBytes: 813648,
        sha256:
            '4089fde2af16c340642a5c857be42f6d0f21caf71dd5b4f32d62efcd41c77bd5',
      ),
    ],
  ),
];

/// Total download for the one shipping bundle: 1,004,548,432 B (958.0 MiB).
///
/// Named so the pre-flight space check and the tests share one number instead
/// of each re-summing the asset list. Breakdown: 835 MiB decoder (graph +
/// external weights), 64.1 MiB send-side entropy graph, 57.7 MiB decode-side
/// entropy graph, 0.8 MiB CDF tables.
const int kImageCodecBundleTotalBytes = 1004548432;

/// Result of an encode or a decode.
class ImageCodecResult {
  /// Encode result: the compressed payload only, with no chunk headers.
  final Uint8List? bitstream;

  /// Decode result: PNG-encoded RGB image.
  final Uint8List? pngBytes;

  /// Decode result: packed 8-bit RGB, `resolution * resolution * 3` bytes.
  ///
  /// This is what the inference backend actually produces; [pngBytes] is an
  /// optional re-encoding of it for widgets that want an `Image.memory`.
  final Uint8List? rgbBytes;

  final AeicRatePoint ratePoint;

  /// Square edge length. 512 today and a hard floor — the SD-Turbo UNet in the
  /// decoder needs a 64x64 latent and collapses below it.
  final int resolution;

  final int durationMs;
  final ImageCodecStatus status;

  const ImageCodecResult({
    required this.ratePoint,
    required this.resolution,
    required this.durationMs,
    required this.status,
    this.bitstream,
    this.pngBytes,
    this.rgbBytes,
  });
}

class ImageCodecDownloadCancelled implements Exception {
  const ImageCodecDownloadCancelled();

  @override
  String toString() => 'Download canceled.';
}

/// Raised by the codec session while the native inference seam is unimplemented.
class ImageCodecUnimplemented implements Exception {
  final String detail;

  const ImageCodecUnimplemented(this.detail);

  @override
  String toString() => 'Image codec backend not implemented: $detail';
}

/// Raised when a bitstream-level [encode]/[decode] is attempted but the entropy
/// path is not present in this build.
///
/// WHY THIS EXISTS AND WHY IT IS NOT A BUG TO FIX HERE. The shipping ONNX
/// artifact is the **synthesis half only**: `y_hat [1,256,16,16] -> image
/// [1,3,512,512]`. Turning bytes into `y_hat` (and back) needs two more things
/// that do not exist in Dart or in the shipped artifact:
///
///   1. the entropy-side graph (`h_s`, `g_c` and the four adapters, kept in
///      fp32 — `aic/onnx/aeic_entropy_side_fp32_op*.onnx`, 67 MB, not exported
///      into the shipped model), and
///   2. the rANS range coder itself, which today exists only as the AEIC C++
///      extension (`aic/aeic/src/codec/MLCodec_rans*.so`).
///
/// Until both land, [ImageCodecBackend.decodeLatentToRgb] is the real, working
/// entry point and the bitstream methods throw this. Faking them is not an
/// option: an rANS desync produces a sharp, plausible, *wrong* image with no
/// error raised, so a stub that returns noise-shaped bytes would be
/// indistinguishable from the genuine failure mode this codec already has.
class ImageCodecEntropyPathMissing extends ImageCodecUnimplemented {
  const ImageCodecEntropyPathMissing([
    super.detail =
        'the rANS entropy path (entropy-side graph + range coder) is not part '
        'of this build; only latent->image synthesis is available',
  ]);
}

/// Raised when a bitstream operation is attempted against an install that
/// predates the entropy bundle.
///
/// Distinct from [ImageCodecEntropyPathMissing] on purpose. That one means the
/// *build* cannot do this and no user action helps; this one means the *files
/// on this device* are a decoder-only install and the remedy is a download.
/// Reporting the second as the first is what would strand every user who
/// installed the decoder-only build.
class ImageCodecBundleIncomplete extends ImageCodecUnimplemented {
  const ImageCodecBundleIncomplete([
    super.detail =
        'the installed model predates the entropy bundle; re-download the '
        'image codec model',
  ]);
}

/// Raised when a downloaded asset's SHA-256 does not match the expected digest.
class ImageCodecIntegrityFailure implements Exception {
  final String fileName;
  final String expected;
  final String actual;

  const ImageCodecIntegrityFailure({
    required this.fileName,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() =>
      'Checksum mismatch for $fileName: expected $expected, got $actual.';
}

/// Persisted image-codec preferences.
///
/// These five fields are destined for `AppSettings` (see the integration notes
/// for task B4, item 1); they live in their own value type until then so this
/// workstream adds no edits to `app_settings.dart`. The JSON keys already match
/// the `image_codec_*` names the AppSettings migration will use, so moving them
/// is a copy, not a rewrite.
class ImageCodecPreferences {
  final bool enabled;
  final String? selectedModelId;
  final String? modelSourceUrl;

  /// [AeicRatePoint.wireValue] of the composer's default rate point.
  final int ratePoint;

  final List<ImageCodecModelRecord> downloadedModels;

  const ImageCodecPreferences({
    this.enabled = false,
    this.selectedModelId,
    this.modelSourceUrl,
    this.ratePoint = 4, // AeicRatePoint.ft32
    this.downloadedModels = const [],
  });

  AeicRatePoint get aeicRatePoint => parseAeicRatePoint(ratePoint);

  Map<String, dynamic> toJson() {
    return {
      'image_codec_enabled': enabled,
      'image_codec_selected_model_id': selectedModelId,
      'image_codec_model_source_url': modelSourceUrl,
      'image_codec_rate_point': ratePoint,
      'image_codec_downloaded_models': [
        for (final model in downloadedModels) model.toJson(),
      ],
    };
  }

  factory ImageCodecPreferences.fromJson(Map<String, dynamic> json) {
    final rawModels = json['image_codec_downloaded_models'];
    return ImageCodecPreferences(
      enabled: json['image_codec_enabled'] as bool? ?? false,
      selectedModelId: json['image_codec_selected_model_id'] as String?,
      modelSourceUrl: json['image_codec_model_source_url'] as String?,
      ratePoint: json['image_codec_rate_point'] as int? ?? 4,
      downloadedModels: rawModels is List
          ? [
              for (final entry in rawModels)
                if (entry is Map<String, dynamic>)
                  ImageCodecModelRecord.fromJson(entry),
            ]
          : const [],
    );
  }

  static const Object _unset = Object();

  ImageCodecPreferences copyWith({
    bool? enabled,
    Object? selectedModelId = _unset,
    Object? modelSourceUrl = _unset,
    int? ratePoint,
    List<ImageCodecModelRecord>? downloadedModels,
  }) {
    return ImageCodecPreferences(
      enabled: enabled ?? this.enabled,
      selectedModelId: identical(selectedModelId, _unset)
          ? this.selectedModelId
          : selectedModelId as String?,
      modelSourceUrl: identical(modelSourceUrl, _unset)
          ? this.modelSourceUrl
          : modelSourceUrl as String?,
      ratePoint: ratePoint ?? this.ratePoint,
      downloadedModels: downloadedModels ?? this.downloadedModels,
    );
  }
}
