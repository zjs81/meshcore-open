import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/path_selection.dart';
import 'app_settings_service.dart';
import 'app_debug_log_service.dart';

class _AckHistoryEntry {
  final String messageId;
  final List<int> ackHashes;
  final DateTime timestamp;

  _AckHistoryEntry({
    required this.messageId,
    required this.ackHashes,
    required this.timestamp,
  });
}

/// (messageId, timestamp, attemptIndex, pathSelection) — stored per ACK hash
/// for O(1) lookup.  [pathSelection] snapshots the route used for this
/// specific attempt so that a late PUSH_CODE_SEND_CONFIRMED credits the
/// correct path even when the message has since been retried on a different
/// route.  Firmware hashes only `attempt & 3`, so attempts N and N+4 of one
/// message share an ACK hash; each hash therefore keeps every attempt that
/// produced it.
typedef AckHashMapping = ({
  String messageId,
  DateTime timestamp,
  int attemptIndex,
  PathSelection? pathSelection,
});

class RetryServiceConfig {
  final FutureOr<void> Function(Contact, String, int, int) sendMessage;
  final void Function(String, Message) addMessage;
  final void Function(Message) updateMessage;
  final Function(Contact)? clearContactPath;
  final Function(Contact, Uint8List, int)? setContactPath;
  final int Function(
    int pathLength,
    int messageBytes, {
    String? contactKey,
    int? deviceTimeoutMs,
  })?
  calculateTimeout;
  final Uint8List? Function()? getSelfPublicKey;
  final String Function(Contact, String)? prepareContactOutboundText;
  final AppSettingsService? appSettingsService;
  final AppDebugLogService? debugLogService;
  final void Function(String, PathSelection, bool, int?)? recordPathResult;
  final void Function(String, int, int, int)? onDeliveryObserved;
  final PathSelection? Function(
    String contactKey,
    int attemptIndex,
    int maxRetries,
    List<PathSelection> recentSelections,
  )?
  selectRetryPath;

  const RetryServiceConfig({
    required this.sendMessage,
    required this.addMessage,
    required this.updateMessage,
    this.clearContactPath,
    this.setContactPath,
    this.calculateTimeout,
    this.getSelfPublicKey,
    this.prepareContactOutboundText,
    this.appSettingsService,
    this.debugLogService,
    this.recordPathResult,
    this.onDeliveryObserved,
    this.selectRetryPath,
  });
}

class MessageRetryService extends ChangeNotifier {
  static const int maxAckHistorySize = 100;

  /// Global cap on concurrent in-flight messages across ALL contacts.
  /// The firmware's expected_ack_table is a single 8-entry circular buffer
  /// shared globally; cap at 6 to leave two slots of headroom.
  static const int _maxGlobalInFlight = 6;

  int _maxRetries = 5;
  int get maxRetries => _maxRetries;

  final Map<String, Timer> _timeoutTimers = {};
  final Map<String, Message> _pendingMessages = {};
  final Map<String, Contact> _pendingContacts = {};
  final Map<String, List<PathSelection>> _attemptPathHistory = {};
  final Map<String, List<AckHashMapping>> _ackHashToMessageId = {};
  final Map<String, List<int>> _expectedAckHashes = {};
  final List<_AckHistoryEntry> _ackHistory = [];
  final Map<String, List<String>> _sendQueue = {};
  final Set<String> _activeMessages = {};
  final Set<String> _resolvedMessages = {};
  final Map<String, String> _expectedHashToMessageId = {};

  RetryServiceConfig? _config;

  /// Extra time allowed for RESP_CODE_SENT on top of the delivery timeout
  /// before an attempt with no SENT reply is treated as timed out.
  final Duration sentWatchdogGrace;

  MessageRetryService({this.sentWatchdogGrace = const Duration(seconds: 5)});

  void initialize(RetryServiceConfig config) {
    _config = config;
  }

  void setMaxRetries(int value) {
    _maxRetries = value.clamp(2, 10);
  }

