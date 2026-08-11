import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/image_codec_file_store.dart';
import 'package:meshcore_open/services/image_codec_service.dart';
import 'package:meshcore_open/services/image_codec_settings_store.dart';

/// Real file store, redirected at a temp directory.
///
/// Subclassed rather than faked on purpose: the resume logic's whole premise is
/// that a partial file's *length on disk* is its progress marker, so a test that
/// mocked the filesystem would be testing the mock. Only the one method that
/// needs `path_provider` (unavailable in a unit test) is overridden.
class _TempFileStore extends ImageCodecFileStore {
  final String root;

  _TempFileStore(this.root);

  @override
  Future<String> modelDirectoryPath() async => root;
}

/// Deterministic pseudo-random bytes, so a sliced Range response can be checked
/// byte-for-byte against the source.
Uint8List _body(int length, [int seed = 7]) {
  final bytes = Uint8List(length);
  var state = seed | 1;
  for (var i = 0; i < length; i++) {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    bytes[i] = (state >> 16) & 0xFF;
  }
  return bytes;
}

String _sha256(List<int> bytes) => crypto.sha256.convert(bytes).toString();

/// A record of every range the client asked for, as `'start-end'`.
class _Log {
  final List<String> ranges = [];
  int headCount = 0;
}

/// Serves [assets] (by last path segment) over Range requests.
///
/// [failAtOffset] makes exactly one range request die half-way through its body,
/// which is what an interrupted 872 MB transfer looks like from Dart's side.
http.Client Function() _server(
  Map<String, Uint8List> assets,
  _Log log, {
  int? failAtOffset,
  bool acceptRanges = true,
}) {
  return () => MockClient.streaming((request, _) async {
    final name = request.url.pathSegments.last;
    final data = assets[name];
    if (data == null) {
      return http.StreamedResponse(const Stream<List<int>>.empty(), 404);
    }
    if (request.method == 'HEAD') {
      log.headCount++;
      return http.StreamedResponse(
        const Stream<List<int>>.empty(),
        200,
        contentLength: data.length,
        headers: acceptRanges ? {'accept-ranges': 'bytes'} : const {},
      );
    }
    final range = request.headers['Range'];
    if (range == null) {
      return http.StreamedResponse(
        Stream<List<int>>.value(data),
        200,
        contentLength: data.length,
      );
    }
    final match = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(range)!;
    final start = int.parse(match.group(1)!);
    final end = int.parse(match.group(2)!);
    log.ranges.add('$start-$end');
    final slice = data.sublist(start, end + 1);

    Stream<List<int>> stream() async* {
      if (failAtOffset == start) {
        yield slice.sublist(0, slice.length ~/ 2);
        throw const SocketException('connection reset by peer');
      }
      // Several chunks, so a mid-stream failure is a realistic partial write.
      const pieces = 4;
      final step = (slice.length / pieces).ceil();
      for (var i = 0; i < slice.length; i += step) {
        yield slice.sublist(i, (i + step).clamp(0, slice.length));
      }
    }

    return http.StreamedResponse(
      stream(),
      206,
      contentLength: slice.length,
      headers: {'content-range': 'bytes $start-$end/${data.length}'},
    );
  });
}

