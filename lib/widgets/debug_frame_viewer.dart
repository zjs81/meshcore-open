import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../connector/meshcore_protocol.dart';

/// Debug widget to show the hex dump of a frame
class DebugFrameViewer {
  static void showFrameDebug(
    BuildContext context,
    Uint8List frame,
    String title,
  ) {
    final hexString = frame
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');

    final details = StringBuffer();
    details.writeln(context.l10n.debugFrame_length(frame.length));
    details.writeln('');
    details.writeln(
      context.l10n.debugFrame_command(
        frame[0].toRadixString(16).padLeft(2, '0'),
      ),
    );

    if (frame[0] == cmdSendTxtMsg && frame.length > 37) {
      details.writeln('');
      details.writeln(context.l10n.debugFrame_textMessageHeader);
      details.writeln(
        context.l10n.debugFrame_destinationPubKey(
          pubKeyToHex(frame.sublist(1, 33)),
        ),
      );
      details.writeln(
        context.l10n.debugFrame_timestamp(readUint32LE(frame, 33)),
      );
      details.writeln(
        context.l10n.debugFrame_flags(
          frame[37].toRadixString(16).padLeft(2, '0'),
        ),
      );
      final txtType = (frame[37] >> 2) & 0x03;
      final typeLabel = txtType == txtTypeCliData
          ? context.l10n.debugFrame_textTypeCli
          : context.l10n.debugFrame_textTypePlain;
      details.writeln(context.l10n.debugFrame_textType(txtType, typeLabel));
      if (frame.length > 38) {
        final textBytes = frame.sublist(38);
        final nullIdx = textBytes.indexOf(0);
        final text = String.fromCharCodes(
          nullIdx >= 0 ? textBytes.sublist(0, nullIdx) : textBytes,
        );
        details.writeln(context.l10n.debugFrame_text(text));
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                details.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const Divider(),
              Text(
                context.l10n.debugFrame_hexDump,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                hexString,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }
}
