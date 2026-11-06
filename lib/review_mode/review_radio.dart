import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../connector/meshcore_protocol.dart';
import '../connector/pending_command_replies.dart';
import '../services/message_retry_service.dart';
import 'review_frames.dart';
import 'review_script.dart';

/// A simulated MeshCore radio that speaks the companion binary protocol.
class ReviewRadio {
  ReviewRadio({
    this.scheduledMessageInterval = const Duration(seconds: 45),
    this.ackDelay = const Duration(milliseconds: 1500),
    this.replyDelay = const Duration(seconds: 4),
    this.firmwareVerCode = ReviewScript.firmwareVerCode,
  }) {
    _seedState();
  }

  /// 64 lowercase hex chars, fixed and obviously fake.
  static const String selfPublicKeyHex =
      'ee5e04b332b386b6cce8355ccf27fffd3a98b7a7a5b9b3a550c039c6ebae38e4';

  /// First 10 hex chars of [selfPublicKeyHex], the per-radio storage scope.
  static String get storagePrefix => selfPublicKeyHex.substring(0, 10);

  final Duration scheduledMessageInterval;
  final Duration ackDelay;
  final Duration replyDelay;

  /// FIRMWARE_VER_CODE reported in DEVICE_INFO (tests use older values to
  /// exercise version gates).
  final int firmwareVerCode;

  // Default flood scope (CMD_SET/GET_DEFAULT_FLOOD_SCOPE): name field + key.
  Uint8List? _defaultFloodScope;

  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>.broadcast();
  final List<Uint8List> _outbox = [];
  final Set<Timer> _timers = {};
  final List<Uint8List> _messageQueue = [];
  final List<_Contact> _contacts = [];
  final Map<int, _Channel> _channels = {};
  final Uint8List _selfKey = hexToPubKey(selfPublicKeyHex);

  Timer? _flushTimer;
  Timer? _scheduledTimer;
  bool _disposed = false;
  bool _nextScheduledIsDirect = true;
  int _directPoolIndex = 0;
  int _channelPoolIndex = 0;
  int _directReplyIndex = 0;
  int _channelReplyIndex = 0;

  String _name = ReviewScript.selfName;
  int _latitudeE6 = ReviewScript.selfLatitudeE6;
  int _longitudeE6 = ReviewScript.selfLongitudeE6;
  int _frequencyHz = ReviewScript.frequencyHz;
  int _bandwidthHz = ReviewScript.bandwidthHz;
  int _spreadingFactor = ReviewScript.spreadingFactor;
  int _codingRate = ReviewScript.codingRate;
  int _txPowerDbm = ReviewScript.txPowerDbm;
  int _autoAddFlags =
      autoAddChatFlag | autoAddRepeaterFlag | autoAddRoomServerFlag;
  int _timeOffsetSecs = 0;

  /// Frames radio to app. Each event is one complete companion frame.
  Stream<Uint8List> get frames => _controller.stream;

  int get _nowSecs =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + _timeOffsetSecs;

  void _seedState() {
    final now = _nowSecs;
    for (final c in ReviewScript.contacts) {
      _contacts.add(
        _Contact(
          publicKey: hexToPubKey(c.publicKeyHex),
          type: c.type,
          path: c.pathHex.isEmpty ? Uint8List(0) : hex2Uint8List(c.pathHex),
          name: c.name,
          lastAdvertSecs: now - c.lastAdvertAgoSecs,
          latitudeE6: (c.latitude * 1e6).round(),
          longitudeE6: (c.longitude * 1e6).round(),
          lastModSecs: now,
        ),
      );
    }
    for (final c in ReviewScript.channels) {
      _channels[c.index] = _Channel(c.name, hex2Uint8List(c.pskHex));
    }

    final history = <_SeedEntry>[
      for (final m in ReviewScript.seedDirectMessages)
        _SeedEntry(
          m.agoSecs,
          ReviewFrames.contactMessage(
            senderPublicKey: _contacts[m.contactIndex].publicKey,
            text: m.text,
            timestampSecs: now - m.agoSecs,
            pathLen: ReviewScript.contacts[m.contactIndex].hopCount,
          ),
        ),
      for (final m in ReviewScript.seedChannelMessages)
        _SeedEntry(
          m.agoSecs,
          ReviewFrames.channelMessage(
            channelIndex: m.channelIndex,
            sender: m.sender,
            message: m.text,
            timestampSecs: now - m.agoSecs,
            path: _pathForSender(m.sender),
          ),
        ),
    ]..sort((a, b) => b.agoSecs.compareTo(a.agoSecs));
    for (final entry in history) {
      _messageQueue.add(entry.frame);
    }
  }