  /// Compute expected ACK hash using same algorithm as firmware:
  /// SHA256([timestamp(4)][attempt(1)][text][sender_pubkey(32)]) -> first 4 bytes
  static int computeExpectedAckHash(
    int timestampSeconds,
    int attempt,
    String text,
    Uint8List senderPubKey,
  ) {
    final textBytes = utf8.encode(text);
    final buffer = Uint8List(4 + 1 + textBytes.length + senderPubKey.length);
    int offset = 0;

    // timestamp (4 bytes, little-endian)
    buffer[offset++] = timestampSeconds & 0xFF;
    buffer[offset++] = (timestampSeconds >> 8) & 0xFF;
    buffer[offset++] = (timestampSeconds >> 16) & 0xFF;
    buffer[offset++] = (timestampSeconds >> 24) & 0xFF;

    // attempt (1 byte)
    buffer[offset++] = attempt & 0x03;

    // text
    buffer.setRange(offset, offset + textBytes.length, textBytes);
    offset += textBytes.length;

    // sender public key (32 bytes)
    buffer.setRange(offset, offset + senderPubKey.length, senderPubKey);

    // Compute SHA256 and return first 4 bytes
    final hash = sha256.convert(buffer);
    final bytes = Uint8List.fromList(hash.bytes.sublist(0, 4));
    return (bytes[3] << 24) | (bytes[2] << 16) | (bytes[1] << 8) | bytes[0];
  }

  Future<void> sendMessageWithRetry({
    required Contact contact,
    required String text,
    String? originalText,
    String? translatedLanguageCode,
    String? translationModelId,
    Uint8List? pathBytes,
    int? pathLength,
  }) async {
    final messageId = const Uuid().v4();
    final resolved = resolvePathSelection(contact);
    final messagePathBytes =
        pathBytes ?? Uint8List.fromList(resolved.pathBytes);
    final messagePathLength =
        pathLength ?? (resolved.useFlood ? -1 : resolved.hopCount);
    final message = Message(
      senderKey: contact.publicKey,
      text: text,
      originalText: originalText,
      translatedLanguageCode: translatedLanguageCode,
      translationModelId: translationModelId,
      timestamp: DateTime.now(),
      isOutgoing: true,
      status: MessageStatus.pending,
      messageId: messageId,
      retryCount: 0,
      pathLength: messagePathLength,
      pathBytes: messagePathBytes,
    );

    _pendingMessages[messageId] = message;
    _pendingContacts[messageId] = contact;

    _config?.addMessage(contact.publicKeyHex, message);

    // Queue per contact — one message in-flight per contact at a time, and
    // bounded globally by _maxGlobalInFlight across all contacts so we never
    // overflow the firmware's 8-entry global expected_ack_table.
    final contactKey = contact.publicKeyHex;
    _sendQueue[contactKey] ??= [];
    _sendQueue[contactKey]!.add(messageId);

    if (!_activeMessages.any(
      (id) => _pendingContacts[id]?.publicKeyHex == contactKey,
    )) {
      _sendNextForContact(contactKey);
    }
  }

  void _sendNextForContact(String contactKey) {
    // Enforce the global in-flight cap before starting a new send.
    // The firmware's expected_ack_table is a single 8-entry circular buffer
    // shared across all contacts; exceeding it silently evicts an older slot.
    if (_activeMessages.length >= _maxGlobalInFlight) return;

    final queue = _sendQueue[contactKey];
    if (queue == null) return;

    // Drain stale entries iteratively instead of recursing.
    while (queue.isNotEmpty) {
      final messageId = queue.removeAt(0);
      if (_pendingMessages.containsKey(messageId)) {
        _activeMessages.add(messageId);
        _attemptSendOrFail(messageId);
        return;
      }
    }
  }

  void _attemptSendOrFail(String messageId) {
    _attemptSend(messageId).catchError((Object e) {
      debugPrint('_attemptSend threw for $messageId: $e');
      _config?.debugLogService?.warn(
        'Send failed for message $messageId: $e',
        tag: 'AckHash',
      );
      _failMessage(messageId);
    });
  }

