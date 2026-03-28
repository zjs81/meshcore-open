import '../models/contact.dart';
import '../connector/meshcore_protocol.dart';

class PathHelper {
  static String formatPathHex(List<int> pathBytes) {
    return pathBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(',');
  }

  static String resolvePathNames(
    List<int> pathBytes,
    List<Contact> allContacts,
  ) {
    return pathBytes
        .map((b) {
          final hex = b.toRadixString(16).padLeft(2, '0').toUpperCase();
          final matches = allContacts
              .where(
                (c) =>
                    c.publicKey.first == b &&
                    (c.type == advTypeRepeater || c.type == advTypeRoom),
              )
              .toList();
          if (matches.isEmpty) return hex;
          if (matches.length == 1) return matches.first.name;
          return matches.map((c) => c.name).join(' | ');
        })
        .join(' \u2192 ');
  }
}
