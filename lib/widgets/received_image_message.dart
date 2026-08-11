/// In-bubble renderer for AEIC images received over the mesh.
///
/// Mirrors `lib/widgets/gif_message.dart`: a fixed-size box (so the reversed
/// `ListView` never jumps as chunks land), one widget per message, all state
/// pulled from [ReceivedImageStore].
///
/// ## RISK R6 — permanent synthesized-content label
///
/// A 156-byte AEIC bitstream decoded by a one-step diffusion model is not a
/// photograph. On the measurement corpus this decoder turned a fox into a
/// sharp, natural, artefact-free sheep. Every decoded image therefore carries
/// TWO provenance elements that no caller can influence:
///
///   * [_SyntheticBanner]  — a band burnt into the bottom of the image itself,
///                           inside the `ClipRRect`, inside the `Stack`. It is
///                           part of the pixels the user sees and part of any
///                           screenshot that contains the image at all.
///   * [_SyntheticCaption] — a line of text immediately under the image.
///
/// Both are private to this file, are not parameterised, and are reused
/// verbatim by the full-screen viewer this widget opens on tap, so there is no
/// route in the app that can show the pixels without them. The only case in
/// which they are absent is [ReceivedImageEntry.isOutgoing], where the PNG is
/// the sender's own 512x512 crop and the label would be a falsehood — that is
/// read from the store's sidecar, never from a constructor argument.
///
/// The widget deliberately exposes no share/save action: an exported raster
/// would have to have the caption composited into it first, and that belongs
/// with whoever implements export, not here.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/received_image_store.dart';
import 'image_send_codec_binding.dart' show ImageCodecAvailability;

/// User-visible strings for the NON-decoded states.
///
/// Exists so the wiring agent can hand in `AppLocalizations` values once the
/// `receivedImage_*` ARB keys land (they do not exist yet, so English defaults
/// ship inline). Deliberately contains no field for the R6 badge or caption:
/// those must not be overridable, shortenable or blankable.
@immutable
class ReceivedImageStrings {
  final String Function(int received, int total) incoming;
  final String queued;
  final String tapToDecode;

  /// Headline of the awaiting-action placeholder: how big the bitstream is and
  /// how many packets carried it, e.g. "156 bytes · 2 packets".
  final String Function(int bytes, int packets) awaiting;

  /// The affordance on the awaiting-action placeholder.
  final String tapToProcess;
  final String decoding;
  final String Function(int received, int total) incomplete;
  final String corrupt;
  final String decoderMissing;
  final String evicted;
  final String retry;
  final String decodeAgain;
  final String openSettings;

  const ReceivedImageStrings({
    required this.incoming,
    required this.queued,
    required this.tapToDecode,
    // Optional on purpose: `channel_chat_screen.dart` builds this object and is
    // owned by another workstream, so the two tap-to-process strings must not
    // break that call site before the `receivedImage_*` ARB keys land.
    this.awaiting = _defaultAwaiting,
    this.tapToProcess = 'Tap to process',
    required this.decoding,
    required this.incomplete,
    required this.corrupt,
    required this.decoderMissing,
    required this.evicted,
    required this.retry,
    required this.decodeAgain,
    required this.openSettings,
  });

  // TODO(l10n): replace with context.l10n.receivedImage_* once app_en.arb has
  // the keys listed in section 5(k) of the receive spec.
  static ReceivedImageStrings english = ReceivedImageStrings(
    incoming: (received, total) => '$received of $total packets',
    queued: 'Waiting to decode',
    tapToDecode: 'Tap to decode',
    awaiting: _defaultAwaiting,
    tapToProcess: 'Tap to process',
    decoding: 'Reconstructing… about 1 s',
    incomplete: (received, total) =>
        'Image incomplete — $received of $total packets arrived',
    corrupt: 'Image could not be reconstructed',
    decoderMissing: 'Image received — image decoding is off',
    evicted: 'Image no longer stored',
    retry: 'Try again',
    decodeAgain: 'Decode again',
    openSettings: 'Set up',
  );
}

/// English default for [ReceivedImageStrings.awaiting]. A top-level function so
/// it can be a `const` default value on the constructor.
String _defaultAwaiting(int bytes, int packets) =>
    '$bytes bytes · $packets packets';