  /// Marks a message that could not be handed to the radio as failed and
  /// releases its in-flight slot so the contact's queue keeps moving.
  void _failMessage(String messageId) {
    final message = _pendingMessages[messageId];
    if (message == null) return;
    _timeoutTimers[messageId]?.cancel();
    if (message.status != MessageStatus.failed &&
        message.status != MessageStatus.delivered) {
      _config?.updateMessage(message.copyWith(status: MessageStatus.failed));
    }
    _cleanupMessage(messageId);
    notifyListeners();
  }

  /// Fails every pending and queued message. Call when the radio link drops:
  /// nothing in flight can be sent or acknowledged any more.
  void failAllPending() {
    _sendQueue.clear();
    for (final messageId in _pendingMessages.keys.toList()) {
      _failMessage(messageId);
    }
  }

  void _onMessageResolved(String messageId, String contactKey) {
    if (_resolvedMessages.contains(messageId)) return;
    _resolvedMessages.add(messageId);
    // If cleanup already removed this message from the active set, it has
    // already pumped the queues; avoid double-pumping.
    if (!_activeMessages.remove(messageId)) return;
    _pumpQueues(contactKey);
  }

  void _pumpQueues(String contactKey) {
    // Pump this contact's queue first, then any other contacts that are waiting.
    _sendNextForContact(contactKey);
    for (final key in _sendQueue.keys) {
      if (key == contactKey) continue;
      if (_activeMessages.length >= _maxGlobalInFlight) break;
      final queue = _sendQueue[key];
      if (queue != null && queue.isNotEmpty) {
        _sendNextForContact(key);
      }
    }
  }

  PathSelection? _selectPathForAttempt(Message message, Contact contact) {
    final config = _config;
    if (config == null) return null;
    final autoRotationEnabled =
        config.appSettingsService?.settings.autoRouteRotationEnabled == true;
    if (!autoRotationEnabled ||
        contact.pathOverride != null ||
        config.selectRetryPath == null) {
      return null;
    }

    final recentSelections = List<PathSelection>.from(
      _attemptPathHistory[message.messageId] ?? const <PathSelection>[],
    );
    return config.selectRetryPath!(
      contact.publicKeyHex,
      message.retryCount,
      maxRetries,
      recentSelections,
    );
  }

  void _recordAttemptPathHistory(String messageId, PathSelection selection) {
    if (selection.useFlood) return;
    final history = _attemptPathHistory.putIfAbsent(messageId, () => []);
    history.add(selection);
    if (history.length > recentAttemptDiversityWindow) {
      history.removeAt(0);
    }
  }

