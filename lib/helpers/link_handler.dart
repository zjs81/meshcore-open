import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../screens/channel_chat_screen.dart';
import '../utils/platform_info.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/utf8_length_limiter.dart';

/// Matches a `@[name]` mention and captures just the name.
final RegExp mentionRegExp = RegExp(r'@\[([^\]]+)\]');

/// Base opacity of the background drawn behind a mention.
const double mentionBackgroundAlpha = 0.42;

/// Matches a `#word` hashtag and captures the word (without the `#`). The
/// tag must start with a letter so issue numbers like `#123` stay plain, and
/// must not continue a preceding word (`abc#def` stays plain too).
final RegExp hashtagRegExp = RegExp(
  r'(?<![\p{L}\p{N}_])#(\p{L}[\p{L}\p{N}_]*)',
  unicode: true,
);

/// A `#word` hashtag, tappable to offer adding it as a channel.
class HashtagElement extends LinkifyElement {
  HashtagElement(super.name);

  @override
  bool equals(other) => other is HashtagElement && super.equals(other);
}

/// Splits `#word` hashtags out of text elements.
class HashtagLinkifier extends Linkifier {
  const HashtagLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final list = <LinkifyElement>[];
    for (final element in elements) {
      if (element is TextElement) {
        var lastEnd = 0;
        for (final match in hashtagRegExp.allMatches(element.text)) {
          if (match.start > lastEnd) {
            list.add(TextElement(element.text.substring(lastEnd, match.start)));
          }
          list.add(HashtagElement(match.group(1)!));
          lastEnd = match.end;
        }
        if (lastEnd == 0) {
          list.add(element);
        } else if (lastEnd < element.text.length) {
          list.add(TextElement(element.text.substring(lastEnd)));
        }
      } else {
        list.add(element);
      }
    }
    return list;
  }
}

/// A `@[name]` mention, shown as the bare name in the mention style.
class MentionElement extends LinkifyElement {
  MentionElement(super.name);

  @override
  bool equals(other) => other is MentionElement && super.equals(other);
}

/// Splits `@[name]` mentions out of text elements.
class MentionLinkifier extends Linkifier {
  const MentionLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final list = <LinkifyElement>[];
    for (final element in elements) {
      if (element is TextElement) {
        var lastEnd = 0;
        for (final match in mentionRegExp.allMatches(element.text)) {
          if (match.start > lastEnd) {
            list.add(TextElement(element.text.substring(lastEnd, match.start)));
          }
          list.add(MentionElement(match.group(1)!));
          lastEnd = match.end;
        }
        if (lastEnd == 0) {
          list.add(element);
        } else if (lastEnd < element.text.length) {
          list.add(TextElement(element.text.substring(lastEnd)));
        }
      } else {
        list.add(element);
      }
    }
    return list;
  }
}

