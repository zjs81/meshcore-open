import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/image_codec_support.dart';
import 'package:meshcore_open/models/translation_support.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/image_codec_service.dart';
import 'package:meshcore_open/services/image_codec_settings_store.dart';
import 'package:meshcore_open/services/translation_file_store.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';
import 'package:meshcore_open/widgets/image_codec_models_section.dart';
import 'package:meshcore_open/widgets/mesh_nav_tile.dart';
import 'package:meshcore_open/widgets/model_download_list.dart';
import 'package:meshcore_open/widgets/settings_reveal.dart';
import 'package:meshcore_open/widgets/translation_settings_section.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryTranslationFileStore extends TranslationFileStore {
  final Map<String, int> _files = {};

  @override
  Future<String> modelDirectoryPath() async => '/memory/translation_models';

  @override
  Future<List<TranslationModelRecord>> scanDownloadedModels() async => const [];

  @override
  Future<void> deleteModel(TranslationModelRecord model) async {
    _files.remove(model.localPath);
  }

  @override
  Future<void> deleteFile(String path) async {
    _files.remove(path);
  }

  @override
  Future<DownloadedModelFile> writeModelBytes({
    required String fileName,
    required Stream<List<int>> chunks,
  }) async {
    var total = 0;
    await for (final chunk in chunks) {
      total += chunk.length;
    }
    final path = '/memory/translation_models/$fileName';
    _files[path] = total;
    return DownloadedModelFile(localPath: path, fileSizeBytes: total);
  }
}

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
    await settings.setTranslationEnabled(true);
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
    await settings.setTranslationEnabled(true);
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

  testWidgets(
    'reopening settings during a custom download supports cancel, completion, and failure',
    (tester) async {
      StreamController<List<int>>? getStream;
      final settings = AppSettingsService();
      await settings.loadSettings();
      await settings.setTranslationEnabled(true);
      final translation = TranslationService(
        settings,
        fileStore: _MemoryTranslationFileStore(),
        clientFactory: () => MockClient.streaming((request, _) async {
          if (request.method == 'HEAD') {
            return http.StreamedResponse(
              const Stream<List<int>>.empty(),
              200,
              contentLength: 1024,
            );
          }
          final controller = StreamController<List<int>>();
          getStream = controller;
          return http.StreamedResponse(
            controller.stream,
            200,
            contentLength: 1024,
          );
        }),
      );
      addTearDown(translation.dispose);

      final providers = <SingleChildWidget>[
        ChangeNotifierProvider<AppSettingsService>.value(value: settings),
        ChangeNotifierProvider<TranslationService>.value(value: translation),
      ];

      Future<void> startCustomDownload(String url) async {
        await pump(
          tester,
          const TranslationSettingsSection(),
          providers: providers,
        );
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), url);
        await tester.pump();
        final urlFieldDownload = find.descendant(
          of: find.byType(TextField),
          matching: find.byTooltip('Download'),
        );
        await tester.ensureVisible(urlFieldDownload);
        await tester.tap(urlFieldDownload);
        await tester.pump();
        await tester.pump();
      }

      Future<void> leaveAndReopen() async {
        await pump(tester, const SizedBox.shrink(), providers: providers);
        await pump(
          tester,
          const TranslationSettingsSection(),
          providers: providers,
        );
      }

      // 1. Cancel after reopen.
      await startCustomDownload('https://example.com/Custom-Cancel.gguf');
      await tester.pump(Duration.zero);
      getStream!.add(List<int>.filled(512, 1));
      await tester.pump(Duration.zero);
      expect(translation.downloadedBytes, 512);
      await leaveAndReopen();
      expect(find.text('Custom-Cancel'), findsOneWidget);
      expect(find.textContaining('Downloading'), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);
      expect(
        find.byKey(
          ValueKey('model-download-${translationPresetModels.first.id}'),
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<IconButton>(
              find.descendant(
                of: find.byType(TextField),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.ensureVisible(find.byTooltip('Cancel'));
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pump();
      expect(translation.lastError, 'Download stopped.');
      getStream!.add(List<int>.filled(16, 1));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(translation.isDownloading, isFalse);
      expect(find.text('Custom-Cancel'), findsNothing);
      expect(find.text('Download stopped.'), findsNothing);

      // 2. Complete after reopen.
      await startCustomDownload('https://example.com/Custom-Complete.gguf');
      await tester.pump(Duration.zero);
      getStream!.add(List<int>.filled(512, 2));
      await tester.pump(Duration.zero);
      await leaveAndReopen();
      expect(find.text('Custom-Complete'), findsOneWidget);
      expect(find.textContaining('Downloading'), findsOneWidget);

      getStream!.add(List<int>.filled(512, 2));
      unawaited(getStream!.close());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(find.text('Custom-Complete'), findsOneWidget);
      expect(find.textContaining('Ready'), findsOneWidget);
      expect(find.textContaining('Active'), findsOneWidget);

      // 3. Failure after reopen.
      await startCustomDownload('https://example.com/Custom-Fail.gguf');
      await tester.pump(Duration.zero);
      getStream!.add(List<int>.filled(256, 3));
      await tester.pump(Duration.zero);
      await leaveAndReopen();
      expect(find.text('Custom-Fail'), findsOneWidget);
      expect(find.textContaining('Downloading'), findsOneWidget);

      getStream!.addError(http.ClientException('Connection reset'));
      unawaited(getStream!.close());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(find.text('Custom-Fail'), findsOneWidget);
      expect(find.textContaining("Couldn't download"), findsOneWidget);
      expect(find.textContaining('Connection reset'), findsOneWidget);
      // Error is shown in the model row detail, not duplicated below the URL field.
      expect(find.text('ClientException: Connection reset'), findsNothing);
      expect(
        find.byKey(
          const ValueKey('model-download-https://example.com/Custom-Fail.gguf'),
        ),
        findsOneWidget,
      );
    },
  );

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

  testWidgets(
    'notDownloaded uses non-download leading icon and aligns icons cleanly',
    (tester) async {
      await pump(
        tester,
        ModelDownloadList(
          items: [
            ModelDownloadItem(
              id: 'new',
              name: 'Uninstalled model',
              sizeBytes: 958 * 1024 * 1024,
              status: ModelDownloadStatus.notDownloaded,
              onDownload: () {},
            ),
            ModelDownloadItem(
              id: 'incomplete',
              name: 'Partial model',
              sizeBytes: 500 * 1024 * 1024,
              status: ModelDownloadStatus.notDownloaded,
              statusLabel: 'Incomplete',
              onDownload: () {},
              onDelete: () {},
            ),
            ModelDownloadItem(
              id: 'busy',
              name: 'Downloading model',
              sizeBytes: 958 * 1024 * 1024,
              status: ModelDownloadStatus.downloading,
              progress: 0.4,
              downloadedBytes: 400 * 1024 * 1024,
              totalBytes: 958 * 1024 * 1024,
              onCancel: () {},
            ),
            ModelDownloadItem(
              id: 'active',
              name: 'Active model',
              sizeBytes: 1100 * 1024 * 1024,
              status: ModelDownloadStatus.ready,
              selected: true,
              onDelete: () {},
            ),
            ModelDownloadItem(
              id: 'bad',
              name: 'Failed model',
              status: ModelDownloadStatus.error,
              detail:
                  'Download failed because the server closed the connection unexpectedly.',
              onDownload: () {},
            ),
          ],
        ),
      );

      final newRow = find.byKey(const ValueKey('model-row-new'));
      final newLeading = find.descendant(
        of: newRow,
        matching: find.byIcon(Icons.memory_outlined),
      );
      expect(newLeading, findsOneWidget);
      final newTrailingButton = find.byKey(
        const ValueKey('model-download-new'),
      );
      final newTrailingIcon = find.descendant(
        of: newTrailingButton,
        matching: find.byIcon(Icons.download_outlined),
      );
      expect(newTrailingIcon, findsOneWidget);
      // Leading icon must differ from trailing download icon.
      expect(
        tester.widget<Icon>(newLeading).icon,
        isNot(tester.widget<Icon>(newTrailingIcon).icon),
      );
      expect(tester.getSize(newLeading), const Size(24, 24));
      expect(
        tester.getCenter(newLeading).dy,
        closeTo(tester.getCenter(newTrailingIcon).dy, 1.0),
      );

      for (final (rowKey, buttonKey) in [
        ('model-row-incomplete', 'model-download-incomplete'),
        ('model-row-busy', 'model-cancel-busy'),
        ('model-row-active', 'model-remove-active'),
        ('model-row-bad', 'model-download-bad'),
      ]) {
        final row = find.byKey(ValueKey(rowKey));
        final button = find.byKey(ValueKey(buttonKey));
        final title = find
            .descendant(of: row, matching: find.byType(Text))
            .first;
        final leading = find
            .descendant(of: row, matching: find.byType(Icon))
            .first;
        final spinner = find.descendant(
          of: row,
          matching: find.byType(CircularProgressIndicator),
        );
        final leadingFinder = spinner.evaluate().isNotEmpty ? spinner : leading;
        expect(
          tester.getRect(leadingFinder).right,
          lessThan(tester.getRect(title).left),
        );
        expect(
          tester.getCenter(leadingFinder).dy,
          closeTo(tester.getCenter(button).dy, 1.0),
          reason: '$rowKey leading indicator and trailing button must center',
        );
      }
    },
  );

  testWidgets(
    'TranslationSettingsSection hides sub-options when off, reveals on enable, and aligns rows',
    (tester) async {
      final settings = AppSettingsService();
      await settings.loadSettings();
      final translation = TranslationService(settings);
      addTearDown(translation.dispose);

      await pump(
        tester,
        const TranslationSettingsSection(),
        providers: [
          ChangeNotifierProvider<AppSettingsService>.value(value: settings),
          ChangeNotifierProvider<TranslationService>.value(value: translation),
        ],
      );

      final context = tester.element(find.byType(TranslationSettingsSection));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.translation_enableTitle), findsOneWidget);
      expect(find.text(l10n.translation_autoIncomingTitle), findsNothing);
      expect(find.text(l10n.translation_composerTitle), findsNothing);
      expect(find.text(l10n.translation_targetLanguage), findsNothing);
      expect(find.text('Tencent HY-MT 1.5 1.8B Q4_K_M'), findsNothing);
      expect(find.text(l10n.translation_manualUrlLabel), findsNothing);

      await tester.tap(find.text(l10n.translation_enableTitle));
      await tester.pump();
      await tester.pump(RevealOnEnable.duration);
      await tester.pumpAndSettle();

      expect(find.text(l10n.translation_autoIncomingTitle), findsOneWidget);
      expect(find.text(l10n.translation_composerTitle), findsOneWidget);
      expect(find.text(l10n.translation_targetLanguage), findsOneWidget);
      expect(find.text('Tencent HY-MT 1.5 1.8B Q4_K_M'), findsOneWidget);
      expect(find.text(l10n.translation_manualUrlLabel), findsOneWidget);

      final revealFinder = find.byType(SettingsReveal);
      expect(revealFinder, findsOneWidget);
      final revealMaterial = tester.widget<Material>(
        find
            .descendant(of: revealFinder, matching: find.byType(Material))
            .first,
      );
      expect(
        revealMaterial.color,
        Theme.of(context).colorScheme.surfaceContainerHighest,
      );

      // Switches and Target language row are enabled when visible.
      final autoIncomingSwitch = tester.widget<SwitchListTile>(
        find.ancestor(
          of: find.text(l10n.translation_autoIncomingTitle),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(autoIncomingSwitch.onChanged, isNotNull);

      // Leading icons, titles, and trailing icons align across Target language
      // (MeshNavTile) and revealed ModelDownloadList rows.
      final targetTile = find.ancestor(
        of: find.text(l10n.translation_targetLanguage),
        matching: find.byType(MeshNavTile),
      );
      final targetIcon = find.descendant(
        of: targetTile,
        matching: find.byIcon(Icons.language),
      );
      final targetChevron = find.descendant(
        of: targetTile,
        matching: find.byIcon(Icons.chevron_right),
      );

      final firstPreset = translationPresetModels.first;
      final modelRow = find.byKey(ValueKey('model-row-${firstPreset.id}'));
      final modelLeadingIcon = find.descendant(
        of: modelRow,
        matching: find.byIcon(Icons.memory_outlined),
      );
      final modelTitle = find.descendant(
        of: modelRow,
        matching: find.text('Tencent HY-MT 1.5 1.8B Q4_K_M'),
      );
      final modelDownloadIcon = find.descendant(
        of: find.byKey(ValueKey('model-download-${firstPreset.id}')),
        matching: find.byIcon(Icons.download_outlined),
      );

      expect(modelLeadingIcon, findsOneWidget);
      expect(
        tester.getRect(modelLeadingIcon).left,
        closeTo(tester.getRect(targetIcon).left, 0.5),
      );
      expect(
        tester.getRect(modelTitle).left,
        closeTo(
          tester.getRect(find.text(l10n.translation_targetLanguage)).left,
          0.5,
        ),
      );
      expect(
        tester.getRect(modelDownloadIcon).right,
        closeTo(tester.getRect(targetChevron).right, 0.5),
      );

      // Toggling off hides sub-options again.
      await tester.tap(find.text(l10n.translation_enableTitle));
      await tester.pumpAndSettle();
      expect(find.text(l10n.translation_autoIncomingTitle), findsNothing);
      expect(find.text(l10n.translation_targetLanguage), findsNothing);
      expect(find.text(l10n.translation_manualUrlLabel), findsNothing);
    },
  );

  for (final scale in [1.3, 2.0]) {
    testWidgets(
      'translation section and two-action model rows fit 320dp at ${scale}x',
      (tester) async {
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

        final settings = AppSettingsService();
        await settings.loadSettings();
        await settings.setTranslationEnabled(true);
        final translation = TranslationService(settings);
        addTearDown(translation.dispose);

        await pump(
          tester,
          Column(
            children: [
              const TranslationSettingsSection(),
              ModelDownloadList(
                items: [
                  ModelDownloadItem(
                    id: 'incomplete',
                    name: 'Tencent HY-MT 1.5 1.8B Q4_K_M',
                    sizeBytes: 958 * 1024 * 1024,
                    status: ModelDownloadStatus.notDownloaded,
                    statusLabel: 'Incomplete',
                    onDownload: () {},
                    onDelete: () {},
                  ),
                ],
              ),
            ],
          ),
          providers: [
            ChangeNotifierProvider<AppSettingsService>.value(value: settings),
            ChangeNotifierProvider<TranslationService>.value(
              value: translation,
            ),
          ],
          textScale: scale,
          size: const Size(320, 568),
        );
        expect(overflows, isEmpty);
      },
    );
  }
}
