import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/helpers/guessed_location_estimator.dart';

const _phoenix = (33.45, -112.07);
const _casaGrande = (32.88, -111.76);
const _flagstaff = (35.20, -111.65);
const _london = (51.50, -0.12);

Uint8List _key(List<int> bytes) =>
    Uint8List.fromList([...bytes, ...List.filled(32 - bytes.length, 0)]);

GuessInput _input({
  required List<GuessCandidate> candidates,
  required List<(Uint8List, double, double)> anchors,
  (double, double)? self,
}) => (
  candidates: candidates,
  anchors: anchors,
  selfPosition: self,
  maxRangeKm: null,
);

GuessCandidate _node(List<(List<int>, int)> paths) =>
    (publicKey: _key([0x99]), paths: paths);

double _km((double, double) a, double lat, double lon) => const Distance().as(
  LengthUnit.Kilometer,
  LatLng(a.$1, a.$2),
  LatLng(lat, lon),
);

void main() {
  test('places a node next to the repeater its path ends on', () {
    final result = estimateGuessedLocations(
      _input(
        candidates: [
          _node([
            ([0xA1, 0xB2], 1),
          ]),
        ],
        anchors: [
          (_key([0xA1]), _phoenix.$1, _phoenix.$2),
          (_key([0xB2]), _casaGrande.$1, _casaGrande.$2),
        ],
        self: _phoenix,
      ),
    );

    expect(result, hasLength(1));
    final (index, lat, lon, highConfidence) = result.single;
    expect(index, 0);
    expect(_km(_casaGrande, lat, lon), lessThan(1));
    expect(highConfidence, isFalse);
  });

  test('resolves a colliding hop prefix to the repeater in range', () {
    // Two repeaters share prefix 0xB2: one in Tucson, one in London.
    final result = estimateGuessedLocations(
      _input(
        candidates: [
          _node([
            ([0xA1, 0xB2], 1),
          ]),
        ],
        anchors: [
          (_key([0xA1]), _phoenix.$1, _phoenix.$2),
          (_key([0xB2]), _london.$1, _london.$2),
          (_key([0xB2, 0x01]), _casaGrande.$1, _casaGrande.$2),
        ],
        self: _phoenix,
      ),
    );

    final (_, lat, lon, _) = result.single;
    expect(_km(_casaGrande, lat, lon), lessThan(1));
  });

  test('skips an ambiguous prefix when there is no reference point', () {
    final result = estimateGuessedLocations(
      _input(
        candidates: [
          _node([
            ([0xB2], 1),
          ]),
        ],
        anchors: [
          (_key([0xB2]), _london.$1, _london.$2),
          (_key([0xB2, 0x01]), _casaGrande.$1, _casaGrande.$2),
        ],
      ),
    );

    expect(result, isEmpty);
  });

  test('weights repeaters by how many paths ended on them', () {
    final result = estimateGuessedLocations(
      _input(
        candidates: [
          _node([
            ([0xB2], 1),
            ([0xB2], 1),
            ([0xB2], 1),
            ([0xC3], 1),
          ]),
        ],
        anchors: [
          (_key([0xB2]), _phoenix.$1, _phoenix.$2),
          (_key([0xC3]), _casaGrande.$1, _casaGrande.$2),
        ],
      ),
    );

    final (_, lat, lon, highConfidence) = result.single;
    expect(highConfidence, isTrue);
    // Three votes for Phoenix, one for Tucson: a quarter of the way.
    expect(
      lat,
      closeTo(_phoenix.$1 + (_casaGrande.$1 - _phoenix.$1) / 4, 0.01),
    );
    expect(
      lon,
      closeTo(_phoenix.$2 + (_casaGrande.$2 - _phoenix.$2) / 4, 0.01),
    );
  });

  test('result does not depend on path order', () {
    List<(int, double, double, bool)> run(List<(List<int>, int)> paths) =>
        estimateGuessedLocations(
          _input(
            candidates: [_node(paths)],
            anchors: [
              (_key([0xB2]), _phoenix.$1, _phoenix.$2),
              (_key([0xC3]), _flagstaff.$1, _flagstaff.$2),
            ],
          ),
        );

    expect(
      run([
        ([0xB2], 1),
        ([0xC3], 1),
      ]),
      run([
        ([0xC3], 1),
        ([0xB2], 1),
      ]),
    );
  });

  test('drops a repeater too far from the others to share one node', () {
    final result = estimateGuessedLocations(
      _input(
        candidates: [
          _node([
            ([0xB2], 1),
            ([0xC3], 1),
            ([0xD4], 1),
          ]),
        ],
        anchors: [
          (_key([0xB2]), _phoenix.$1, _phoenix.$2),
          (_key([0xC3]), _casaGrande.$1, _casaGrande.$2),
          (_key([0xD4]), _london.$1, _london.$2),
        ],
      ),
    );

    final (_, lat, lon, _) = result.single;
    expect(lat, closeTo((_phoenix.$1 + _casaGrande.$1) / 2, 0.01));
    expect(lon, closeTo((_phoenix.$2 + _casaGrande.$2) / 2, 0.01));
  });

  test('handles 2-byte hop hashes', () {
    final result = estimateGuessedLocations(
      _input(
        candidates: [
          _node([
            ([0xA1, 0x01, 0xB2, 0x02], 2),
          ]),
        ],
        anchors: [
          (_key([0xA1, 0x01]), _phoenix.$1, _phoenix.$2),
          (_key([0xB2, 0x02]), _casaGrande.$1, _casaGrande.$2),
          (_key([0xB2, 0x03]), _flagstaff.$1, _flagstaff.$2),
        ],
        self: _phoenix,
      ),
    );

    final (_, lat, lon, _) = result.single;
    expect(_km(_casaGrande, lat, lon), lessThan(1));
  });
}
