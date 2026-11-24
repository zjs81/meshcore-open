import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/message_url_image_helper.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';

Future<ui.Image> _solid(int w, int h) {
  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    Uint8List(w * h * 4),
    w,
    h,
    ui.PixelFormat.rgba8888,
    c.complete,
  );
  return c.future;
}

class _FailingProvider extends ImageProvider<_FailingProvider> {
  @override
  Future<_FailingProvider> obtainKey(ImageConfiguration c) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Future.error(Exception('nope')));
}

Widget _host(Widget child, {double width = 320, double scale = 1.0}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 800),
        textScaler: TextScaler.linear(scale),
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          // Mimics a bubble: bounded width, tight-to-content otherwise.
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width - 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(alignment: Alignment.centerLeft, child: child),
                const Text('caption text that follows the image'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<Size> _previewSize(WidgetTester tester, int w, int h) async {
  final image = await tester.runAsync(() => _solid(w, h));
  await tester.pumpWidget(
    _host(
      MessageUrlImagePreview(
        imageUrl: 'https://example.com/a.png',
        imageProvider: _ImageProviderOf(image!),
      ),
    ),
  );
  await tester.pump();
  return tester.getSize(find.byType(RawImage));
}

class _ImageProviderOf extends ImageProvider<_ImageProviderOf> {
  _ImageProviderOf(this.image);
  final ui.Image image;

  @override
  Future<_ImageProviderOf> obtainKey(ImageConfiguration c) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _ImageProviderOf key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    SynchronousFuture(ImageInfo(image: image.clone())),
  );
}

void main() {
  test('urlImagePreviewSize keeps aspect ratio and caps height', () {
    expect(urlImagePreviewSize(400, 100, 280), const Size(280, 70));
    expect(urlImagePreviewSize(300, 300, 280), const Size(280, 280));
    final tall = urlImagePreviewSize(100, 1000, 280);
    expect(tall.height, MessageUrlImagePreview.maxHeight);
    expect(tall.width, closeTo(40, 0.001));
  });

  testWidgets('4:1 image fills width with height width/4', (tester) async {
    final size = await _previewSize(tester, 400, 100);
    expect(size.width, 280);
    expect(size.height, closeTo(70, 0.001));
  });

  testWidgets('square image is 1:1 at full width', (tester) async {
    final size = await _previewSize(tester, 300, 300);
    expect(size, const Size(280, 280));
  });

  testWidgets('tall image is capped and shown whole', (tester) async {
    final size = await _previewSize(tester, 100, 1000);
    expect(size.height, MessageUrlImagePreview.maxHeight);
    expect(size.width, closeTo(40, 0.001));
  });

  testWidgets('unbounded width falls back to 320', (tester) async {
    final image = await tester.runAsync(() => _solid(640, 320));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: MessageUrlImagePreview(
              imageUrl: 'x',
              imageProvider: _ImageProviderOf(image!),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.getSize(find.byType(RawImage)), const Size(320, 160));
  });

  for (final scale in [1.3, 2.0]) {
    testWidgets('error state is compact without overflow at ${scale}x', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MessageUrlImagePreview(
            imageUrl: 'x',
            imageProvider: _FailingProvider(),
          ),
          scale: scale,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Unable to load image'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loading placeholder is compact and full width', (tester) async {
    await tester.pumpWidget(
      _host(
        MessageUrlImagePreview(imageUrl: 'x', imageProvider: _NeverProvider()),
      ),
    );
    final box = find.ancestor(
      of: find.byType(CircularProgressIndicator),
      matching: find.byType(SizedBox),
    );
    final size = tester.getSize(box.first);
    expect(size.width, 280);
    expect(size.height, MessageUrlImagePreview.statusHeight);
  });
}

class _NeverProvider extends ImageProvider<_NeverProvider> {
  @override
  Future<_NeverProvider> obtainKey(ImageConfiguration c) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _NeverProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}
