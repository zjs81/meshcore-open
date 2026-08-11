import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../utils/lora_airtime.dart';
import 'image_send_codec_binding.dart';

/// Estimated wall clock above which the sheet warns the user explicitly.
const Duration kImageSendLongAirtime = Duration(seconds: 5);

/// What the user committed to when they tapped Send.
class ImageSendPreviewResult {
  /// The encoded bitstream, ready to be chunked onto the air.
  final Uint8List payload;

  /// The rate point the payload was encoded at. Always [kImageSendRatePoint] in
  /// this build; carried through because the transport writes it on the wire.
  final ImageCodecRatePoint rate;

  /// Whether an XOR parity packet should be appended.
  final bool includeParity;

  /// Packets that will actually be transmitted, parity included.
  final int packetCount;

  /// Estimated transmitter occupancy, or null if the radio settings were
  /// unknown. This is *not* how long the send takes — see [wallClock].
  final Duration? airtime;

  /// Estimated wall clock including per-chunk pacing — the figure the user was
  /// actually shown. Null when the radio settings were unknown.
  final Duration? wallClock;

  const ImageSendPreviewResult({
    required this.payload,
    required this.rate,
    required this.includeParity,
    required this.packetCount,
    required this.airtime,
    required this.wallClock,
  });
}

/// Shows the pre-send image preview.
///
/// Returns null if the user cancelled, or an [ImageSendPreviewResult] carrying
/// the encoded payload if they confirmed. The caller owns the actual send.
///
/// [imageBytes] is the raw picked file (JPEG/PNG/…). [originalFileBytes] is its
/// on-disk size, shown against the transmitted size.
///
/// [radio] overrides the live radio parameters; when omitted they are read from
/// the [MeshCoreConnector] in the widget tree. Pass it explicitly to preview
/// this sheet without a connector.
///
/// There is no quality/rate argument: ft32 ([kImageSendRatePoint]) is the only
/// shipping model, so the sheet no longer offers a choice.
Future<ImageSendPreviewResult?> showImageSendPreviewSheet({
  required BuildContext context,
  required Uint8List imageBytes,
  required int originalFileBytes,
  required ImageSendCodec codec,
  ImageSendRadio? radio,
  bool initialParity = true,
}) {
  return showModalBottomSheet<ImageSendPreviewResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ImageSendPreviewSheet(
      imageBytes: imageBytes,
      originalFileBytes: originalFileBytes,
      codec: codec,
      radio: radio,
      initialParity: initialParity,
    ),
  );
}

class ImageSendPreviewSheet extends StatefulWidget {
  final Uint8List imageBytes;
  final int originalFileBytes;
  final ImageSendCodec codec;
  final ImageSendRadio? radio;
  final bool initialParity;

  const ImageSendPreviewSheet({
    super.key,
    required this.imageBytes,
    required this.originalFileBytes,
    required this.codec,
    this.radio,
    this.initialParity = true,
  });

  @override
  State<ImageSendPreviewSheet> createState() => _ImageSendPreviewSheetState();
}

/// The live radio parameters, exactly as the connector exposes them: each may
/// be null before the device has reported its SELF_INFO frame.
class ImageSendRadio {
  final int? spreadingFactor;
  final int? bandwidthHz;

  /// Raw firmware coding rate; [estimateSendFromRadioParams] normalises it.
  final int? rawCodingRate;

  const ImageSendRadio({
    this.spreadingFactor,
    this.bandwidthHz,
    this.rawCodingRate,
  });

  bool get isKnown =>
      spreadingFactor != null && bandwidthHz != null && rawCodingRate != null;
}

/// Packet/byte/airtime figures for one rate point.
///
/// Before an encode has finished the payload size is only known as a measured
/// range, so [best] and [worst] differ; afterwards they are identical.
class _RateEstimate {
  /// Exact payload size once encoded, null while still estimating.
  final int? payloadBytes;
  final SendEstimate best;
  final SendEstimate worst;

  const _RateEstimate({
    required this.payloadBytes,
    required this.best,
    required this.worst,
  });

  bool get isExact => payloadBytes != null;
}

class _ImageSendPreviewSheetState extends State<ImageSendPreviewSheet> {
  /// The encoded ft32 bitstream, once the encode finishes.
  Uint8List? _encoded;