  Uint8List? _pathForSender(String sender) {
    for (final c in _contacts) {
      if (c.name == sender && c.path.isNotEmpty) return c.path;
    }
    return null;
  }

  /// Starts the scheduled incoming-message timer.
  void start() {
    if (_disposed || _scheduledTimer != null) return;
    _scheduledTimer = Timer.periodic(scheduledMessageInterval, (_) {
      _enqueueScheduledMessage();
    });
  }

  /// Immediately queues one incoming message and pushes MSG_WAITING.
  void sendTestMessage() {
    if (_disposed) return;
    _enqueueScheduledMessage();
  }

  void _enqueueScheduledMessage() {
    if (_disposed) return;
    final now = _nowSecs;
    if (_nextScheduledIsDirect) {
      final pool = ReviewScript.incomingDirectPool;
      final line = pool[_directPoolIndex++ % pool.length];
      _messageQueue.add(
        ReviewFrames.contactMessage(
          senderPublicKey: _contacts[line.contactIndex].publicKey,
          text: line.text,
          timestampSecs: now,
          pathLen: ReviewScript.contacts[line.contactIndex].hopCount,
        ),
      );
    } else {
      final pool = ReviewScript.incomingChannelPool;
      final line = pool[_channelPoolIndex++ % pool.length];
      _messageQueue.add(
        ReviewFrames.channelMessage(
          channelIndex: line.channelIndex,
          sender: line.sender,
          message: line.text,
          timestampSecs: now,
          path: _pathForSender(line.sender),
        ),
      );
    }
    _nextScheduledIsDirect = !_nextScheduledIsDirect;
    _emit([ReviewFrames.msgWaiting()]);
  }

