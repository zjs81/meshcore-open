import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/widgets/image_send_codec_binding.dart';

void main() {
  group('rerollSourceRect', () {
    const sizes = [
      (4000, 3000),
      (3000, 4000),
      (1920, 1080),
      (512, 512),
      (7, 3),
    ];

    test('variant 0 is the whole photo', () {
      for (final (w, h) in sizes) {
        final r = rerollSourceRect(w, h, 0);
        expect(r.left, 0);
        expect(r.top, 0);
        expect(r.width, w);
        expect(r.height, h);
      }
    });

    test('every variant stays inside the photo and keeps its shape', () {
      for (final (w, h) in sizes) {
        for (var v = 0; v < kImageSendMaxVersions; v++) {
          final r = rerollSourceRect(w, h, v);
          expect(r.left, greaterThanOrEqualTo(0), reason: '$w x $h v$v');
          expect(r.top, greaterThanOrEqualTo(0), reason: '$w x $h v$v');
          expect(r.left + r.width, lessThanOrEqualTo(w + 1e-9));
          expect(r.top + r.height, lessThanOrEqualTo(h + 1e-9));
          // Same aspect, so the version keeps the photo's aspect code.
          expect(r.width / r.height, closeTo(w / h, (w / h) * 0.01));
          // "The whole photo": at most a few percent trimmed.
          expect(r.width, greaterThanOrEqualTo(w * 0.95));
        }
      }
    });

    test('variants differ from each other and are deterministic', () {
      final rects = [
        for (var v = 0; v < kImageSendMaxVersions; v++)
          rerollSourceRect(4000, 3000, v),
      ];
      expect(rects.toSet().length, kImageSendMaxVersions);
      expect(rerollSourceRect(4000, 3000, 3), rects[3]);
    });

    test('rejects a variant outside the table', () {
      expect(() => rerollSourceRect(10, 10, -1), throwsRangeError);
      expect(
        () => rerollSourceRect(10, 10, kImageSendMaxVersions),
        throwsRangeError,
      );
    });
  });
}
