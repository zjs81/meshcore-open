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

class RepeaterCommandService {
  final MeshCoreConnector _connector;
  final Map<String, Completer<String>> _pendingCommands = {};
  final Map<String, Timer> _commandTimeouts = {};
  final Map<String, String> _commandPrefixes = {};
  final Map<String, String> _pendingByPrefix = {};
  int _prefixCounter = 0;

  static const int maxRetries = 5;

  RepeaterCommandService(this._connector);

  /// Send a CLI command to a repeater with automatic retries
  /// Returns a future that completes when a response is received or after max retries
  Future<String> sendCommand(
    Contact repeater,
    String command, {
    Function(String)? onResponse,
    Function(int)? onAttempt,
    int retries = maxRetries,
  }) async {
    command = normalizeRepeaterClockSyncCommand(command);
    final attemptCount = retries < 1 ? 1 : retries;
    final selection = await _connector.preparePathForContactSend(repeater);

    for (int attempt = 0; attempt < attemptCount; attempt++) {
      onAttempt?.call(attempt + 1);
      try {
        final response = await _sendCommandAttempt(
          repeater,
          command,
          selection,
          attempt,
        );
        onResponse?.call(response);
        return response;
      } catch (e) {
        if (attempt == attemptCount - 1) rethrow;
      }
    }

    throw Exception('Command failed after $attemptCount attempts');
  }

  Future<String> _sendCommandAttempt(
    Contact repeater,
    String command,
    PathSelection selection,
    int attempt,
  ) async {
    final repeaterKey = repeater.publicKeyHex;
    final prefix = _nextPrefixToken();
    final commandId = '${repeaterKey}_$prefix';
    final completer = Completer<String>();
    _pendingCommands[commandId] = completer;
    _commandPrefixes[commandId] = prefix;
    _pendingByPrefix[prefix] = commandId;

    try {
      final framedCommand = '$prefix$command';
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
      final timeoutMs = _connector.calculateTimeout(
        pathLength: pathLengthValue,
        messageBytes: responseBytes,
      );
      final timeoutSeconds = (timeoutMs / 1000).ceil();
      await _connector.sendFrame(frame);
      _commandTimeouts[commandId]?.cancel();
      _commandTimeouts[commandId] = Timer(
        Duration(milliseconds: timeoutMs),
        () {
          final completer = _pendingCommands[commandId];
          if (completer != null && !completer.isCompleted) {
            completer.completeError(
              'Command timeout after $timeoutSeconds seconds',
            );
            _cleanup(commandId);
          }
        },
      );
    } catch (e) {
      _cleanup(commandId);
      throw Exception('Failed to send command: $e');
    }

    try {
      return await completer.future;
    } finally {
      _cleanup(commandId);
    }
  }

  /// Call this when a text message response is received from a repeater
  void handleResponse(Contact repeater, String responseText) {
    // Find pending command for this repeater and complete it
    final repeaterKey = repeater.publicKeyHex;

    String? commandId;
    String responsePayload = responseText;
    if (responseText.length >= 3 && responseText[2] == '|') {
      final prefix = responseText.substring(0, 3);
      commandId = _pendingByPrefix[prefix];
      responsePayload = responseText.substring(3).trimLeft();
    }

    commandId ??= _pendingCommands.keys.firstWhere(
      (id) => id.startsWith(repeaterKey),
      orElse: () => '',
    );

    if (commandId.isEmpty) return;

    final completer = _pendingCommands[commandId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(responsePayload);
      _cleanup(commandId);
    }
  }

  void _cleanup(String commandId) {
    _commandTimeouts[commandId]?.cancel();
    _commandTimeouts.remove(commandId);
    _pendingCommands.remove(commandId);
    final prefix = _commandPrefixes.remove(commandId);
    if (prefix != null) {
      _pendingByPrefix.remove(prefix);
    }
  }

  void dispose() {
    for (final timer in _commandTimeouts.values) {
      timer.cancel();
    }
    _commandTimeouts.clear();
    _pendingCommands.clear();
    _commandPrefixes.clear();
    _pendingByPrefix.clear();
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