  /// Frame app to radio. Responses are emitted asynchronously.
  void handle(Uint8List frame) {
    if (_disposed || frame.isEmpty) return;
    final code = frame[0];
    switch (code) {
      case cmdDeviceQuery:
        _emit([
          ReviewFrames.deviceInfo(
            firmwareVerCode: firmwareVerCode,
            maxContacts: ReviewScript.maxContacts,
            maxChannels: ReviewScript.maxChannels,
          ),
        ]);
        break;
      case cmdAppStart:
        _emit([_selfInfoFrame()]);
        break;
      case cmdGetContacts:
        _handleGetContacts(frame);
        break;
      case cmdGetContactByKey:
        _handleGetContactByKey(frame);
        break;
      case cmdGetChannel:
        _handleGetChannel(frame);
        break;
      case cmdSetChannel:
        _handleSetChannel(frame);
        break;
      case cmdSyncNextMessage:
        _emit([
          _messageQueue.isEmpty
              ? ReviewFrames.noMoreMessages()
              : _messageQueue.removeAt(0),
        ]);
        break;
      case cmdSendTxtMsg:
        _handleSendText(frame);
        break;
      case cmdSendChannelTxtMsg:
        _handleSendChannelText(frame);
        break;
      case cmdGetBattAndStorage:
        _emit([
          ReviewFrames.battAndStorage(
            millivolts: 3980,
            usedKb: 412,
            totalKb: 1792,
          ),
        ]);
        break;
      case cmdGetDeviceTime:
        _emit([ReviewFrames.currTime(_nowSecs)]);
        break;
      case cmdSetDeviceTime:
        if (frame.length >= 5) {
          _timeOffsetSecs =
              readUint32LE(frame, 1) -
              DateTime.now().millisecondsSinceEpoch ~/ 1000;
        }
        _emit([ReviewFrames.ok()]);
        break;
      case cmdGetCustomVar:
        _emit([ReviewFrames.customVars('gps:0')]);
        break;
      case cmdGetAutoAddConfig:
        _emit([ReviewFrames.autoAddConfig(flags: _autoAddFlags)]);
        break;
      case cmdSetAutoAddConfig:
        if (frame.length >= 2) _autoAddFlags = frame[1];
        _emit([ReviewFrames.ok()]);
        break;
      case cmdGetAllowedRepeatFreq:
        _emit([
          ReviewFrames.allowedRepeatFreq(const [
            (lowKHz: 433000, highKHz: 433000),
            (lowKHz: 869000, highKHz: 869000),
            (lowKHz: 918000, highKHz: 918000),
          ]),
        ]);
        break;
      case cmdGetDefaultFloodScope when firmwareVerCode < 11:
      case cmdSetDefaultFloodScope when firmwareVerCode < 11:
        _emit([ReviewFrames.err()]);
        break;
      case cmdGetDefaultFloodScope:
        _emit([
          Uint8List.fromList([
            respCodeDefaultFloodScope,
            ...?_defaultFloodScope,
          ]),
        ]);
        break;
      case cmdSetDefaultFloodScope:
        _defaultFloodScope =
            frame.length >= 1 + defaultFloodScopeNameSize + floodScopeKeySize
            ? Uint8List.fromList(frame.sublist(1))
            : null;
        _emit([ReviewFrames.ok()]);
        break;
      case cmdGetStats:
        _emit([
          frame.length >= 2 && frame[1] == statsTypeRadio
              ? ReviewFrames.radioStats(
                  noiseFloorDbm: -112,
                  lastRssiDbm: -78,
                  lastSnrQuarterDb: 28,
                  txAirSecs: 12,
                  rxAirSecs: 48,
                )
              : ReviewFrames.err(),
        ]);
        break;
      case cmdSetAdvertName:
        _name = _readCString(frame, 1, maxNameSize - 1);
        _emit([ReviewFrames.ok()]);
        break;
      case cmdSetAdvertLatLon:
        if (frame.length >= 9) {
          _latitudeE6 = readInt32LE(frame, 1);
          _longitudeE6 = readInt32LE(frame, 5);
        }
        _emit([ReviewFrames.ok()]);
        break;
      case cmdSetRadioParams:
        if (frame.length >= 11) {
          _frequencyHz = readUint32LE(frame, 1);
          _bandwidthHz = readUint32LE(frame, 5);
          _spreadingFactor = frame[9];
          _codingRate = frame[10];
        }
        _emit([ReviewFrames.ok()]);
        break;
      case cmdSetRadioTxPower:
        if (frame.length >= 2) _txPowerDbm = frame[1];
        _emit([ReviewFrames.ok()]);
        break;
      case cmdRemoveContact:
        if (frame.length >= 1 + pubKeySize) {
          final key = frame.sublist(1, 1 + pubKeySize);
          _contacts.removeWhere((c) => listEquals(c.publicKey, key));
        }
        _emit([ReviewFrames.ok()]);
        break;
      case cmdSendLogin:
        _handleLogin(frame);
        break;
      case cmdSendStatusReq:
      case cmdSendTracePath:
      case cmdSendBinaryReq:
      case cmdSendAnonReq:
        _emit([ReviewFrames.err()]);
        break;
      case cmdSendControlData:
        _emit([ReviewFrames.ok()]);
        _handleNodeDiscover(frame);
        break;
      case cmdSendTelemetryReq:
        // The 4-byte "self" form is answered with a push the app does not
        // track; remote requests are answered with ERR.
        if (frame.length > 4) _emit([ReviewFrames.err()]);
        break;
      default:
        // Setters, advert, reset path, flood scope, import/export and any
        // other command the app tracks get OK; untracked ones get nothing.
        final reply = replyCodeForCommand(frame);
        if (reply == respCodeOk) {
          _emit([ReviewFrames.ok()]);
        } else if (reply != null) {
          _emit([ReviewFrames.err()]);
        }
    }
  }

  Uint8List _selfInfoFrame() => ReviewFrames.selfInfo(
    publicKey: _selfKey,
    name: _name,
    latitudeE6: _latitudeE6,
    longitudeE6: _longitudeE6,
    frequencyHz: _frequencyHz,
    bandwidthHz: _bandwidthHz,
    spreadingFactor: _spreadingFactor,
    codingRate: _codingRate,
    txPowerDbm: _txPowerDbm,
    maxTxPowerDbm: ReviewScript.maxTxPowerDbm,
  );

  Uint8List _contactFrame(_Contact c) => ReviewFrames.contact(
    publicKey: c.publicKey,
    type: c.type,
    path: c.path,
    name: c.name,
    lastAdvertSecs: c.lastAdvertSecs,
    latitudeE6: c.latitudeE6,
    longitudeE6: c.longitudeE6,
    lastModSecs: c.lastModSecs,
  );

  void _handleGetContacts(Uint8List frame) {
    final since = frame.length >= 5 ? readUint32LE(frame, 1) : 0;
    final matching = _contacts.where((c) => c.lastModSecs > since).toList();
    var mostRecent = since;
    for (final c in matching) {
      if (c.lastModSecs > mostRecent) mostRecent = c.lastModSecs;
    }
    _emit([
      ReviewFrames.contactsStart(_contacts.length),
      for (final c in matching) _contactFrame(c),
      ReviewFrames.endOfContacts(mostRecent),
    ]);
  }