  Future<void> _attemptSend(String messageId) async {
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    final config = _config;

    if (message == null || contact == null || config == null) return;

    final currentSelection = _selectPathForAttempt(message, contact);

    if (currentSelection != null) {
      final updatedMessage = message.copyWith(
        pathLength: currentSelection.useFlood ? -1 : currentSelection.hopCount,
        pathBytes: currentSelection.useFlood
            ? Uint8List(0)
            : Uint8List.fromList(currentSelection.pathBytes),
      );
      _pendingMessages[messageId] = updatedMessage;
    } else if (message.retryCount > 0) {
      // No schedule entry for this retry — re-resolve path from current contact
      // state so user's path override changes are picked up between retries.
      final resolved = resolvePathSelection(contact);
      final updatedMessage = message.copyWith(
        pathLength: resolved.useFlood ? -1 : resolved.hopCount,
        pathBytes: Uint8List.fromList(resolved.pathBytes),
      );
      _pendingMessages[messageId] = updatedMessage;
    }

    // Re-read after potential schedule update
    final effectiveMessage = _pendingMessages[messageId] ?? message;

    // Sync path settings with device before sending
    if (config.setContactPath != null && config.clearContactPath != null) {
      final bool useFlood = currentSelection != null
          ? currentSelection.useFlood
          : (effectiveMessage.pathLength != null &&
                effectiveMessage.pathLength! < 0);
      final List<int> pathBytes = currentSelection != null
          ? currentSelection.pathBytes
          : effectiveMessage.pathBytes;
      final int hopCount = currentSelection != null
          ? currentSelection.hopCount
          : (effectiveMessage.pathLength ?? 0);

      if (useFlood) {
        await config.clearContactPath!(contact);
      } else if (effectiveMessage.pathLength != null) {
        await config.setContactPath!(
          contact,
          Uint8List.fromList(pathBytes),
          hopCount,
        );
      }
    }

    // Re-validate after async gap — a timer or ACK could have resolved/retried
    // this message while we were awaiting the path callback.
    final currentMessage = _pendingMessages[messageId];
    if (currentMessage == null || _resolvedMessages.contains(messageId)) {
      debugPrint(
        '_attemptSend: message $messageId resolved during path sync, aborting',
      );
      return;
    }
    if (currentMessage.retryCount != message.retryCount) {
      debugPrint(
        '_attemptSend: message $messageId retryCount changed during path sync, aborting',
      );
      return;
    }

    if (currentSelection != null) {
      _recordAttemptPathHistory(messageId, currentSelection);
    }

    final attempt = message.retryCount;
    final timestampSeconds = message.timestamp.millisecondsSinceEpoch ~/ 1000;

    // Compute expected ACK hash that device will return in RESP_CODE_SENT
    // IMPORTANT: Use the transformed text (with SMAZ encoding if enabled) to match device's hash
    final selfPubKey = config.getSelfPublicKey?.call();
    if (config.getSelfPublicKey != null && selfPubKey == null) {
      throw StateError('Self public key unknown; cannot track ACK');
    }
    String? expectedHashHex;
    if (selfPubKey != null) {
      final outboundText =
          config.prepareContactOutboundText?.call(contact, message.text) ??
          message.text;
      final expectedHash = MessageRetryService.computeExpectedAckHash(
        timestampSeconds,
        attempt,
        outboundText,
        selfPubKey,
      );
      expectedHashHex = expectedHash.toRadixString(16).padLeft(8, '0');
      _expectedHashToMessageId[expectedHashHex] = messageId;

      final shortText = message.text.length > 20
          ? '${message.text.substring(0, 20)}...'
          : message.text;
      config.debugLogService?.info(
        'Sent "$shortText" to ${contact.name} → expect ACK hash $expectedHashHex (attempt $attempt)',
        tag: 'AckHash',
      );
    }

    await config.sendMessage(contact, message.text, attempt, timestampSeconds);
    _startSentWatchdog(messageId, attempt, expectedHashHex);
  }

  /// Arms a timer for an attempt whose RESP_CODE_SENT has not arrived yet.
  /// Without it a lost SENT reply leaves the message pending forever and
  /// blocks the contact's queue. A SENT reply replaces this timer with the
  /// normal ACK timeout via [_startTimeoutTimer].
  void _startSentWatchdog(
    String messageId,
    int attempt,
    String? expectedHashHex,
  ) {
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    if (message == null || contact == null) return;
    if (_resolvedMessages.contains(messageId)) return;
    if (message.retryCount != attempt ||
        message.status != MessageStatus.pending) {
      return; // SENT already arrived, or a newer attempt took over.
    }
    if (_timeoutTimers[messageId]?.isActive ?? false) return;

    final timeoutMs =
        _deliveryTimeoutFor(message, contact) +
        sentWatchdogGrace.inMilliseconds;
    _timeoutTimers[messageId] = Timer(Duration(milliseconds: timeoutMs), () {
      final current = _pendingMessages[messageId];
      if (current == null ||
          current.retryCount != attempt ||
          current.status != MessageStatus.pending) {
        return;
      }
      _config?.debugLogService?.warn(
        'No RESP_CODE_SENT for message $messageId (attempt $attempt) '
        'after ${timeoutMs}ms → treating as timed out',
        tag: 'AckHash',
      );
      if (expectedHashHex != null &&
          _expectedHashToMessageId[expectedHashHex] == messageId) {
        // Drop the SENT expectation so a late SENT for this attempt can't
        // restart timers for the retry; keep the hash ACK-matchable in case
        // the radio did transmit it.
        _expectedHashToMessageId.remove(expectedHashHex);
        _addAckHashMapping(expectedHashHex, messageId, current);
        final hash = int.parse(expectedHashHex, radix: 16);
        final hashes = _expectedAckHashes.putIfAbsent(messageId, () => []);
        if (!hashes.contains(hash)) hashes.add(hash);
      }
      _handleTimeout(messageId);
    });
  }