/// Text of the R6 label. Private and const: not injectable, not localisable
/// yet, and never empty.
const String _kSyntheticBadge = 'AI-reconstructed';

/// The caption is built from the ACTUAL bitstream size, never a nominal one:
/// quoting a fixed "~156 bytes" under an image that took 209 is its own small
/// dishonesty, in a label whose whole job is honesty.
String _syntheticCaptionFor(int bytes) =>
    'Reconstructed by an AI model from $bytes bytes. '
    'Fine detail is generated, not transmitted.';

class ReceivedImageMessage extends StatefulWidget {
  /// 14 hex chars, as parsed out of the message text by
  /// [ReceivedImageRef.parse].
  final String streamId;

  /// True for the local user's own message. Not an R6 escape hatch: the label is
  /// driven by [ReceivedImageEntry.synthesized], which is derived in the store.
  final bool isOutgoing;

  /// Colour for the explanatory text inside a chat bubble.
  final Color fallbackTextColor;

  final double maxSize;

  /// Test/preview override. Normally resolved from the widget tree.
  final ReceivedImageStore? store;

  final ReceivedImageStrings? strings;

  /// Route to the image-messages settings page (offered only when the decoder
  /// is missing because no weights are downloaded).
  final VoidCallback? onOpenCodecSettings;

  const ReceivedImageMessage({
    super.key,
    required this.streamId,
    required this.isOutgoing,
    required this.fallbackTextColor,
    this.maxSize = 200,
    this.store,
    this.strings,
    this.onOpenCodecSettings,
  });

  @override
  State<ReceivedImageMessage> createState() => _ReceivedImageMessageState();
}

class _ReceivedImageMessageState extends State<ReceivedImageMessage> {
  ReceivedImageStore? _store;

  /// Which stream we have already asked the store to page in. Keyed by id, not
  /// a bare bool: a `ListView` recycles this State object across messages, and
  /// a bool left over from the previous stream meant the new one's pixels were
  /// never requested and the bubble sat on a spinner forever.
  String? _pngRequestedFor;

  ReceivedImageStore? _resolveStore() {
    final injected = widget.store;
    if (injected != null) return injected;
    try {
      return Provider.of<ReceivedImageStore>(context, listen: false);
    } on ProviderNotFoundException {
      // The receive service is not registered (e.g. a screen test); render the
      // "no decoder" state rather than crashing the whole message list.
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = _resolveStore();
    _maybeLoadPng();
  }

  @override
  void didUpdateWidget(covariant ReceivedImageMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamId != widget.streamId) {
      _pngRequestedFor = null;
      _store = _resolveStore();
      _maybeLoadPng();
    }
  }

  void _maybeLoadPng() {
    final store = _store;
    if (store == null) return;
    if (_pngRequestedFor == widget.streamId) return;
    final entry = store.entryFor(widget.streamId);
    if (entry == null) return;
    if (entry.state != ReceivedImageState.decoded) return;
    if (entry.pngBytes != null) return;
    _pngRequestedFor = widget.streamId;
    store.ensurePng(widget.streamId);
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (store == null) {
      return _box(context, _unavailableBody(context, null));
    }
    return ValueListenableBuilder<ReceivedImageEntry?>(
      valueListenable: store.listenableFor(widget.streamId),
      builder: (context, _, _) {
        final entry = store.entryFor(widget.streamId);
        _maybeLoadPng();
        if (entry == null) {
          return _box(context, _unavailableBody(context, null));
        }
        return _buildForEntry(context, store, entry);
      },
    );
  }

  ReceivedImageStrings get _s => widget.strings ?? ReceivedImageStrings.english;

