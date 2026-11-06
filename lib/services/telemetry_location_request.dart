import 'dart:async';

import 'package:flutter/foundation.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/cayenne_lpp.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../utils/app_logger.dart';

enum TelemetryLocationResult { located, noLocation, failed }

/// Returns the first valid GPS fix in parsed Cayenne LPP telemetry, or null.
({double latitude, double longitude})? telemetryGpsFix(
  List<Map<String, dynamic>> entries,
) {
  for (final entry in entries) {
    final values = entry['values'];
    if (values is! Map) continue;
    final gps = values['gps'];
    if (gps is! Map) continue;
    final lat = gps['latitude'];
    final lon = gps['longitude'];
    if (lat is! num || lon is! num) continue;
    final latitude = lat.toDouble();
    final longitude = lon.toDouble();
    const double epsilon = 1e-6;
    final valid =
        (latitude.abs() > epsilon || longitude.abs() > epsilon) &&
        latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
    if (valid) return (latitude: latitude, longitude: longitude);
  }
  return null;
}

/// Asks [contact] for its telemetry and, when the reply carries a GPS fix,
/// stores it on the contact so the map moves the node right away.
Future<TelemetryLocationResult> requestTelemetryLocation(
  MeshCoreConnector connector,
  Contact contact,
) async {
  final completer = Completer<List<Map<String, dynamic>>?>();
  // Armed just before our send: a background retry's RESP_CODE_SENT that
  // lands while the path is being prepared must not be taken for ours.
  var awaitingSent = false;
  int? tag;
  Timer? timeout;
  void finish(List<Map<String, dynamic>>? parsed) {
    if (completer.isCompleted) return;
    timeout?.cancel();
    completer.complete(parsed);
  }

  final isChat = contact.type == advTypeChat;
  final subscription = connector.receivedFrames.listen((frame) {
    if (frame.isEmpty || completer.isCompleted) return;
    final reader = BufferReader(frame);
    try {
      final cmd = reader.readByte();
      if (cmd == respCodeSent && awaitingSent) {
        awaitingSent = false;
        reader.skipBytes(1); // reserved
        tag = reader.readUInt32LE();
        final tripTime = reader.readUInt32LE();
        timeout?.cancel();
        timeout = Timer(Duration(milliseconds: tripTime), () => finish(null));
      } else if (cmd == respCodeErr && awaitingSent) {
        awaitingSent = false;
        finish(null);
      } else if (cmd == pushCodeBinaryResponse) {
        // Binary requests always answer here. A chat telemetry reply also
        // lands here, tagged, when another request replaced it as the
        // radio's pending request.
        reader.skipBytes(1); // reserved
        if (tag == null || reader.readUInt32LE() != tag) return;
        finish(CayenneLpp.parseByChannel(reader.readRemainingBytes()));
      } else if (cmd == pushCodeTelemetryResponse && isChat) {
        reader.skipBytes(1); // reserved
        final prefix = reader.readBytes(6);
        if (!listEquals(contact.publicKey.sublist(0, 6), prefix)) return;
        finish(CayenneLpp.parseByChannel(reader.readRemainingBytes()));
      }
    } catch (e) {
      appLogger.error('Error parsing telemetry location frame: $e');
    }
  });

  PathSelection? selection;
  try {
    selection = await connector.preparePathForContactSend(contact);
    awaitingSent = true;
    // Guards the wait for the radio's send ack; its trip time replaces this.
    timeout = Timer(const Duration(seconds: 10), () => finish(null));
    await connector.sendFrame(
      isChat
          ? buildSendTelemetryReq(contact.publicKey)
          : buildSendBinaryReq(
              contact.publicKey,
              payload: buildTelemetryBinaryPayload(),
            ),
    );
  } catch (e) {
    appLogger.error('Telemetry location request failed: $e');
    finish(null);
  }

  final parsed = await completer.future;
  await subscription.cancel();
  if (selection != null) {
    connector.recordRepeaterPathResult(
      contact,
      selection,
      parsed != null,
      null,
    );
  }
  if (parsed == null) return TelemetryLocationResult.failed;
  final fix = telemetryGpsFix(parsed);
  if (fix == null) return TelemetryLocationResult.noLocation;
  connector.updateContactLocationFromTelemetry(
    contact.publicKeyHex,
    fix.latitude,
    fix.longitude,
  );
  return TelemetryLocationResult.located;
}
