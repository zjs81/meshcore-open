import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/path_selection.dart';
import 'app_settings_service.dart';
import 'app_debug_log_service.dart';

class _AckHistoryEntry {
  final String messageId;
  final List<Uint8List> ackHashes;
  final DateTime timestamp;

  _AckHistoryEntry({
    required this.messageId,
    required this.ackHashes,
    required this.timestamp,
  });
}

class _AckHashMapping {
  final String messageId;
  final DateTime timestamp;

  _AckHashMapping({required this.messageId, required this.timestamp});
}

class MessageRetryService extends ChangeNotifier {
  static const int maxRetries = 5;
  static const int maxAckHistorySize = 100;

  final Map<String, Timer> _timeoutTimers = {};
  final Map<String, Message> _pendingMessages = {};
  final Map<String, Contact> _pendingContacts = {};
  final Map<String, PathSelection> _pendingPathSelections = {};
  final Map<String, _AckHashMapping> _ackHashToMessageId =
      {}; // ackHashHex → messageId + timestamp for O(1) lookup
  final Map<String, List<Uint8List>> _expectedAckHashes =
      {}; // Track all expected ACKs for retries (for history)
  final List<_AckHistoryEntry> _ackHistory =
      []; // Rolling buffer of recent ACK hashes
  final Map<String, List<String>> _pendingMessageQueuePerContact =
      {}; // contactPubKeyHex → FIFO queue of messageIds (DEPRECATED - will be removed)
  final Map<String, String> _expectedHashToMessageId =
      {}; // expectedAckHashHex → messageId (for matching RESP_CODE_SENT by hash)

  Function(Contact, String, int, int)? _sendMessageCallback;
  Function(String, Message)? _addMessageCallback;
  Function(Message)? _updateMessageCallback;
  Function(Contact)? _clearContactPathCallback;
  Function(Contact, Uint8List, int)? _setContactPathCallback;
  Function(int, int)? _calculateTimeoutCallback;
  Uint8List? Function()? _getSelfPublicKeyCallback;
  String Function(Contact, String)? _prepareContactOutboundTextCallback;
  AppSettingsService? _appSettingsService;
  AppDebugLogService? _debugLogService;
  Function(String, PathSelection, bool, int?)? _recordPathResultCallback;

  MessageRetryService();

  void initialize({
    required Function(Contact, String, int, int) sendMessageCallback,
    required Function(String, Message) addMessageCallback,
    required Function(Message) updateMessageCallback,
    Function(Contact)? clearContactPathCallback,
    Function(Contact, Uint8List, int)? setContactPathCallback,
    Function(int pathLength, int messageBytes)? calculateTimeoutCallback,
    Uint8List? Function()? getSelfPublicKeyCallback,
    String Function(Contact, String)? prepareContactOutboundTextCallback,
    AppSettingsService? appSettingsService,
    AppDebugLogService? debugLogService,
    Function(String, PathSelection, bool, int?)? recordPathResultCallback,
  }) {
    _sendMessageCallback = sendMessageCallback;
    _addMessageCallback = addMessageCallback;
    _updateMessageCallback = updateMessageCallback;
    _clearContactPathCallback = clearContactPathCallback;
    _setContactPathCallback = setContactPathCallback;
    _calculateTimeoutCallback = calculateTimeoutCallback;
    _getSelfPublicKeyCallback = getSelfPublicKeyCallback;
    _prepareContactOutboundTextCallback = prepareContactOutboundTextCallback;
    _appSettingsService = appSettingsService;
    _debugLogService = debugLogService;
    _recordPathResultCallback = recordPathResultCallback;
  }

  /// Compute expected ACK hash using same algorithm as firmware:
  /// SHA256([timestamp(4)][attempt(1)][text][sender_pubkey(32)]) -> first 4 bytes
  static Uint8List computeExpectedAckHash(
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
    return Uint8List.fromList(hash.bytes.sublist(0, 4));
  }