  void _handleGetContactByKey(Uint8List frame) {
    if (frame.length >= 1 + pubKeySize) {
      final key = frame.sublist(1, 1 + pubKeySize);
      for (final c in _contacts) {
        if (listEquals(c.publicKey, key)) {
          _emit([_contactFrame(c)]);
          return;
        }
      }
    }
    _emit([ReviewFrames.err(ReviewFrames.errNotFound)]);
  }

  void _handleGetChannel(Uint8List frame) {
    final index = frame.length >= 2 ? frame[1] : 0;
    if (index >= ReviewScript.maxChannels) {
      _emit([ReviewFrames.err(ReviewFrames.errNotFound)]);
      return;
    }
    final channel = _channels[index];
    _emit([
      ReviewFrames.channelInfo(
        index: index,
        name: channel?.name ?? '',
        psk: channel?.psk ?? Uint8List(16),
      ),
    ]);
  }

  void _handleSetChannel(Uint8List frame) {
    // [cmd][idx][name x32][psk x16]
    if (frame.length >= 50) {
      final index = frame[1];
      final name = _readCString(frame, 2, 32);
      final psk = Uint8List.fromList(frame.sublist(34, 50));
      if (name.isEmpty && psk.every((b) => b == 0)) {
        _channels.remove(index);
      } else {
        _channels[index] = _Channel(name, psk);
      }
    }
    _emit([ReviewFrames.ok()]);
  }

  void _handleSendText(Uint8List frame) {
    // [cmd][txt_type][attempt][timestamp x4][pub_key_prefix x6][text...]\0
    if (frame.length < 13) {
      _emit([ReviewFrames.err()]);
      return;
    }
    final attempt = frame[2];
    final timestamp = readUint32LE(frame, 3);
    final prefix = frame.sublist(7, 13);
    final text = _readCString(frame, 13, frame.length - 13);

    final contact = _contactByPrefix(prefix);
    if (contact == null) {
      _emit([ReviewFrames.err(ReviewFrames.errNotFound)]);
      return;
    }

    final ackHash = MessageRetryService.computeExpectedAckHash(
      timestamp,
      attempt,
      text,
      _selfKey,
    );
    final tripMs = ackDelay.inMilliseconds;
    _emit([
      ReviewFrames.sent(
        // Every simulated contact has a known path; an empty one is a
        // direct neighbour, so sends are never flooded.
        flood: false,
        ackHash: ackHash,
        timeoutMs: 8000,
      ),
    ]);
    _later(ackDelay, () {
      _emit([ReviewFrames.sendConfirmed(ackHash: ackHash, tripTimeMs: tripMs)]);
    });

    if (contact.type == advTypeChat || contact.type == advTypeRoom) {
      _later(ackDelay + replyDelay, () {
        final replies = ReviewScript.directReplies;
        _messageQueue.add(
          ReviewFrames.contactMessage(
            senderPublicKey: contact.publicKey,
            text: replies[_directReplyIndex++ % replies.length],
            timestampSecs: _nowSecs,
            pathLen: contact.path.length,
          ),
        );
        _emit([ReviewFrames.msgWaiting()]);
      });
    }
  }

  /// Pushes [frame] to the app as if the radio had sent it.
  @visibleForTesting
  void emitForTest(Uint8List frame) => _emit([frame]);

  /// Answers a DISCOVER_REQ the way firmware repeaters and sensors do: one
  /// zero-hop DISCOVER_RESP per matching node, echoing the request tag.
  void _handleNodeDiscover(Uint8List frame) {
    // [cmd][0x8<flags>][type mask][tag u32][since u32]
    if (frame.length < 7 || (frame[1] >> 4) != controlSubtypeDiscoverReq) {
      return;
    }
    final prefixOnly = (frame[1] & 0x01) != 0;
    final typeMask = frame[2];
    final tag = frame.sublist(3, 7);
    var snrQuarterDb = 40;
    for (final c in _contacts) {
      if (c.type != advTypeRepeater && c.type != advTypeSensor) continue;
      if ((typeMask & (1 << c.type)) == 0) continue;
      final key = prefixOnly ? c.publicKey.sublist(0, 8) : c.publicKey;
      final snr = snrQuarterDb;
      snrQuarterDb -= 12;
      _later(ackDelay, () {
        _emit([
          Uint8List.fromList([
            pushCodeControlData,
            snr & 0xFF,
            (-60) & 0xFF,
            0, // path_len: zero-hop
            (controlSubtypeDiscoverResp << 4) | c.type,
            (snr - 8) & 0xFF,
            ...tag,
            ...key,
          ]),
        ]);
      });
    }
  }