class LinkHandler {
  static TextStyle defaultLinkStyle(BuildContext context, TextStyle base) {
    final brightness = Theme.of(context).brightness;
    final orange = brightness == Brightness.dark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFE65100);
    return base.copyWith(color: orange, decoration: TextDecoration.underline);
  }

  static TextStyle mentionStyle(BuildContext context, TextStyle base) {
    return base.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: mentionBackground(context),
    );
  }

  /// Background drawn behind a mention to make it stand out.
  static Color mentionBackground(BuildContext context) {
    return Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: mentionBackgroundAlpha);
  }

  /// Returns a [SelectableText.rich] on desktop or a [Text.rich] on mobile,
  /// with URLs and emails linkified and `@[name]` mentions rendered as the
  /// bare name in the mention style on a coloured background. The ambient
  /// [TextScaler] applies automatically.
  ///
  /// When [selfMentionName] matches a mention, that mention's background
  /// gently pulses. Pass [mentionAttention] (true while the chat first
  /// opens) to flash it a few times before it settles. Animations are
  /// skipped when the platform asks for reduced motion.
  static Widget buildLinkifyText({
    required BuildContext context,
    required String text,
    required TextStyle style,
    TextStyle? linkStyle,
    VoidCallback? onSecondaryTap,
    String? selfMentionName,
    bool mentionAttention = false,
  }) {
    final effectiveLinkStyle = linkStyle ?? defaultLinkStyle(context, style);
    const options = LinkifyOptions(humanize: false, defaultToHttps: false);
    const linkifiers = [
      MentionLinkifier(),
      UrlLinkifier(),
      EmailLinkifier(),
      // After URL/Email so `#` inside a URL fragment is not split out.
      HashtagLinkifier(),
    ];

    var elements = <LinkifyElement>[TextElement(text)];
    for (final linkifier in linkifiers) {
      elements = linkifier.parse(elements, options);
    }

    if (selfMentionName != null &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false) &&
        elements.any(
          (element) =>
              element is MentionElement &&
              _namesMatch(element.text, selfMentionName),
        )) {
      return _MentionPulseText(
        elements: elements,
        style: style,
        linkStyle: effectiveLinkStyle,
        selfMentionName: selfMentionName,
        attention: mentionAttention,
        onSecondaryTap: onSecondaryTap,
      );
    }
    return _buildText(
      context,
      elements,
      style: style,
      linkStyle: effectiveLinkStyle,
      mentionFor: (_) => mentionStyle(context, style),
      onSecondaryTap: onSecondaryTap,
    );
  }

  static bool _namesMatch(String a, String b) =>
      a.toLowerCase() == b.toLowerCase();

  static Widget _buildText(
    BuildContext context,
    List<LinkifyElement> elements, {
    required TextStyle style,
    required TextStyle linkStyle,
    required TextStyle Function(String mentionName) mentionFor,
    VoidCallback? onSecondaryTap,
  }) {
    void onOpen(LinkableElement link) => handleLinkTap(context, link.url);

    final children = <InlineSpan>[
      for (final element in elements)
        if (element is MentionElement)
          TextSpan(text: element.text, style: mentionFor(element.text))
        else if (element is HashtagElement)
          TextSpan(
            text: '#${element.text}',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => handleHashtagTap(context, element.text),
            mouseCursor: SystemMouseCursors.click,
          )
        else if (element is LinkableElement)
          TextSpan(
            text: element.text,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = () => onOpen(element),
            mouseCursor: SystemMouseCursors.click,
          )
        else
          TextSpan(text: element.text, style: style),
    ];
    final span = TextSpan(children: children);

    if (PlatformInfo.isDesktop) {
      final selectable = SelectableText.rich(span);
      if (onSecondaryTap == null) return selectable;
      return Listener(
        onPointerDown: (event) {
          if (event.buttons & kSecondaryMouseButton != 0) onSecondaryTap();
        },
        behavior: HitTestBehavior.translucent,
        child: selectable,
      );
    }
    return Text.rich(span);
  }

  static Future<void> handleLinkTap(BuildContext context, String url) async {
    // Show confirmation dialog
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.l10n.chat_openLink),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.chat_openLinkConfirmation,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.chat_open),
          ),
        ],
      ),
    );

    if (shouldOpen != true) return;

    // Launch URL
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          showDismissibleSnackBar(
            context,
            content: Text(context.l10n.chat_couldNotOpenLink(url)),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.chat_invalidLink),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  /// Opens the tapped `#hashtag` channel, or offers to add it if missing.
  static Future<void> handleHashtagTap(
    BuildContext context,
    String hashtag,
  ) async {
    final channelName = '#$hashtag';
    final connector = context.read<MeshCoreConnector>();

    final existing = connector.channels.where(
      (c) => c.name.toLowerCase() == channelName.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      final channel = existing.first;
      final unread = connector.getUnreadCountForChannelIndex(channel.index);
      connector.markChannelRead(channel.index);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChannelChatScreen(channel: channel, initialUnreadCount: unread),
        ),
      );
      return;
    }

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.chat_hashtagAddChannelTitle),
        content: Text(
          dialogContext.l10n.chat_hashtagAddChannelConfirm(channelName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.common_add),
          ),
        ],
      ),
    );
    if (shouldAdd != true || !context.mounted) return;

    if (!connector.isConnected) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.settings_notConnectedError),
      );
      return;
    }
    if (connector.channels.any(
      (c) => c.name.toLowerCase() == channelName.toLowerCase(),
    )) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_hashtagChannelExists(channelName)),
      );
      return;
    }
    if (utf8ByteLength(channelName) > maxRadioNameBytes) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.channels_nameTooLong(maxRadioNameBytes)),
      );
      return;
    }
    if (connector.isSyncingChannels || !connector.hasLoadedChannels) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.channels_waitForSync),
      );
      return;
    }
    final usedIndices = {
      ...connector.channels.map((c) => c.index),
      ...connector.unconfirmedChannelSlots,
    };
    int? slot;
    for (var i = 0; i < connector.maxChannels; i++) {
      if (!usedIndices.contains(i)) {
        slot = i;
        break;
      }
    }
    if (slot == null) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.channels_noFreeSlots),
      );
      return;
    }
    try {
      await connector.setChannel(
        slot,
        channelName,
        Channel.derivePskFromHashtag(hashtag),
      );
    } catch (e) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text('$e'),
          backgroundColor: Colors.red,
        );
      }
      return;
    }
    if (context.mounted) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.channels_channelAdded(channelName)),
      );
    }
  }
}