  Widget _buildForEntry(
    BuildContext context,
    ReceivedImageStore store,
    ReceivedImageEntry entry,
  ) {
    switch (entry.state) {
      case ReceivedImageState.decoded:
        final png = entry.pngBytes;
        if (png == null) {
          return _box(
            context,
            _progressBody(context, progress: null, label: _s.decoding),
          );
        }
        return _decodedBody(context, entry, png);

      case ReceivedImageState.receiving:
        final total = entry.totalChunks <= 0 ? 1 : entry.totalChunks;
        return _box(
          context,
          _progressBody(
            context,
            progress: (entry.receivedChunks / total).clamp(0.0, 1.0),
            label: _s.incoming(entry.receivedChunks, total),
          ),
        );

      // "Bitstream complete, not decoded". Two shades of it, distinguished by
      // queue membership rather than by a fourth enum value:
      //   needsManualDecode  -> parked, waiting for a tap (the setting is off,
      //                         or the burst cap trimmed it)
      //   !needsManualDecode -> already in the store's decode queue
      // Both are tappable. The second one deliberately so: a sidecar restored
      // by load() is never re-enqueued, so without a tap target a restored
      // "Waiting to decode" card would be dead forever.
      case ReceivedImageState.reassembled:
        return _box(
          context,
          _iconBody(
            context,
            icon: entry.needsManualDecode
                ? Icons.image_outlined
                : Icons.hourglass_empty,
            label: entry.needsManualDecode
                ? _s.awaiting(entry.bitstreamByteCount, entry.totalChunks)
                : _s.queued,
            action: entry.needsManualDecode
                ? _ActionSpec(
                    _s.tapToProcess,
                    () => _onProcessTap(store, entry),
                  )
                : null,
          ),
          onTap: () => _onProcessTap(store, entry),
        );

      case ReceivedImageState.decoding:
        return _box(
          context,
          _progressBody(context, progress: null, label: _s.decoding),
        );

      case ReceivedImageState.failedIncomplete:
        return _box(
          context,
          _iconBody(
            context,
            icon: Icons.broken_image_outlined,
            label: _s.incomplete(entry.receivedChunks, entry.totalChunks),
            isError: true,
          ),
        );

      case ReceivedImageState.failedCorrupt:
        return _box(
          context,
          _iconBody(
            context,
            icon: Icons.error_outline,
            label: _s.corrupt,
            isError: true,
            action: entry.canRetryDecode
                ? _ActionSpec(
                    _s.retry,
                    () => store.requestDecode(entry.streamId),
                  )
                : null,
          ),
        );

      case ReceivedImageState.decoderUnavailable:
        return _box(context, _unavailableBody(context, entry));

      case ReceivedImageState.evicted:
        return _box(
          context,
          _iconBody(
            context,
            icon: Icons.delete_outline,
            label: _s.evicted,
            action: entry.canRetryDecode
                ? _ActionSpec(
                    _s.decodeAgain,
                    () => store.requestDecode(entry.streamId),
                  )
                : null,
          ),
        );
    }
  }

  /// Availability of the store's decoder seam.
  ///
  /// Read through the store's public `decoder` field rather than importing
  /// `ImageCodecService`: the bubble only needs to know whether a tap would
  /// reach a working codec.
  ImageCodecAvailability _availability(ReceivedImageStore store) =>
      store.decoder?.availability ?? ImageCodecAvailability.unavailable;

  /// The one tap handler for the awaiting-action card.
  ///
  /// With no model installed, going through [ReceivedImageStore.requestDecode]
  /// would cost the user two taps: the entry would flip to
  /// `decoderUnavailable`, and only *then* would the card offer a "Set up"
  /// button. So when the codec is not ready and the host screen gave us a route
  /// to the image-messages setting, go straight there.
  void _onProcessTap(ReceivedImageStore store, ReceivedImageEntry entry) {
    final openSettings = widget.onOpenCodecSettings;
    if (_availability(store) != ImageCodecAvailability.ready &&
        openSettings != null) {
      openSettings();
      return;
    }
    store.requestDecode(entry.streamId);
  }

  // ---- bodies --------------------------------------------------------------

  /// 4:3 placeholder box, same discipline as `GifMessage`, so a bubble does not
  /// resize as an image progresses.
  Widget _box(BuildContext context, Widget child, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final box = Container(
      width: widget.maxSize,
      height: widget.maxSize * 0.75,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: child),
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }

