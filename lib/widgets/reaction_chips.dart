import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/message.dart';
import '../theme/mesh_theme.dart';

/// The emoji reaction pills under a chat bubble, shared by the direct and
/// channel chat screens.
///
/// [statuses] carries per-emoji send state for reactions this device sent
/// (direct chats only): pending chips are dimmed with a spinner and failed
/// chips become a retry button with a full-size tap target.
class ReactionChips extends StatelessWidget {
  final Map<String, List<String?>> reactions;
  final Map<String, MessageStatus> statuses;

  /// Called when a chip that is not in the failed state is tapped.
  final ValueChanged<String>? onTap;

  /// Called when a failed chip is tapped.
  final ValueChanged<String>? onRetry;

  const ReactionChips({
    super.key,
    required this.reactions,
    this.statuses = const {},
    this.onTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final entry in reactions.entries)
          _ReactionChip(
            emoji: entry.key,
            count: entry.value.length,
            status: statuses[entry.key],
            onTap: onTap,
            onRetry: onRetry,
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final MessageStatus? status;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onRetry;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.status,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPending =
        status == MessageStatus.pending || status == MessageStatus.sent;
    final isFailed = status == MessageStatus.failed;
    final VoidCallback? handler = isFailed
        ? (onRetry == null ? null : () => onRetry!(emoji))
        : (onTap == null ? null : () => onTap!(emoji));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MeshRadii.pill),
      side: BorderSide(
        color: isFailed ? scheme.error : scheme.outlineVariant,
        width: 1,
      ),
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: MeshTheme.emoji(fontSize: 16),
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
        ),
        if (count > 1) ...[
          const SizedBox(width: 4),
          Text(
            '$count',
            style: MeshTheme.mono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
        if (isPending) ...[
          const SizedBox(width: 4),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: scheme.primary,
            ),
          ),
        ],
        if (isFailed) ...[
          const SizedBox(width: 6),
          Icon(Icons.replay, size: 18, color: scheme.error),
        ],
      ],
    );

    content = Padding(
      padding: EdgeInsets.symmetric(horizontal: isFailed ? 12 : 8, vertical: 4),
      child: content,
    );
    if (isFailed) {
      // A failed reaction is a retry button: give it a full tap target.
      content = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
        child: Center(widthFactor: 1, heightFactor: 1, child: content),
      );
    }

    Widget chip = Material(
      color: isFailed ? scheme.errorContainer : scheme.surfaceContainerHigh,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: handler, child: content),
    );
    if (isFailed && onRetry != null) {
      chip = Semantics(
        button: true,
        label: context.l10n.common_retry,
        child: chip,
      );
    }
    return Opacity(opacity: isPending ? 0.5 : 1.0, child: chip);
  }
}
