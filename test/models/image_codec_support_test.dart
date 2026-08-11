import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/widgets/image_send_codec_binding.dart';

void main() {
  group('ImageCodecModelRecord', () {
    test('round-trips through JSON', () {
      final record = ImageCodecModelRecord(
        id: 'aeic-se-512-int8',
        name: 'aeic_se_512_int8.onnx',
        sourceUrl: 'https://example.invalid/model.onnx',
        localPath: '/tmp/aeic_se_512_int8.onnx',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(1730000000000),
        fileSizeBytes: 873463808,
        assetFileNames: ['a.onnx', 'a.onnx.data', 'e.onnx', 't.bin'],
        bundleVersion: kImageCodecBundleVersion,
      );

      final restored = ImageCodecModelRecord.fromJson(record.toJson());

      expect(restored.id, record.id);
      expect(restored.name, record.name);
      expect(restored.sourceUrl, record.sourceUrl);
      expect(restored.localPath, record.localPath);
      expect(restored.downloadedAt, record.downloadedAt);
      expect(restored.fileSizeBytes, record.fileSizeBytes);
      expect(restored.assetFileNames, record.assetFileNames);
      expect(restored.bundleVersion, kImageCodecBundleVersion);
    });

    test('tolerates a missing/garbage payload', () {
      final restored = ImageCodecModelRecord.fromJson(<String, dynamic>{});
      expect(restored.id, '');
      expect(restored.fileSizeBytes, 0);
      expect(restored.downloadedAt.millisecondsSinceEpoch, 0);
      expect(restored.assetFileNames, isEmpty);
      expect(restored.bundleVersion, 0);
    });

    test('a record written by a pre-bundle build reads as version 0', () {
      // The exact JSON the decoder-only build wrote. It must still load, and it
      // must be recognisable as needing an upgrade rather than silently
      // claiming to be a full bundle.
      final restored = ImageCodecModelRecord.fromJson(<String, dynamic>{
        'id': 'aeic-se-decoder-qdq-conv-pct-novae',
        'name': 'aeic_decoder_qdq_conv_pct_novae.onnx',
        'source_url': 'https://example.invalid/x.onnx',
        'local_path': '/tmp/aeic_decoder_qdq_conv_pct_novae.onnx',
        'downloaded_at': 1730000000000,
        'file_size_bytes': 2909610,
      });
      expect(restored.bundleVersion, 0);
      expect(restored.bundleVersion, lessThan(kImageCodecBundleVersion));
      expect(restored.assetFileNames, isEmpty);
      expect(restored.localPath, isNotEmpty);
      expect(restored.assetRoles, isEmpty);
    });

    test('asset roles survive JSON and tell the two entropy graphs apart', () {
      // The whole point of the field: `e_send.onnx` and `e_decode.onnx` are
      // indistinguishable by name, extension or position, and swapping them is
      // the silent-corruption failure mode.
      final record = ImageCodecModelRecord(
        id: 'bundle',
        name: 'd.onnx',
        sourceUrl: 'https://example.invalid/d.onnx',
        localPath: '/tmp/d.onnx',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(1730000000000),
        fileSizeBytes: 1,
        assetFileNames: const [
          'd.onnx',
          'd.onnx.data',
          'e_send.onnx',
          'e_decode.onnx',
          't.bin',
        ],
        assetRoles: const {
          'd.onnx': ImageCodecAssetRole.decoderGraph,
          'd.onnx.data': ImageCodecAssetRole.decoderWeights,
          'e_send.onnx': ImageCodecAssetRole.entropyGraph,
          'e_decode.onnx': ImageCodecAssetRole.entropyDecodeGraph,
          't.bin': ImageCodecAssetRole.cdfTables,
        },
        bundleVersion: kImageCodecBundleVersion,
      );

      // Serialised by NAME, so appending an enum member cannot re-label a file
      // that is already installed.
      expect(record.toJson()['asset_roles'], {
        'd.onnx': 'decoderGraph',
        'd.onnx.data': 'decoderWeights',
        'e_send.onnx': 'entropyGraph',
        'e_decode.onnx': 'entropyDecodeGraph',
        't.bin': 'cdfTables',
      });

      final restored = ImageCodecModelRecord.fromJson(record.toJson());
      expect(
        restored.fileNameForRole(ImageCodecAssetRole.entropyGraph),
        'e_send.onnx',
      );
      expect(
        restored.fileNameForRole(ImageCodecAssetRole.entropyDecodeGraph),
        'e_decode.onnx',
      );
      expect(
        restored.fileNameForRole(ImageCodecAssetRole.entropyWeights),
        isNull,
      );
    });

    test('an unknown role name is dropped, not coerced to a real role', () {
      // A record written by a newer build. Filing its unknown file under some
      // existing role would hand ORT the wrong graph.
      final restored = ImageCodecModelRecord.fromJson(<String, dynamic>{
        'asset_file_names': ['a.onnx', 'b.bin'],
        'asset_roles': {
          'a.onnx': 'somethingFromTheFuture',
          'b.bin': 'cdfTables',
        },
      });
      expect(restored.assetRoles.keys, ['b.bin']);
      expect(restored.fileNameForRole(ImageCodecAssetRole.cdfTables), 'b.bin');
      expect(parseImageCodecAssetRole('somethingFromTheFuture'), isNull);
      expect(
        parseImageCodecAssetRole('entropyDecodeGraph'),
        ImageCodecAssetRole.entropyDecodeGraph,
      );
    });

    test('a role naming a file that is not installed does not resolve', () {
      // assetRoles and assetFileNames can disagree if a file was reaped; the
      // list of what is actually on disk wins.
      final record = ImageCodecModelRecord(
        id: 'x',
        name: 'd.onnx',
        sourceUrl: '',
        localPath: '/tmp/d.onnx',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
        fileSizeBytes: 0,
        assetFileNames: const ['d.onnx'],
        assetRoles: const {
          'd.onnx': ImageCodecAssetRole.decoderGraph,
          'gone.onnx': ImageCodecAssetRole.entropyDecodeGraph,
        },
      );
      expect(
        record.fileNameForRole(ImageCodecAssetRole.entropyDecodeGraph),
        isNull,
      );
    });
  });

  group('ImageCodecBundle', () {
    test('is complete only with both entropy graph and tables', () {
      const decoderOnly = ImageCodecBundle(decoderGraphPath: '/m/d.onnx');
      expect(decoderOnly.isComplete, isFalse);
      const noTables = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        entropyGraphPath: '/m/e.onnx',
      );
      expect(noTables.isComplete, isFalse);
      const noEntropy = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        tablesPath: '/m/t.bin',
      );
      expect(noEntropy.isComplete, isFalse);
      const full = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        entropyGraphPath: '/m/e.onnx',
        tablesPath: '/m/t.bin',
      );
      expect(full.isComplete, isTrue);
    });

    test('supportsDecode additionally requires the decode-side graph', () {
      // Bundle version 1: the send-side entropy graph only. It can encode --
      // that graph emits every stage at once, which is all an encoder needs --
      // but decoding is sequential and needs the If-branched export.
      const sendOnly = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        entropyGraphPath: '/m/e.onnx',
        tablesPath: '/m/t.bin',
      );
      expect(sendOnly.isComplete, isTrue);
      expect(sendOnly.supportsDecode, isFalse);

      const both = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        entropyGraphPath: '/m/e.onnx',
        entropyDecodeGraphPath: '/m/e_dec.onnx',
        tablesPath: '/m/t.bin',
      );
      expect(both.supportsDecode, isTrue);

      // A decode-side graph without the tables is still useless.
      const noTables = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        entropyGraphPath: '/m/e.onnx',
        entropyDecodeGraphPath: '/m/e_dec.onnx',
      );
      expect(noTables.supportsDecode, isFalse);
    });

    test('the decode-side graph participates in equality', () {
      // The service keys its cached session on the bundle. If this field were
      // left out of ==, upgrading a v1 install in place would reuse an isolate
      // that never learned about the new graph.
      const sendOnly = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        entropyGraphPath: '/m/e.onnx',
        tablesPath: '/m/t.bin',
      );
      const both = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        entropyGraphPath: '/m/e.onnx',
        entropyDecodeGraphPath: '/m/e_dec.onnx',
        tablesPath: '/m/t.bin',
      );
      expect(both, isNot(sendOnly));
      expect(both.hashCode, isNot(sendOnly.hashCode));
      expect(both.toString(), contains('/m/e_dec.onnx'));
    });

    test('defaults to the shipping rate point and compares by value', () {
      const a = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        entropyGraphPath: '/m/e.onnx',
        tablesPath: '/m/t.bin',
      );
      const b = ImageCodecBundle(
        decoderGraphPath: '/m/d.onnx',
        entropyGraphPath: '/m/e.onnx',
        tablesPath: '/m/t.bin',
      );
      expect(a.ratePoint, kShippingAeicRatePoint);
      // The service keys its cached session on the bundle; value equality is
      // what stops an identical bundle from respawning the isolate.
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          const ImageCodecBundle(
            decoderGraphPath: '/m/d.onnx',
            entropyGraphPath: '/m/e.onnx',
            tablesPath: '/m/other.bin',
          ),
        ),
      );
    });
  });

  group('AeicRatePoint', () {
    test('ordinals are the persisted/isolate wire values', () {
      expect(AeicRatePoint.ft2.wireValue, 0);
      expect(AeicRatePoint.ft32.wireValue, 4);
      expect(parseAeicRatePoint(4), AeicRatePoint.ft32);
    });

    test('parse falls back to ft32 for out-of-range values', () {
      expect(parseAeicRatePoint(-1), AeicRatePoint.ft32);
      expect(parseAeicRatePoint(99), AeicRatePoint.ft32);
    });

    test('label carries the measured mean size where one exists', () {
      expect(AeicRatePoint.ft32.label, 'ft32 (~156 B)');
      expect(AeicRatePoint.ft2.label, 'ft2');
    });

    test('ft32 is the only shipping rate point', () {
      expect(kShippingAeicRatePoint, AeicRatePoint.ft32);
      // ft16 was dropped: 2-3 data chunks with 79 B of headroom. The UI mapping
      // is constant now, so no selector value can reach another checkpoint.
      for (final rate in ImageCodecRatePoint.values) {
        expect(aeicRatePointForUi(rate), AeicRatePoint.ft32);
      }
      for (final rate in AeicRatePoint.values) {
        expect(uiRatePointForAeic(rate), ImageCodecRatePoint.standard);
      }
    });

    test('ft32 measurements are the real corpus numbers', () {
      expect(AeicRatePoint.ft32.meanBytes, 156); // 155.8 B over 26 images
      expect(AeicRatePoint.ft32.maxBytes, 209);
    });

    test('UI index and model ordinal are NOT interchangeable', () {
      // Guards the trap documented on AeicRatePoint: the on-air nibble is
      // ImageCodecRatePoint.index, the settings/isolate value is this ordinal.
      expect(
        ImageCodecRatePoint.standard.index,
        isNot(AeicRatePoint.ft32.wireValue),
      );
    });
  });

  group('ImageCodecPreferences', () {
    test('defaults to disabled at ft32 with no models', () {
      const prefs = ImageCodecPreferences();
      expect(prefs.enabled, isFalse);
      expect(prefs.aeicRatePoint, AeicRatePoint.ft32);
      expect(prefs.downloadedModels, isEmpty);
    });

    test('round-trips through JSON including nested models', () {
      final preset = imageCodecPresetModels.first;
      final prefs = ImageCodecPreferences(
        enabled: true,
        selectedModelId: preset.id,
        modelSourceUrl: preset.graph.sourceUrl,
        ratePoint: AeicRatePoint.ft32.wireValue,
        downloadedModels: [
          ImageCodecModelRecord(
            id: preset.id,
            name: preset.fileName,
            sourceUrl: preset.graph.sourceUrl,
            localPath: '/tmp/${preset.fileName}',
            downloadedAt: DateTime.fromMillisecondsSinceEpoch(1730000000000),
            fileSizeBytes: preset.graph.sizeBytes,
          ),
        ],
      );

      final restored = ImageCodecPreferences.fromJson(prefs.toJson());

      expect(restored.enabled, isTrue);
      expect(restored.selectedModelId, preset.id);
      expect(restored.modelSourceUrl, prefs.modelSourceUrl);
      expect(restored.aeicRatePoint, AeicRatePoint.ft32);
      expect(restored.downloadedModels, hasLength(1));
      expect(restored.downloadedModels.first.id, preset.id);
    });

    test('copyWith can clear nullable strings via the sentinel', () {
      const prefs = ImageCodecPreferences(selectedModelId: 'x');
      expect(prefs.copyWith().selectedModelId, 'x');
      expect(prefs.copyWith(selectedModelId: null).selectedModelId, isNull);
    });
  });

  group('imageCodecPresetModels', () {
    test('ships exactly one model: one ft32 bundle, not two downloads', () {
      expect(imageCodecPresetModels, hasLength(1));
      final preset = imageCodecPresetModels.single;
      expect(preset.id, 'aeic-se-ft32-bundle-v1');
      expect(preset.ratePoint, AeicRatePoint.ft32);
      expect(preset.isComplete, isTrue);
      expect(preset.totalSizeBytes, kImageCodecBundleTotalBytes);
      // 958.0 MiB across the five files, measured with stat on the local
      // exports. See the upload manifest in image_codec_support.dart.
      expect(preset.totalSizeBytes, 1004548432);
    });

    test('ships qdq_conv_pct, NOT the novae variant', () {
      // The novae variant leaves the VAE in fp32: +38 MB on disk and +0.83 GiB
      // peak RSS for 0.17 dB. RAM is the binding constraint on a phone.
      final preset = imageCodecPresetModels.single;
      expect(preset.fileName, 'aeic_decoder_qdq_conv_pct.onnx');
      for (final asset in preset.assets) {
        expect(asset.fileName, isNot(contains('novae')));
      }
      expect(
        preset.assetFor(ImageCodecAssetRole.decoderWeights).sizeBytes,
        872896480,
      );
    });

    test('carries all five roles exactly once', () {
      final preset = imageCodecPresetModels.single;
      expect(preset.assets, hasLength(5));
      for (final role in const [
        ImageCodecAssetRole.decoderGraph,
        ImageCodecAssetRole.decoderWeights,
        ImageCodecAssetRole.entropyGraph,
        ImageCodecAssetRole.entropyDecodeGraph,
        ImageCodecAssetRole.cdfTables,
      ]) {
        expect(
          preset.assets.where((a) => a.role == role),
          hasLength(1),
          reason: 'exactly one asset per role: $role',
        );
      }
      // Reserved and deliberately absent: the fp32 entropy export is
      // self-contained.
      expect(preset.maybeAssetFor(ImageCodecAssetRole.entropyWeights), isNull);
    });

    test('resolves the graph by role, not by list position', () {
      final preset = imageCodecPresetModels.single;
      expect(preset.graph, preset.assetFor(ImageCodecAssetRole.decoderGraph));
      expect(preset.graph.fileName, endsWith('.onnx'));
      expect(
        preset.assetFor(ImageCodecAssetRole.decoderWeights).fileName,
        '${preset.graph.fileName}.data',
        reason: 'ORT resolves external data by the exact filename in the graph',
      );
      // A reordered list must not change which file ORT is handed.
      final reordered = ImageCodecModelSpec(
        id: preset.id,
        label: preset.label,
        assets: preset.assets.reversed.toList(),
      );
      expect(reordered.fileName, preset.fileName);
    });

    test('the entropy graph and the tables are the ones that were validated', () {
      final preset = imageCodecPresetModels.single;
      final entropy = preset.assetFor(ImageCodecAssetRole.entropyGraph);
      // op17 fp32: byte-identical bitstreams on 26/26 images. Not op20, not int8.
      expect(entropy.fileName, 'aeic_entropy_side_fp32_op17.onnx');
      expect(entropy.sizeBytes, 67262167);
      // The decode-side export of the same weights. fp32 as well: int8 there
      // breaks the bit-exactness the rANS decoder depends on.
      final decode = preset.assetFor(ImageCodecAssetRole.entropyDecodeGraph);
      expect(decode.fileName, 'aeic_entropy_decode_fp32_op17.onnx');
      expect(decode.sizeBytes, 60509540);
      expect(decode.fileName, isNot(entropy.fileName));
      final tables = preset.assetFor(ImageCodecAssetRole.cdfTables);
      expect(tables.fileName, 'aeic_cdf_ft32.bin');
      expect(tables.sizeBytes, 813648);
    });

    test('an incomplete spec is detectable', () {
      final preset = imageCodecPresetModels.single;
      final decoderOnly = ImageCodecModelSpec(
        id: 'legacy',
        label: 'Legacy',
        assets: [
          preset.assetFor(ImageCodecAssetRole.decoderGraph),
          preset.assetFor(ImageCodecAssetRole.decoderWeights),
        ],
      );
      expect(decoderOnly.isComplete, isFalse);
      expect(decoderOnly.maybeAssetFor(ImageCodecAssetRole.cdfTables), isNull);
      expect(
        () => decoderOnly.assetFor(ImageCodecAssetRole.cdfTables),
        throwsStateError,
      );

      // A version-1 spec: everything except the decode-side graph. It would
      // install a codec that can send and never receive, so downloadPresetModel
      // must refuse it too.
      final sendOnly = ImageCodecModelSpec(
        id: 'v1',
        label: 'Send-only',
        assets: [
          for (final asset in preset.assets)
            if (asset.role != ImageCodecAssetRole.entropyDecodeGraph) asset,
        ],
      );
      expect(sendOnly.assets, hasLength(4));
      expect(sendOnly.isComplete, isFalse);
    });

    test('uses the HuggingFace resolve/main URL shape', () {
      for (final asset in imageCodecPresetModels.single.assets) {
        expect(asset.sourceUrl, startsWith('https://huggingface.co/'));
        expect(asset.sourceUrl, contains('/resolve/main/'));
        expect(asset.sourceUrl, endsWith('?download=true'));
        expect(asset.sourceUrl, contains(asset.fileName));
      }
    });

    test('friendly name resolves through the registry', () {
      final preset = imageCodecPresetModels.single;
      final record = ImageCodecModelRecord(
        id: preset.id,
        name: preset.fileName,
        sourceUrl: '',
        localPath: '/tmp/x',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
        fileSizeBytes: 0,
      );
      expect(imageCodecModelFriendlyName(record), preset.label);
    });

    test('latent contract matches the export', () {
      expect(kImageCodecLatentShape, [1, 256, 16, 16]);
      expect(kImageCodecLatentElements, 65536);
      expect(kImageCodecDecoderInputName, 'y_hat');
    });
  });

  group('exceptions', () {
    test(
      'an incomplete install is NOT the same failure as a missing build',
      () {
        // Both are ImageCodecUnimplemented, but only one has a remedy the user
        // can act on, and the UI branches on exactly that difference.
        const incomplete = ImageCodecBundleIncomplete();
        const missing = ImageCodecEntropyPathMissing();
        expect(incomplete, isA<ImageCodecUnimplemented>());
        expect(missing, isA<ImageCodecUnimplemented>());
        expect(incomplete, isNot(isA<ImageCodecEntropyPathMissing>()));
        expect(incomplete.toString(), contains('re-download'));
      },
    );
  });

  group('parseImageCodecStatus', () {
    test('maps known values and defaults to none', () {
      expect(parseImageCodecStatus('completed'), ImageCodecStatus.completed);
      expect(parseImageCodecStatus('nonsense'), ImageCodecStatus.none);
      expect(parseImageCodecStatus(42), ImageCodecStatus.none);
    });
  });
}