  int _deliveryTimeoutFor(Message message, Contact contact) {
    final config = _config;
    final calculate = config?.calculateTimeout;
    if (calculate == null) return calculateDefaultTimeout(contact);
    final outboundText =
        config?.prepareContactOutboundText?.call(contact, message.text) ??
        message.text;
    return calculate(
      message.pathLength ?? contact.pathLength,
      utf8.encode(outboundText).length,
      contactKey: contact.publicKeyHex,
    );
  }

  void _addAckHashMapping(
    String ackHashHex,
    String messageId,
    Message message,
  ) {
    final mappings = _ackHashToMessageId.putIfAbsent(ackHashHex, () => []);
    mappings.removeWhere(
      (m) => m.messageId == messageId && m.attemptIndex == message.retryCount,
    );
    mappings.add((
      messageId: messageId,
      timestamp: DateTime.now(),
      attemptIndex: message.retryCount,
      pathSelection: _selectionFromMessage(message),
    ));
  }

  bool updateMessageFromSent(int ackHash, int timeoutMs) {
    // Firmware sets expected_ack = 0 for CLI/command sends (TXT_TYPE_CLI_DATA).
    // No ACK will ever be issued for these, so arming a retry timer is wrong.
    if (ackHash == 0) return false;

    final config = _config;
    if (config == null) return false;

    final ackHashHex = ackHash.toRadixString(16).padLeft(8, '0');

    // Try hash-based matching (fixes LoRa message drops causing mismatches)
    String? messageId = _expectedHashToMessageId.remove(ackHashHex);
    Contact? contact;

    if (messageId != null) {
      contact = _pendingContacts[messageId];
      final message = _pendingMessages[messageId];

      if (contact != null && message != null) {
        final shortText = message.text.length > 20
            ? '${message.text.substring(0, 20)}...'
            : message.text;
        config.debugLogService?.info(
          'RESP_CODE_SENT received: ACK hash $ackHashHex ✓ matched "$shortText" to ${contact.name}',
          tag: 'AckHash',
        );
      } else {
        config.debugLogService?.warn(
          'RESP_CODE_SENT: ACK hash $ackHashHex matched but message no longer pending',
          tag: 'AckHash',
        );
        messageId = null;
        contact = null;
      }
    }

    if (messageId == null || contact == null) {
      debugPrint('No pending message found for ACK hash: $ackHashHex');
      return false;
    }

    final message = _pendingMessages[messageId]!;
    _addAckHashMapping(ackHashHex, messageId, message);

    // Add this ACK hash to the list of expected ACKs for this message (for history)
    _expectedAckHashes[messageId] ??= [];
    if (!_expectedAckHashes[messageId]!.any((hash) => hash == ackHash)) {
      _expectedAckHashes[messageId]!.add(ackHash);
    }

    // Calculate timeout: prefer ML prediction, then device-provided, then physics fallback
    final pathLengthValue = message.pathLength ?? contact.pathLength;
    final outboundTextForTimeout =
        config.prepareContactOutboundText?.call(contact, message.text) ??
        message.text;
    final messageBytesForTimeout = utf8.encode(outboundTextForTimeout).length;

    int actualTimeout = timeoutMs;
    if (config.calculateTimeout != null) {
      actualTimeout = config.calculateTimeout!(
        pathLengthValue,
        messageBytesForTimeout,
        contactKey: contact.publicKeyHex,
        deviceTimeoutMs: timeoutMs > 0 ? timeoutMs : null,
      );
    }

    final updatedMessage = message.copyWith(
      status: MessageStatus.sent,
      expectedAckHash: ackHash,
      estimatedTimeoutMs: actualTimeout,
      sentAt: DateTime.now(),
    );

    _pendingMessages[messageId] = updatedMessage;
    config.updateMessage(updatedMessage);

    _startTimeoutTimer(messageId, actualTimeout);
    return true;
  }

