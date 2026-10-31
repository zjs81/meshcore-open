import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'contact.dart';

/// The map's path-trace builder state: the hops picked so far, the trace
/// mode and the last result. Held by [UiViewStateService] for the app session
/// so leaving the map or opening the result doesn't discard it.
class MapPathTraceDraft {
  bool active = false;
  Uint8List? radioKey;
  final List<int> pathBytes = [];
  final List<int> hopWidths = [];
  final List<Contact> contacts = [];
  final List<LatLng> points = [];
  bool returnPath = true;
  Uint8List? lastResultFrame;

  bool get hasHops => pathBytes.isNotEmpty;

  bool belongsTo(Uint8List? selfKey) =>
      radioKey == null || selfKey == null || listEquals(radioKey, selfKey);

  void clear() {
    pathBytes.clear();
    hopWidths.clear();
    contacts.clear();
    points.clear();
    lastResultFrame = null;
  }
}
