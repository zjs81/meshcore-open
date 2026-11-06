import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/translation_support.dart';
import '../services/app_settings_service.dart';
import '../services/translation_service.dart';
import '../utils/app_logger.dart';
import '../utils/platform_info.dart';
import 'marker_label_dialog.dart';

/// Send guard and one-second cooldown shared by the chat composers.
///
/// The cooldown is only stamped by [markDispatched], i.e. once a send has
/// actually gone to the connector, so a rejected attempt (empty, too long,
/// translation aborted) never locks the user out.
class ChatSendGuard {
  static const cooldown = Duration(seconds: 1);

  DateTime? _lastDispatchAt;
  bool _busy = false;

  /// True while a send is awaiting outgoing translation, so a second tap
  /// can't send the same text again.
  bool get isBusy => _busy;

  /// Runs [action] unless another send is already in flight.
  Future<void> runExclusive(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  /// Returns false, and tells the user, if the last dispatch was under a
  /// second ago.
  bool checkCooldown(BuildContext context) {
    final last = _lastDispatchAt;
    if (last != null && DateTime.now().difference(last) < cooldown) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_sendCooldown),
      );
      return false;
    }
    return true;
  }

  void markDispatched() => _lastDispatchAt = DateTime.now();
}

/// Outcome of the optional outgoing translation step.
@immutable
class OutgoingTranslation {
  final String text;
  final String? originalText;
  final String? languageCode;
  final String? modelId;

  const OutgoingTranslation(
    this.text, {
    this.originalText,
    this.languageCode,
    this.modelId,
  });
}

/// Translates [text] when composer translation is on and applies, returning
/// the text to send plus translation metadata. Returns null when [context]
/// was unmounted while the translation ran.
Future<OutgoingTranslation?> translateOutgoingText(
  BuildContext context,
  String text,
) async {
  final settings = context.read<AppSettingsService>().settings;
  if (!settings.translationEnabled) return OutgoingTranslation(text);
  final translationService = context.read<TranslationService>();
  final targetLanguageCode = translationService.resolvedTargetLanguageCode(
    Localizations.localeOf(context).languageCode,
  );
  if (!translationService.shouldTranslateOutgoing(
    text: text,
    targetLanguageCode: targetLanguageCode,
  )) {
    return OutgoingTranslation(text);
  }
  final result = await translationService.translateOutgoingText(
    text: text,
    targetLanguageCode: targetLanguageCode,
  );
  if (!context.mounted) return null;
  if (result != null &&
      result.status == MessageTranslationStatus.completed &&
      result.translatedText.isNotEmpty) {
    return OutgoingTranslation(
      result.translatedText,
      originalText: text,
      languageCode: result.targetLanguageCode,
      modelId: result.modelId,
    );
  }
  return OutgoingTranslation(text);
}

/// Shares the radio's own position as a map marker through [send]. Uses the
/// same [guard] as typed messages so it can't race or flood alongside them.
Future<void> shareMyLocationMarker({
  required BuildContext context,
  required MeshCoreConnector connector,
  required ChatSendGuard guard,
  required Future<void> Function(String markerText) send,
  String logTag = 'Chat',
}) async {
  final lat = connector.selfLatitude;
  final lon = connector.selfLongitude;
  if (!hasShareableLocation(lat, lon)) {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_noRadioLocation),
    );
    return;
  }
  final selfName = connector.selfName;
  final label = await showMarkerLabelDialog(
    context,
    lat: lat!,
    lon: lon!,
    defaultLabel: selfName != null && selfName.isNotEmpty
        ? selfName
        : context.l10n.map_sharedPin,
    flags: 'poi',
    confirmText: context.l10n.common_share,
  );
  if (label == null || label.isEmpty || !context.mounted) return;
  await guard.runExclusive(() async {
    if (!guard.checkCooldown(context)) return;
    final pending = send(formatMarkerText(lat, lon, label, 'poi'));
    guard.markDispatched();
    try {
      await pending;
    } catch (e) {
      // A failed send is already marked failed on the message itself.
      appLogger.warn('Sharing location failed: $e', tag: logTag);
    }
  });
}

/// Copies a message to the clipboard and confirms it.
void copyChatMessageText(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  // Android shows its own clipboard chip; the snackbar is redundant there
  // and lingers over the input field after the chip dismisses.
  if (PlatformInfo.isAndroid) return;
  showDismissibleSnackBar(
    context,
    content: Text(context.l10n.chat_messageCopied),
  );
}

/// Asks before clearing a transcript. [message] says what will be erased.
Future<bool> confirmClearChat(
  BuildContext context, {
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.contact_clearChat),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(dialogContext.l10n.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: Text(dialogContext.l10n.common_delete),
        ),
      ],
    ),
  );
  return confirmed == true;
}