  Future<void> sendMessageWithRetry({
    required Contact contact,
    required String text,
    PathSelection? pathSelection,
    Uint8List? pathBytes,
    int? pathLength,
  }) async {
    final messageId = const Uuid().v4();
    final useFlood = pathSelection?.useFlood ?? false;
    final messagePathBytes =
        pathBytes ?? _resolveMessagePathBytes(contact, useFlood, pathSelection);
    final messagePathLength =
        pathLength ??
        _resolveMessagePathLength(contact, useFlood, pathSelection);
    final message = Message(
      senderKey: contact.publicKey,
      text: text,
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
    if (pathSelection != null) {
      _pendingPathSelections[messageId] = pathSelection;
    }

    if (_addMessageCallback != null) {
      _addMessageCallback!(contact.publicKeyHex, message);
    }

    await _attemptSend(messageId);
  }

  Future<void> _attemptSend(String messageId) async {
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];

    if (message == null || contact == null) return;

    // Sync path settings with device before sending
    // Use the path that was captured when the message was first sent
    if (_setContactPathCallback != null && _clearContactPathCallback != null) {
      if (message.pathLength != null && message.pathLength! < 0) {
        // Flood mode - clear the path
        debugPrint(
          'Setting flood mode for retry attempt ${message.retryCount}',
        );
        _clearContactPathCallback!(contact);
      } else if (message.pathLength != null && message.pathLength! >= 0) {
        // Specific path (including direct neighbor with pathLength=0)
        final pathStr = message.pathBytes.isEmpty
            ? 'direct'
            : message.pathBytes
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join(',');
        debugPrint(
          'Setting path [$pathStr] (${message.pathLength} hops) for retry attempt ${message.retryCount}',
        );
        await _setContactPathCallback!(
          contact,
          message.pathBytes,
          message.pathLength!,
        );
      }
    }

    final attempt = message.retryCount.clamp(0, 3);
    final timestampSeconds = message.timestamp.millisecondsSinceEpoch ~/ 1000;

    // Compute expected ACK hash that device will return in RESP_CODE_SENT
    // IMPORTANT: Use the transformed text (with SMAZ encoding if enabled) to match device's hash
    final selfPubKey = _getSelfPublicKeyCallback?.call();
    if (selfPubKey != null) {
      final outboundText =
          _prepareContactOutboundTextCallback?.call(contact, message.text) ??
          message.text;
      final expectedHash = MessageRetryService.computeExpectedAckHash(
        timestampSeconds,
        attempt,
        outboundText,
        selfPubKey,
      );
      final expectedHashHex = expectedHash
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      _expectedHashToMessageId[expectedHashHex] = messageId;

      final shortText = message.text.length > 20
          ? '${message.text.substring(0, 20)}...'
          : message.text;
      _debugLogService?.info(
        'Sent "$shortText" to ${contact.name} → expect ACK hash $expectedHashHex (attempt $attempt)',
        tag: 'AckHash',
      );
      debugPrint(
        'Computed expected ACK hash $expectedHashHex for message $messageId',
      );
    }

    // DEPRECATED: Old queue-based matching (kept for fallback)
    _pendingMessageQueuePerContact[contact.publicKeyHex] ??= [];
    _pendingMessageQueuePerContact[contact.publicKeyHex]!.add(messageId);

    if (_sendMessageCallback != null) {
      _sendMessageCallback!(contact, message.text, attempt, timestampSeconds);
    }
  }

