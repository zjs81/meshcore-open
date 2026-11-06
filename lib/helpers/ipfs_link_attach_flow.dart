import 'dart:convert';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import 'ipfs_upload_helper.dart';
import 'snack_bar_builder.dart';

/// Shared "send image via IPFS" flow for the direct-message and channel chat
/// screens: picks a file, uploads it with the configured IPFS settings and
/// puts the resulting link at the start of the composer draft.
///
/// [maxBytes] is the screen's outbound byte limit and [encodeOutbound] turns
/// draft text into exactly what the send path measures (including any reply
/// prefix), so the limit is checked against that form. The draft is never
/// shortened: if the link won't fit, nothing is uploaded and the user is told
/// to shorten the message.
Future<void> attachIpfsLinkToDraft({
  required BuildContext context,
  required TextEditingController controller,
  required FocusNode focusNode,
  required int maxBytes,
  required String Function(String text) encodeOutbound,
}) async {
  final l10n = context.l10n;
  final settings = context.read<AppSettingsService>().settings;
  if (settings.uploadIpfsEndpoint.trim().isEmpty) {
    showDismissibleSnackBar(
      context,
      content: Text(l10n.chat_ipfsUploadNotConfigured),
    );
    return;
  }

  String draftWithLink(String messageUrl) => composeIpfsLinkDraft(
    messageUrl: messageUrl,
    existingText: controller.text.trim(),
  );
  bool fits(String draft) => ipfsLinkDraftFits(
    draft,
    maxBytes: maxBytes,
    encodeOutbound: encodeOutbound,
  );

  final sampleLink = IpfsUploadHelper.linkForCid(
    uploadGateway: settings.uploadIpfsGateway,
    cid: IpfsUploadHelper.sampleCid,
  );
  if (!fits(draftWithLink(sampleLink))) {
    showDismissibleSnackBar(context, content: Text(l10n.chat_ipfsLinkNoRoom));
    return;
  }

  void showFailure(Object error) {
    if (!context.mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(ipfsUploadErrorText(l10n, error)),
    );
  }

  final String messageUrl;
  try {
    final file = await file_selector.openFile();
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    if (bytes.isEmpty) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.chat_ipfsSelectedFileEmpty),
      );
      return;
    }
    messageUrl = await IpfsUploadHelper.uploadImageWithSettings(
      settings: settings,
      bytes: bytes,
      fileName: file.name,
      mimeType: IpfsUploadHelper.mimeTypeForFileName(file.name),
    );
  } on Exception catch (error) {
    showFailure(error);
    return;
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'ipfs link attach',
      ),
    );
    showFailure(error);
    return;
  }
  if (!context.mounted) return;

  final messageText = draftWithLink(messageUrl);
  controller.value = TextEditingValue(
    text: messageText,
    selection: TextSelection.collapsed(offset: messageText.length),
  );
  focusNode.requestFocus();
  if (!fits(messageText)) {
    showDismissibleSnackBar(
      context,
      content: Text(l10n.chat_ipfsLinkOverLimit),
    );
  }
}

/// The localized snackbar text for an upload [error]: config problems get a
/// specific message, anything else a generic one with technical details.
@visibleForTesting
String ipfsUploadErrorText(AppLocalizations l10n, Object error) {
  if (error is IpfsUploadConfigException) {
    return switch (error.reason) {
      IpfsUploadConfigError.emptyEndpoint => l10n.chat_ipfsUploadNotConfigured,
      IpfsUploadConfigError.invalidEndpoint => l10n.chat_ipfsEndpointInvalid,
      IpfsUploadConfigError.pinataTokenMissing =>
        l10n.chat_ipfsPinataTokenMissing,
      IpfsUploadConfigError.filebaseTokenMissing =>
        l10n.chat_ipfsFilebaseTokenMissing,
      IpfsUploadConfigError.kuboPathInvalid => l10n.chat_ipfsKuboPathInvalid,
    };
  }
  final details = '$error'.replaceFirst(RegExp(r'^Exception: '), '');
  return l10n.chat_ipfsUploadFailed(details);
}

/// Puts [messageUrl] in front of [existingText], leaving the text intact.
@visibleForTesting
String composeIpfsLinkDraft({
  required String messageUrl,
  required String existingText,
}) => existingText.isEmpty ? '$messageUrl ' : '$messageUrl\n$existingText';

/// Whether [draft], encoded the way the send path encodes it, fits [maxBytes].
@visibleForTesting
bool ipfsLinkDraftFits(
  String draft, {
  required int maxBytes,
  required String Function(String text) encodeOutbound,
}) => utf8.encode(encodeOutbound(draft.trim())).length <= maxBytes;