  bool get hasPendingMessages => _pendingMessages.isNotEmpty;

  /// Update the stored contact snapshot for all pending messages to this contact.
  /// Call this when the contact's pathOverride changes so retries use the new path.
  void updatePendingContact(Contact contact) {
    final keys = _pendingContacts.entries
        .where((e) => e.value.publicKeyHex == contact.publicKeyHex)
        .map((e) => e.key)
        .toList();
    for (final key in keys) {
      _pendingContacts[key] = contact;
    }
  }

  void _startTimeoutTimer(String messageId, int timeoutMs) {
    _timeoutTimers[messageId]?.cancel();
    _timeoutTimers[messageId] = Timer(Duration(milliseconds: timeoutMs), () {
      _handleTimeout(messageId);
    });
  }

  void untrack(String messageId) {
    _timeoutTimers[messageId]?.cancel();
    _cleanupMessage(messageId);
  }

  void _cleanupMessage(String messageId) {
    _moveAckHashesToHistory(messageId);
    _ackHashToMessageId.removeWhere((_, mappings) {
      mappings.removeWhere((mapping) => mapping.messageId == messageId);
      return mappings.isEmpty;
    });
    _expectedHashToMessageId.removeWhere((_, msgId) => msgId == messageId);
    final contactKey = _pendingContacts[messageId]?.publicKeyHex;
    _pendingMessages.remove(messageId);
    _pendingContacts.remove(messageId);
    _attemptPathHistory.remove(messageId);
    _timeoutTimers.remove(messageId);
    _resolvedMessages.remove(messageId);
    // Cancellation (and other cleanup paths) must release the active in-flight
    // slot and pump waiting queues so the global cap does not stall forever.
    if (_activeMessages.remove(messageId) && contactKey != null) {
      _pumpQueues(contactKey);
    }
  }

  void _handleTimeout(String messageId) {
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    final config = _config;
    final selection = message != null ? _selectionFromMessage(message) : null;

    if (message == null || contact == null) {
      debugPrint(
        'Timeout fired but message $messageId no longer pending (likely already delivered)',
      );
      return;
    }

    final shortText = message.text.length > 20
        ? '${message.text.substring(0, 20)}...'
        : message.text;
    config?.debugLogService?.warn(
      'Timeout: No ACK received for "$shortText" to ${contact.name} (attempt ${message.retryCount}) → retrying',
      tag: 'AckHash',
    );

    if (message.retryCount < maxRetries - 1 &&
        _textFitsAttempt(message, contact, message.retryCount + 1)) {
      final backoffMs = 1000 * (1 << message.retryCount);

      if (selection != null) {
        _recordPathResultFromMessage(
          contact.publicKeyHex,
          message,
          selection,
          false,
          null,
        );
      }

      final updatedMessage = message.copyWith(
        retryCount: message.retryCount + 1,
        status: MessageStatus.pending,
      );

      _pendingMessages[messageId] = updatedMessage;
      config?.updateMessage(updatedMessage);

      config?.debugLogService?.info(
        'Scheduling retry for "$shortText" to ${contact.name} after ${backoffMs}ms backoff',
        tag: 'AckHash',
      );

      _timeoutTimers[messageId] = Timer(Duration(milliseconds: backoffMs), () {
        if (_pendingMessages.containsKey(messageId)) {
          _attemptSendOrFail(messageId);
        }
      });
    } else {
      // Max retries reached - mark as failed
      final failedMessage = message.copyWith(status: MessageStatus.failed);
      _pendingMessages[messageId] = failedMessage;

      if (config?.appSettingsService?.settings.clearPathOnMaxRetry == true &&
          config?.clearContactPath != null) {
        config!.clearContactPath!(contact);
      }

      _recordPathResultFromMessage(
        contact.publicKeyHex,
        message,
        selection,
        false,
        null,
      );

      config?.updateMessage(failedMessage);

      notifyListeners();

      _onMessageResolved(messageId, contact.publicKeyHex);

      // Keep message in pending maps for 30s grace period so late ACKs
      // can still match and update the message to delivered.
      _timeoutTimers[messageId] = Timer(const Duration(seconds: 30), () {
        _cleanupMessage(messageId);
      });
    }
  }