  bool updateMessageFromSent(
    Uint8List ackHash,
    int timeoutMs, {
    bool allowQueueFallback = true,
  }) {
    final ackHashHex = ackHash
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    // NEW: Try hash-based matching first (fixes LoRa message drops causing mismatches)
    String? messageId = _expectedHashToMessageId.remove(ackHashHex);
    Contact? contact;

    if (messageId != null) {
      contact = _pendingContacts[messageId];
      final message = _pendingMessages[messageId];

      if (contact != null && message != null) {
        final shortText = message.text.length > 20
            ? '${message.text.substring(0, 20)}...'
            : message.text;
        _debugLogService?.info(
          'RESP_CODE_SENT received: ACK hash $ackHashHex ✓ matched "$shortText" to ${contact.name}',
          tag: 'AckHash',
        );
        debugPrint(
          'Hash-based match: ACK hash $ackHashHex → message $messageId ✓',
        );

        // Remove from old queue since we matched
        _pendingMessageQueuePerContact[contact.publicKeyHex]?.remove(messageId);
        if (_pendingMessageQueuePerContact[contact.publicKeyHex]?.isEmpty ??
            false) {
          _pendingMessageQueuePerContact.remove(contact.publicKeyHex);
        }
      } else {
        _debugLogService?.warn(
          'RESP_CODE_SENT: ACK hash $ackHashHex matched but message no longer pending',
          tag: 'AckHash',
        );
        debugPrint('Hash matched $messageId but message no longer pending');
        messageId = null;
        contact = null;
      }
    }

    // FALLBACK: Old queue-based matching (for messages sent before hash computation was added)
    if (messageId == null && allowQueueFallback) {
      _debugLogService?.warn(
        'RESP_CODE_SENT: ACK hash $ackHashHex not found in hash table, falling back to queue',
        tag: 'AckHash',
      );
      debugPrint(
        'Hash-based match failed for $ackHashHex, falling back to queue-based matching',
      );

      for (var entry in _pendingMessageQueuePerContact.entries) {
        final contactKey = entry.key;
        final queue = entry.value;

        if (queue.isNotEmpty) {
          final candidateMessageId = queue.removeAt(0);

          if (_pendingMessages.containsKey(candidateMessageId)) {
            messageId = candidateMessageId;
            contact = _pendingContacts[candidateMessageId];
            debugPrint(
              'Queue-based match (fallback): $ackHashHex → message $messageId for $contactKey',
            );
            break;
          } else {
            debugPrint('Dequeued stale message $candidateMessageId - skipping');
            if (queue.isNotEmpty) {
              final nextMessageId = queue.removeAt(0);
              if (_pendingMessages.containsKey(nextMessageId)) {
                messageId = nextMessageId;
                contact = _pendingContacts[nextMessageId];
                debugPrint(
                  'Queue-based match (fallback): $ackHashHex → message $messageId',
                );
                break;
              }
            }
          }
        }
      }
    }

    if (messageId == null || contact == null) {
      debugPrint('No pending message found for ACK hash: $ackHashHex');
      return false;
    }

    // Store the mapping for future lookups (e.g., when ACK arrives)
    // Keep timestamp so we can clean up old mappings later
    _ackHashToMessageId[ackHashHex] = _AckHashMapping(
      messageId: messageId,
      timestamp: DateTime.now(),
    );
    debugPrint('Mapped ACK hash $ackHashHex to message $messageId');

    final message = _pendingMessages[messageId];
    final selection = _pendingPathSelections[messageId];

    if (message == null) {
      debugPrint(
        'Message $messageId no longer pending for ACK hash: $ackHashHex',
      );
      _ackHashToMessageId.remove(ackHashHex);
      return false;
    }

    // Add this ACK hash to the list of expected ACKs for this message (for history)
    _expectedAckHashes[messageId] ??= [];
    if (!_expectedAckHashes[messageId]!.any(
      (hash) => listEquals(hash, ackHash),
    )) {
      _expectedAckHashes[messageId]!.add(Uint8List.fromList(ackHash));
      debugPrint(
        'Added ACK hash $ackHashHex to message $messageId (total: ${_expectedAckHashes[messageId]!.length})',
      );
    }

    // Use device-provided timeout, or calculate from radio settings if timeout is 0 or invalid
    int actualTimeout = timeoutMs;
    if (timeoutMs <= 0 && _calculateTimeoutCallback != null) {
      int pathLengthValue;
      if (selection != null) {
        pathLengthValue = selection.useFlood ? -1 : selection.hopCount;
        if (pathLengthValue < 0) pathLengthValue = contact.pathLength;
      } else if (message.pathLength != null) {
        pathLengthValue = message.pathLength!;
      } else {
        pathLengthValue = contact.pathLength;
      }
      actualTimeout = _calculateTimeoutCallback!(
        pathLengthValue,
        message.text.length,
      );
      debugPrint(
        'Using calculated timeout: ${actualTimeout}ms for path length $pathLengthValue',
      );
    }

    final updatedMessage = message.copyWith(
      status: MessageStatus.sent,
      expectedAckHash: ackHash,
      estimatedTimeoutMs: actualTimeout,
      sentAt: DateTime.now(),
    );

    _pendingMessages[messageId] = updatedMessage;

    if (_updateMessageCallback != null) {
      _updateMessageCallback!(updatedMessage);
    }

    _startTimeoutTimer(messageId, actualTimeout);
    debugPrint('Updated message $messageId with ACK hash: $ackHashHex');
    return true;
  }

