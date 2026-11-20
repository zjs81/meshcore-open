import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/theme/mesh_theme.dart';

void main() {
  group('snrColor gradient', () {
    test('anchors red at -10 dB and green at +8 dB', () {
      expect(MeshTheme.snrColor(-10, blocked: false), MeshPalette.alert);
      expect(MeshTheme.snrColor(-15, blocked: false), MeshPalette.alert);
      expect(MeshTheme.snrColor(8, blocked: false), MeshPalette.signal);
      expect(MeshTheme.snrColor(12, blocked: false), MeshPalette.signal);
    });

    test('midpoint is amber', () {
      expect(MeshTheme.snrColor(-1, blocked: false), MeshPalette.warn);
    });

    test('interpolates smoothly between the anchors', () {
      final below = MeshTheme.snrColor(-6, blocked: false);
      final above = MeshTheme.snrColor(4, blocked: false);
      expect(
        below.g,
        inInclusiveRange(MeshPalette.alert.g + 0.01, MeshPalette.warn.g - 0.01),
      );
      expect(
        above.g,
        inInclusiveRange(
          MeshPalette.warn.g + 0.01,
          MeshPalette.signal.g - 0.01,
        ),
      );
      expect(
        MeshTheme.snrColor(-3, blocked: false).g,
        greaterThan(MeshTheme.snrColor(-8, blocked: false).g),
      );
    });

    test('blocked and unknown signals keep their fixed colors', () {
      expect(MeshTheme.snrColor(null, blocked: false), MeshPalette.ink3);
      expect(MeshTheme.snrColor(100, blocked: true), MeshPalette.alert);
    });
  });

  group('rssiColor gradient', () {
    test('anchors red at -140 dBm and green at -20 dBm', () {
      expect(MeshTheme.rssiColor(-140), MeshPalette.alert);
      expect(MeshTheme.rssiColor(-160), MeshPalette.alert);
      expect(MeshTheme.rssiColor(-20), MeshPalette.signal);
      expect(MeshTheme.rssiColor(-10), MeshPalette.signal);
    });

    test('midpoint is amber', () {
      expect(MeshTheme.rssiColor(-80), MeshPalette.warn);
    });

    test('null keeps its fixed color', () {
      expect(MeshTheme.rssiColor(null), MeshPalette.ink3);
    });
  });

  group('signalColor gradient', () {
    test('defaults to ink when no measurement is present', () {
      expect(MeshTheme.signalColor(), MeshPalette.ink3);
    });

    test('SNR alone follows the gradient anchors', () {
      expect(MeshTheme.signalColor(snrDb: -10), MeshPalette.alert);
      expect(MeshTheme.signalColor(snrDb: 8), MeshPalette.signal);
    });

    test('uses the worse of SNR and RSSI', () {
      final weakRssi = MeshTheme.signalColor(snrDb: 8, rssiDbm: -119);
      final strongRssi = MeshTheme.signalColor(snrDb: 8, rssiDbm: -30);
      expect(weakRssi.g, lessThan(strongRssi.g));
    });
  });
}
