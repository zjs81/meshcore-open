import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/path_helper.dart';
import '../helpers/path_trace_input.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/map_path_trace_draft.dart';
import '../services/ui_view_state_service.dart';
import '../theme/mesh_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/mesh_ui.dart';
import 'path_trace_map.dart';

class ManualPathTraceScreen extends StatefulWidget {
  /// Optional prefill; when null the last entry of this session is restored.
  final String? initialText;
  final bool? initialReturnPath;

  const ManualPathTraceScreen({
    super.key,
    this.initialText,
    this.initialReturnPath,
  });

  static void open(
    BuildContext context, {
    String? initialText,
    bool? initialReturnPath,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualPathTraceScreen(
          initialText: initialText,
          initialReturnPath: initialReturnPath,
        ),
      ),
    );
  }

  @override
  State<ManualPathTraceScreen> createState() => _ManualPathTraceScreenState();
}

class _ManualPathTraceScreenState extends State<ManualPathTraceScreen> {
  late final MapPathTraceDraft _draft;
  late final TextEditingController _controller;
  late bool _returnPath;

  @override
  void initState() {
    super.initState();
    // Read here, not lazily: dispose() writes back to it and can't look up
    // providers from a deactivated context.
    _draft = context.read<UiViewStateService>().mapPathTrace;
    _controller = TextEditingController(
      text: widget.initialText ?? _draft.manualText,
    );
    _returnPath = widget.initialReturnPath ?? _draft.manualReturnPath;
  }

  @override
  void dispose() {
    _draft.manualText = _controller.text;
    _draft.manualReturnPath = _returnPath;
    _controller.dispose();
    super.dispose();
  }

  String _example(int width) => width == 1
      ? 'A1,B2,C3'
      : width == 2
      ? 'A1B2,C3D4'
      : 'A1B2C3,D4E5F6';

  List<Contact> _matches(MeshCoreConnector connector, Uint8List hop) {
    return connector.allContactsUnfiltered.where((c) {
      if (c.type != advTypeRepeater && c.type != advTypeRoom) return false;
      if (c.publicKey.length < hop.length) return false;
      for (var i = 0; i < hop.length; i++) {
        if (c.publicKey[i] != hop[i]) return false;
      }
      return true;
    }).toList();
  }

  String? _errorText(PathTraceInputError error) {
    final l10n = context.l10n;
    switch (error) {
      case PathTraceInputError.empty:
        return null;
      case PathTraceInputError.invalidHex:
        return l10n.manualTrace_errorInvalidHex;
      case PathTraceInputError.oddLength:
        return l10n.manualTrace_errorOddLength;
      case PathTraceInputError.mixedWidths:
        return l10n.manualTrace_errorMixedWidths;
      case PathTraceInputError.unsupportedWidth:
        return l10n.manualTrace_errorUnsupportedWidth;
      case PathTraceInputError.tooManyHops:
        return l10n.manualTrace_errorTooManyHops(maxPathSize);
    }
  }

  void _run(MeshCoreConnector connector, PathTraceInput input) {
    final contacts = <Contact>[];
    for (final hop in input.hops) {
      final m = _matches(connector, hop);
      if (m.length == 1) contacts.add(m.first);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PathTraceMapScreen(
          title: context.l10n.contacts_pathTrace,
          path: input.bytes,
          pathHashByteWidth: input.hopWidth,
          flipPathAround: _returnPath,
          pathContacts: contacts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final scheme = Theme.of(context).colorScheme;
    final result = PathTraceInputParser.parse(
      _controller.text,
      connector.pathHashByteWidth,
    );
    final input = result.input;
    final fits =
        input == null || traceFitsInRequest(input, roundTrip: _returnPath);
    final errorText = result.error != null
        ? _errorText(result.error!)
        : (fits ? null : l10n.manualTrace_errorTraceTooLong);
    final exampleWidth = input?.hopWidth ?? connector.pathHashByteWidth;
    final canRun = input != null && fits && connector.isConnected;
    const buttonSize = Size(48, 48);

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(l10n.contacts_pathTrace),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _controller,
              autofocus: _controller.text.isEmpty,
              minLines: 2,
              maxLines: 4,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.visiblePassword,
              style: MeshTheme.mono(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: l10n.manualTrace_inputLabel,
                helperText: l10n.manualTrace_helper(_example(exampleWidth)),
                helperMaxLines: 2,
                helperStyle: const TextStyle(fontSize: 14),
                errorText: errorText,
                errorMaxLines: 3,
                errorStyle: const TextStyle(fontSize: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (input != null) ...[
              Text(
                l10n.manualTrace_previewTitle(input.hops.length),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              for (final hop in input.hops)
                _hopRow(context, hop, _matches(connector, hop)),
              const SizedBox(height: 16),
            ],
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.sync_alt),
                  label: MeshSegmentLabel(l10n.map_pathTraceModeRoundTrip),
                ),
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.arrow_forward),
                  label: MeshSegmentLabel(l10n.map_pathTraceModeAsEntered),
                ),
              ],
              selected: {_returnPath},
              onSelectionChanged: (s) => setState(() => _returnPath = s.first),
              style: SegmentedButton.styleFrom(minimumSize: buttonSize),
            ),
            const SizedBox(height: 8),
            Text(
              _returnPath
                  ? l10n.map_pathTraceModeRoundTripHint
                  : l10n.map_pathTraceModeAsEnteredHint,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canRun ? () => _run(connector, input) : null,
              style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
              icon: const Icon(Icons.radar),
              label: Text(
                l10n.manualTrace_run,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (!connector.isConnected) ...[
              const SizedBox(height: 8),
              Text(
                l10n.manualTrace_notConnected,
                style: TextStyle(fontSize: 14, color: scheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hopRow(BuildContext context, Uint8List hop, List<Contact> matches) {
    final scheme = Theme.of(context).colorScheme;
    final known = matches.isNotEmpty;
    return MeshCard(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(
            PathHelper.formatHopHex(hop),
            style: MeshTheme.mono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              known
                  ? matches.map((c) => c.name).join(' | ')
                  : context.l10n.manualTrace_unknownNode,
              style: TextStyle(
                fontSize: 15,
                color: known ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
