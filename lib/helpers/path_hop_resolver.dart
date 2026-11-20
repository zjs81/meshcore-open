import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../connector/meshcore_protocol.dart';
import 'path_helper.dart';
import '../models/contact.dart';

/// One hop of a packed routing path with every locally-known repeater whose
/// public key matches the hop prefix, plus the chosen assignment.
class PathHopResolution {
  final Uint8List hopBytes;
  final String hopHex;

  /// All local repeaters/rooms matching this hop's prefix hash, active ones
  /// first, then most recently seen first.
  final List<Contact> candidates;

  /// Contact chosen by an explicit user selection, if any.
  final Contact? forced;

  /// True when more than one repeater shares the prefix and no explicit
  /// selection has been made yet.
  bool ambiguous;

  /// Assignment chosen for this hop (null when nothing matches).
  Contact? selected;

  PathHopResolution({
    required this.hopBytes,
    required this.hopHex,
    required this.candidates,
    this.forced,
    this.ambiguous = false,
  }) : selected = forced ?? (candidates.isEmpty ? null : candidates.first);
}

class PathHopResolver {
  /// A hop-to-hop segment longer than this is treated as physically
  /// impossible for MeshCore's range and never assigned during resolution.
  static const double maxPlausibleHopMeters = 250000;

  const PathHopResolver._();

  static List<Contact?> resolve({
    required List<int> pathBytes,
    required List<Contact> contacts,
    LatLng? endpoint,
    bool resolveFromEnd = false,
    int pathHashByteWidth = 1,
  }) {
    return resolveDetailed(
      pathBytes: pathBytes,
      contacts: contacts,
      endpoint: endpoint,
      resolveFromEnd: resolveFromEnd,
      pathHashByteWidth: pathHashByteWidth,
    ).map((r) => r.selected).toList();
  }

  /// Resolves every hop, preferring the assignment with the shortest total
  /// distance and never assigning segments over [maxPlausibleHopMeters];
  /// hops that cannot fit within the cap stay unresolved.
  /// [forcedSelection] maps hop prefix hex to a full public key hex the user
  /// picked for an ambiguous hop.
  static List<PathHopResolution> resolveDetailed({
    required List<int> pathBytes,
    required List<Contact> contacts,
    LatLng? endpoint,
    bool resolveFromEnd = false,
    int pathHashByteWidth = 1,
    Map<String, String> forcedSelection = const {},
  }) {
    final width = pathHashByteWidth.clamp(1, 3).toInt();
    final candidatesByPrefix = <String, List<Contact>>{};
    for (final contact in contacts) {
      if (contact.publicKey.length < width) continue;
      if (contact.type != advTypeRepeater && contact.type != advTypeRoom) {
        continue;
      }
      final prefix = PathHelper.formatHopHex(
        contact.publicKey.sublist(0, width),
      );
      candidatesByPrefix.putIfAbsent(prefix, () => <Contact>[]).add(contact);
    }
    for (final candidates in candidatesByPrefix.values) {
      // Active repeaters win over inactive ones, then most recently seen.
      candidates.sort((a, b) {
        if (a.isActive != b.isActive) {
          return a.isActive ? -1 : 1;
        }
        return b.lastSeen.compareTo(a.lastSeen);
      });
    }

    final hops = PathHelper.splitPathBytes(pathBytes, width);
    final resolutions = <PathHopResolution>[];
    for (final hop in hops) {
      final hex = PathHelper.formatHopHex(hop);
      final candidates = List<Contact>.from(
        candidatesByPrefix[hex] ?? const <Contact>[],
      );
      final forcedKey = forcedSelection[hex]?.toLowerCase();
      Contact? forced;
      if (forcedKey != null) {
        for (final contact in candidates) {
          if (contact.publicKeyHex.toLowerCase() == forcedKey) {
            forced = contact;
            break;
          }
        }
      }
      resolutions.add(
        PathHopResolution(
          hopBytes: hop,
          hopHex: hex,
          candidates: candidates,
          forced: forced,
          ambiguous: forced == null && candidates.length > 1,
        ),
      );
    }

    final chainOrder = resolveFromEnd
        ? List<int>.generate(
            resolutions.length,
            (i) => resolutions.length - 1 - i,
          )
        : List<int>.generate(resolutions.length, (i) => i);
    _assignShortestTotal(resolutions, chainOrder, endpoint);
    return resolutions;
  }