  late bool _parity;
  bool _encoding = false;
  bool _sending = false;
  bool _failed = false;

  /// Latest radio params seen in build; used by [_onSend] so the confirm path
  /// does not have to touch an InheritedWidget after an await.
  ImageSendRadio? _radio;

  @override
  void initState() {
    super.initState();
    _parity = widget.initialParity;
    if (widget.codec.availability == ImageCodecAvailability.ready) {
      _encode();
    }
  }

  Future<Uint8List?> _encode() async {
    final cached = _encoded;
    if (cached != null) return cached;
    setState(() {
      _encoding = true;
      _failed = false;
    });
    try {
      final bytes = await widget.codec.encode(
        widget.imageBytes,
        kImageSendRatePoint,
      );
      if (!mounted) return bytes;
      setState(() {
        _encoded = bytes;
        _encoding = false;
      });
      return bytes;
    } catch (_) {
      if (!mounted) return null;
      setState(() {
        _encoding = false;
        _failed = true;
      });
      return null;
    }
  }

  ImageSendRadio _radioParams(BuildContext context) {
    final override = widget.radio;
    if (override != null) return override;
    final connector = context.watch<MeshCoreConnector>();
    return ImageSendRadio(
      spreadingFactor: connector.currentSf,
      bandwidthHz: connector.currentBwHz,
      rawCodingRate: connector.currentCr,
    );
  }

  _RateEstimate _estimateFor(ImageSendRadio radio) {
    final bytes = _encoded;
    if (bytes != null) {
      final exact = _estimate(bytes.length, radio);
      return _RateEstimate(
        payloadBytes: bytes.length,
        best: exact,
        worst: exact,
      );
    }
    // Nothing encoded yet: show the measured ft32 range so the user sees a
    // figure immediately rather than a spinner.
    final stats = ImageCodecRateStats.forRate(kImageSendRatePoint);
    return _RateEstimate(
      payloadBytes: null,
      best: _estimate(stats.minBytes, radio),
      worst: _estimate(stats.maxBytes, radio),
    );
  }

  SendEstimate _estimate(int payloadBytes, ImageSendRadio radio) {
    return estimateSendFromRadioParams(
      payloadBytes: payloadBytes,
      spreadingFactor: radio.spreadingFactor,
      bandwidthHz: radio.bandwidthHz,
      codingRate: radio.rawCodingRate,
      parity: _parity,
    );
  }

