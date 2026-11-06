import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/utils/location_grid.dart';

void main() {
  const vectors = [
    (33.448376, -112.074036, 33.45, -112.080261),
    (47.606209, -122.332069, 47.61, -122.344218),
    (-33.8688, 151.2093, -33.87, 151.215954),
    (0.0, 0.0, 0.01, -0.009997),
    (51.5007, -0.1246, 51.51, -0.125401),
  ];

  test('matches the API contract test vectors', () {
    for (final (lat, lon, wantLat, wantLon) in vectors) {
      final snapped = snapToLocationGrid(lat, lon);
      expect(snapped.lat, closeTo(wantLat, 1e-9), reason: '$lat,$lon lat');
      expect(snapped.lon, closeTo(wantLon, 1e-9), reason: '$lat,$lon lon');
    }
  });

  test('snapping a center is idempotent', () {
    for (final (lat, lon, _, _) in vectors) {
      final once = snapToLocationGrid(lat, lon);
      final twice = snapToLocationGrid(once.lat, once.lon);
      expect(twice.lat, closeTo(once.lat, 1e-6));
      expect(twice.lon, closeTo(once.lon, 1e-6));
    }
  });
}
