import 'package:flutter/material.dart';

import '../connector/meshcore_protocol.dart';
import '../helpers/guessed_location_estimator.dart';
import '../helpers/utf8_length_limiter.dart';
import '../l10n/l10n.dart';
import '../theme/mesh_theme.dart';
import 'byte_count_input.dart';

/// Makes [label] safe for the `m:lat,lon|label|flags` marker format: a `|`
/// would split the label into the flags field and a line break would end the
/// message, so both are replaced.
String sanitizeMarkerLabel(String label) =>
    label.replaceAll('|', '/').replaceAll(RegExp(r'[\r\n]+'), ' ').trim();

/// The shared-marker message text parsed by `parseMarkerText`.
String formatMarkerText(double lat, double lon, String label, String flags) =>
    'm:${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}|'
    '${sanitizeMarkerLabel(label)}|$flags';

/// Bytes left for the label once the marker's fixed parts are counted, using
/// the smaller of the contact and (worst-case sender name) channel limits so
/// the marker fits either destination.
int markerLabelByteBudget(double lat, double lon, String flags) {
  final maxPayload = [
    maxContactMessageBytes(),
    maxChannelMessageBytes(null),
  ].reduce((a, b) => a < b ? a : b);
  final overhead = utf8ByteLength(formatMarkerText(lat, lon, '', flags));
  final budget = maxPayload - overhead;
  return budget > 0 ? budget : 0;
}

/// Whether the radio reports a usable position. Firmware sends 0,0 when no
/// location is set, which must not be shared as a real marker.
bool hasShareableLocation(double? lat, double? lon) =>
    lat != null && lon != null && isPlausibleLocation(lat, lon);

/// Asks for a marker label. Returns the sanitised label (or the sanitised
/// [defaultLabel] when left empty), or null when cancelled.
Future<String?> showMarkerLabelDialog(
  BuildContext context, {
  required double lat,
  required double lon,
  required String defaultLabel,
  required String flags,
  required String confirmText,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => MarkerLabelDialog(
      maxBytes: markerLabelByteBudget(lat, lon, flags),
      defaultLabel: defaultLabel,
      confirmText: confirmText,
    ),
  );
}

/// Label prompt for a shared map marker. Owns its controller and focus node
/// so they outlive the dialog's exit animation instead of being disposed
/// while the field is still mounted.
class MarkerLabelDialog extends StatefulWidget {
  const MarkerLabelDialog({
    super.key,
    required this.maxBytes,
    required this.defaultLabel,
    required this.confirmText,
  });

  final int maxBytes;
  final String defaultLabel;
  final String confirmText;

  @override
  State<MarkerLabelDialog> createState() => _MarkerLabelDialogState();
}

class _MarkerLabelDialogState extends State<MarkerLabelDialog> {
  late final String _fittedDefault = truncateUtf8(
    sanitizeMarkerLabel(widget.defaultLabel),
    widget.maxBytes,
  );
  late final TextEditingController _controller =
      TextEditingController(text: _fittedDefault)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: _fittedDefault.length,
        );
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final label = sanitizeMarkerLabel(_controller.text);
    Navigator.pop(context, label.isEmpty ? _fittedDefault : label);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(MeshRadii.md),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return AlertDialog(
      title: Text(l10n.map_pinLabel),
      content: ByteCountedTextField(
        autofocus: true,
        focusNode: _focusNode,
        maxBytes: widget.maxBytes,
        controller: _controller,
        decoration: InputDecoration(
          hintText: l10n.map_label,
          helperText: l10n.map_labelUpdateHint,
          helperMaxLines: 3,
          helperStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MeshRadii.md),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmText)),
      ],
    );
  }
}