  /// Picks one candidate per hop so the total path distance is minimal.
  /// [chainOrder] runs from the receiver-side hop toward the far end, so the
  /// known endpoint (self position) is the anchor of the chain. Segments over
  /// [maxPlausibleHopMeters] are never assigned; when no assignment fits the
  /// cap, every non-forced hop stays unresolved.
  static void _assignShortestTotal(
    List<PathHopResolution> resolutions,
    List<int> chainOrder,
    LatLng? endpoint,
  ) {
    if (resolutions.isEmpty) return;
    final distance = Distance();
    LatLng? positionOf(Contact? contact) {
      if (contact == null ||
          !contact.hasLocation ||
          contact.latitude == null ||
          contact.longitude == null) {
        return null;
      }
      return LatLng(contact.latitude!, contact.longitude!);
    }

    // Per hop, the assignable options in chain order. Forced hops have a
    // single locked option; unknown hops a single null option.
    final hopOptions = <List<_Option>>[];
    for (final index in chainOrder) {
      final resolution = resolutions[index];
      if (resolution.forced != null) {
        hopOptions.add([
          _Option(resolution.forced, positionOf(resolution.forced)),
        ]);
      } else if (resolution.candidates.isEmpty) {
        hopOptions.add([_Option(null, null)]);
      } else {
        final positioned = resolution.candidates
            .map((c) => _Option(c, positionOf(c)))
            .where((o) => o.position != null)
            .toList();
        hopOptions.add(
          positioned.isEmpty
              ? [for (final c in resolution.candidates) _Option(c, null)]
              : positioned,
        );
      }
    }

    final assignment = _runPass(
      hopOptions,
      endpoint,
      distance,
      maxPlausibleHopMeters,
    );
    if (assignment != null) {
      for (var i = 0; i < chainOrder.length; i++) {
        resolutions[chainOrder[i]].selected = assignment[i];
      }
      return;
    }
    for (final resolution in resolutions) {
      if (resolution.forced == null) {
        resolution.selected = null;
      }
    }
  }

  /// Forward DP over the chain. State is the last *positioned* choice seen
  /// (or the anchor); unpositioned options carry the state forward at zero
  /// cost. Returns null when no assignment fits the cap.
  static List<Contact?>? _runPass(
    List<List<_Option>> hopOptions,
    LatLng? endpoint,
    Distance distance,
    double capMeters,
  ) {
    final anchor = _Option(null, endpoint);
    // State -> minimal accumulated cost after processing each hop.
    var frontier = <_Option, double>{anchor: 0};
    final chosen = <Map<_Option, _Option>>[];
    final carry = <Map<_Option, _Option>>[];

    for (final options in hopOptions) {
      final next = <_Option, double>{};
      final pick = <_Option, _Option>{};
      final from = <_Option, _Option>{};
      for (final state in frontier.entries) {
        for (final option in options) {
          var cost = state.value;
          if (state.key.position != null && option.position != null) {
            final segment = distance(state.key.position!, option.position!);
            if (segment > capMeters) continue;
            cost += segment;
          }
          final newState = option.position != null ? option : state.key;
          if (next[newState] == null || cost < next[newState]!) {
            next[newState] = cost;
            pick[newState] = option;
            from[newState] = state.key;
          }
        }
      }
      if (next.isEmpty) return null;
      frontier = next;
      chosen.add(pick);
      carry.add(from);
    }

    var best = frontier.entries.first;
    for (final entry in frontier.entries) {
      if (entry.value < best.value) best = entry;
    }

    final result = List<Contact?>.filled(hopOptions.length, null);
    var state = best.key;
    for (var i = hopOptions.length - 1; i >= 0; i--) {
      final option = chosen[i][state] ?? hopOptions[i].first;
      result[i] = option.contact;
      state = carry[i][state] ?? state;
    }
    return result;
  }
}

class _Option {
  final Contact? contact;
  final LatLng? position;

  _Option(this.contact, this.position);

  @override
  bool operator ==(Object other) {
    if (other is! _Option) return false;
    final a = contact;
    final b = other.contact;
    if (a == null || b == null) {
      return a == null && b == null && position == other.position;
    }
    return a.publicKeyHex == b.publicKeyHex;
  }

  @override
  int get hashCode => contact?.publicKeyHex.hashCode ?? position?.hashCode ?? 0;
}
