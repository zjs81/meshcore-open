import 'dart:convert';
import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import 'contact_qr.dart';

/// Builds the device frame that applies [scanned].
///
/// Advert blobs are replayed with `CMD_IMPORT_CONTACT`; contact cards are
/// written with `CMD_ADD_UPDATE_CONTACT`, preserving the flags, name and route
/// of [existing] when the QR omits them. A card carries no route, so a contact
/// the device does not know yet is written with the `0xFF` unknown-path
/// sentinel (`Contact.fromFrame` maps it to `hopCount == -1`) and its messages
/// flood until an advert supplies a path.
///
/// [pathHashByteWidth] is the connector's current path-hash mode, needed to
/// re-encode a preserved path the same way the rest of the app does.
Uint8List buildContactQrFrame(
  ScannedContact scanned, {
  Contact? existing,
  int pathHashByteWidth = 1,
}) {
  if (scanned.isAdvertPacket) {
    return buildImportContactFrame(scanned.advertPacket!);
  }
  final route = _routeOf(existing, pathHashByteWidth);
  return buildUpdateContactPathFrame(
    scanned.publicKey!,
    route.path,
    route.pathLen,
    type: scanned.type,
    flags: existing?.flags ?? 0,
    name: _fitName(
      scanned.name.isEmpty ? (existing?.name ?? '') : scanned.name,
    ),
  );
}

/// Rescanning a contact must not throw away a route the device already has:
/// writing an empty path with the unknown sentinel would force flooding until
/// another advert restores it. Reuse [existing]'s path when it is valid for the
/// current mode, encoded as `MeshCoreConnector._encodePathLenForCurrentMode`
/// does (hop count in bits 0-5, mode in bits 6-7).
({Uint8List path, int pathLen}) _routeOf(Contact? existing, int width) {
  final unknown = (path: Uint8List(0), pathLen: 0xFF);
  if (existing == null) return unknown;
  final hops = existing.pathLength;
  if (hops < 0 || hops > 0x3F) return unknown;
  final hashWidth = width.clamp(1, 4).toInt();
  final path = existing.path;
  if (path.length > maxPathSize || path.length != hops * hashWidth) {
    return unknown;
  }
  return (path: path, pathLen: hops | ((hashWidth - 1) << 6));
}

/// `writeCString` clips the encoded name to `maxNameSize - 1` bytes without
/// looking at character boundaries, which would leave a half-written rune in
/// the contact record. Drop whole characters instead.
String _fitName(String name) {
  const limit = maxNameSize - 1;
  if (utf8.encode(name).length <= limit) return name;
  final buffer = StringBuffer();
  var used = 0;
  for (final rune in name.runes) {
    final char = String.fromCharCode(rune);
    final charBytes = utf8.encode(char).length;
    if (used + charBytes > limit) break;
    buffer.write(char);
    used += charBytes;
  }
  return buffer.toString();
}