  bool get hasPendingMessages => _pendingMessages.isNotEmpty;

  bool hasExpectedAckHash(Uint8List ackHash) {
    final ackHashHex = ackHash
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return _expectedHashToMessageId.containsKey(ackHashHex) ||
        _ackHashToMessageId.containsKey(ackHashHex);
  }

  void _startTimeoutTimer(String messageId, int timeoutMs) {
    _timeoutTimers[messageId]?.cancel();
    _timeoutTimers[messageId] = Timer(Duration(milliseconds: timeoutMs), () {
      _handleTimeout(messageId);
    });
  }

  void _handleTimeout(String messageId) {
    final message = _pendingMessages[messageId];
    final contact = _pendingContacts[messageId];
    final selection = _pendingPathSelections[messageId];

    if (message == null || contact == null) {
      debugPrint(
        'Timeout fired but message $messageId no longer pending (likely already delivered)',
      );
      return;
    }

    final shortText = message.text.length > 20
        ? '${message.text.substring(0, 20)}...'
        : message.text;
    _debugLogService?.warn(
      'Timeout: No ACK received for "$shortText" to ${contact.name} (attempt ${message.retryCount}) → retrying',
      tag: 'AckHash',
    );
    debugPrint(
      'Timeout for message $messageId (retry ${message.retryCount}/${maxRetries - 1})',
    );

    if (message.retryCount < maxRetries - 1) {
      final backoffMs = 1000 * (1 << message.retryCount);

      final updatedMessage = message.copyWith(
        retryCount: message.retryCount + 1,
        status: MessageStatus.pending,
        // Keep expectedAckHash - it will be updated when the new attempt is sent
      );

      _pendingMessages[messageId] = updatedMessage;

      if (_updateMessageCallback != null) {
        _updateMessageCallback!(updatedMessage);
      }

      _debugLogService?.info(
        'Scheduling retry for "$shortText" to ${contact.name} after ${backoffMs}ms backoff',
        tag: 'AckHash',
      );
      debugPrint('Scheduling retry after ${backoffMs}ms');

      // Store the backoff timer so it can be canceled if new RESP_CODE_SENT arrives
      _timeoutTimers[messageId] = Timer(Duration(milliseconds: backoffMs), () {
        // Double-check message is still pending before retry
        if (_pendingMessages.containsKey(messageId)) {
          _attemptSend(messageId);
        } else {
          debugPrint(
            'Retry cancelled: message $messageId was delivered while waiting',
          );
        }
      });
    } else {
      // Max retries reached - mark as failed
      final failedMessage = message.copyWith(status: MessageStatus.failed);

      // Move ACK hashes to history before removing
      _moveAckHashesToHistory(messageId);

      _pendingMessages.remove(messageId);
      _pendingContacts.remove(messageId);
      _pendingPathSelections.remove(messageId);
      _timeoutTimers[messageId]?.cancel();
      _timeoutTimers.remove(messageId);

      // Clean up the queue entry for this contact
      _pendingMessageQueuePerContact[contact.publicKeyHex]?.remove(messageId);
      if (_pendingMessageQueuePerContact[contact.publicKeyHex]?.isEmpty ??
          false) {
        _pendingMessageQueuePerContact.remove(contact.publicKeyHex);
      }

      // Check if we should clear the path on max retry
      if (_appSettingsService?.settings.clearPathOnMaxRetry == true &&
          _clearContactPathCallback != null) {
        _clearContactPathCallback!(contact);
      }

      _recordPathResultFromMessage(
        contact.publicKeyHex,
        message,
        selection,
        false,
        null,
      );

      if (_updateMessageCallback != null) {
        _updateMessageCallback!(failedMessage);
      }

      notifyListeners();
    }
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

      // Trim history to max size (rolling buffer)
      while (_ackHistory.length > maxAckHistorySize) {
        _ackHistory.removeAt(0);
      }

      debugPrint(
        'Moved ${ackHashes.length} ACK hashes to history for message $messageId (history size: ${_ackHistory.length})',
      );
    }
  }

  bool _checkAckHistory(Uint8List ackHash) {
    for (final entry in _ackHistory) {
      for (final expectedHash in entry.ackHashes) {
        if (listEquals(expectedHash, ackHash)) {
          debugPrint(
            'Found ACK match in history: messageId=${entry.messageId}, age=${DateTime.now().difference(entry.timestamp).inSeconds}s',
          );
          return true;
        }
      }
    }
    return false;
  }

  void handleAckReceived(Uint8List ackHash, int tripTimeMs) {
    String? matchedMessageId;
    final ackHashHex = ackHash
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    debugPrint('ACK received: $ackHashHex, trip time: ${tripTimeMs}ms');

    // First, clean up old ACK hash mappings (older than 15 minutes)
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 15));
    final hashesToRemove = <String>[];
    for (var entry in _ackHashToMessageId.entries) {
      if (entry.value.timestamp.isBefore(cutoffTime)) {
        hashesToRemove.add(entry.key);
      }
    }
    for (var hash in hashesToRemove) {
      _ackHashToMessageId.remove(hash);
    }
    if (hashesToRemove.isNotEmpty) {
      debugPrint('Cleaned up ${hashesToRemove.length} old ACK hash mappings');
    }

    // Use direct O(1) lookup via ACK hash mapping
    final mapping = _ackHashToMessageId[ackHashHex];
    if (mapping != null) {
      matchedMessageId = mapping.messageId;
      debugPrint('Matched ACK to message via direct lookup: $matchedMessageId');
    } else {
      _debugLogService?.warn(
        'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex not found in direct mapping, trying fallback',
        tag: 'AckHash',
      );
      // Fallback: Check against ALL expected ACK hashes (from all retry attempts)
      debugPrint(
        'ACK not in mapping, checking _expectedAckHashes (${_expectedAckHashes.length} messages)',
      );
      for (var entry in _expectedAckHashes.entries) {
        final messageId = entry.key;
        final expectedHashes = entry.value;

        for (final expectedHash in expectedHashes) {
          if (listEquals(expectedHash, ackHash)) {
            matchedMessageId = messageId;
            debugPrint(
              'Matched ACK to message via fallback: $matchedMessageId (attempt ${expectedHashes.indexOf(expectedHash)})',
            );
            break;
          }
        }

        if (matchedMessageId != null) break;
      }
    }

    if (matchedMessageId != null) {
      final message = _pendingMessages[matchedMessageId]!;
      final contact = _pendingContacts[matchedMessageId];
      final selection = _pendingPathSelections[matchedMessageId];

      final shortText = message.text.length > 20
          ? '${message.text.substring(0, 20)}...'
          : message.text;
      _debugLogService?.info(
        'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex ✓ "$shortText" delivered to ${contact?.name ?? "unknown"} in ${tripTimeMs}ms',
        tag: 'AckHash',
      );

      // Cancel any pending timeout or retry
      _timeoutTimers[matchedMessageId]?.cancel();
      _timeoutTimers.remove(matchedMessageId);

      final deliveredMessage = message.copyWith(
        status: MessageStatus.delivered,
        deliveredAt: DateTime.now(),
        tripTimeMs: tripTimeMs,
      );

      // Move ACK hashes to history before removing
      _moveAckHashesToHistory(matchedMessageId);

      _pendingMessages.remove(matchedMessageId);
      _pendingContacts.remove(matchedMessageId);
      _pendingPathSelections.remove(matchedMessageId);

      // Clean up the queue entry for this contact (remove any remaining references to this message)
      if (contact != null) {
        _pendingMessageQueuePerContact[contact.publicKeyHex]?.remove(
          matchedMessageId,
        );
        if (_pendingMessageQueuePerContact[contact.publicKeyHex]?.isEmpty ??
            false) {
          _pendingMessageQueuePerContact.remove(contact.publicKeyHex);
        }
      }

      if (_updateMessageCallback != null) {
        _updateMessageCallback!(deliveredMessage);
      }

      if (contact != null) {
        _recordPathResultFromMessage(
          contact.publicKeyHex,
          message,
          selection,
          true,
          tripTimeMs,
        );
      }

      notifyListeners();
    } else {
      // Check ACK history for recently completed messages
      if (_checkAckHistory(ackHash)) {
        _debugLogService?.info(
          'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex matched a recently completed message (duplicate ACK)',
          tag: 'AckHash',
        );
        debugPrint('ACK matched a recently completed message from history');
      } else {
        _debugLogService?.error(
          'PUSH_CODE_SEND_CONFIRMED: ACK hash $ackHashHex has no matching message!',
          tag: 'AckHash',
        );
        debugPrint('No matching message found for ACK: $ackHashHex');
      }
    }
  }

  Uint8List _resolveMessagePathBytes(
    Contact contact,
    bool forceFlood,
    PathSelection? selection,
  ) {
    // Priority 1: Check user's path override
    if (contact.pathOverride != null) {
      if (contact.pathOverride! < 0) {
        return Uint8List(0); // Force flood
      }
      return contact.pathOverrideBytes ?? Uint8List(0);
    }

    // Priority 2: Check forceFlood or device flood mode
    if (forceFlood || contact.pathLength < 0 || selection?.useFlood == true) {
      return Uint8List(0);
    }

    // Priority 3: Check PathSelection (auto-rotation)
    if (selection != null && selection.pathBytes.isNotEmpty) {
      return Uint8List.fromList(selection.pathBytes);
    }

    // Priority 4: Use device's discovered path
    return contact.path;
  }

  int? _resolveMessagePathLength(
    Contact contact,
    bool forceFlood,
    PathSelection? selection,
  ) {
    // Priority 1: Check user's path override
    if (contact.pathOverride != null) {
      return contact.pathOverride;
    }

    // Priority 2: Check forceFlood or device flood mode
    if (forceFlood || contact.pathLength < 0 || selection?.useFlood == true) {
      return -1;
    }

    // Priority 3: Check PathSelection (auto-rotation)
    if (selection != null && selection.pathBytes.isNotEmpty) {
      return selection.hopCount;
    }

    // Priority 4: Use device's discovered path
    return contact.pathLength;
  }

  String? getContactKeyForAckHash(Uint8List ackHash) {
    for (var entry in _pendingMessages.entries) {
      final message = entry.value;
      if (message.expectedAckHash != null &&
          listEquals(message.expectedAckHash, ackHash)) {
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
    if (_recordPathResultCallback == null) return;
    final recordSelection = selection ?? _selectionFromMessage(message);
    if (recordSelection == null) return;
    _recordPathResultCallback!(
      contactKey,
      recordSelection,
      success,
      tripTimeMs,
    );
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
    _pendingPathSelections.clear();
    _expectedAckHashes.clear();
    _ackHistory.clear();
    _ackHashToMessageId.clear();
    _pendingMessageQueuePerContact.clear();
    super.dispose();
  }
}
