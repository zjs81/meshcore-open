import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../connector/meshcore_connector.dart';
import '../../../helpers/snack_bar_builder.dart';
import '../../../l10n/l10n.dart';
import '../../../models/channel.dart';
import '../../../utils/radio_guard.dart';
import '../../../widgets/mesh_nav_tile.dart';
import '../../../widgets/mesh_ui.dart';
import '../chess_packets.dart';
import '../chess_service.dart';
import 'chess_text.dart';

/// Names recently heard on [channel], newest first, without our own.
List<String> recentChannelSenders(
  MeshCoreConnector connector,
  Channel channel, {
  int limit = 30,
}) {
  final self = (connector.selfName ?? '').trim().toLowerCase();
  final seen = <String>{};
  final out = <String>[];
  final messages = connector.getChannelMessages(channel);
  for (final m in messages.reversed) {
    if (m.isOutgoing) continue;
    final name = m.senderName.trim();
    final key = name.toLowerCase();
    if (name.isEmpty || key == self || !seen.add(key)) continue;
    out.add(name);
    if (out.length >= limit) break;
  }
  return out;
}

/// Picks the opponent (for a [direct] challenge), time per move and colour,
/// then sends the invite.
Future<void> showChessNewGameSheet(
  BuildContext context, {
  required Channel channel,
  required bool direct,
}) async {
  final channelId = channel.storageId;
  if (channelId == null) return;
  final senders = direct
      ? recentChannelSenders(context.read<MeshCoreConnector>(), channel)
      : const <String>[];
  final service = context.read<ChessService>();
  final l10n = context.l10n;

  final result = await showMeshSheet<_NewGameChoice>(
    context,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => _NewGameBody(
        direct: direct,
        senders: senders,
        controller: controller,
      ),
    ),
  );
  if (result == null || !context.mounted) return;
  if (!ensureRadioConnected(context)) return;
  final game = await service.createInvite(
    channelId: channelId,
    deadline: result.deadline,
    colour: result.colour,
    targetName: result.target,
  );
  if (!context.mounted) return;
  showDismissibleSnackBar(
    context,
    content: Text(
      game == null
          ? l10n.chess_sendFailed
          : direct
          ? l10n.chess_challengeSent(result.target ?? '')
          : l10n.chess_inviteSent,
    ),
  );
}

class _NewGameChoice {
  final String? target;
  final ChessDeadline deadline;
  final ChessColourPreference colour;

  const _NewGameChoice(this.target, this.deadline, this.colour);
}

class _NewGameBody extends StatefulWidget {
  final bool direct;
  final List<String> senders;
  final ScrollController controller;

  const _NewGameBody({
    required this.direct,
    required this.senders,
    required this.controller,
  });

  @override
  State<_NewGameBody> createState() => _NewGameBodyState();
}

class _NewGameBodyState extends State<_NewGameBody> {
  String? _target;
  ChessDeadline _deadline = ChessDeadline.defaultValue;
  ChessColourPreference _colour = ChessColourPreference.random;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ready = !widget.direct || _target != null;
    return Column(
      children: [
        BottomSheetHeader(
          title: widget.direct
              ? l10n.chess_newChallenge
              : l10n.chess_newOpenInvite,
        ),
        Expanded(
          child: ListView(
            controller: widget.controller,
            children: [
              if (widget.direct) ...[
                SectionHeader(l10n.chess_pickOpponent),
                if (widget.senders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.chess_noRecentSenders),
                  ),
                for (final name in widget.senders)
                  MeshSheetOption(
                    label: name,
                    selected: _target == name,
                    onTap: () => setState(() => _target = name),
                  ),
              ],
              SectionHeader(l10n.chess_deadlineLabel),
              for (final d in ChessDeadline.values)
                MeshSheetOption(
                  label: l10n.chessDeadlineLabel(d),
                  selected: _deadline == d,
                  onTap: () => setState(() => _deadline = d),
                ),
              SectionHeader(l10n.chess_colourLabel),
              for (final c in ChessColourPreference.values)
                MeshSheetOption(
                  label: l10n.chessColourLabel(c),
                  selected: _colour == c,
                  onTap: () => setState(() => _colour = c),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: ready
                  ? () => Navigator.pop(
                      context,
                      _NewGameChoice(_target, _deadline, _colour),
                    )
                  : null,
              child: Text(
                widget.direct
                    ? l10n.chess_sendChallenge
                    : l10n.chess_postInvite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
