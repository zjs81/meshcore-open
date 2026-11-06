import 'dart:async';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';

/// Companion firmware (MeshCore commit 4a869163, 2025-12-30) replaces the CLI
/// frame timestamp with the companion node's RTC for TXT_TYPE_CLI_DATA, so a
/// plain "clock sync" sets the repeater clock to the node clock. The official
/// meshcore-cli translates it to an explicit `time <epoch>` command instead;
/// do the same so the repeater always gets the phone's time.
String normalizeRepeaterClockSyncCommand(String command, {int? nowSeconds}) {
  final epoch = nowSeconds ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return command.trim().toLowerCase() == 'clock sync' ? 'time $epoch' : command;
}

/// One [RepeaterCommandService.sendCommand] call. Every retry adds a fresh
/// `XX|` prefix, and a reply to any of them completes the call, so a late
/// reply to an earlier attempt is not mistaken for silence.
class _PendingCommand {
  _PendingCommand(this.repeaterKey);

  final String repeaterKey;
  final Completer<String> completer = Completer<String>();
  final Set<String> prefixes = {};
}

class RepeaterCommandService {
  final MeshCoreConnector _connector;
  final Set<_PendingCommand> _pendingCommands = {};
  final Map<String, _PendingCommand> _pendingByPrefix = {};
  int _prefixCounter = 0;

  static const int maxRetries = 5;
  static final RegExp _prefixPattern = RegExp(r'^[0-9A-Fa-f]{2}\|');

  RepeaterCommandService(this._connector);

  /// Send a CLI command to a repeater with automatic retries
  /// Returns a future that completes when a response is received or after max retries.
  /// With [raw], the command is sent verbatim without the `XX|` reply prefix.
  Future<String> sendCommand(
    Contact repeater,
    String command, {
    Function(String)? onResponse,
    Function(int)? onAttempt,
    int retries = maxRetries,
    bool raw = false,
  }) async {
    if (!raw) command = normalizeRepeaterClockSyncCommand(command);
    final attemptCount = retries < 1 ? 1 : retries;
    final pending = _PendingCommand(repeater.publicKeyHex);
    _pendingCommands.add(pending);
    try {
      final selection = await _connector.preparePathForContactSend(repeater);

      for (int attempt = 0; attempt < attemptCount; attempt++) {
        onAttempt?.call(attempt + 1);
        try {
          final response = await _sendCommandAttempt(
            repeater,
            command,
            selection,
            attempt,
            raw,
            pending,
          );
          onResponse?.call(response);
          return response;
        } catch (e) {
          if (attempt == attemptCount - 1) rethrow;
        }
      }

      throw Exception('Command failed after $attemptCount attempts');
    } finally {
      _cleanup(pending);
    }
  }

  Future<String> _sendCommandAttempt(
    Contact repeater,
    String command,
    PathSelection selection,
    int attempt,
    bool raw,
    _PendingCommand pending,
  ) async {
    // A reply to an earlier attempt may have arrived during the backoff.
    if (pending.completer.isCompleted) return pending.completer.future;

    final prefix = _nextPrefixToken();
    pending.prefixes.add(prefix);
    _pendingByPrefix[prefix] = pending;

    final int timeoutMs;
    try {
      final framedCommand = raw ? command : '$prefix$command';
      final pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
      final timestampSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _connector.trackRepeaterAck(
        contact: repeater,
        selection: selection,
        text: framedCommand,
        timestampSeconds: timestampSeconds,
        attempt: attempt,
      );
      final frame = buildSendCliCommandFrame(
        repeater.publicKey,
        framedCommand,
        attempt: attempt,
        timestampSeconds: timestampSeconds,
      );
      final responseBytes = frame.length > maxFrameSize
          ? frame.length
          : maxFrameSize;
      timeoutMs = _connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: responseBytes,
      );
      await _connector.sendFrame(frame);
    } catch (e) {
      throw Exception('Failed to send command: $e');
    }

    final timeoutSeconds = (timeoutMs / 1000).ceil();
    return pending.completer.future.timeout(
      Duration(milliseconds: timeoutMs),
      onTimeout: () =>
          Future<String>.error('Command timeout after $timeoutSeconds seconds'),
    );
  }

  /// The text [sendCommand] would put on the wire for its next attempt: the
  /// clock-sync rewrite plus the `XX|` reply prefix (unless [raw]). Used for
  /// debug previews so they match what is actually sent.
  String previewFramedCommand(String command, {bool raw = false}) {
    if (raw) return command;
    return '${_peekPrefixToken()}${normalizeRepeaterClockSyncCommand(command)}';
  }

  /// Send [line] verbatim and don't wait for a reply. While `region load` is
  /// active the firmware consumes each line before prefix stripping and
  /// sends nothing back (simple_repeater/MyMesh.cpp handleCommand).
  Future<void> sendUnansweredLine(Contact repeater, String line) {
    return _connector.sendFrame(
      buildSendCliCommandFrame(repeater.publicKey, line),
    );
  }

  /// Call this when a text message response is received from a repeater
  void handleResponse(Contact repeater, String responseText) {
    // Find pending command for this repeater and complete it
    final repeaterKey = repeater.publicKeyHex;

    _PendingCommand? pending;
    String responsePayload = responseText;
    if (_prefixPattern.hasMatch(responseText)) {
      final prefix = responseText.substring(0, 3).toUpperCase();
      pending = _pendingByPrefix[prefix];
      if (pending == null || pending.repeaterKey != repeaterKey) {
        return;
      }
      responsePayload = responseText.substring(3).trimLeft();
    }

    if (pending == null) {
      for (final candidate in _pendingCommands) {
        if (candidate.repeaterKey == repeaterKey &&
            !candidate.completer.isCompleted) {
          pending = candidate;
          break;
        }
      }
    }

    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.complete(responsePayload);
    }
  }

  void _cleanup(_PendingCommand pending) {
    _pendingCommands.remove(pending);
    for (final prefix in pending.prefixes) {
      if (identical(_pendingByPrefix[prefix], pending)) {
        _pendingByPrefix.remove(prefix);
      }
    }
  }

  void dispose() {
    _pendingCommands.clear();
    _pendingByPrefix.clear();
  }

  String _peekPrefixToken() {
    for (var i = 0; i < 256; i++) {
      final value = (_prefixCounter + i) & 0xFF;
      final token = '${value.toRadixString(16).padLeft(2, '0').toUpperCase()}|';
      if (!_pendingByPrefix.containsKey(token)) {
        return token;
      }
    }
    return '00|';
  }

  String _nextPrefixToken() {
    for (var i = 0; i < 256; i++) {
      final value = _prefixCounter++ & 0xFF;
      final token = '${value.toRadixString(16).padLeft(2, '0').toUpperCase()}|';
      if (!_pendingByPrefix.containsKey(token)) {
        return token;
      }
    }
    return '00|';
  }
}
