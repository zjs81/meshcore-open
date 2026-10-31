import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/marker_message.dart';

void main() {
  test('parseMarkerText accepts in-range coordinates', () {
    final payload = parseMarkerText('m:45.5,-122.6|Camp|x');
    expect(payload, isNotNull);
    expect(payload!.position.latitude, 45.5);
    expect(payload.position.longitude, -122.6);
    expect(payload.label, 'Camp');
  });

  test('parseMarkerText rejects out-of-range coordinates', () {
    expect(parseMarkerText('m:999,999|x|'), isNull);
    expect(parseMarkerText('m:90.1,0|x|'), isNull);
    expect(parseMarkerText('m:0,-180.5|x|'), isNull);
    expect(parseMarkerText('m:-90,180|edge|'), isNotNull);
  });
}
