import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/models/translation_support.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/image_codec_service.dart';
import 'package:meshcore_open/services/image_codec_settings_store.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/image_codec_models_section.dart';
import 'package:meshcore_open/widgets/model_download_list.dart';
import 'package:meshcore_open/widgets/translation_settings_section.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    List<SingleChildWidget> providers = const [],
    double textScale = 1,
    Size size = const Size(400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = MaterialApp(
      theme: MeshTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: home)),
    );
    await tester.pumpWidget(
      providers.isEmpty ? app : MultiProvider(providers: providers, child: app),
    );
  }

  testWidgets('rows share name, size, status and one action', (tester) async {
    var downloaded = 0;
    var cancelled = 0;
    var removed = 0;
    var selected = 0;
    await pump(
      tester,
      ModelDownloadList(
        items: [
          ModelDownloadItem(
            id: 'new',
            name: 'Preset model',
            sizeBytes: 958 * 1024 * 1024,
            status: ModelDownloadStatus.notDownloaded,
            onDownload: () => downloaded++,
          ),
          ModelDownloadItem(
            id: 'busy',
            name: 'Preset model',
            sizeBytes: 958 * 1024 * 1024,
            status: ModelDownloadStatus.downloading,
            progress: 0.4,
            downloadedBytes: 400 * 1024 * 1024,
            totalBytes: 958 * 1024 * 1024,
            onCancel: () => cancelled++,
          ),
          ModelDownloadItem(
            id: 'ready',
            name: 'Installed model',
            sizeBytes: 1100 * 1024 * 1024,
            status: ModelDownloadStatus.ready,
            selected: true,
            onDelete: () => removed++,
            onSelect: () => selected++,
          ),
          ModelDownloadItem(
            id: 'bad',
            name: 'Broken model',
            status: ModelDownloadStatus.error,
            detail: 'HTTP 404',
            onDownload: () => downloaded++,
          ),
        ],
      ),
    );

    expect(find.textContaining('958 MB'), findsWidgets);
    expect(find.textContaining('Not downloaded'), findsOneWidget);
    expect(find.textContaining('Downloading'), findsOneWidget);
    expect(find.textContaining('Ready'), findsOneWidget);
    expect(find.textContaining('Active'), findsOneWidget);
    expect(find.textContaining("Couldn't download"), findsOneWidget);
    expect(find.text('HTTP 404'), findsOneWidget);
    expect(find.textContaining('400.0 / 958.0 MB (40%)'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('http'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('model-download-new')));
    await tester.tap(find.byKey(const ValueKey('model-cancel-busy')));
    await tester.tap(find.byKey(const ValueKey('model-remove-ready')));
    await tester.tap(find.text('Installed model'));
    expect(downloaded, 1);
    expect(cancelled, 1);
    expect(removed, 1);
    // The ready row is already selected, so onSelect is still wired here and
    // the row tap invokes it. Callers omit onSelect once it is active.
    expect(selected, 1);
  });

  testWidgets('a long row wraps at 320dp and text scale 2', (tester) async {
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString().split('\n').first);
        return;
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await pump(
      tester,
      ModelDownloadList(
        items: [
          ModelDownloadItem(
            id: 'long',
            name: 'Tencent HY-MT 1.5 1.8B Q4_K_M',
            sizeBytes: 1140000000,
            status: ModelDownloadStatus.downloading,
            progress: 0.2,
            downloadedBytes: 200 * 1024 * 1024,
            totalBytes: 1140000000,
            onCancel: () {},
          ),
        ],
      ),
      textScale: 2,
      size: const Size(320, 568),
    );
    expect(overflows, isEmpty);
    expect(find.text('Tencent HY-MT 1.5 1.8B Q4_K_M'), findsOneWidget);
  });

  testWidgets('translation presets and installs share one list', (
    tester,
  ) async {
    final settings = AppSettingsService();
    await settings.loadSettings();
    final preset = translationPresetModels.first;
    final other = translationPresetModels[1];
    await settings.setTranslationDownloadedModels([
      TranslationModelRecord(
        id: preset.id,
        name: preset.name,
        sourceUrl: preset.sourceUrl,
        localPath: '/tmp/model.gguf',
        downloadedAt: DateTime.utc(2026, 1, 1),
        fileSizeBytes: 1140000000,
      ),
      TranslationModelRecord(
        id: other.id,
        name: other.name,
        sourceUrl: other.sourceUrl,
        localPath: '/tmp/other.gguf',
        downloadedAt: DateTime.utc(2026, 1, 2),
        fileSizeBytes: 1400 * 1024 * 1024,
      ),
    ]);
    await settings.setTranslationSelectedModelId(preset.id);
    final translation = TranslationService(settings);

    await pump(
      tester,
      const TranslationSettingsSection(),
      providers: [
        ChangeNotifierProvider<AppSettingsService>.value(value: settings),
        ChangeNotifierProvider<TranslationService>.value(value: translation),
      ],
    );

    expect(find.text('Tencent HY-MT 1.5 1.8B Q4_K_M'), findsOneWidget);
    expect(find.text('Tencent HY-MT 1.5 1.8B Q6_K'), findsOneWidget);
    expect(find.textContaining('Ready'), findsNWidgets(2));
    expect(find.textContaining('Active'), findsOneWidget);
    expect(find.textContaining('Not downloaded'), findsNothing);
    expect(find.text('Downloaded model'), findsNothing);
    expect(find.text('Preset Hugging Face model'), findsNothing);
    expect(find.text('Manual model URL'), findsOneWidget);
    expect(find.textContaining('huggingface.co'), findsNothing);
    expect(find.textContaining('.gguf'), findsNothing);

    await tester.tap(find.text('Tencent HY-MT 1.5 1.8B Q6_K'));
    await tester.pump();
    expect(settings.settings.translationSelectedModelId, other.id);

    await tester.tap(find.byKey(ValueKey('model-remove-${preset.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      settings.settings.translationDownloadedModels.map((model) => model.id),
      [other.id],
    );
    expect(find.textContaining('Not downloaded'), findsOneWidget);
  });

  testWidgets('a custom download stays visible after settings is reopened', (
    tester,
  ) async {
    final settings = AppSettingsService();
    await settings.loadSettings();
    final translation = TranslationService(settings);
    addTearDown(translation.dispose);
    // The page that started the download is gone. Only the service still
    // knows which file is in flight.
    translation.debugSetActiveDownload(
      sourceUrl: 'http://127.0.0.1/Tencent-demo.gguf',
      fileName: 'Tencent-demo.gguf',
      downloadedBytes: 400 * 1024,
      totalBytes: 1024 * 1024,
    );

    final providers = <SingleChildWidget>[
      ChangeNotifierProvider<AppSettingsService>.value(value: settings),
      ChangeNotifierProvider<TranslationService>.value(value: translation),
    ];
    await pump(
      tester,
      const TranslationSettingsSection(),
      providers: providers,
    );
    expect(find.text('Tencent-demo'), findsOneWidget);
    expect(find.textContaining('Downloading'), findsOneWidget);
    expect(find.textContaining('0.4 / 1.0 MB (39%)'), findsOneWidget);
    expect(find.byTooltip('Cancel'), findsOneWidget);

    await pump(tester, const SizedBox.shrink(), providers: providers);
    await pump(
      tester,
      const TranslationSettingsSection(),
      providers: providers,
    );
    expect(find.text('Tencent-demo'), findsOneWidget);
    expect(find.textContaining('Downloading'), findsOneWidget);
    expect(find.byTooltip('Cancel'), findsOneWidget);
    expect(find.text('Tencent HY-MT 1.5 1.8B Q4_K_M'), findsOneWidget);

    final preset = translationPresetModels.first;
    translation.debugSetActiveDownload(
      sourceUrl: preset.sourceUrl,
      fileName: preset.name,
      modelId: preset.id,
      displayedFileName: 'Merging chunks...',
    );
    await tester.pump();
    expect(find.text('Tencent-demo'), findsNothing);
    expect(find.textContaining('Downloading'), findsOneWidget);
    expect(find.textContaining('Merging downloaded chunks'), findsOneWidget);
    expect(find.byTooltip('Cancel'), findsOneWidget);
  });

  testWidgets('an installed image bundle is one ready row', (tester) async {
    final spec = imageCodecPresetModels.single;
    final settings = AppSettingsService();
    final store = InMemoryImageCodecSettingsStore(
      ImageCodecPreferences(
        enabled: true,
        selectedModelId: spec.id,
        downloadedModels: [
          ImageCodecModelRecord(
            id: spec.id,
            name: spec.fileName,
            sourceUrl: spec.graph.sourceUrl,
            localPath: '/tmp/${spec.fileName}',
            downloadedAt: DateTime.utc(2026, 1, 1),
            fileSizeBytes: spec.totalSizeBytes,
            assetFileNames: [for (final asset in spec.assets) asset.fileName],
            assetRoles: {
              for (final asset in spec.assets) asset.fileName: asset.role,
            },
            bundleVersion: kImageCodecBundleVersion,
          ),
        ],
      ),
    );
    final codec = ImageCodecService(settings, settingsStore: store);

    await pump(
      tester,
      const ImageCodecModelsSection(),
      providers: [
        ChangeNotifierProvider<ImageCodecService>.value(value: codec),
      ],
    );

    expect(find.text(spec.label), findsOneWidget);
    expect(find.textContaining(spec.fileName), findsNothing);
    expect(find.textContaining('.onnx'), findsNothing);
    expect(find.textContaining('958 MB'), findsOneWidget);
    expect(find.textContaining('Ready'), findsOneWidget);
    expect(find.textContaining('Active'), findsOneWidget);
    expect(find.byTooltip('Remove model'), findsOneWidget);
    expect(find.byTooltip('Download'), findsNothing);
  });

  testWidgets('a partial image bundle stays on the preset row', (tester) async {
    final spec = imageCodecPresetModels.single;
    final settings = AppSettingsService();
    final store = InMemoryImageCodecSettingsStore(
      ImageCodecPreferences(
        enabled: true,
        downloadedModels: [
          ImageCodecModelRecord(
            id: spec.id,
            name: spec.fileName,
            sourceUrl: spec.graph.sourceUrl,
            localPath: '/tmp/${spec.fileName}',
            downloadedAt: DateTime.utc(2026, 1, 1),
            fileSizeBytes: spec.graph.sizeBytes,
            assetFileNames: [spec.fileName],
            bundleVersion: 0,
          ),
        ],
      ),
    );
    final codec = ImageCodecService(settings, settingsStore: store);

    await pump(
      tester,
      const ImageCodecModelsSection(),
      providers: [
        ChangeNotifierProvider<ImageCodecService>.value(value: codec),
      ],
    );

    expect(find.text(spec.label), findsOneWidget);
    expect(find.textContaining(spec.fileName), findsNothing);
    expect(find.textContaining('Incomplete'), findsOneWidget);
    expect(find.byTooltip('Download'), findsOneWidget);
    expect(find.byTooltip('Remove model'), findsOneWidget);
  });
}
