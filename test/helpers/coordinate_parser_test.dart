import 'package:flutter/foundation.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/coordinate_parser.dart';

void main() {
  group('CoordinateParser.parse', () {
    test('parses positive and negative decimal pairs', () {
      const inputs = [
        ('37.7749,-122.4194', 37.7749, -122.4194),
        ('38.722,-9.139', 38.722, -9.139),
        ('-33.86882, 151.20929', -33.86882, 151.20929),
        ('51.5074, -0.1278', 51.5074, -0.1278),
        ('0.0, 0.0', 0.0, 0.0),
        ('45.515232, -122.678385', 45.515232, -122.678385),
        ('37.77491234,  -122.41945678', 37.77491234, -122.41945678),
      ];

      for (final (text, expectedLat, expectedLon) in inputs) {
        final parsed = CoordinateParser.parse(text);
        expect(parsed, hasLength(1), reason: 'Failed for "$text"');
        expect(parsed.first.latitude, closeTo(expectedLat, 1e-12));
        expect(parsed.first.longitude, closeTo(expectedLon, 1e-12));
        expect(parsed.first.rawText, text);
        expect(parsed.first.start, 0);
        expect(parsed.first.end, text.length);
      }
    });

    test('parses explicit + signs and optional whitespace after comma', () {
      final parsed = CoordinateParser.parse(
        'Meet at +37.7749,+122.4194 or +45.5152,\t-122.6784',
      );
      expect(parsed, hasLength(2));
      expect(parsed[0].rawText, '+37.7749,+122.4194');
      expect(parsed[0].latitude, 37.7749);
      expect(parsed[0].longitude, 122.4194);
      expect(parsed[1].rawText, '+45.5152,\t-122.6784');
      expect(parsed[1].latitude, 45.5152);
      expect(parsed[1].longitude, -122.6784);
    });

    test('accepts WGS84 boundary coordinates and rejects out-of-range', () {
      final validBounds = CoordinateParser.parse(
        '90.0, 180.0 and -90.0, -180.0',
      );
      expect(validBounds, hasLength(2));
      expect(validBounds[0].latitude, 90.0);
      expect(validBounds[0].longitude, 180.0);
      expect(validBounds[1].latitude, -90.0);
      expect(validBounds[1].longitude, -180.0);

      const invalidBounds = [
        '90.0001, 0.0',
        '-90.1, 0.0',
        '0.0, 180.0001',
        '0.0, -180.1',
        '990.0, -180.0',
        '123.45, 67.89',
      ];
      for (final text in invalidBounds) {
        expect(
          CoordinateParser.parse(text),
          isEmpty,
          reason: 'Should reject "$text"',
        );
      }
    });

    test('rejects plain integer pairs and mixed integer/decimal pairs', () {
      const invalid = [
        '1,2',
        '10, 20',
        '-45, 122',
        '37,-122.4194',
        '37.7749,-122',
      ];
      for (final text in invalid) {
        expect(
          CoordinateParser.parse(text),
          isEmpty,
          reason: 'Should reject "$text"',
        );
      }
    });

    test('rejects version numbers and digits inside words or identifiers', () {
      const invalid = [
        '1.2.3,4.5',
        '1.2,3.4.5',
        '1.2, 3.4.5',
        '1.2.3, 4.5.6',
        'v1.2,3.4',
        'foo37.7749,-122.4194',
        '37.7749,-122.4194bar',
        'id_37.7749,-122.4194',
        '37.7749,-122.4194_end',
        '--37.7749,-122.4194',
        '+-37.7749,-122.4194',
        '1.2,3.4-5',
      ];
      for (final text in invalid) {
        expect(
          CoordinateParser.parse(text),
          isEmpty,
          reason: 'Should reject "$text"',
        );
      }
    });

    test('handles punctuation boundaries around coordinates', () {
      const text =
          'Camp (37.7749, -122.4194), ridge [45.5152,-122.6784], end 38.722,-9.139.';
      final parsed = CoordinateParser.parse(text);
      expect(parsed, hasLength(3));
      expect(parsed[0].rawText, '37.7749, -122.4194');
      expect(text.substring(parsed[0].start, parsed[0].end), parsed[0].rawText);
      expect(parsed[1].rawText, '45.5152,-122.6784');
      expect(text.substring(parsed[1].start, parsed[1].end), parsed[1].rawText);
      expect(parsed[2].rawText, '38.722,-9.139');
      expect(text.substring(parsed[2].start, parsed[2].end), parsed[2].rawText);
    });

    test('parses multiple coordinates and #wardriving messages', () {
      const wardriving =
          '#wardriving 37.7749,-122.4194 SNR: 8.5dB -> (37.7812, -122.4111) '
          'and 38.722,-9.139, 51.5074, -0.1278';
      final parsed = CoordinateParser.parse(wardriving);
      expect(parsed, hasLength(4));
      expect(parsed.map((c) => c.rawText).toList(), [
        '37.7749,-122.4194',
        '37.7812, -122.4111',
        '38.722,-9.139',
        '51.5074, -0.1278',
      ]);
    });

    test('does not misparse coordinates inside URLs or emails', () {
      const urlOnly = [
        'https://maps.google.com/?q=37.7749,-122.4194',
        'https://www.openstreetmap.org/?mlat=37.7749&mlon=-122.4194#map=16/37.7749/-122.4194',
        'https://example.com/@37.7749,-122.4194,15z',
        'geo:37.7749,-122.4194',
        'maps.google.com/?q=37.7749,-122.4194',
      ];
      for (final text in urlOnly) {
        expect(
          CoordinateParser.parse(text),
          isEmpty,
          reason: 'Should not parse coordinate inside "$text"',
        );
      }

      const mixed =
          'Route https://maps.google.com/?q=10.0,20.0 meet at 37.7749, -122.4194';
      final parsed = CoordinateParser.parse(mixed);
      expect(parsed, hasLength(1));
      expect(parsed.first.rawText, '37.7749, -122.4194');

      final elements = CoordinateParser.linkifyWithCoordinates(mixed);
      expect(elements.whereType<UrlElement>(), hasLength(1));
      expect(elements.whereType<CoordinateElement>(), hasLength(1));
    });
  });

  group('buildExternalMapUri', () {
    test('builds platform-appropriate map URIs', () {
      expect(
        buildExternalMapUri(
          37.7749,
          -122.4194,
          platform: TargetPlatform.android,
          isWeb: false,
        ).toString(),
        'geo:37.7749,-122.4194?q=37.7749,-122.4194',
      );
      expect(
        buildExternalMapUri(
          37.7749,
          -122.4194,
          platform: TargetPlatform.iOS,
          isWeb: false,
        ).toString(),
        'https://maps.apple.com/?ll=37.7749,-122.4194&q=37.7749,-122.4194',
      );
      expect(
        buildExternalMapUri(
          37.7749,
          -122.4194,
          platform: TargetPlatform.macOS,
          isWeb: false,
        ).toString(),
        'https://maps.apple.com/?ll=37.7749,-122.4194&q=37.7749,-122.4194',
      );
      expect(
        buildExternalMapUri(
          37.7749,
          -122.4194,
          platform: TargetPlatform.linux,
          isWeb: false,
        ).toString(),
        'https://www.openstreetmap.org/?mlat=37.7749&mlon=-122.4194#map=16/37.7749/-122.4194',
      );
      expect(
        buildExternalMapUri(
          37.7749,
          -122.4194,
          platform: TargetPlatform.windows,
          isWeb: false,
        ).toString(),
        'https://www.openstreetmap.org/?mlat=37.7749&mlon=-122.4194#map=16/37.7749/-122.4194',
      );
      expect(
        buildExternalMapUri(-0.0, -0.0, isWeb: true).toString(),
        'https://www.openstreetmap.org/?mlat=0.0&mlon=0.0#map=16/0.0/0.0',
      );
    });
  });
}