/// Linkified text whose self-mentions gently pulse, flashing a few times
/// when [attention] is set so opening the chat draws the eye to them.
class _MentionPulseText extends StatefulWidget {
  const _MentionPulseText({
    required this.elements,
    required this.style,
    required this.linkStyle,
    required this.selfMentionName,
    required this.attention,
    this.onSecondaryTap,
  });

  final List<LinkifyElement> elements;
  final TextStyle style;
  final TextStyle linkStyle;
  final String selfMentionName;
  final bool attention;
  final VoidCallback? onSecondaryTap;

  @override
  State<_MentionPulseText> createState() => _MentionPulseTextState();
}

class _MentionPulseTextState extends State<_MentionPulseText>
    with TickerProviderStateMixin {
  static const Duration _pulsePeriod = Duration(milliseconds: 2600);
  static const Duration _attentionDuration = Duration(milliseconds: 1800);
  static const double _pulseAmplitude = 0.12;
  static const double _attentionAmplitude = 0.45;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _pulsePeriod,
  )..repeat(reverse: true);
  AnimationController? _attention;

  @override
  void initState() {
    super.initState();
    if (!widget.attention) return;
    final attention = AnimationController(
      vsync: this,
      duration: _attentionDuration,
    );
    _attention = attention;
    attention.forward().then((_) {
      if (!mounted) {
        attention.dispose();
        return;
      }
      setState(() => _attention = null);
      attention.dispose();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _attention?.dispose();
    super.dispose();
  }

  /// Three flashes that fade out over the attention window.
  static double _attentionFlash(double t) =>
      (1.0 - t) * (0.5 + 0.5 * math.cos(t * math.pi * 5));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final attention = _attention;
        final flash = attention == null
            ? 0.0
            : _attentionFlash(attention.value);
        final alpha =
            (mentionBackgroundAlpha +
                    math.sin(_pulse.value * math.pi) * _pulseAmplitude +
                    flash * _attentionAmplitude)
                .clamp(0.0, 0.92);
        final selfMentionName = widget.selfMentionName;
        return LinkHandler._buildText(
          context,
          widget.elements,
          style: widget.style,
          linkStyle: widget.linkStyle,
          mentionFor: (name) {
            final base = LinkHandler.mentionStyle(context, widget.style);
            if (!LinkHandler._namesMatch(name, selfMentionName)) return base;
            return base.copyWith(
              backgroundColor: scheme.primary.withValues(alpha: alpha),
              color: Color.lerp(
                scheme.primary,
                scheme.onPrimary,
                ((alpha - 0.62) / 0.3).clamp(0.0, 1.0),
              ),
            );
          },
          onSecondaryTap: widget.onSecondaryTap,
        );
      },
    );
  }
}