  Future<void> _onSend() async {
    setState(() => _sending = true);
    final payload = await _encode();
    if (!mounted) return;
    if (payload == null) {
      setState(() => _sending = false);
      return;
    }
    final radio = _radio ?? const ImageSendRadio();
    final estimate = _estimate(payload.length, radio);
    Navigator.of(context).pop(
      ImageSendPreviewResult(
        payload: payload,
        rate: kImageSendRatePoint,
        includeParity: estimate.includesParity,
        packetCount: estimate.chunkCount,
        airtime: estimate.totalAirtime,
        wallClock: estimate.pacedWallClock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final radio = _radioParams(context);
    _radio = radio;
    final selected = _estimateFor(radio);
    final ready = widget.codec.availability == ImageCodecAvailability.ready;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _grabHandle(colors),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.imageSend_title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.imageSend_cancel,
                    onPressed: _sending
                        ? null
                        : () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _preview(theme, colors),
                  const SizedBox(height: 16),
                  if (!ready) _unavailableBanner(theme, colors),
                  if (ready) ...[
                    // Packet count and time on air lead: with the quality
                    // selector gone they are the only decision the user makes.
                    _headlineStats(theme, colors, selected),
                    const SizedBox(height: 16),
                    _sizeRow(theme, colors, selected),
                    const SizedBox(height: 12),
                    // Warnings sit directly under the figures they qualify.
                    ..._warnings(theme, colors, radio, selected),
                    const SizedBox(height: 4),
                    _parityTile(theme, colors),
                    if (_failed) ...[
                      const SizedBox(height: 12),
                      _banner(
                        colors: colors,
                        theme: theme,
                        icon: Icons.error_outline,
                        background: colors.errorContainer,
                        foreground: colors.onErrorContainer,
                        title: l10n.imageSend_encodeFailed,
                        body: null,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            _actions(theme, ready),
          ],
        ),
      ),
    );
  }

  Widget _grabHandle(ColorScheme colors) => Container(
    width: 36,
    height: 4,
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: colors.onSurfaceVariant.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  /// The square render. [BoxFit.fill] on a 1:1 box is exactly the 512x512
  /// centre crop the codec will take, so what is shown is what is sent.
  ///
  /// The preview is deliberately capped in height: the packet count and airtime
  /// below it are the reason this screen exists and must not be pushed off the
  /// first screenful by a full-width square.
  Widget _preview(ThemeData theme, ColorScheme colors) {
    final maxSide = MediaQuery.sizeOf(context).height * 0.28;
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSide, maxWidth: maxSide),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: colors.surfaceContainerHighest,
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.fill,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stack) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.imageSend_cropNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _sizeRow(ThemeData theme, ColorScheme colors, _RateEstimate estimate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _sizeChip(
          theme,
          colors,
          context.l10n.imageSend_originalSize,
          _formatBytes(widget.originalFileBytes),
          strikethrough: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.arrow_forward,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
        ),
        _sizeChip(
          theme,
          colors,
          context.l10n.imageSend_onAirSize,
          _onAirBytesText(estimate),
          emphasised: true,
        ),
      ],
    );
  }

  Widget _sizeChip(
    ThemeData theme,
    ColorScheme colors,
    String label,
    String value, {
    bool strikethrough = false,
    bool emphasised = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: emphasised ? colors.primary : colors.onSurface,
            decoration: strikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  /// The point of the whole screen: what this send costs, in big type.
  ///
  /// Only two figures, both large: the packet count and the realistic time the
  /// send will take. The byte sizes moved down to [_sizeRow] — with the quality
  /// selector gone there is room to give these two the whole width.
  Widget _headlineStats(
    ThemeData theme,
    ColorScheme colors,
    _RateEstimate estimate,
  ) {
    final localizations = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stat(
              theme,
              colors,
              localizations.imageSend_packetsLabel,
              _packetCountText(estimate),
            ),
          ),
          _statDivider(colors),
          Expanded(
            child: _stat(
              theme,
              colors,
              localizations.imageSend_airtimeLabel,
              _airtimeText(estimate),
              emphasised: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider(ColorScheme colors) =>
      Container(width: 1, height: 44, color: colors.outlineVariant);

  Widget _stat(
    ThemeData theme,
    ColorScheme colors,
    String label,
    String value, {
    bool emphasised = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: emphasised ? colors.primary : colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _parityTile(ThemeData theme, ColorScheme colors) {
    final localizations = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _parity,
      onChanged: _sending ? null : (v) => setState(() => _parity = v),
      secondary: const Icon(Icons.shield_outlined, size: 20),
      title: Text(localizations.imageSend_parityTitle),
      subtitle: Text(
        localizations.imageSend_paritySubtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }

  List<Widget> _warnings(
    ThemeData theme,
    ColorScheme colors,
    ImageSendRadio radio,
    _RateEstimate estimate,
  ) {
    final localizations = context.l10n;
    final widgets = <Widget>[];
    if (!radio.isKnown) {
      widgets.add(
        _banner(
          colors: colors,
          theme: theme,
          icon: Icons.settings_input_antenna,
          background: colors.errorContainer,
          foreground: colors.onErrorContainer,
          title: localizations.imageSend_radioUnknownTitle,
          body: localizations.imageSend_radioUnknownBody,
        ),
      );
    } else {
      // Compared against the paced wall clock, not raw airtime: the warning is
      // about how long the user waits, which is the figure shown above it.
      final worst = estimate.worst.pacedWallClock;
      if (worst != null && worst >= kImageSendLongAirtime) {
        widgets.add(
          _banner(
            colors: colors,
            theme: theme,
            icon: Icons.hourglass_bottom,
            background: colors.tertiaryContainer,
            foreground: colors.onTertiaryContainer,
            title: localizations.imageSend_longSendTitle,
            body: localizations.imageSend_longSendBody(_formatDuration(worst)),
          ),
        );
      }
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.hub_outlined, size: 16, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                localizations.imageSend_floodNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return widgets;
  }

  /// The "why can't I send?" banner.
  ///
  /// For [ImageCodecAvailability.unavailable] the generic localised string says
  /// only that the codec cannot run, which leaves the user with no idea whether
  /// to wait, download something, or give up. The codec knows exactly which
  /// permanent property of the build it hit, so
  /// [ImageSendCodec.unavailableReason] REPLACES the generic string whenever it
  /// is non-empty. It falls back to the localised generic only when the codec
  /// declined to say why.
  Widget _unavailableBanner(ThemeData theme, ColorScheme colors) {
    final localizations = context.l10n;
    final String message;
    switch (widget.codec.availability) {
      case ImageCodecAvailability.disabled:
        message = localizations.imageSend_codecDisabled;
        break;
      case ImageCodecAvailability.downloading:
        message = localizations.imageSend_codecDownloading;
        break;
      case ImageCodecAvailability.unavailable:
        final reason = widget.codec.unavailableReason?.trim();
        message = (reason == null || reason.isEmpty)
            ? localizations.imageSend_codecUnavailable
            : reason;
        break;
      case ImageCodecAvailability.ready:
        return const SizedBox.shrink();
    }
    return _banner(
      colors: colors,
      theme: theme,
      icon: Icons.info_outline,
      background: colors.surfaceContainerHighest,
      foreground: colors.onSurfaceVariant,
      title: message,
      body: null,
    );
  }

  Widget _banner({
    required ColorScheme colors,
    required ThemeData theme,
    required IconData icon,
    required Color background,
    required Color foreground,
    required String title,
    required String? body,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(ThemeData theme, bool ready) {
    final localizations = context.l10n;
    final busy = _sending || _encoding;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _sending
                  ? null
                  : () => Navigator.of(context).maybePop(),
              child: Text(localizations.imageSend_cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: (!ready || busy) ? null : _onSend,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(localizations.imageSend_send),
            ),
          ),
        ],
      ),
    );
  }

  /// Total bytes actually put on the air (headers + payload + parity).
  String _onAirBytesText(_RateEstimate estimate) {
    final lo = estimate.best.totalBytes;
    final hi = estimate.worst.totalBytes;
    if (lo == hi) return _formatBytes(lo);
    return _rangeText(_formatBytes(lo), _formatBytes(hi));
  }

  /// Bare packet count, e.g. "3" or "2–3".
  String _packetCountText(_RateEstimate estimate) {
    final lo = estimate.best.chunkCount;
    final hi = estimate.worst.chunkCount;
    if (lo == hi) return '$lo';
    return _rangeText('$lo', '$hi');
  }

  /// The headline time figure.
  ///
  /// This is [SendEstimate.pacedWallClock], NOT raw airtime: a 2-3 packet image
  /// is paced, so raw transmitter occupancy would understate the wait the user
  /// is being asked to accept. Renders `imageSend_unknownValue`
  /// ("—") whenever the radio parameters are unknown — areLoRaParamsValid() has
  /// already forced the estimate's time fields to null in that case, and a
  /// fabricated ETA is worse than none on a screen whose whole purpose is
  /// informed consent.
  String _airtimeText(_RateEstimate estimate) {
    final l10n = context.l10n;
    final min = estimate.best.pacedWallClock;
    final max = estimate.worst.pacedWallClock;
    if (min == null || max == null) return l10n.imageSend_unknownValue;
    if (min == max) return _formatDuration(max);
    return _rangeText(_formatDuration(min), _formatDuration(max));
  }

  String _rangeText(String min, String max) =>
      context.l10n.imageSend_range(min, max);

  String _formatDuration(Duration d) {
    final l10n = context.l10n;
    final totalSeconds = d.inMilliseconds / 1000.0;
    if (totalSeconds < 60) {
      final text = totalSeconds < 10
          ? totalSeconds.toStringAsFixed(1)
          : totalSeconds.round().toString();
      return l10n.imageSend_secondsValue(text);
    }
    final minutes = d.inMinutes;
    final seconds = d.inSeconds - minutes * 60;
    return l10n.imageSend_minutesSecondsValue('$minutes', '$seconds');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} kB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