void main() {
  late Directory tempDir;
  late _TempFileStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_codec_dl');
    store = _TempFileStore(tempDir.path);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  ImageCodecService serviceWith(http.Client Function() clientFactory) {
    return ImageCodecService(
      AppSettingsService(),
      fileStore: store,
      settingsStore: InMemoryImageCodecSettingsStore(),
      clientFactory: clientFactory,
    );
  }

  // 12 MiB clears the 10 MB threshold, so this asset takes the 8-way ranged
  // path; the three small ones take the plain GET path. Both are exercised.
  // The shape mirrors the real bundle: a small decoder graph, a huge weights
  // sibling, a mid-size entropy graph and a tiny table file.
  final large = _body(12 * 1024 * 1024, 3);
  final small = _body(4096, 11);
  final entropy = _body(65536, 23);
  final entropyDecode = _body(32768, 31);
  final tables = _body(2048, 29);

  /// The five-role spec. Digests default to empty (verification skipped), which
  /// is the shipping state until the weights are published.
  ImageCodecModelSpec spec({
    String? largeDigest,
    String? smallDigest,
    String? entropyDigest,
    String? entropyDecodeDigest,
    String? tablesDigest,
  }) {
    return ImageCodecModelSpec(
      id: 'test-model',
      label: 'Test model',
      ratePoint: AeicRatePoint.ft32,
      assets: [
        ImageCodecModelAsset(
          role: ImageCodecAssetRole.decoderGraph,
          fileName: 'model.onnx',
          sourceUrl: 'https://example.invalid/repo/model.onnx',
          sizeBytes: small.length,
          sha256: smallDigest ?? '',
        ),
        ImageCodecModelAsset(
          role: ImageCodecAssetRole.decoderWeights,
          fileName: 'model.onnx.data',
          sourceUrl: 'https://example.invalid/repo/model.onnx.data',
          sizeBytes: large.length,
          sha256: largeDigest ?? '',
        ),
        ImageCodecModelAsset(
          role: ImageCodecAssetRole.entropyGraph,
          fileName: 'entropy.onnx',
          sourceUrl: 'https://example.invalid/repo/entropy.onnx',
          sizeBytes: entropy.length,
          sha256: entropyDigest ?? '',
        ),
        ImageCodecModelAsset(
          role: ImageCodecAssetRole.entropyDecodeGraph,
          fileName: 'entropy_decode.onnx',
          sourceUrl: 'https://example.invalid/repo/entropy_decode.onnx',
          sizeBytes: entropyDecode.length,
          sha256: entropyDecodeDigest ?? '',
        ),
        ImageCodecModelAsset(
          role: ImageCodecAssetRole.cdfTables,
          fileName: 'cdf.bin',
          sourceUrl: 'https://example.invalid/repo/cdf.bin',
          sizeBytes: tables.length,
          sha256: tablesDigest ?? '',
        ),
      ],
    );
  }

  ImageCodecModelSpec verifiedSpec() => spec(
    smallDigest: _sha256(small),
    largeDigest: _sha256(large),
    entropyDigest: _sha256(entropy),
    entropyDecodeDigest: _sha256(entropyDecode),
    tablesDigest: _sha256(tables),
  );

  final serverAssets = <String, Uint8List>{
    'model.onnx': small,
    'model.onnx.data': large,
    'entropy.onnx': entropy,
    'entropy_decode.onnx': entropyDecode,
    'cdf.bin': tables,
  };

  group('downloadPresetModel', () {
    test('fetches all five assets of the bundle and verifies each', () async {
      final log = _Log();
      final service = serviceWith(_server(serverAssets, log));
      addTearDown(service.dispose);

      final record = await service.downloadPresetModel(verifiedSpec());

      // The record points at the DECODER GRAPH, not the weights and not
      // whichever asset happened to be first: that is the path ONNX Runtime is
      // handed.
      expect(record.name, 'model.onnx');
      expect(record.localPath, '${tempDir.path}/model.onnx');
      // ...but the recorded size is the whole bundle, because that is what the
      // user gave up on their device.
      expect(
        record.fileSizeBytes,
        small.length +
            large.length +
            entropy.length +
            entropyDecode.length +
            tables.length,
      );
      expect(record.assetFileNames, [
        'model.onnx',
        'model.onnx.data',
        'entropy.onnx',
        'entropy_decode.onnx',
        'cdf.bin',
      ]);
      expect(record.bundleVersion, kImageCodecBundleVersion);

      final graph = File('${tempDir.path}/model.onnx');
      final weights = File('${tempDir.path}/model.onnx.data');
      expect(graph.existsSync(), isTrue);
      expect(weights.existsSync(), isTrue);
      expect(await graph.readAsBytes(), small);
      expect(await weights.length(), large.length);
      expect(_sha256(await weights.readAsBytes()), _sha256(large));
      expect(await File('${tempDir.path}/entropy.onnx').readAsBytes(), entropy);
      // Two different entropy exports land side by side; neither may overwrite
      // or be mistaken for the other.
      expect(
        await File('${tempDir.path}/entropy_decode.onnx').readAsBytes(),
        entropyDecode,
      );
      expect(entropyDecode, isNot(entropy));
      expect(await File('${tempDir.path}/cdf.bin').readAsBytes(), tables);

      // The external-weights sibling MUST keep its exact name or the graph's
      // relative reference will not resolve.
      expect(weights.uri.pathSegments.last, 'model.onnx.data');

      // Resume state is swept once an asset verifies.
      final leftovers = tempDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.startsWith('.'))
          .toList();
      expect(leftovers, isEmpty);

      expect(service.selectedModel?.id, 'test-model');
    });

    test('progress is one bar across the set, not four', () async {
      final log = _Log();
      final service = serviceWith(_server(serverAssets, log));
      addTearDown(service.dispose);

      final progress = <double>[];
      final names = <String>{};
      service.addListener(() {
        final value = service.downloadProgress;
        if (value != null) progress.add(value);
        final name = service.downloadFileName;
        if (name != null) names.add(name);
      });

      await service.downloadPresetModel(verifiedSpec());

      expect(progress, isNotEmpty);
      // Monotonic: a per-file bar would snap back to 0 three times.
      for (var i = 1; i < progress.length; i++) {
        expect(
          progress[i],
          greaterThanOrEqualTo(progress[i - 1]),
          reason: 'progress went backwards at $i',
        );
      }
      expect(progress.last, closeTo(1.0, 0.001));
      // Every asset was named while it was in flight, so the UI can say which
      // of the four files a 900 MB transfer is on.
      expect(
        names,
        containsAll(<String>['model.onnx', 'model.onnx.data', 'cdf.bin']),
      );
    });

    test('refuses a spec that is missing a bundle role', () async {
      final service = serviceWith(_server(serverAssets, _Log()));
      addTearDown(service.dispose);

      // Decoder-only: it would install a codec that can render a latent and
      // nothing else, which is exactly the state this work removes.
      final full = spec();
      await expectLater(
        service.downloadPresetModel(
          ImageCodecModelSpec(
            id: 'decoder-only',
            label: 'Decoder only',
            assets: full.assets.take(2).toList(),
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(tempDir.listSync(), isEmpty);
    });

    test('discardPartialDownload sweeps every asset of the bundle', () async {
      final service = serviceWith(_server(serverAssets, _Log()));
      addTearDown(service.dispose);
      final target = spec();
      for (final asset in target.assets) {
        await File(
          await store.chunkFilePath('${asset.fileName}.99', 0),
        ).writeAsBytes(const [1, 2, 3]);
      }
      final other = File(await store.chunkFilePath('unrelated.onnx.99', 0));
      await other.writeAsBytes(const [1]);

      await service.discardPartialDownload(target);

      final leftovers = tempDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList();
      expect(leftovers, ['.unrelated.onnx.99_chunk_0']);
    });

    test('refuses a spec whose URLs are placeholders', () async {
      final service = serviceWith(_server(serverAssets, _Log()));
      addTearDown(service.dispose);

      await expectLater(
        service.downloadPresetModel(
          ImageCodecModelSpec(
            id: 'placeholder',
            label: 'Placeholder',
            urlsArePlaceholders: true,
            assets: spec().assets,
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(tempDir.listSync(), isEmpty);
    });

    test('the shipped preset points at published, verifiable assets', () {
      // The weights are published, so the old "still a placeholder" guard is
      // inverted: what matters now is that nothing ships half-wired. A real URL
      // with an empty digest is worse than a placeholder, because the download
      // succeeds and the integrity check silently passes.
      expect(imageCodecPresetModels, hasLength(1));
      for (final preset in imageCodecPresetModels) {
        expect(preset.urlsArePlaceholders, isFalse);
        expect(preset.assets, isNotEmpty);
        for (final asset in preset.assets) {
          expect(
            asset.sourceUrl,
            startsWith('https://huggingface.co/'),
            reason: asset.fileName,
          );
          expect(
            asset.sourceUrl,
            contains(asset.fileName),
            reason: '${asset.fileName} url must name its own file',
          );
          expect(asset.sizeBytes, greaterThan(0), reason: asset.fileName);
          expect(
            asset.sha256,
            matches(RegExp(r'^[0-9a-f]{64}$')),
            reason: '${asset.fileName} needs a real digest',
          );
        }
        // Five assets, one bundle: decoder graph + weights, both entropy
        // graphs, and the CDF tables.
        expect(preset.assets, hasLength(5));
      }
    });
  });

  group('resume', () {
    test('a broken transfer resumes from the bytes already on disk', () async {
      final chunkSize = (large.length / 8).ceil();
      final victimStart = chunkSize * 3;

      final firstLog = _Log();
      final first = serviceWith(
        _server(serverAssets, firstLog, failAtOffset: victimStart),
      );
      addTearDown(first.dispose);

      await expectLater(
        first.downloadPresetModel(spec()),
        throwsA(isA<SocketException>()),
      );

      // Seven chunks landed whole, one is half-written, and none were deleted.
      final partials = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.uri.pathSegments.last.startsWith('.'))
          .toList();
      expect(partials, hasLength(8));
      final victimPath = partials.firstWhere(
        (f) => f.uri.pathSegments.last.endsWith('_chunk_3'),
      );
      final resumeFrom = await victimPath.length();
      expect(resumeFrom, greaterThan(0));
      expect(resumeFrom, lessThan(chunkSize));
      expect(File('${tempDir.path}/model.onnx.data').existsSync(), isFalse);

      final secondLog = _Log();
      final second = serviceWith(_server(serverAssets, secondLog));
      addTearDown(second.dispose);
      await second.downloadPresetModel(verifiedSpec());

      // Exactly one range was re-requested, and it started where the partial
      // file ended rather than at the chunk boundary.
      expect(secondLog.ranges, hasLength(1));
      expect(
        secondLog.ranges.single,
        startsWith('${victimStart + resumeFrom}-'),
      );

      final weights = File('${tempDir.path}/model.onnx.data');
      expect(await weights.length(), large.length);
      expect(_sha256(await weights.readAsBytes()), _sha256(large));
    });

    test('an already-complete verified asset is not re-fetched', () async {
      final log = _Log();
      final service = serviceWith(_server(serverAssets, log));
      addTearDown(service.dispose);
      final digested = verifiedSpec();

      await service.downloadPresetModel(digested);
      final rangesAfterFirst = log.ranges.length;
      expect(rangesAfterFirst, greaterThan(0));

      await service.downloadPresetModel(digested);
      expect(log.ranges.length, rangesAfterFirst, reason: 'no re-download');
    });

    test('resume state does not survive a change in upstream length', () async {
      // Chunk keys embed the total size, so offsets computed for one length can
      // never be spliced onto a file of another length.
      final a = await store.chunkFilePath('model.onnx.data.1000', 3);
      final b = await store.chunkFilePath('model.onnx.data.2000', 3);
      expect(a, isNot(b));
    });
  });

  group('integrity', () {
    test('a wrong digest fails loudly and removes the file', () async {
      final service = serviceWith(_server(serverAssets, _Log()));
      addTearDown(service.dispose);

      await expectLater(
        service.downloadPresetModel(
          spec(smallDigest: _sha256(utf8.encode('not the model'))),
        ),
        throwsA(isA<ImageCodecIntegrityFailure>()),
      );
      expect(File('${tempDir.path}/model.onnx').existsSync(), isFalse);
      expect(service.selectedModel, isNull);
    });

    test('sha256OfFile streams the same digest as an in-memory hash', () async {
      final path = '${tempDir.path}/blob.bin';
      await File(path).writeAsBytes(large);
      expect(await store.sha256OfFile(path), _sha256(large));
    });

    test('a missing digest is skipped rather than treated as a match', () {
      const withDigest = ImageCodecModelAsset(
        role: ImageCodecAssetRole.decoderGraph,
        fileName: 'a',
        sourceUrl: 'https://example.invalid/a',
        sizeBytes: 1,
        sha256:
            '0000000000000000000000000000000000000000000000000000000000000000',
      );
      const without = ImageCodecModelAsset(
        role: ImageCodecAssetRole.cdfTables,
        fileName: 'b',
        sourceUrl: 'https://example.invalid/b',
        sizeBytes: 1,
      );
      expect(withDigest.hasChecksum, isTrue);
      expect(without.hasChecksum, isFalse);
    });
  });

  group('scanDownloadedModels', () {
    test('preserves chunk files but reaps other hidden junk', () async {
      final chunk = File(await store.chunkFilePath('model.onnx.data.99', 2));
      await chunk.writeAsBytes(const [1, 2, 3]);
      final junk = File('${tempDir.path}/.DS_Store');
      await junk.writeAsBytes(const [0]);
      await File('${tempDir.path}/model.onnx').writeAsBytes(small);

      final found = await store.scanDownloadedModels();

      expect(found.map((m) => m.name), ['model.onnx']);
      expect(chunk.existsSync(), isTrue, reason: 'resume state must survive');
      expect(junk.existsSync(), isFalse);
    });

    test('deletePartialDownloads sweeps only the named model', () async {
      final mine = File(await store.chunkFilePath('model.onnx.data.99', 0));
      final other = File(await store.chunkFilePath('other.onnx.99', 0));
      await mine.writeAsBytes(const [1]);
      await other.writeAsBytes(const [1]);

      await store.deletePartialDownloads('model.onnx.data');

      expect(mine.existsSync(), isFalse);
      expect(other.existsSync(), isTrue);
    });
  });

  group('non-ranged servers', () {
    test('fall back to a single GET', () async {
      final log = _Log();
      final service = serviceWith(
        _server(serverAssets, log, acceptRanges: false),
      );
      addTearDown(service.dispose);

      await service.downloadPresetModel(verifiedSpec());

      expect(log.ranges, isEmpty);
      expect(
        await File('${tempDir.path}/model.onnx.data').length(),
        large.length,
      );
    });
  });

  group('installedBundle', () {
    test(
      'a fresh install resolves the decoder, entropy and table paths',
      () async {
        final service = serviceWith(_server(serverAssets, _Log()));
        addTearDown(service.dispose);

        await service.downloadPresetModel(verifiedSpec());

        final bundle = service.installedBundle;
        expect(bundle, isNotNull);
        expect(bundle!.decoderGraphPath, '${tempDir.path}/model.onnx');
        expect(bundle.entropyGraphPath, '${tempDir.path}/entropy.onnx');
        // Resolved by ROLE. Both entropy files end in `.onnx`, so a
        // position- or extension-based guess would be a coin flip, and handing
        // the decode-side graph to the encoder fails at the first run.
        expect(
          bundle.entropyDecodeGraphPath,
          '${tempDir.path}/entropy_decode.onnx',
        );
        expect(bundle.tablesPath, '${tempDir.path}/cdf.bin');
        expect(bundle.isComplete, isTrue);
        expect(bundle.supportsDecode, isTrue);
        expect(service.needsModelUpgrade, isFalse);
        expect(service.needsModelDownload, isFalse);
      },
    );

    test('a bundle-version-1 install can send but not receive', () async {
      // The record the previous release wrote: four assets, no decode-side
      // graph. Encoding still works, decoding does not, and the remedy is a
      // re-download rather than "your device cannot do this".
      final v1 = ImageCodecModelRecord(
        id: 'test-model',
        name: 'model.onnx',
        sourceUrl: 'https://example.invalid/repo/model.onnx',
        localPath: '${tempDir.path}/model.onnx',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(1730000000000),
        fileSizeBytes: 1,
        assetFileNames: const [
          'model.onnx',
          'model.onnx.data',
          'entropy.onnx',
          'cdf.bin',
        ],
        bundleVersion: 1,
      );
      final service = ImageCodecService(
        AppSettingsService(),
        fileStore: store,
        settingsStore: InMemoryImageCodecSettingsStore(
          ImageCodecPreferences(
            enabled: true,
            selectedModelId: v1.id,
            downloadedModels: [v1],
          ),
        ),
        clientFactory: _server(serverAssets, _Log()),
      );
      addTearDown(service.dispose);

      final bundle = service.installedBundle;
      expect(bundle, isNotNull);
      expect(bundle!.entropyGraphPath, '${tempDir.path}/entropy.onnx');
      // No spec asset name is present in the record, and the heuristic must NOT
      // invent one: a filename that was never downloaded resolves to an opaque
      // ORT failure instead of a download prompt.
      expect(bundle.entropyDecodeGraphPath, isNull);
      expect(bundle.isComplete, isTrue);
      expect(bundle.supportsDecode, isFalse);
      expect(service.needsModelUpgrade, isTrue);
      expect(service.needsModelDownload, isFalse);
      expect(service.canDecode, isFalse);
      expect(service.statusReason, isNotNull);
    });

    test('a pre-bundle install is an upgrade, not a broken build', () {
      // The decoder-only record the shipped build wrote: no asset list, no
      // bundle version. It must stay loadable, report an incomplete bundle,
      // and ask for a download rather than declaring the device incapable.
      final legacy = ImageCodecModelRecord(
        id: 'aeic-se-decoder-qdq-conv-pct-novae',
        name: 'aeic_decoder_qdq_conv_pct_novae.onnx',
        sourceUrl: 'https://example.invalid/x.onnx',
        localPath: '${tempDir.path}/aeic_decoder_qdq_conv_pct_novae.onnx',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(1730000000000),
        fileSizeBytes: 2909610,
      );
      final service = ImageCodecService(
        AppSettingsService(),
        fileStore: store,
        settingsStore: InMemoryImageCodecSettingsStore(
          ImageCodecPreferences(
            enabled: true,
            selectedModelId: legacy.id,
            downloadedModels: [legacy],
          ),
        ),
        clientFactory: _server(serverAssets, _Log()),
      );
      addTearDown(service.dispose);

      expect(service.needsModelDownload, isFalse, reason: 'a model IS present');
      expect(service.needsModelUpgrade, isTrue);
      final bundle = service.installedBundle;
      expect(bundle, isNotNull);
      expect(bundle!.decoderGraphPath, legacy.localPath);
      expect(bundle.entropyGraphPath, isNull);
      expect(bundle.entropyDecodeGraphPath, isNull);
      expect(bundle.tablesPath, isNull);
      expect(bundle.isComplete, isFalse);
      expect(bundle.supportsDecode, isFalse);
      expect(service.canEncode, isFalse);
      expect(service.canDecode, isFalse);
      // An incomplete install is a download away, so the user always gets a
      // sentence explaining what to do.
      expect(service.statusReason, isNotNull);
    });

    test('nothing installed means no bundle and a download prompt', () {
      final service = ImageCodecService(
        AppSettingsService(),
        fileStore: store,
        settingsStore: InMemoryImageCodecSettingsStore(
          const ImageCodecPreferences(enabled: true),
        ),
        clientFactory: _server(serverAssets, _Log()),
      );
      addTearDown(service.dispose);

      expect(service.installedBundle, isNull);
      expect(service.needsModelDownload, isTrue);
      expect(service.needsModelUpgrade, isFalse);
      expect(service.canEncode, isFalse);
    });

    test('statusReason is a superset of unavailableReason', () {
      final service = serviceWith(_server(serverAssets, _Log()));
      addTearDown(service.dispose);

      // While kImageCodecBitstreamPathAvailable is false this is the build
      // sentence; when the gate flips, the remaining branches (switched off,
      // not downloaded, needs upgrade) take over. Either way it is non-empty
      // whenever the codec is not ready, which is the contract the compose
      // sheet's banner depends on.
      final status = service.statusReason;
      expect(status, isNotNull);
      expect(status!.trim(), isNotEmpty);
      final permanent = service.unavailableReason;
      if (permanent != null) {
        expect(status, permanent);
      }
    });
  });
}
