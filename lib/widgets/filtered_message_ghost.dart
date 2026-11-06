import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/message_filter.dart';
import '../theme/mesh_theme.dart';

/// Localized "Filtered: …" line for a message the filter hid.
///
/// [reason] is the stored `ChannelMessage.filterReason` (a [FilterReason]
/// JSON name); [detail] the matching rule pattern for rule hits, shortened
/// (see [shortFilterDetail]) so a rule made from a whole spam message never
/// spells that message out. An unknown or missing reason falls back to the
/// generic manual wording.
String messageFilterReasonLabel(
  AppLocalizations l10n,
  String? reason,
  String? detail,
) {
  switch (filterReasonFromJson(reason)) {
    case FilterReason.textRule:
      return l10n.messageFilter_reasonTextRule(shortFilterDetail(detail));
    case FilterReason.senderRule:
      return l10n.messageFilter_reasonSenderRule(shortFilterDetail(detail));
    case FilterReason.repeatedCharacters:
      return l10n.messageFilter_reasonRepeatedCharacters;
    case FilterReason.duplicate:
      return l10n.messageFilter_reasonDuplicate;
    case FilterReason.crossSenderDuplicate:
      return l10n.messageFilter_reasonCrossSenderDuplicate;
    case FilterReason.learned:
      return l10n.messageFilter_reasonLearned;
    case FilterReason.manual:
    case null:
      return l10n.messageFilter_reasonManual;
  }
}

/// Longest rule pattern shown in a reason line, in characters.
const int filterDetailMaxLength = 24;

/// [detail] on one line, cut to [filterDetailMaxLength] characters plus an
/// ellipsis.
String shortFilterDetail(String? detail) {
  final oneLine = (detail ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  final chars = oneLine.characters;
  if (chars.length <= filterDetailMaxLength) return oneLine;
  return '${chars.take(filterDetailMaxLength).toString().trimRight()}…';
}

/// Low-emphasis stand-in for one or more messages hidden by the message
/// filter.
///
/// Deliberately smaller and quieter than a message bubble, and never shows
/// the hidden text or sender — only how many messages there are and why the
/// newest was hidden. The whole row is one tap target (at least 48dp tall)
/// that reveals the run.
class FilteredMessageGhost extends StatelessWidget {
  /// Number of hidden messages this row stands for (at least 1).
  final int count;

  /// Why the newest hidden message was filtered, already localized.
  final String reason;

  /// Chat text scale, so the row grows with the bubbles around it.
  final double textScale;

  /// The run is revealed and this row is the header above it: tapping hides
  /// the messages again.
  final bool expanded;

  final VoidCallback onTap;

  const FilteredMessageGhost({
    super.key,
    required this.count,
    required this.reason,
    required this.onTap,
    this.textScale = 1.0,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final title = expanded
        ? (count <= 1
              ? l10n.messageFilter_ghostSingleExpanded
              : l10n.messageFilter_ghostManyExpanded(count))
        : (count <= 1
              ? l10n.messageFilter_ghostSingle
              : l10n.messageFilter_ghostMany(count));
    final radius = BorderRadius.circular(MeshRadii.md);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Semantics(
            button: true,
            // Only announce an expanded state on the header of a revealed run.
            expanded: expanded ? true : null,
            label: '$title. $reason',
            // excludeSemantics drops the InkWell's tap action, so expose it
            // here for screen readers.
            onTap: onTap,
            excludeSemantics: true,
            child: Material(
              color: scheme.surfaceContainerLow.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: l10n.messageFilter_ghostIconTooltip,
                          child: AnimatedSwitcher(
                            duration: _ghostSwapDuration(context),
                            child: Icon(
                              expanded
                                  ? Icons.expand_less
                                  : Icons.visibility_off_outlined,
                              key: ValueKey(expanded),
                              size: 18 * textScale,
                              color: muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: _ghostSwapDuration(context),
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: AlignmentDirectional.centerStart,
                                  children: [...previous, ?current],
                                ),
                                child: Text(
                                  title,
                                  key: ValueKey(title),
                                  style: TextStyle(
                                    fontSize: 14 * textScale,
                                    fontWeight: FontWeight.w600,
                                    color: muted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                reason,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13 * textScale,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cross-fade time for the ghost row's icon and title when a run opens or
/// closes; zero when the platform asks for reduced motion.
Duration _ghostSwapDuration(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false
    ? Duration.zero
    : const Duration(milliseconds: 180);

/// How long a run of hidden messages takes to open or close.
const Duration filteredRunAnimationDuration = Duration(milliseconds: 250);

/// A run of messages hidden by the filter, shown as one [FilteredMessageGhost]
/// header with the messages underneath it.
///
/// Toggling [expanded] animates the messages open (unrolling below the header
/// with a fade) or closed again, in place, so the run never jumps around the
/// chat. Messages are only built while some of them are visible. With reduced
/// motion turned on the change is instant.
class FilteredMessageRun extends StatefulWidget {
  /// Number of hidden messages in the run (at least 1).
  final int count;

  /// Why the newest message was hidden, already localized.
  final String reason;

  final double textScale;

  /// Whether the run's messages are shown.
  final bool expanded;

  /// Called when the header is tapped (open when collapsed, close when open).
  final VoidCallback onToggle;

  /// Builds the run's message bubbles, oldest first (top to bottom).
  final List<Widget> Function(BuildContext context) buildMessages;

  const FilteredMessageRun({
    super.key,
    required this.count,
    required this.reason,
    required this.expanded,
    required this.onToggle,
    required this.buildMessages,
    this.textScale = 1.0,
  });

  @override
  State<FilteredMessageRun> createState() => _FilteredMessageRunState();
}

class _FilteredMessageRunState extends State<FilteredMessageRun>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: filteredRunAnimationDuration,
    value: widget.expanded ? 1.0 : 0.0,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didUpdateWidget(FilteredMessageRun oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.value = widget.expanded ? 1.0 : 0.0;
    } else if (widget.expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilteredMessageGhost(
          count: widget.count,
          reason: widget.reason,
          textScale: widget.textScale,
          expanded: widget.expanded,
          onTap: widget.onToggle,
        ),
        AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            if (_controller.isDismissed) return const SizedBox.shrink();
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _curve.value,
                child: Opacity(
                  opacity: _curve.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.buildMessages(context),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Slim, calm banner shown inside a revealed filtered message's bubble, above
/// its text: why it was hidden, plus "Not spam" and "Hide".
class FilteredMessageBanner extends StatelessWidget {
  final String reason;
  final double textScale;

  /// Text colour of the surrounding bubble; the banner derives its muted
  /// tones from it so it reads on both incoming and themed bubbles.
  final Color color;
  final VoidCallback onNotSpam;
  final VoidCallback onHide;

  const FilteredMessageBanner({
    super.key,
    required this.reason,
    required this.color,
    required this.onNotSpam,
    required this.onHide,
    this.textScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = color.withValues(alpha: 0.78);
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size(48, 48),
      tapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: TextStyle(
        fontSize: 13 * textScale,
        fontWeight: FontWeight.w600,
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 4, 2, 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(MeshRadii.sm),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 16 * textScale,
                color: muted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  reason,
                  style: TextStyle(fontSize: 13 * textScale, color: muted),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                style: buttonStyle,
                onPressed: onNotSpam,
                child: Text(l10n.messageFilter_notSpam),
              ),
              TextButton(
                style: buttonStyle,
                onPressed: onHide,
                child: Text(l10n.messageFilter_hideAgain),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
