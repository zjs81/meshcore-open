import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../connector/meshcore_protocol.dart';
import 'path_helper.dart';
import '../models/contact.dart';

class PathHopResolver {
  const PathHopResolver._();

  /// Maximum plausible single-hop LoRa RF link distance in meters (250 km).
  /// Accommodates long-range line-of-sight mountain-top hops while rejecting
  /// multi-hundred/multi-thousand-km prefix collisions.
  static const double maxSingleHopDistanceMeters = 250000.0;

  static List<Contact?> resolve({
    required List<int> pathBytes,
    required List<Contact> contacts,
    LatLng? endpoint,
    bool resolveFromEnd = false,
    int pathHashByteWidth = 1,
    double maxHopDistanceMeters = maxSingleHopDistanceMeters,
    List<Contact>? preferredContacts,
  }) {
    final width = pathHashByteWidth.clamp(1, 3).toInt();
    final hops = PathHelper.splitPathBytes(pathBytes, width);
    return resolveHops(
      hops: hops,
      contacts: contacts,
      endpoint: endpoint,
      resolveFromEnd: resolveFromEnd,
      maxHopDistanceMeters: maxHopDistanceMeters,
      preferredContacts: preferredContacts,
    );
  }

  static List<Contact?> resolveHops({
    required List<Uint8List> hops,
    required List<Contact> contacts,
    LatLng? endpoint,
    bool resolveFromEnd = false,
    double maxHopDistanceMeters = maxSingleHopDistanceMeters,
    bool Function(Contact)? contactFilter,
    List<Contact>? preferredContacts,
  }) {
    if (hops.isEmpty) return const [];

    final widths = <int>{
      for (final hop in hops)
        if (hop.isNotEmpty) hop.length,
    };
    bool includeContact(Contact contact) =>
        contactFilter?.call(contact) ??
        (contact.type == advTypeRepeater || contact.type == advTypeRoom);

    void indexContact(Map<String, List<Contact>> buckets, Contact contact) {
      for (final width in widths) {
        if (contact.publicKey.length < width) continue;
        final prefix = PathHelper.formatHopHex(
          contact.publicKey.sublist(0, width),
        );
        buckets.putIfAbsent(prefix, () => <Contact>[]).add(contact);
      }
    }

    final preferredKeys = <String>{};
    final preferredByPrefix = <String, List<Contact>>{};
    if (preferredContacts != null) {
      for (final contact in preferredContacts) {
        if (!includeContact(contact)) continue;
        preferredKeys.add(contact.publicKeyHex);
        indexContact(preferredByPrefix, contact);
      }
    }

    final fallbackByPrefix = <String, List<Contact>>{};
    for (final contact in contacts) {
      if (!includeContact(contact)) continue;
      if (preferredKeys.contains(contact.publicKeyHex)) continue;
      indexContact(fallbackByPrefix, contact);
    }

    for (final candidates in preferredByPrefix.values) {
      candidates.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    }
    for (final candidates in fallbackByPrefix.values) {
      candidates.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
    }

    final hopCount = hops.length;
    final resolved = List<Contact?>.filled(hopCount, null);
    final indexes = resolveFromEnd
        ? List<int>.generate(hopCount, (i) => hopCount - 1 - i)
        : List<int>.generate(hopCount, (i) => i);
    final stepPrefixes = <String>[
      for (final index in indexes) PathHelper.formatHopHex(hops[index]),
    ];
    final distance = Distance();

    (Contact, double)? pickNearestLocatedFrom(
      Map<String, List<Contact>> buckets,
      String prefix,
      Set<Contact> used,
      LatLng anchor,
      double maxDistanceMeters,
    ) {
      final candidates = buckets[prefix];
      if (candidates == null || candidates.isEmpty) return null;
      Contact? best;
      double? bestDistance;
      for (final candidate in candidates) {
        if (used.contains(candidate)) continue;
        final position = _positionOf(candidate);
        if (position == null) continue;
        final d = distance(anchor, position);
        if (d <= maxDistanceMeters &&
            (bestDistance == null || d < bestDistance)) {
          bestDistance = d;
          best = candidate;
        }
      }
      if (best == null || bestDistance == null) return null;
      return (best, bestDistance);
    }

    Contact? pickFirstUnlocatedFrom(
      Map<String, List<Contact>> buckets,
      String prefix,
      Set<Contact> used,
    ) {
      final candidates = buckets[prefix];
      if (candidates == null || candidates.isEmpty) return null;
      for (final candidate in candidates) {
        if (used.contains(candidate)) continue;
        if (_positionOf(candidate) == null) return candidate;
      }
      return null;
    }

    Contact? pickFirstAnyFrom(
      Map<String, List<Contact>> buckets,
      String prefix,
      Set<Contact> used,
    ) {
      final candidates = buckets[prefix];
      if (candidates == null || candidates.isEmpty) return null;
      for (final candidate in candidates) {
        if (!used.contains(candidate)) return candidate;
      }
      return null;
    }

    (Contact, double, bool)? pickBestLocated(
      String prefix,
      Set<Contact> used,
      LatLng anchor,
      double maxDistanceMeters,
    ) {
      final preferred = pickNearestLocatedFrom(
        preferredByPrefix,
        prefix,
        used,
        anchor,
        maxDistanceMeters,
      );
      if (preferred != null) return (preferred.$1, preferred.$2, true);
      if (pickFirstUnlocatedFrom(preferredByPrefix, prefix, used) != null) {
        return null;
      }
      final fallback = pickNearestLocatedFrom(
        fallbackByPrefix,
        prefix,
        used,
        anchor,
        maxDistanceMeters,
      );
      if (fallback != null) return (fallback.$1, fallback.$2, false);
      return null;
    }

    Contact? pickBestUnlocated(String prefix, Set<Contact> used) {
      return pickFirstUnlocatedFrom(preferredByPrefix, prefix, used) ??
          pickFirstUnlocatedFrom(fallbackByPrefix, prefix, used);
    }

    Contact? pickBestAny(String prefix, Set<Contact> used) {
      return pickFirstAnyFrom(preferredByPrefix, prefix, used) ??
          pickFirstAnyFrom(fallbackByPrefix, prefix, used);
    }

    final used = Set<Contact>.identity();

    if (endpoint != null) {
      var previousPosition = endpoint;
      var lastAnchorStep = -1;
      for (var step = 0; step < hopCount; step++) {
        final prefix = stepPrefixes[step];
        final hopGap = step - lastAnchorStep;
        final maxAllowed = hopGap * maxHopDistanceMeters;
        final preferred = pickNearestLocatedFrom(
          preferredByPrefix,
          prefix,
          used,
          previousPosition,
          maxAllowed,
        );
        if (preferred != null) {
          used.add(preferred.$1);
          resolved[indexes[step]] = preferred.$1;
          previousPosition = _positionOf(preferred.$1)!;
          lastAnchorStep = step;
          continue;
        }
        final preferredUnlocated = pickFirstUnlocatedFrom(
          preferredByPrefix,
          prefix,
          used,
        );
        if (preferredUnlocated != null) {
          used.add(preferredUnlocated);
          resolved[indexes[step]] = preferredUnlocated;
          continue;
        }
        final fallback = pickNearestLocatedFrom(
          fallbackByPrefix,
          prefix,
          used,
          previousPosition,
          maxAllowed,
        );
        if (fallback != null) {
          used.add(fallback.$1);
          resolved[indexes[step]] = fallback.$1;
          previousPosition = _positionOf(fallback.$1)!;
          lastAnchorStep = step;
        } else {
          final unlocated = pickFirstUnlocatedFrom(
            fallbackByPrefix,
            prefix,
            used,
          );
          if (unlocated != null) {
            used.add(unlocated);
            resolved[indexes[step]] = unlocated;
          }
        }
      }
      return resolved;
    }

    // Without a known endpoint, find the located anchor whose plausible chain
    // explains the most located hops so a single distant prefix collision does
    // not poison the rest of the path.
    bool bucketHasLocated(Map<String, List<Contact>> buckets) {
      for (final prefix in stepPrefixes) {
        final candidates = buckets[prefix];
        if (candidates != null &&
            candidates.any((c) => _positionOf(c) != null)) {
          return true;
        }
      }
      return false;
    }

    final hasAnyLocated =
        bucketHasLocated(preferredByPrefix) ||
        bucketHasLocated(fallbackByPrefix);

    if (!hasAnyLocated) {
      for (var step = 0; step < hopCount; step++) {
        final contact = pickBestAny(stepPrefixes[step], used);
        if (contact != null) {
          used.add(contact);
          resolved[indexes[step]] = contact;
        }
      }
      return resolved;
    }

    List<Contact?>? bestRun;
    var bestLocatedCount = 0;
    var bestPreferredCount = 0;
    var bestTotalDistance = double.infinity;
    var bestLastSeenSum = -1;

    for (var anchorStep = 0; anchorStep < hopCount; anchorStep++) {
      final prefix = stepPrefixes[anchorStep];
      final anchorCandidates = <(Contact, bool)>[
        for (final c in preferredByPrefix[prefix] ?? const <Contact>[])
          (c, true),
        for (final c in fallbackByPrefix[prefix] ?? const <Contact>[])
          (c, false),
      ];
      for (final (anchorCandidate, isPreferredAnchor) in anchorCandidates) {
        final anchorPos = _positionOf(anchorCandidate);
        if (anchorPos == null) continue;

        final run = List<Contact?>.filled(hopCount, null);
        final runUsed = Set<Contact>.identity()..add(anchorCandidate);
        run[anchorStep] = anchorCandidate;
        var locatedCount = 1;
        var preferredCount = isPreferredAnchor ? 1 : 0;
        var totalDistance = 0.0;
        var lastSeenSum = anchorCandidate.lastSeen.millisecondsSinceEpoch;

        var prevPos = anchorPos;
        var lastAnchor = anchorStep;
        for (var step = anchorStep + 1; step < hopCount; step++) {
          final maxAllowed = (step - lastAnchor) * maxHopDistanceMeters;
          final match = pickBestLocated(
            stepPrefixes[step],
            runUsed,
            prevPos,
            maxAllowed,
          );
          if (match == null) continue;
          run[step] = match.$1;
          runUsed.add(match.$1);
          prevPos = _positionOf(match.$1)!;
          lastAnchor = step;
          locatedCount++;
          if (match.$3) preferredCount++;
          totalDistance += match.$2;
          lastSeenSum += match.$1.lastSeen.millisecondsSinceEpoch;
        }

        prevPos = anchorPos;
        lastAnchor = anchorStep;
        for (var step = anchorStep - 1; step >= 0; step--) {
          final maxAllowed = (lastAnchor - step) * maxHopDistanceMeters;
          final match = pickBestLocated(
            stepPrefixes[step],
            runUsed,
            prevPos,
            maxAllowed,
          );
          if (match == null) continue;
          run[step] = match.$1;
          runUsed.add(match.$1);
          prevPos = _positionOf(match.$1)!;
          lastAnchor = step;
          locatedCount++;
          if (match.$3) preferredCount++;
          totalDistance += match.$2;
          lastSeenSum += match.$1.lastSeen.millisecondsSinceEpoch;
        }

        final isBetter =
            locatedCount > bestLocatedCount ||
            (locatedCount == bestLocatedCount &&
                preferredCount > bestPreferredCount) ||
            (locatedCount == bestLocatedCount &&
                preferredCount == bestPreferredCount &&
                totalDistance < bestTotalDistance - 1e-6) ||
            (locatedCount == bestLocatedCount &&
                preferredCount == bestPreferredCount &&
                (totalDistance - bestTotalDistance).abs() <= 1e-6 &&
                lastSeenSum > bestLastSeenSum);
        if (isBetter) {
          bestRun = run;
          bestLocatedCount = locatedCount;
          bestPreferredCount = preferredCount;
          bestTotalDistance = totalDistance;
          bestLastSeenSum = lastSeenSum;
        }
      }
    }

    if (bestRun != null) {
      for (var step = 0; step < hopCount; step++) {
        final contact = bestRun[step];
        if (contact != null) {
          used.add(contact);
          resolved[indexes[step]] = contact;
        }
      }
      for (var step = 0; step < hopCount; step++) {
        if (bestRun[step] != null) continue;
        final unlocated = pickBestUnlocated(stepPrefixes[step], used);
        if (unlocated != null) {
          used.add(unlocated);
          resolved[indexes[step]] = unlocated;
        }
      }
    }

    return resolved;
  }

  static LatLng? _positionOf(Contact contact) {
    if (!contact.hasLocation ||
        contact.latitude == null ||
        contact.longitude == null) {
      return null;
    }
    return LatLng(contact.latitude!, contact.longitude!);
  }
}
