import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../helpers/snack_bar_builder.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/mesh_theme.dart';
import '../../../utils/radio_guard.dart';
import '../../../widgets/mesh_nav_tile.dart';
import '../../../widgets/mesh_ui.dart';
import '../chess_game.dart';
import '../chess_service.dart';
import 'chess_board.dart';
import 'chess_text.dart';

/// A chess game, for players and spectators alike.
class ChessGameScreen extends StatefulWidget {
  final String channelId;
  final int gameId;

  const ChessGameScreen({
    super.key,
    required this.channelId,
    required this.gameId,
  });

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  ChessService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service ??= context.read<ChessService>();
  }

  @override
  void dispose() {
    _service?.viewing = null;
    super.dispose();
  }

  Future<void> _run(Future<bool> Function() action) async {
    if (!ensureRadioConnected(context)) return;
    final ok = await action();
    if (!ok && mounted) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chess_sendFailed),
      );
    }
  }

  Future<void> _confirmResign(ChessService service, ChessGame game) async {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.chess_resignConfirmTitle),
        content: Text(l10n.chess_resignConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.chess_actionResign),
          ),
        ],
      ),
    );
    if (yes == true && mounted) await _run(() => service.resign(game));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = context.watch<ChessService>();
    final game = service.game(widget.channelId, widget.gameId);
    if (game == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.chess_sheetTitle), centerTitle: true),
        body: Center(child: Text(l10n.chess_gameGone)),
      );
    }
    service.viewing = game;
    final readOnly = context.radioReadOnly;
    final busy = service.isSending(game);
    final canAct = !readOnly && service.canSend && !busy;
    final flipped = game.mySide == ChessSide.black;
    final myTurn = game.isMyTurn && canAct;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.chessPlayers(game),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = constraints.maxWidth.clamp(0.0, 560.0) - 16;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _PlayerStrip(
                  game: game,
                  side: flipped ? ChessSide.white : ChessSide.black,
                ),
                Center(
                  child: SizedBox(
                    width: boardSize,
                    child: game.hasPosition
                        ? ChessBoardView(
                            fen: game.fen,
                            flipped: flipped,
                            lastMoveUci: game.lastMoveUci,
                            inCheck: game.board.in_check,
                            legalMoves: myTurn ? game.legalUci() : const [],
                            onMove: myTurn
                                ? (uci) =>
                                      _run(() => service.makeMove(game, uci))
                                : null,
                          )
                        : AspectRatio(
                            aspectRatio: 1,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  l10n.chess_statusUnknownPosition,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                _PlayerStrip(
                  game: game,
                  side: flipped ? ChessSide.black : ChessSide.white,
                ),
                _StatusCard(game: game, service: service),
                _Actions(
                  game: game,
                  service: service,
                  canAct: canAct,
                  onRun: _run,
                  onResign: () => _confirmResign(service, game),
                ),
                SectionHeader(l10n.chess_movesTitle),
                _MoveList(game: game),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlayerStrip extends StatelessWidget {
  final ChessGame game;
  final ChessSide side;

  const _PlayerStrip({required this.game, required this.side});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final name = game.nameOf(side) ?? l10n.chess_unknownPlayer;
    final toMove =
        game.status == ChessGameStatus.active &&
        game.hasPosition &&
        game.sideToMove == side;
    final isMe = game.mySide == side;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            side == ChessSide.white ? Icons.circle_outlined : Icons.circle,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isMe ? l10n.chess_playerYou(name) : name,
              style: meshTileTitleStyle(theme),
            ),
          ),
          if (toMove)
            StatusChip(
              label: l10n.chess_toMoveChip,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

/// Whose move it is, time left, draw offers, result.
class _StatusCard extends StatelessWidget {
  final ChessGame game;
  final ChessService service;

  const _StatusCard({required this.game, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final lines = <String>[];
    switch (game.status) {
      case ChessGameStatus.invite:
      case ChessGameStatus.starting:
        lines.add(l10n.chess_rowStarting);
      case ChessGameStatus.finished:
        lines.add(l10n.chessResult(game));
      case ChessGameStatus.active:
        if (!game.hasPosition) {
          lines.add(l10n.chess_statusUnknownPosition);
        } else if (game.isMyTurn) {
          lines.add(l10n.chess_statusYourMove);
        } else {
          final name = game.nameOf(game.sideToMove) ?? l10n.chess_unknownPlayer;
          lines.add(
            game.isPlayer
                ? l10n.chess_statusWaiting(name)
                : l10n.chess_statusToMove(name),
          );
        }
        final at = service.deadlineAt(game);
        if (at != null && game.hasPosition) {
          final left = at.difference(DateTime.now());
          lines.add(
            left.isNegative
                ? l10n.chess_statusOverdue
                : l10n.chess_statusTimeLeft(l10n.chessDuration(left)),
          );
        }
        final offeredBy = game.drawOfferedBy;
        if (offeredBy != null) {
          lines.add(
            l10n.chess_statusDrawOffered(
              game.nameOf(offeredBy) ?? l10n.chess_unknownPlayer,
            ),
          );
        }
        if (game.moveUnconfirmed) lines.add(l10n.chess_statusMoveUnconfirmed);
        if (!game.hasPlayers) {
          lines.add(l10n.chess_statusUnverified);
        } else if (!game.playersConfirmed) {
          lines.add(l10n.chess_statusPlayersUnchecked);
        }
    }
    return MeshCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lines.first,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final line in lines.skip(1)) ...[
            const SizedBox(height: 4),
            Text(
              line,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final ChessGame game;
  final ChessService service;
  final bool canAct;
  final Future<void> Function(Future<bool> Function()) onRun;
  final VoidCallback onResign;

  const _Actions({
    required this.game,
    required this.service,
    required this.canAct,
    required this.onRun,
    required this.onResign,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final buttons = <Widget>[];
    final active = game.status == ChessGameStatus.active;
    if (active && game.isPlayer) {
      final offeredBy = game.drawOfferedBy;
      if (offeredBy != null && offeredBy != game.mySide) {
        buttons.add(
          FilledButton(
            onPressed: canAct
                ? () => onRun(() => service.acceptDraw(game))
                : null,
            child: Text(l10n.chess_actionAcceptDraw),
          ),
        );
      } else if (offeredBy == null) {
        buttons.add(
          OutlinedButton(
            onPressed: canAct
                ? () => onRun(() => service.offerDraw(game))
                : null,
            child: Text(l10n.chess_actionOfferDraw),
          ),
        );
      }
      if (service.canClaimTimeout(game)) {
        buttons.add(
          FilledButton(
            onPressed: canAct
                ? () => onRun(() => service.claimTimeout(game))
                : null,
            child: Text(l10n.chess_actionClaimTimeout),
          ),
        );
      }
      buttons.add(
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: canAct ? onResign : null,
          child: Text(l10n.chess_actionResign),
        ),
      );
    }
    if (game.isOpen && (!game.isMyTurn || !game.hasPlayers)) {
      buttons.add(
        Tooltip(
          message: l10n.chess_actionNudgeTooltip,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: canAct
                ? () => onRun(() => service.requestUpdate(game))
                : null,
            label: Text(l10n.chess_actionNudge),
          ),
        ),
      );
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
    );
  }
}

/// Moves as numbered pairs; runs of moves we never heard collapse into one
/// "missed" entry.
class _MoveList extends StatelessWidget {
  final ChessGame game;

  const _MoveList({required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (game.sanMoves.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          l10n.chess_noMovesYet,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final entries = <String>[];
    var i = 0;
    final moves = game.sanMoves;
    while (i < moves.length) {
      if (moves[i] == null) {
        while (i < moves.length && moves[i] == null) {
          i++;
        }
        entries.add(l10n.chess_movesMissed);
        continue;
      }
      final number = i ~/ 2 + 1;
      if (i.isEven) {
        final black = i + 1 < moves.length ? moves[i + 1] : null;
        entries.add(
          black == null
              ? '$number. ${moves[i]}'
              : '$number. ${moves[i]} $black',
        );
        i += black == null ? 1 : 2;
      } else {
        entries.add('$number… ${moves[i]}');
        i++;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          for (final e in entries) Text(e, style: MeshTheme.mono(fontSize: 14)),
        ],
      ),
    );
  }
}
