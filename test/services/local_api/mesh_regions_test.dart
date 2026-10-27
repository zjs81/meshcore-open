import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/services/local_api/mesh_regions.dart';

void main() {
  final catalog = MeshRegionCatalog.fromJsonString('''
  {"version":1,"regions":[
    {"name":"sk","label":"Slovakia","kind":"country","lat":48.7164,"lon":19.5,"radiusKm":350},
    {"name":"sk-ba","label":"Bratislava","kind":"city","lat":48.1486,"lon":17.1077,"radiusKm":100},
    {"name":"sk-za","label":"Zilina","kind":"city","lat":49.2231,"lon":18.7394,"radiusKm":100}
  ]}
  ''');

  test('the nearest city wins over the country fallback', () {
    expect(catalog.resolve(48.15, 17.11)?.name, 'sk-ba');
    expect(catalog.resolve(49.22, 18.74)?.name, 'sk-za');
  });

  test('a place outside every circle resolves to nothing', () {
    expect(catalog.resolve(40.0, 0.0), isNull);
  });

  test('a broken asset means an empty catalog, not a crash', () {
    expect(MeshRegionCatalog.fromJsonString('not json').regions, isEmpty);
    expect(MeshRegionCatalog.fromJsonString('{"regions":[]}').regions, isEmpty);
  });
}
