import 'package:flutter/foundation.dart';

import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';

class PathHelper {
  static String formatPathHex(List<int> pathBytes) {
    return pathBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(',');
  }

  static String hopHex(int byte) {
    return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  static String formatHopHex(List<int> hopBytes) {
    return hopBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();
  }

  static String? hopName(int byte, List<Contact> allContacts) {
    final matches = allContacts
        .where(
          (c) =>
              c.publicKey.isNotEmpty &&
              c.publicKey.first == byte &&
              (c.type == advTypeRepeater || c.type == advTypeRoom),
        )
        .toList();
    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first.name;
    return matches.map((c) => c.name).join(' | ');
  }

  static List<Uint8List> splitPathBytes(
    List<int> pathBytes,
    int hashByteWidth,
  ) {
    if (pathBytes.isEmpty) return const [];

    final width = hashByteWidth.clamp(1, 4).toInt();
    final hops = <Uint8List>[];
    for (int i = 0; i < pathBytes.length; i += width) {
      final endIdx = (i + width).clamp(0, pathBytes.length).toInt();
      final hopBytes = pathBytes.sublist(i, endIdx);
      if (hopBytes.isNotEmpty) {
        hops.add(Uint8List.fromList(hopBytes));
      }
    }
    return hops;
  }

  /// Resolves path bytes to contact names, supporting multi-byte hash widths.
  ///
  /// Groups path bytes according to [hashByteWidth]:
  /// - 1: Single byte per hop (256 unique nodes)
  /// - 2: Two bytes per hop (65K unique nodes)
  /// - 3: Three bytes per hop (16M unique nodes)
  /// - 4: Four bytes per hop (4.3G unique nodes)
  static String resolvePathNames(
    List<int> pathBytes,
    List<Contact> allContacts,
    int hashByteWidth,
  ) {
    if (pathBytes.isEmpty) return '';

    final parts = <String>[];

    for (final hopBytes in splitPathBytes(pathBytes, hashByteWidth)) {
      final hex = formatHopHex(hopBytes);

      final matches = allContacts.where((c) {
        if (c.publicKey.length < hopBytes.length) return false;
        if (c.type != advTypeRepeater && c.type != advTypeRoom) return false;
        return listEquals(c.publicKey.sublist(0, hopBytes.length), hopBytes);
      }).toList();

      if (matches.isEmpty) {
        parts.add(hex);
      } else if (matches.length == 1) {
        parts.add(matches.first.name);
      } else {
        parts.add(matches.map((c) => c.name).join(' | '));
      }
    }

    return parts.join(' \u2192 ');
  }
}
