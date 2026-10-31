import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';

/// Asks the user to confirm, then sets the radio's advertised location to
/// [position] and waits for SELF_INFO to report it. Shows a success or
/// failure snackbar and returns whether the radio confirmed the new location.
Future<bool> confirmAndSetMyLocation(
  BuildContext context,
  MeshCoreConnector connector,
  LatLng position,
) async {
  if (!connector.isConnected) return false;
  final l10n = context.l10n;
  final latText = position.latitude.toStringAsFixed(6);
  final lonText = position.longitude.toStringAsFixed(6);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.map_setLocationConfirmTitle),
      content: Text(l10n.map_setLocationConfirmBody(latText, lonText)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.map_setLocationAction),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted || !connector.isConnected) {
    return false;
  }

  // The firmware stores coordinates as int32 micro-degrees.
  bool matches() {
    final lat = connector.selfLatitude;
    final lon = connector.selfLongitude;
    return lat != null &&
        lon != null &&
        (lat - position.latitude).abs() < 2e-6 &&
        (lon - position.longitude).abs() < 2e-6;
  }

  var ok = false;
  try {
    await connector.setNodeLocation(
      lat: position.latitude,
      lon: position.longitude,
    );
    await connector.refreshDeviceInfo();
    // Self info arrives asynchronously after the query; wait for it.
    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while (context.mounted && connector.isConnected) {
      if (matches()) {
        ok = true;
        break;
      }
      if (DateTime.now().isAfter(deadline)) break;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  } catch (e) {
    debugPrint('Set node location failed: $e');
  }
  if (!context.mounted) return ok;
  showDismissibleSnackBar(
    context,
    content: Text(
      ok ? l10n.map_locationSetSuccess : l10n.map_locationSetFailed,
    ),
  );
  return ok;
}
