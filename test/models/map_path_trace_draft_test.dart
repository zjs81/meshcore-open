import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_open/models/map_path_trace_draft.dart';
import 'package:meshcore_open/services/ui_view_state_service.dart';

void main() {
  test('draft survives on the shared view state service', () {
    final service = UiViewStateService();
    final draft = service.mapPathTrace
      ..active = true
      ..returnPath = false;
    draft.pathBytes.addAll([0xAB, 0xCD]);
    draft.points.add(const LatLng(1, 2));

    expect(identical(service.mapPathTrace, draft), isTrue);
    expect(service.mapPathTrace.hasHops, isTrue);
    expect(service.mapPathTrace.returnPath, isFalse);
  });

  test('clear drops hops and the last result but keeps the mode', () {
    final draft = MapPathTraceDraft()
      ..returnPath = false
      ..lastResultFrame = Uint8List.fromList([1, 2, 3]);
    draft.pathBytes.add(0xAB);
    draft.hopWidths.add(1);
    draft.points.add(const LatLng(1, 2));

    draft.clear();

    expect(draft.hasHops, isFalse);
    expect(draft.hopWidths, isEmpty);
    expect(draft.points, isEmpty);
    expect(draft.lastResultFrame, isNull);
    expect(draft.returnPath, isFalse);
  });

  test('belongsTo matches only the radio it was built on', () {
    final draft = MapPathTraceDraft();
    expect(draft.belongsTo(Uint8List.fromList([1, 2])), isTrue);
    draft.radioKey = Uint8List.fromList([1, 2]);
    expect(draft.belongsTo(Uint8List.fromList([1, 2])), isTrue);
    expect(draft.belongsTo(Uint8List.fromList([3, 4])), isFalse);
  });
}