  /// From attempt 4 on the firmware appends [0][attempt] to the payload and
  /// rejects text longer than MAX_TEXT_LEN - 2 (BaseChatMesh::composeMsgPacket).
  bool _textFitsAttempt(Message message, Contact contact, int attempt) {
    if (attempt <= maxFullLengthTextAttempt) return true;
    final outboundText =
        _config?.prepareContactOutboundText?.call(contact, message.text) ??
        message.text;
    return utf8.encode(outboundText).length <=
        maxTextPayloadBytesAfterFullLengthAttempts;
  }

  void _moveAckHashesToHistory(String messageId) {
    final ackHashes = _expectedAckHashes.remove(messageId);
    if (ackHashes != null && ackHashes.isNotEmpty) {
      _ackHistory.add(
        _AckHistoryEntry(
          messageId: messageId,
          ackHashes: ackHashes,
          timestamp: DateTime.now(),
        ),
      );

      while (_ackHistory.length > maxAckHistorySize) {
        _ackHistory.removeAt(0);
      }
    }
  }

  bool _checkAckHistory(int ackHash) {
    for (final entry in _ackHistory) {
      for (final expectedHash in entry.ackHashes) {
        if (expectedHash == ackHash) {
          return true;
        }
      }
    }
    return false;
  }

  void handleAckReceived(int ackHash, int tripTimeMs) {
    final config = _config;
    String? matchedMessageId;
    int? matchedAttemptIndex;
    PathSelection? matchedPathSelection;
    // True when attempts on different routes share this ACK hash, so the
    // route that delivered it is unknown and must not be credited.
    var ambiguousPath = false;
    final ackHashHex = ackHash.toRadixString(16).padLeft(8, '0');

    // Clean up old ACK hash mappings (older than 15 minutes)
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 15));
    _ackHashToMessageId.removeWhere((_, mappings) {
      mappings.removeWhere((m) => m.timestamp.isBefore(cutoffTime));
      return mappings.isEmpty;
    });

    // Use direct O(1) lookup via ACK hash mapping
    final mappings = _ackHashToMessageId[ackHashHex];
    if (mappings != null && mappings.isNotEmpty) {
      final mapping = mappings.first;
      matchedMessageId = mapping.messageId;
      matchedAttemptIndex = mapping.attemptIndex;
      matchedPathSelection = mapping.pathSelection;
      ambiguousPath = mappings.any(
        (m) =>
            m.messageId != mapping.messageId ||
            !_sameSelection(m.pathSelection, mapping.pathSelection),
      );
    } else {
      config?.debugLogService?.warn(
        'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex not found in direct mapping, trying fallback',
        tag: 'AckHash',
      );
      // Fallback: Check against ALL expected ACK hashes (from all retry attempts)
      for (var entry in _expectedAckHashes.entries) {
        final messageId = entry.key;
        final expectedHashes = entry.value;

        for (final expectedHash in expectedHashes) {
          if (expectedHash == ackHash) {
            matchedMessageId = messageId;
            break;
          }
        }

        if (matchedMessageId != null) break;
      }
    }

    if (matchedMessageId != null) {
      final message = _pendingMessages[matchedMessageId];
      if (message == null) {
        _ackHashToMessageId.remove(ackHashHex);
        return;
      }
      final contact = _pendingContacts[matchedMessageId];
      final ackedAttempt = matchedAttemptIndex ?? message.retryCount;
      final selection = matchedPathSelection ?? _selectionFromMessage(message);

      final shortText = message.text.length > 20
          ? '${message.text.substring(0, 20)}...'
          : message.text;
      config?.debugLogService?.info(
        'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex ✓ "$shortText" delivered to ${contact?.name ?? "unknown"} on attempt $ackedAttempt in ${tripTimeMs}ms',
        tag: 'AckHash',
      );

      _timeoutTimers[matchedMessageId]?.cancel();

      final deliveredMessage = message.copyWith(
        status: MessageStatus.delivered,
        deliveredAt: DateTime.now(),
        tripTimeMs: tripTimeMs,
      );

      final wasAlreadyResolved = _resolvedMessages.contains(matchedMessageId);

      _cleanupMessage(matchedMessageId);

      config?.updateMessage(deliveredMessage);

      if (contact != null) {
        if (!ambiguousPath) {
          _recordPathResultFromMessage(
            contact.publicKeyHex,
            message,
            selection,
            true,
            tripTimeMs,
          );
        }
        // Learn from the attempt this ACK belongs to, not the latest one: a
        // late ACK for a direct attempt can land after a retry went flood.
        if (config?.onDeliveryObserved != null &&
            tripTimeMs > 0 &&
            selection != null &&
            !ambiguousPath) {
          final outboundTextForObserved =
              config!.prepareContactOutboundText?.call(contact, message.text) ??
              message.text;
          final messageBytesForObserved = utf8
              .encode(outboundTextForObserved)
              .length;
          config.onDeliveryObserved!(
            contact.publicKeyHex,
            selection.useFlood ? -1 : selection.hopCount,
            messageBytesForObserved,
            tripTimeMs,
          );
        }
        if (!wasAlreadyResolved) {
          _onMessageResolved(matchedMessageId, contact.publicKeyHex);
        }
      }

      notifyListeners();
    } else {
      if (_checkAckHistory(ackHash)) {
        config?.debugLogService?.info(
          'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex matched a recently completed message (duplicate ACK)',
          tag: 'AckHash',
        );
      } else {
        config?.debugLogService?.error(
          'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex has no matching message!',
          tag: 'AckHash',
        );
        debugPrint('No matching message found for ACK: $ackHashHex');
      }
    }
  }

  String? getContactKeyForAckHash(int ackHash) {
    for (var entry in _pendingMessages.entries) {
      final message = entry.value;
      if (message.expectedAckHash != null &&
          message.expectedAckHash == ackHash) {
        final contact = _pendingContacts[entry.key];
        return contact?.publicKeyHex;
      }
    }
    return null;
  }

  int calculateDefaultTimeout(Contact contact) {
    if (contact.pathLength < 0) {
      return 15000;
    } else {
      return 3000 + (3000 * contact.pathLength);
    }
  }

  void _recordPathResultFromMessage(
    String contactKey,
    Message message,
    PathSelection? selection,
    bool success,
    int? tripTimeMs,
  ) {
    final callback = _config?.recordPathResult;
    if (callback == null) return;
    final recordSelection = selection ?? _selectionFromMessage(message);
    if (recordSelection == null) return;
    callback(contactKey, recordSelection, success, tripTimeMs);
  }

  static bool _sameSelection(PathSelection? a, PathSelection? b) {
    if (a == null || b == null) return a == b;
    return a.useFlood == b.useFlood &&
        a.hopCount == b.hopCount &&
        listEquals(a.pathBytes, b.pathBytes);
  }

  PathSelection? _selectionFromMessage(Message message) {
    if (message.pathLength != null && message.pathLength! < 0) {
      return const PathSelection(pathBytes: [], hopCount: -1, useFlood: true);
    }
    if (message.pathBytes.isEmpty && message.pathLength == null) {
      return null;
    }
    return PathSelection(
      pathBytes: message.pathBytes,
      hopCount: message.pathLength ?? message.pathBytes.length,
      useFlood: false,
    );
  }

  @override
  void dispose() {
    for (var timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();
    _pendingMessages.clear();
    _pendingContacts.clear();
    _attemptPathHistory.clear();
    _expectedAckHashes.clear();
    _ackHistory.clear();
    _ackHashToMessageId.clear();
    _sendQueue.clear();
    _activeMessages.clear();
    _resolvedMessages.clear();
    super.dispose();
  }
}
