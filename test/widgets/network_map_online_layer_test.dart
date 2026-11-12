import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/services/network_map/network_map_api_client.dart';
import 'package:meshcore_open/widgets/network_map_online_layer.dart';

NetworkMapCell _cell(String id, double lat, double lon) =>
    NetworkMapCell(cell: id, center: LatLng(lat, lon), boundary: const []);

NetworkMapRepeater _repeater(String key) => NetworkMapRepeater(
  key: key,
  name: null,
  type: 2,
  cell: _cell(key, 52.0, 13.0),
  locationSource: 'advert',
  confidence: 1,
  status: NetworkMapRepeaterStatus.active,
  confirmed: true,
  sightings: 1,
  firstSeen: null,
  lastSeen: null,
);

NetworkMapLink _link(String a, String b, {required bool confirmed}) =>
    NetworkMapLink(
      a: a,
      b: b,
      aCell: _cell(a, 52.0, 13.0),
      bCell: _cell(b, 52.1, 13.1),
      packets: 1,
      snr: null,
      confirmed: confirmed,
    );

List<Polyline> _linkLayerPolylines(
  NetworkMapOnlineController controller,
  List<NetworkMapLink> links,
) {
  final layers = buildNetworkMapOnlineLayers(
    controller: controller,
    repeaters: [
      for (final link in links) ...[_repeater(link.a), _repeater(link.b)],
    ],
    links: links,
    localMarkerKeys: const {},
    onTap: (_) {},
  );
  final lineLayer = layers.whereType<PolylineLayer>().single;
  return lineLayer.polylines;
}

void main() {
  test('links sharing a stroke style are grouped for batched drawing', () {
    final controller = NetworkMapOnlineController();
    addTearDown(controller.dispose);
    final links = [
      _link('a', 'b', confirmed: false),
      _link('c', 'd', confirmed: true),
      _link('e', 'f', confirmed: false),
      _link('g', 'h', confirmed: true),
    ];
    final polylines = _linkLayerPolylines(controller, links);
    expect(polylines, hasLength(4));
    final confirmedFlags = polylines.map((p) => p.pattern.segments == null);
    expect(confirmedFlags.toList(), orderedEquals([true, true, false, false]));
  });

  test('dense views draw solid lines without borders', () {
    final controller = NetworkMapOnlineController();
    addTearDown(controller.dispose);
    final links = List.generate(
      networkMapDenseLinkCount + 1,
      (i) => _link('a', 'b', confirmed: i.isEven),
    );
    final polylines = _linkLayerPolylines(controller, links);
    expect(polylines, hasLength(links.length));
    for (final polyline in polylines) {
      expect(polyline.pattern.segments, isNull);
      expect(polyline.borderStrokeWidth, 0);
    }
  });

  test('sparse unconfirmed links keep the dashed pattern', () {
    final controller = NetworkMapOnlineController();
    addTearDown(controller.dispose);
    final links = [
      _link('a', 'b', confirmed: true),
      _link('c', 'd', confirmed: false),
    ];
    final polylines = _linkLayerPolylines(controller, links);
    expect(polylines.first.pattern.segments, isNull);
    expect(polylines.last.pattern.segments, isNotNull);
    expect(polylines.last.borderStrokeWidth, 1);
  });

  test('links with an endpoint outside the visible repeaters are dropped', () {
    final controller = NetworkMapOnlineController();
    addTearDown(controller.dispose);
    final layers = buildNetworkMapOnlineLayers(
      controller: controller,
      repeaters: [_repeater('a')],
      links: [_link('a', 'b', confirmed: true)],
      localMarkerKeys: const {},
      onTap: (_) {},
    );
    final lineLayer = layers.whereType<PolylineLayer>().single;
    expect(lineLayer.polylines, isEmpty);
  });
}
