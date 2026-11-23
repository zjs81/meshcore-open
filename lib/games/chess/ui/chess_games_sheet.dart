import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../helpers/snack_bar_builder.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../models/channel.dart';
import '../../../utils/radio_guard.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/mesh_nav_tile.dart';
import '../../../widgets/mesh_ui.dart';
import '../chess_game.dart';
import '../chess_service.dart';
import 'chess_game_screen.dart';
import 'chess_new_game_sheet.dart';
import 'chess_text.dart';

/// Label of the channel menu entry: "Chess games", with the number of open
/// games and invites when there are any.
String chessMenuLabel(BuildContext context, Channel channel) {
  final id = channel.storageId;
  var count = 0;
  try {
    if (id != null) {
      count = context.read<ChessService>().openCountForChannel(id);
    }
  } on ProviderNotFoundException {
    // Hosts without chess (some tests) just show the plain label.
  }
  return count == 0
      ? context.l10n.chess_menuGames
      : context.l10n.chess_menuGamesCount(count);
}

/// Games on [channel]: yours, open invites, games to watch, and buttons to
/// start a new one.
Future<void> showChessGamesSheet(BuildContext context, Channel channel) async {
  final channelId = channel.storageId;
  if (channelId == null) return;
  final action = await showMeshSheet<_NewGameAction>(
    context,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => _ChessGamesSheetBody(
        channel: channel,
        channelId: channelId,
        controller: controller,
        hostContext: context,
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  // Close-then-open: the new-game sheet replaces this one.
  await showChessNewGameSheet(
    context,
    channel: channel,
    direct: action == _NewGameAction.challenge,
  );
}

enum _NewGameAction { challenge, openInvite }

class _ChessGamesSheetBody extends StatelessWidget {
  final Channel channel;
  final String channelId;
  final ScrollController controller;
  final BuildContext hostContext;

  const _ChessGamesSheetBody({
    required this.channel,
    required this.channelId,
    required this.controller,
    required this.hostContext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = context.watch<ChessService>();
    final readOnly = context.radioReadOnly;
    final games = service.gamesForChannel(channelId);
    final mine = games
        .where(
          (g) =>
              g.isOpen &&
              (g.isPlayer ||
                  g.iAmInviter ||
                  g.status == ChessGameStatus.starting),
        )
        .toList();
    final invites = games
        .where(
          (g) =>
              g.status == ChessGameStatus.invite &&
              !g.iAmInviter &&
              service.isListed(g),
        )
        .toList();
    final live = games
        .where(
          (g) =>
              g.isOpen &&
              !mine.contains(g) &&
              !invites.contains(g) &&
              g.status == ChessGameStatus.active,
        )
        .toList();
    final finished = games.where((g) => !g.isOpen).take(10).toList();
    final canStart = !readOnly && service.canSend;

    return Column(
      children: [
        BottomSheetHeader(title: l10n.chess_sheetTitle, subtitle: channel.name),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (!readOnly && !service.canSend)
                MeshCard(child: Text(l10n.settings_requiresFirmware('v1.15'))),
              SectionHeader(l10n.chess_sectionNewGame),
              _ActionCard(
                icon: Icons.person_add_alt_1_outlined,
                title: l10n.chess_newChallenge,
                subtitle: l10n.chess_newChallengeSubtitle,
                onTap: canStart
                    ? () => Navigator.pop(context, _NewGameAction.challenge)
                    : null,
              ),
              _ActionCard(
                icon: Icons.campaign_outlined,
                title: l10n.chess_newOpenInvite,
                subtitle: l10n.chess_newOpenInviteSubtitle,
                onTap: canStart
                    ? () => Navigator.pop(context, _NewGameAction.openInvite)
                    : null,
              ),
              if (games.isEmpty)
                EmptyState(
                  icon: Icons.sports_esports_outlined,
                  title: l10n.chess_emptyTitle,
                  subtitle: l10n.chess_emptySubtitle,
                ),
              if (mine.isNotEmpty) ...[
                SectionHeader(l10n.chess_sectionYourGames),
                for (final g in mine) _GameCard(game: g, host: hostContext),
              ],
              if (invites.isNotEmpty) ...[
                SectionHeader(l10n.chess_sectionInvites),
                for (final g in invites)
                  _InviteCard(game: g, readOnly: readOnly, host: hostContext),
              ],
              if (live.isNotEmpty) ...[
                SectionHeader(l10n.chess_sectionLive),
                for (final g in live) _GameCard(game: g, host: hostContext),
              ],
              if (finished.isNotEmpty) ...[
                SectionHeader(l10n.chess_sectionFinished),
                for (final g in finished) _GameCard(game: g, host: hostContext),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: MeshCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: meshTileTitleStyle(theme)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One game: players, and whose move it is or how it ended.
class _GameCard extends StatelessWidget {
  final ChessGame game;
  final BuildContext host;

  const _GameCard({required this.game, required this.host});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final service = context.read<ChessService>();
    final String title;
    final String subtitle;
    switch (game.status) {
      case ChessGameStatus.invite:
        title = game.targetName == null
            ? l10n.chess_rowYourOpenInvite
            : l10n.chess_rowYourChallenge(game.targetName!);
        subtitle = l10n.chessDeadlineLabel(game.deadline);
      case ChessGameStatus.starting:
        title = l10n.chess_rowInviteFrom(game.inviter?.name ?? '');
        subtitle = l10n.chess_rowStarting;
      case ChessGameStatus.active:
        title = l10n.chessPlayers(game);
        final toMove = game.nameOf(game.sideToMove) ?? l10n.chess_unknownPlayer;
        final turn = game.isMyTurn
            ? l10n.chess_statusYourMove
            : l10n.chess_statusToMove(toMove);
        subtitle = l10n.chess_rowMoveTurn((game.ply ~/ 2) + 1, turn);
      case ChessGameStatus.finished:
        title = game.hasPlayers || game.inviter == null
            ? l10n.chessPlayers(game)
            : _inviteTitle(l10n, service);
        subtitle = l10n.chessResult(game);
    }
    return MeshCard(
      onTap: game.status == ChessGameStatus.invite && game.iAmInviter
          ? () => _confirmCancel(context, service)
          : () {
              Navigator.pop(context);
              Navigator.push(
                host,
                MaterialPageRoute(
                  builder: (_) => ChessGameScreen(
                    channelId: game.channelId,
                    gameId: game.gameId,
                  ),
                ),
              );
            },
      child: Row(
        children: [
          _PieceIcon(highlight: game.isMyTurn),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: meshTileTitleStyle(theme)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: game.isMyTurn
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: game.isMyTurn ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
          if (!game.isOpen)
            IconButton(
              tooltip: l10n.chess_remove,
              icon: const Icon(Icons.close),
              onPressed: () => service.remove(game),
            ),
        ],
      ),
    );
  }

  /// An invite that never became a game: who invited whom.
  String _inviteTitle(AppLocalizations l10n, ChessService service) {
    final target = game.targetName;
    if (game.iAmInviter) {
      return target == null
          ? l10n.chess_rowYourOpenInvite
          : l10n.chess_rowYourChallenge(target);
    }
    final inviter = game.inviter?.name ?? l10n.chess_unknownPlayer;
    if (target == null) return l10n.chess_rowOpenInvite(inviter);
    return service.isSelf(target)
        ? l10n.chess_rowChallengedYou(inviter)
        : l10n.chess_rowChallenge(inviter, target);
  }

  Future<void> _confirmCancel(
    BuildContext context,
    ChessService service,
  ) async {
    final l10n = context.l10n;
    final cancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.chess_cancelInviteTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.chess_cancelInvite),
          ),
        ],
      ),
    );
    if (cancel != true || !context.mounted) return;
    if (!ensureRadioConnected(context)) return;
    final ok = await service.cancelInvite(game);
    if (!ok && context.mounted) {
      showDismissibleSnackBar(context, content: Text(l10n.chess_sendFailed));
    }
  }
}

/// Someone else's invite with Accept (and Decline for a challenge to us).
class _InviteCard extends StatelessWidget {
  final ChessGame game;
  final bool readOnly;
  final BuildContext host;

  const _InviteCard({
    required this.game,
    required this.readOnly,
    required this.host,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final service = context.watch<ChessService>();
    final inviter = game.inviter?.name ?? l10n.chess_unknownPlayer;
    final busy = service.isSending(game);
    final canAct = !readOnly && service.canSend && !busy;
    return MeshCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _PieceIcon(highlight: false),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.targetName == null
                          ? l10n.chess_rowOpenInvite(inviter)
                          : l10n.chess_rowChallengedYou(inviter),
                      style: meshTileTitleStyle(theme),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.chess_rowInviteDetails(
                        l10n.chessDeadlineLabel(game.deadline),
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (game.targetName != null)
                OutlinedButton(
                  onPressed: canAct
                      ? () => _run(context, service.decline)
                      : null,
                  child: Text(l10n.chess_decline),
                ),
              FilledButton(
                onPressed: canAct ? () => _run(context, service.accept) : null,
                child: Text(l10n.chess_accept),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<bool> Function(ChessGame) action,
  ) async {
    if (!ensureRadioConnected(context)) return;
    final ok = await action(game);
    if (!ok && context.mounted) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chess_sendFailed),
      );
    }
  }
}

class _PieceIcon extends StatelessWidget {
  final bool highlight;

  const _PieceIcon({required this.highlight});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: highlight
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: WhiteKnight(size: 30),
    );
  }
}