  Widget _progressBody(
    BuildContext context, {
    required double? progress,
    required String label,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, value: progress),
        ),
        const SizedBox(height: 8),
        _label(context, label),
      ],
    );
  }

  Widget _iconBody(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isError = false,
    _ActionSpec? action,
  }) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : widget.fallbackTextColor;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        _label(context, label, color: color),
        if (action != null)
          TextButton(
            onPressed: action.onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(action.label, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _unavailableBody(BuildContext context, ReceivedImageEntry? entry) {
    final canSetUp = widget.onOpenCodecSettings != null;
    return _iconBody(
      context,
      icon: Icons.visibility_off_outlined,
      label: _s.decoderMissing,
      action: canSetUp
          ? _ActionSpec(_s.openSettings, widget.onOpenCodecSettings!)
          : (entry != null && entry.canRetryDecode && _store != null
                ? _ActionSpec(
                    _s.retry,
                    () => _store!.requestDecode(entry.streamId),
                  )
                : null),
    );
  }

  Widget _label(BuildContext context, String text, {Color? color}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, color: color ?? widget.fallbackTextColor),
    );
  }

  // ---- decoded (R6) --------------------------------------------------------

  Widget _decodedBody(
    BuildContext context,
    ReceivedImageEntry entry,
    Uint8List png,
  ) {
    final size = widget.maxSize;
    return GestureDetector(
      onTap: () => _openViewer(context, entry, png),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: size,
              // The codec always produces a 512x512 square because the sender
              // stretched the whole frame into it. entry.displayAspectRatio is
              // the shape it started as, so undo the stretch here rather than
              // showing a widened photo. Null means square or unknown.
              height: entry.displayAspectRatio == null
                  ? size
                  : size / entry.displayAspectRatio!,
              child: Stack(
                children: [
                  Positioned.fill(
                    // fill, not contain: the pixels ARE the stretched square,
                    // so mapping them onto the original aspect box is exactly
                    // the inverse of what the sender did.
                    child: Image.memory(png, fit: BoxFit.fill),
                  ),
                  if (entry.synthesized)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _SyntheticBanner(),
                    ),
                ],
              ),
            ),
          ),
          if (entry.synthesized)
            SizedBox(
              width: size,
              child: _SyntheticCaption(bytes: entry.bitstreamByteCount),
            ),
        ],
      ),
    );
  }

  void _openViewer(
    BuildContext context,
    ReceivedImageEntry entry,
    Uint8List png,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ReceivedImageViewer(
          png: png,
          synthesized: entry.synthesized,
          bytes: entry.bitstreamByteCount,
        ),
      ),
    );
  }
}

class _ActionSpec {
  final String label;
  final VoidCallback onPressed;

  const _ActionSpec(this.label, this.onPressed);
}

/// R6, part 1: a band composited over the bottom of the image.
class _SyntheticBanner extends StatelessWidget {
  const _SyntheticBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      alignment: Alignment.center,
      color: Colors.black.withValues(alpha: 0.62),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _kSyntheticBadge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// R6, part 2: the full sentence, immediately under the image.
class _SyntheticCaption extends StatelessWidget {
  /// Contrast variant only. The TEXT is the same const in both cases; there is
  /// no parameter that can shorten, blank or restyle it away.
  final bool onDark;

  /// Size of the bitstream this image was reconstructed from.
  final int bytes;

  const _SyntheticCaption({required this.bytes, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        _syntheticCaptionFor(bytes),
        // No maxLines: the bubble is narrow and the sentence must never be
        // truncated. A label that reads "Details are invented. Not a" is worse
        // than none — it clips exactly where the warning was going.
        softWrap: true,
        style: TextStyle(
          fontSize: 10,
          color: onDark
              ? Colors.white70
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Full-screen view. Private to this file so no other widget can present the
/// pixels without the two R6 elements.
class _ReceivedImageViewer extends StatelessWidget {
  final Uint8List png;
  final bool synthesized;

  /// Bitstream size, so the full-screen caption quotes the same real number as
  /// the one in the transcript.
  final int bytes;

  const _ReceivedImageViewer({
    required this.png,
    required this.synthesized,
    required this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Stack(
                children: [
                  InteractiveViewer(child: Image.memory(png)),
                  if (synthesized)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _SyntheticBanner(),
                    ),
                ],
              ),
            ),
            if (synthesized)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SyntheticCaption(bytes: bytes, onDark: true),
              ),
          ],
        ),
      ),
    );
  }
}