  void _handleLogin(Uint8List frame) {
    // [cmd][pub_key x32][password...]
    _Contact? contact;
    if (frame.length >= 1 + pubKeySize) {
      final key = frame.sublist(1, 1 + pubKeySize);
      for (final c in _contacts) {
        if (listEquals(c.publicKey, key)) contact = c;
      }
    }
    if (contact == null) {
      _emit([ReviewFrames.err(ReviewFrames.errNotFound)]);
      return;
    }
    final target = contact;
    // The firmware tags a login with the first 4 bytes of the target key.
    _emit([
      ReviewFrames.sent(
        flood: false,
        ackHash: readUint32LE(target.publicKey, 0),
        timeoutMs: 8000,
      ),
    ]);
    // Room servers accept any password so reviewers can open the room chat.
    // Repeater administration needs real hardware, so it fails right away
    // instead of leaving the login dialog waiting for a timeout.
    _later(ackDelay, () {
      _emit([
        target.type == advTypeRoom
            ? ReviewFrames.loginSuccess(
                publicKey: target.publicKey,
                serverTimeSecs: _nowSecs,
              )
            : ReviewFrames.loginFail(publicKey: target.publicKey),
      ]);
    });
  }

  void _handleSendChannelText(Uint8List frame) {
    // [cmd][txt_type][channel_idx][timestamp x4][text...]\0
    if (frame.length < 8) {
      _emit([ReviewFrames.err()]);
      return;
    }
    final channelIndex = frame[2];
    _emit([ReviewFrames.ok()]);

    final members = ReviewScript.channelMembers[channelIndex];
    if (members == null ||
        members.isEmpty ||
        !_channels.containsKey(channelIndex)) {
      return;
    }
    _later(replyDelay, () {
      final replies = ReviewScript.channelReplies;
      final index = _channelReplyIndex++;
      final sender = members[index % members.length];
      _messageQueue.add(
        ReviewFrames.channelMessage(
          channelIndex: channelIndex,
          sender: sender,
          message: replies[index % replies.length],
          timestampSecs: _nowSecs,
          path: _pathForSender(sender),
        ),
      );
      _emit([ReviewFrames.msgWaiting()]);
    });
  }

  _Contact? _contactByPrefix(List<int> prefix) {
    for (final c in _contacts) {
      if (c.publicKey.length >= prefix.length &&
          listEquals(c.publicKey.sublist(0, prefix.length), prefix)) {
        return c;
      }
    }
    return null;
  }

  String _readCString(Uint8List frame, int start, int maxLength) {
    final end = (start + maxLength).clamp(start, frame.length);
    final bytes = <int>[];
    for (var i = start; i < end; i++) {
      if (frame[i] == 0) break;
      bytes.add(frame[i]);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  void _later(Duration delay, void Function() action) {
    if (_disposed) return;
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (!_disposed) action();
    });
    _timers.add(timer);
  }

  /// Queues frames and flushes them from a timer, so a response is never
  /// delivered synchronously inside [handle] and ordering is preserved.
  void _emit(List<Uint8List> frames) {
    if (_disposed) return;
    _outbox.addAll(frames);
    _flushTimer ??= Timer(Duration.zero, _flush);
  }

  void _flush() {
    _flushTimer = null;
    if (_disposed) return;
    final pending = List<Uint8List>.of(_outbox);
    _outbox.clear();
    for (final frame in pending) {
      if (_disposed || _controller.isClosed) return;
      _controller.add(frame);
    }
  }

  /// Cancels all timers and closes the stream. Safe to call twice.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _scheduledTimer?.cancel();
    _scheduledTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _outbox.clear();
    unawaited(_controller.close());
  }
}

class _Contact {
  final Uint8List publicKey;
  final int type;
  final Uint8List path;
  final String name;
  final int lastAdvertSecs;
  final int latitudeE6;
  final int longitudeE6;
  final int lastModSecs;

  _Contact({
    required this.publicKey,
    required this.type,
    required this.path,
    required this.name,
    required this.lastAdvertSecs,
    required this.latitudeE6,
    required this.longitudeE6,
    required this.lastModSecs,
  });
}

class _Channel {
  final String name;
  final Uint8List psk;

  _Channel(this.name, this.psk);
}

class _SeedEntry {
  final int agoSecs;
  final Uint8List frame;

  _SeedEntry(this.agoSecs, this.frame);
}
