import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../models/channel.dart';
import '../../models/mesh_event.dart';
import '../../utils/app_logger.dart';
import '../image_chunk_transport.dart' show kMaxChannelDataPayload;
import 'local_api_archive.dart';
import 'local_api_crypto.dart';
import 'local_api_host.dart';
import 'local_api_pairing.dart';

/// What the server enforces. The defaults are the documented limits; tests
/// shrink some of them.
class LocalApiLimits {
  /// Paired connections at the same time.
  final int maxClients;

  /// Connections that have not finished pairing (including one waiting for
  /// the user's answer).
  final int maxPendingClients;

  /// Largest inbound WebSocket message, summed over its fragments.
  final int maxMessageBytes;

  /// Outbound bytes the OS has not accepted yet; past this the client is a
  /// slow consumer and is closed with 4013. (dart:io refuses to send 1013.)
  final int maxQueuedBytes;

  final int maxSubscriptions;

  /// Entries in a subscription's `dataTypes` or `pubkeys` list.
  final int maxFilterEntries;

  final int sendsPerMinute;
  final Duration minSendGap;

  /// From connect to the `pair` frame; the challenge expires with it.
  final Duration helloTimeout;

  const LocalApiLimits({
    this.maxClients = 4,
    this.maxPendingClients = 2,
    this.maxMessageBytes = 16 * 1024,
    this.maxQueuedBytes = 256 * 1024,
    this.maxSubscriptions = 16,
    this.maxFilterEntries = 32,
    this.sendsPerMinute = 30,
    this.minSendGap = const Duration(seconds: 2),
    this.helloTimeout = const Duration(seconds: 10),
  });

  Map<String, Object?> toJson() => {
    'maxPayloadBytes': LocalApiServer.maxPayloadBytes,
    'maxMessageBytes': maxMessageBytes,
    'maxQueuedBytes': maxQueuedBytes,
    'sendsPerMinute': sendsPerMinute,
    'minSendGapMs': minSendGap.inMilliseconds,
    'maxSubscriptions': maxSubscriptions,
    'maxFilterEntries': maxFilterEntries,
  };
}

/// Local WebSocket API for other apps on the same device.
///
/// One radio, one BLE connection: this server lets a second application (a
/// road-event client, a bot, a bridge) subscribe to live traffic and send
/// through the same connection the chat UI uses. It is loopback-only, and a
/// client proves a P-256 key the user approved once. See
/// documentation/LOCAL_API.md.
class LocalApiServer {
  static const int protocolVersion = 1;
  static const int defaultPort = 8787;
  static const int maxPayloadBytes = kMaxChannelDataPayload;
  static const String pairingMessagePrefix = 'meshcore-open-pair-v1:';
  static const String _webSocketGuid = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

  final LocalApiHost host;
  final PairingStore pairingStore;
  final PairingBroker pairingBroker;
  final LocalApiArchive? archive;
  final LocalApiLimits limits;
  final int port;

  HttpServer? _server;
  final List<_ApiClient> _clients = [];
  int _upgrading = 0;
  StreamSubscription<MeshEvent>? _eventSubscription;
  StreamSubscription<void>? _changeSubscription;
  Timer? _deviceDebounce;

  LocalApiServer({
    required this.host,
    required this.pairingStore,
    PairingBroker? pairingBroker,
    this.archive,
    this.limits = const LocalApiLimits(),
    this.port = defaultPort,
  }) : pairingBroker = pairingBroker ?? PairingBroker();

  bool get isRunning => _server != null;

  /// Actual port, useful when [port] was 0 (tests) or when reporting the URI.
  int? get boundPort => _server?.port;

  int get clientCount => _clients.length;

  Future<void> start() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server = server;
    _eventSubscription = host.events.listen(_onEvent);
    _changeSubscription = host.changes.listen((_) => _scheduleDeviceUpdate());
    server.listen(
      _handleRequest,
      onError: (Object error) {
        appLogger.warn('Local API server error: $error', tag: 'LocalApi');
      },
    );
    appLogger.info(
      'Local API listening on ws://127.0.0.1:${server.port}/api/v1',
      tag: 'LocalApi',
    );
  }

  Future<void> stop() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _changeSubscription?.cancel();
    _changeSubscription = null;
    _deviceDebounce?.cancel();
    _deviceDebounce = null;
    for (final client in List<_ApiClient>.of(_clients)) {
      client.close(1001, 'server stopping');
    }
    await _server?.close(force: true);
    _server = null;
    await archive?.flush();
  }

  /// Forgets [publicKey] and ends its live sessions.
  Future<void> revoke(String publicKey) async {
    await pairingStore.remove(publicKey);
    archive?.forgetClient(publicKey);
    for (final client in List<_ApiClient>.of(_clients)) {
      if (client.publicKey == publicKey) client.close(4003, 'revoked');
    }
  }

  int get _authenticatedCount =>
      _clients.where((client) => client.authenticated).length;

  void _handleRequest(HttpRequest request) {
    if (request.uri.path != '/api/v1') {
      _refuse(request, HttpStatus.notFound, 'Not found');
      return;
    }
    // Native clients send no Origin; browsers always do, and a web page must
    // not be able to reach the radio through the user's loopback.
    if (request.headers.value('origin') != null) {
      _refuse(request, HttpStatus.forbidden, 'Browsers are not allowed');
      return;
    }
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.headers.set(HttpHeaders.connectionHeader, 'Upgrade');
      _refuse(
        request,
        HttpStatus.upgradeRequired,
        'This endpoint speaks WebSocket only',
      );
      return;
    }
    // Counted before any await, so parallel upgrades cannot overshoot.
    final unpaired = _upgrading + _clients.length - _authenticatedCount;
    if (unpaired >= limits.maxPendingClients) {
      _refuse(request, HttpStatus.serviceUnavailable, 'Too many clients');
      return;
    }
    _upgrading++;
    unawaited(_accept(request));
  }

  void _refuse(HttpRequest request, int status, String message) {
    request.response
      ..statusCode = status
      ..write(message);
    unawaited(request.response.close());
  }

  /// Upgrades by hand rather than with [WebSocketTransformer.upgrade] to keep
  /// the TCP socket: it meters inbound message sizes and outbound backlog, and
  /// can be destroyed when a peer stops reading.
  Future<void> _accept(HttpRequest request) async {
    try {
      final key = request.headers.value('sec-websocket-key')!;
      final accept = base64Encode(
        crypto.sha1.convert(utf8.encode('$key$_webSocketGuid')).bytes,
      );
      request.response
        ..statusCode = HttpStatus.switchingProtocols
        ..headers.set(HttpHeaders.connectionHeader, 'Upgrade')
        ..headers.set(HttpHeaders.upgradeHeader, 'websocket')
        ..headers.set('Sec-WebSocket-Accept', accept)
        ..headers.contentLength = 0;
      final raw = await request.response.detachSocket();
      if (_server == null) {
        raw.destroy();
        return;
      }
      final client = _ApiClient(this, raw);
      _clients.add(client);
      client.start();
      appLogger.info('Local API client connected', tag: 'LocalApi');
    } catch (error) {
      appLogger.warn('Local API upgrade failed: $error', tag: 'LocalApi');
    } finally {
      _upgrading--;
    }
  }

  void _remove(_ApiClient client) {
    if (_clients.remove(client)) {
      appLogger.info('Local API client disconnected', tag: 'LocalApi');
    }
  }

  /// The connector notifies on almost every frame; one snapshot per burst.
  void _scheduleDeviceUpdate() {
    if (_deviceDebounce?.isActive ?? false) return;
    _deviceDebounce = Timer(const Duration(milliseconds: 250), () {
      for (final client in List<_ApiClient>.of(_clients)) {
        client.sendDeviceIfChanged();
      }
    });
  }

  /// What `hello` and `device` say about the radio. `connected` means usable:
  /// connected, with its channels loaded so names resolve.
  Map<String, Object?> deviceSummary() {
    final info = host.deviceInfo();
    return {
      'name': info['name'],
      'pubkey': info['pubkey'],
      'firmwareVerCode': info['firmwareVerCode'],
      'connected': host.isReady,
    };
  }

  void _onEvent(MeshEvent event) {
    if (event is ChannelDataEvent) archive?.record(event);
    for (final client in List<_ApiClient>.of(_clients)) {
      client.deliver(event);
    }
  }
}

class _ApiClient {
  final LocalApiServer server;
  final Socket _raw;
  late final _MeteredSocket _metered;
  late final WebSocket _socket;
  final Map<String, _Subscription> _subscriptions = {};
  final List<DateTime> _sendTimes = [];
  int _nextSubscriptionId = 1;
  Timer? _helloTimeout;
  _Handshake? _handshake;
  bool _helloSeen = false;
  bool _pairSeen = false;
  String? _pairingRequestId;
  String? _lastDevice;
  String? _clientName;
  String? _clientFingerprint;
  String? publicKey;
  bool authenticated = false;
  bool _closed = false;
  int _queuedBytes = 0;

  _ApiClient(this.server, this._raw) {
    _metered = _MeteredSocket(
      _raw,
      maxMessageBytes: server.limits.maxMessageBytes,
      onWritten: (bytes) => _queuedBytes = max(0, _queuedBytes - bytes),
      onTooLarge: () => close(1009, 'message too big'),
    );
    _socket = WebSocket.fromUpgradedSocket(
      _metered,
      serverSide: true,
      compression: CompressionOptions.compressionOff,
    );
  }

  LocalApiLimits get _limits => server.limits;

  void start() {
    _helloTimeout = Timer(_limits.helloTimeout, () {
      if (!authenticated) close(4001, 'hello timeout');
    });
    _socket.listen(
      _handleMessage,
      onDone: () => close(1000, 'closed'),
      onError: (Object error) => close(1011, 'socket error'),
      cancelOnError: true,
    );
  }

  /// Ends the session at once. The close frame is best effort: a peer that
  /// stopped reading never gets it, so the socket is destroyed shortly after.
  void close(int code, String reason) {
    if (_closed) return;
    _closed = true;
    _helloTimeout?.cancel();
    final requestId = _pairingRequestId;
    if (requestId != null) server.pairingBroker.cancel(requestId);
    server._remove(this);
    unawaited(_socket.close(code, reason).catchError((_) {}));
    Timer(const Duration(seconds: 1), _raw.destroy);
  }

  void _handleMessage(dynamic raw) {
    if (_closed) return;
    if (raw is! String) {
      close(1003, 'text frames only');
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      _sendError('bad_request', 'invalid JSON');
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      _sendError('bad_request', 'expected an object');
      return;
    }
    if (!authenticated) {
      _handleHandshake(decoded);
      return;
    }
    unawaited(_dispatch(decoded));
  }

  /// Errors before authentication have no request id.
  void _sendError(String code, String message) {
    _enqueue({
      'type': 'error',
      'error': {'code': code, 'message': message},
    });
  }

  void _reject(String code, String message, int closeCode, String reason) {
    _sendError(code, message);
    close(closeCode, reason);
  }

  void _handleHandshake(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'hello' when !_helloSeen:
        _helloSeen = true;
        _startChallenge(message);
      case 'pair' when _handshake != null && !_pairSeen:
        // One attempt per connection, locked before anything awaits.
        _pairSeen = true;
        unawaited(_completePairing(_handshake!, message));
      default:
        _reject(
          'unauthorized',
          'send hello, then pair once',
          4001,
          'hello first',
        );
    }
  }

  void _startChallenge(Map<String, dynamic> message) {
    final client = message['client'];
    if (client is! Map) {
      _reject('bad_request', 'client is required', 4003, 'bad hello');
      return;
    }
    final name = client['name'];
    final version = client['version'];
    final key = client['publicKey'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > 64 ||
        version is! String ||
        version.length > 32 ||
        key is! String) {
      _reject('bad_request', 'bad client identity', 4003, 'bad hello');
      return;
    }
    final raw = LocalApiCrypto.decodePublicKey(key);
    if (raw == null) {
      _reject('bad_request', 'invalid public key', 4003, 'bad key');
      return;
    }
    final handshake = _Handshake(
      name: name.trim(),
      version: version,
      publicKey: key,
      publicKeyRaw: raw,
      fingerprint: LocalApiCrypto.fingerprint(raw),
      nonce: LocalApiCrypto.newNonce(),
    );
    _handshake = handshake;
    // Sent whether or not the key is paired, so an unauthenticated caller
    // cannot learn which keys are.
    _enqueue({
      'type': 'pairing.challenge',
      'protocol': LocalApiServer.protocolVersion,
      'nonce': handshake.nonce,
      'fingerprint': handshake.fingerprint,
      'message': '${LocalApiServer.pairingMessagePrefix}${handshake.nonce}',
    });
  }

  Future<void> _completePairing(
    _Handshake handshake,
    Map<String, dynamic> message,
  ) async {
    final signature = message['signature'];
    if (signature is! String) {
      _reject('bad_request', 'signature is required', 4003, 'bad signature');
      return;
    }
    final signed = '${LocalApiServer.pairingMessagePrefix}${handshake.nonce}';
    if (!LocalApiCrypto.verify(handshake.publicKeyRaw, signed, signature)) {
      _reject('unauthorized', 'bad signature', 4003, 'bad signature');
      return;
    }

    if (!server.pairingStore.isPaired(handshake.publicKey)) {
      final broker = server.pairingBroker;
      final refusal = broker.refusal(handshake.publicKey);
      if (refusal != null) {
        _reject(refusal, 'cannot ask the user now', 4003, refusal);
        return;
      }
      // The prompt has its own timeout.
      _helloTimeout?.cancel();
      final allowed = await broker.ask(
        name: handshake.name,
        version: handshake.version,
        publicKey: handshake.publicKey,
        fingerprint: handshake.fingerprint,
        onStarted: (id) => _pairingRequestId = id,
      );
      _pairingRequestId = null;
      if (_closed) return;
      if (!allowed) {
        _reject('unauthorized', 'pairing denied', 4003, 'pairing denied');
        return;
      }
      await server.pairingStore.add(
        PairedClient(
          name: handshake.name,
          publicKey: handshake.publicKey,
          fingerprint: handshake.fingerprint,
          pairedAt: DateTime.now(),
        ),
      );
      if (_closed) return;
    }

    if (server._authenticatedCount >= _limits.maxClients) {
      _reject('too_many_clients', 'too many apps connected', 4013, 'busy');
      return;
    }
    authenticated = true;
    publicKey = handshake.publicKey;
    _clientName = handshake.name;
    _clientFingerprint = handshake.fingerprint;
    _helloTimeout?.cancel();
    _handshake = null;
    _enqueue({
      'type': 'hello',
      'protocol': LocalApiServer.protocolVersion,
      'client': {'name': handshake.name, 'fingerprint': handshake.fingerprint},
      'device': server.deviceSummary(),
      'eventTypes': _Subscription.eventTypes,
      'limits': _limits.toJson(),
    });
    // hello already says this; push only what changes from here on.
    _lastDevice = jsonEncode(_deviceMessage());
  }

  Map<String, Object?> _deviceMessage() => {
    'type': 'device',
    'device': server.deviceSummary(),
    'channels': server.host.channels(),
  };

  /// Pushes the radio's state and channels when they differ from what this
  /// client was last told, so it can subscribe again once the radio is back.
  void sendDeviceIfChanged() {
    if (_closed || !authenticated) return;
    final message = _deviceMessage();
    final encoded = jsonEncode(message);
    if (encoded == _lastDevice) return;
    _lastDevice = encoded;
    _enqueue(message);
  }

  Future<void> _dispatch(Map<String, dynamic> message) async {
    final id = message['id'];
    final method = message['method'];
    final rawParams = message['params'];
    final params = rawParams is Map<String, dynamic>
        ? rawParams
        : const <String, dynamic>{};
    if (method is! String) {
      _respondError(id, 'bad_request', 'method is required');
      return;
    }
    try {
      if (method == 'events.subscribe') {
        // Synchronous from validation to registration: the ack, then any
        // replay, then live events, with nothing in between.
        _subscribe(id, params);
        return;
      }
      _respondOk(id, await _call(method, params));
    } on _ApiError catch (error) {
      _respondError(id, error.code, error.message);
    } catch (error) {
      appLogger.warn('Local API $method failed: $error', tag: 'LocalApi');
      _respondError(id, 'internal', 'request failed');
    }
  }

  Future<Object?> _call(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'device.info':
        final info = server.host.deviceInfo();
        return {...info, 'channels': server.host.channels()};
      case 'channels.list':
        return {'channels': server.host.channels()};
      case 'contacts.list':
        final limit = _intParam(params, 'limit', fallback: 200);
        return {'contacts': server.host.contacts(limit: limit.clamp(1, 500))};
      case 'events.unsubscribe':
        final id = params['subscriptionId'];
        if (id is! String || _subscriptions.remove(id) == null) {
          throw _ApiError('bad_request', 'unknown subscription');
        }
        return const <String, Object?>{};
      case 'channel.sendText':
        final channel = _channelParam(params);
        final text = _textParam(params, 'text');
        return _send(() => server.host.sendChannelText(channel, text));
      case 'channel.sendData':
        final channel = _channelParam(params);
        final dataType = _intParam(params, 'dataType');
        if (dataType <= 0 || dataType > 0xFFFF) {
          throw _ApiError('invalid_data_type', 'dataType must be 1..65535');
        }
        final payload = _payloadParam(params);
        if (payload.length > LocalApiServer.maxPayloadBytes) {
          throw _ApiError(
            'payload_too_large',
            'payload is ${payload.length} bytes; the limit is '
                '${LocalApiServer.maxPayloadBytes}',
          );
        }
        if (server.host.isConnected && !server.host.supportsChannelData) {
          throw _ApiError(
            'unsupported_firmware',
            'the radio firmware cannot send channel data',
          );
        }
        return _send(() async {
          final sent = await server.host.sendChannelData(
            channel,
            dataType,
            payload,
          );
          if (!sent) {
            throw _ApiError('not_connected', 'the radio is not connected');
          }
        });
      case 'direct.sendText':
        final pubkey = params['pubkey'];
        if (pubkey is! String) {
          throw _ApiError('bad_request', 'pubkey is required');
        }
        final contact = server.host.resolveContact(pubkey);
        if (contact == null) {
          throw _ApiError('unknown_contact', 'no contact with that pubkey');
        }
        final text = _textParam(params, 'text');
        return _send(() => server.host.sendDirectText(contact, text));
      case 'channels.join':
        return _joinChannel(params);
      case 'advert.send':
        final flood = params['flood'];
        return _send(
          () => server.host.sendAdvert(flood: flood is bool ? flood : true),
        );
      default:
        throw _ApiError('unknown_method', 'unknown method: $method');
    }
  }

  /// Adds a hashtag channel after the user agrees. Only hashtag channels: their
  /// key is derived from the name, so no secret crosses the API.
  Future<Object?> _joinChannel(Map<String, dynamic> params) async {
    final name = params['name'];
    if (name is! String || !_hashtagName.hasMatch(name)) {
      throw _ApiError(
        'invalid_params',
        'name must be a hashtag channel such as #roadstr',
      );
    }
    if (!server.host.isReady) {
      throw _ApiError('not_connected', 'the radio is not connected');
    }
    final psk = Channel.derivePskFromHashtag(name);
    final named = server.host.channelsNamed(name);
    for (final channel in named) {
      if (_sameKey(channel.psk, psk)) {
        return {'index': channel.index, 'name': name, 'created': false};
      }
    }
    if (named.isNotEmpty) {
      throw _ApiError(
        'channel_conflict',
        'a channel named $name with another key exists',
      );
    }
    final broker = server.pairingBroker;
    final key = publicKey!;
    final refusal = broker.refusal(key, channelName: name);
    if (refusal != null) {
      throw _ApiError(refusal, 'cannot ask the user now');
    }
    final allowed = await broker.ask(
      name: _clientName ?? 'An app',
      version: '',
      publicKey: key,
      fingerprint: _clientFingerprint ?? '',
      channelName: name,
      onStarted: (id) => _pairingRequestId = id,
    );
    _pairingRequestId = null;
    if (!allowed) throw _ApiError('denied', 'the user did not add $name');
    if (!server.host.isReady) {
      throw _ApiError('not_connected', 'the radio is not connected');
    }
    final index = await server.host.addHashtagChannel(name);
    if (index == null) {
      throw _ApiError('no_free_slot', 'the radio has no free channel slot');
    }
    return {'index': index, 'name': name, 'created': true};
  }

  static final RegExp _hashtagName = RegExp(r'^#[a-z0-9-]{1,31}$');

  static bool _sameKey(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Spends one send from the quota and gives it back if the radio refuses.
  Future<Object?> _send(Future<void> Function() action) async {
    if (!server.host.isConnected) {
      throw _ApiError('not_connected', 'the radio is not connected');
    }
    final now = DateTime.now();
    _sendTimes.removeWhere(
      (time) => now.difference(time) >= const Duration(minutes: 1),
    );
    if (_sendTimes.isNotEmpty &&
        now.difference(_sendTimes.last) < _limits.minSendGap) {
      throw _ApiError('rate_limited', 'sends are too close together');
    }
    if (_sendTimes.length >= _limits.sendsPerMinute) {
      throw _ApiError('rate_limited', 'too many sends in a minute');
    }
    _sendTimes.add(now);
    try {
      await action();
    } on _ApiError {
      _sendTimes.remove(now);
      rethrow;
    } catch (error) {
      _sendTimes.remove(now);
      appLogger.warn('Local API send failed: $error', tag: 'LocalApi');
      throw _ApiError('radio_error', 'the radio did not accept the command');
    }
    return const {'queued': true};
  }

  void _subscribe(Object? id, Map<String, dynamic> params) {
    if (_subscriptions.length >= _limits.maxSubscriptions) {
      throw _ApiError('rate_limited', 'too many subscriptions');
    }
    final events = params['events'];
    final Set<String> types;
    if (events == null) {
      types = _Subscription.eventTypes.toSet();
    } else if (events is List && events.every((e) => e is String)) {
      types = events.cast<String>().toSet();
    } else {
      throw _ApiError('bad_request', 'events must be a list of strings');
    }
    for (final type in types) {
      if (!_Subscription.eventTypes.contains(type)) {
        throw _ApiError('bad_request', 'unknown event type: $type');
      }
    }

    final rawChannel = params['channel'];
    int? channelIndex;
    String? channelName;
    if (rawChannel is int) {
      channelIndex = rawChannel;
      final match = server.host.channels().where(
        (channel) => channel['index'] == rawChannel,
      );
      channelName = match.isEmpty ? null : match.first['name'] as String?;
    } else if (rawChannel is String) {
      final resolved = _resolveChannel(rawChannel);
      channelIndex = resolved.index;
      channelName = resolved.name;
    } else if (rawChannel != null) {
      throw _ApiError('bad_request', 'channel must be a name or an index');
    }

    final dataTypes = _listParam<int>(params, 'dataTypes').toSet();
    if (dataTypes.any((type) => type <= 0 || type > 0xFFFF)) {
      throw _ApiError('invalid_data_type', 'dataTypes must be 1..65535');
    }
    final pubkeys = _listParam<String>(params, 'pubkeys');
    final since = params.containsKey('since')
        ? _parseSince(params['since'])
        : null;

    final subscriptionId = 's${_nextSubscriptionId++}';
    _respondOk(id, {'subscriptionId': subscriptionId});

    final archive = server.archive;
    final key = publicKey;
    if (archive != null && key != null && types.contains('channel.data')) {
      if (channelName != null && channelName.isNotEmpty) {
        archive.noteInterest(key, channelName, dataTypes);
      }
      if (since != null) {
        for (final entry in archive.replay(
          key,
          since: since,
          channel: channelName,
          dataTypes: dataTypes,
        )) {
          if (channelIndex != null && entry.channelIndex != channelIndex) {
            continue;
          }
          _enqueue({
            'type': 'event',
            'subscriptionId': subscriptionId,
            'event': _encodeEvent(entry.toEvent()),
          });
        }
      }
    }

    _subscriptions[subscriptionId] = _Subscription(
      types: types,
      channelIndex: channelIndex,
      channelName: channelName,
      dataTypes: dataTypes,
      pubkeys: pubkeys,
    );
  }

  void deliver(MeshEvent event) {
    if (_closed || !authenticated) return;
    for (final entry in _subscriptions.entries) {
      if (!entry.value.matches(event)) continue;
      _enqueue({
        'type': 'event',
        'subscriptionId': entry.key,
        'event': _encodeEvent(event),
      });
    }
  }

  Map<String, Object?> _encodeEvent(MeshEvent event) {
    final receivedAt = event.receivedAt.toUtc().toIso8601String();
    switch (event) {
      case ChannelTextEvent():
        return {
          'type': 'channel.text',
          'channel': event.channelName,
          'channelIndex': event.channelIndex,
          'senderName': event.senderName,
          'senderKeyHex': event.senderKeyHex,
          'text': event.text,
          'sentAt': event.sentAt.toUtc().toIso8601String(),
          'messageId': event.messageId,
          'outgoing': event.outgoing,
          'receivedAt': receivedAt,
        };
      case ChannelDataEvent():
        return {
          'type': 'channel.data',
          'channel': event.channelName,
          'channelIndex': event.channelIndex,
          'dataType': event.dataType,
          'payload': base64Encode(event.payload),
          'snrDb': event.snrDb,
          'hops': event.hops,
          'outgoing': event.outgoing,
          'receivedAt': receivedAt,
        };
      case DirectTextEvent():
        return {
          'type': 'direct.text',
          'pubkey': event.pubkeyHex,
          'name': event.name,
          'text': event.text,
          'sentAt': event.sentAt.toUtc().toIso8601String(),
          'messageId': event.messageId,
          'outgoing': event.outgoing,
          'receivedAt': receivedAt,
        };
      case AdvertEvent():
        return {
          'type': 'advert',
          'pubkey': event.pubkeyHex,
          'name': event.name,
          'nodeType': event.type,
          'lastSeen': event.lastSeen?.toUtc().toIso8601String(),
          'receivedAt': receivedAt,
        };
    }
  }

  DateTime _parseSince(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toUtc();
    } else if (value is int && value >= 0) {
      // Epoch seconds, or milliseconds when it is too large to be seconds.
      final millis = value > 100000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
    throw _ApiError('bad_request', 'since must be ISO-8601 or epoch time');
  }

  List<T> _listParam<T>(Map<String, dynamic> params, String name) {
    final value = params[name];
    if (value == null) return const [];
    if (value is! List || !value.every((e) => e is T)) {
      throw _ApiError('bad_request', '$name must be a list');
    }
    if (value.length > _limits.maxFilterEntries) {
      throw _ApiError(
        'bad_request',
        '$name has more than ${_limits.maxFilterEntries} entries',
      );
    }
    return value.cast<T>();
  }

  Channel _resolveChannel(String nameOrIndex) {
    final channel = server.host.resolveChannel(
      nameOrIndex,
      onAmbiguous: () {
        throw _ApiError(
          'ambiguous_channel',
          'more than one channel named $nameOrIndex',
        );
      },
    );
    if (channel == null) {
      throw _ApiError('unknown_channel', 'no channel named $nameOrIndex');
    }
    return channel;
  }

  Channel _channelParam(Map<String, dynamic> params) {
    final raw = params['channel'];
    if (raw is! String) {
      throw _ApiError('bad_request', 'channel is required');
    }
    return _resolveChannel(raw);
  }

  String _textParam(Map<String, dynamic> params, String name) {
    final text = params[name];
    if (text is! String || text.isEmpty) {
      throw _ApiError('bad_request', '$name is required');
    }
    if (text.length > 2000) {
      throw _ApiError('bad_request', '$name is too long');
    }
    return text;
  }

  Uint8List _payloadParam(Map<String, dynamic> params) {
    final raw = params['payload'];
    if (raw is! String || raw.isEmpty) {
      throw _ApiError('bad_request', 'payload (base64) is required');
    }
    try {
      return base64Decode(raw);
    } on FormatException {
      throw _ApiError('bad_request', 'payload is not valid base64');
    }
  }

  int _intParam(Map<String, dynamic> params, String name, {int? fallback}) {
    final value = params[name];
    if (value == null && fallback != null) return fallback;
    if (value is! int) {
      throw _ApiError('bad_request', '$name must be an integer');
    }
    return value;
  }

  void _respondOk(Object? id, Object? result) {
    _enqueue({
      'id': id,
      'ok': true,
      'result': result ?? const <String, Object?>{},
    });
  }

  void _respondError(Object? id, String code, String message) {
    _enqueue({
      'id': id,
      'ok': false,
      'error': {'code': code, 'message': message},
    });
  }

  void _enqueue(Map<String, Object?> message) {
    if (_closed) return;
    final bytes = utf8.encode(jsonEncode(message));
    if (_queuedBytes + bytes.length > _limits.maxQueuedBytes) {
      close(4013, 'slow consumer');
      return;
    }
    _queuedBytes += bytes.length;
    _socket.addUtf8Text(bytes);
  }
}

/// The upgraded TCP socket with the two meters [WebSocket] lacks: the size of
/// each inbound message, and how many outbound bytes the OS has taken.
///
/// Inbound frame headers are parsed only for their lengths; once a message
/// exceeds [maxMessageBytes] nothing more is passed on and [onTooLarge] runs.
/// Outbound chunks are counted as the socket pulls them, which it stops doing
/// while the OS send buffer is full.
class _MeteredSocket extends Stream<Uint8List> implements Socket {
  final Socket _socket;
  final int maxMessageBytes;
  final void Function(int bytes) onWritten;
  final void Function() onTooLarge;

  final List<int> _header = [];
  int _payloadLeft = 0;
  int _messageBytes = 0;
  bool _tooLarge = false;

  _MeteredSocket(
    this._socket, {
    required this.maxMessageBytes,
    required this.onWritten,
    required this.onTooLarge,
  });

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _socket
        .where(_accept)
        .listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }

  bool _accept(Uint8List chunk) {
    if (_tooLarge) return false;
    var i = 0;
    while (i < chunk.length) {
      if (_payloadLeft > 0) {
        final take = min(_payloadLeft, chunk.length - i);
        _payloadLeft -= take;
        i += take;
        continue;
      }
      _header.add(chunk[i++]);
      if (_header.length < 2) continue;
      final lengthCode = _header[1] & 0x7F;
      final extended = lengthCode == 126 ? 2 : (lengthCode == 127 ? 8 : 0);
      final masked = _header[1] & 0x80 != 0;
      if (_header.length < 2 + extended + (masked ? 4 : 0)) continue;

      var length = lengthCode;
      if (extended > 0) {
        length = 0;
        for (var k = 0; k < extended; k++) {
          length = min(length * 256 + _header[2 + k], 1 << 40);
        }
      }
      final opcode = _header[0] & 0x0F;
      final fin = _header[0] & 0x80 != 0;
      _header.clear();
      _payloadLeft = length;
      // Continuation, text and binary frames add up to one message; control
      // frames are capped at 125 bytes by the protocol.
      if (opcode < 8) {
        _messageBytes += length;
        if (_messageBytes > maxMessageBytes) {
          _tooLarge = true;
          onTooLarge();
          return false;
        }
        if (fin) _messageBytes = 0;
      }
    }
    return true;
  }

  @override
  Future addStream(Stream<List<int>> stream) => _socket.addStream(
    stream.map((chunk) {
      onWritten(chunk.length);
      return chunk;
    }),
  );

  @override
  void add(List<int> data) {
    _socket.add(data);
    onWritten(data.length);
  }

  @override
  Encoding get encoding => _socket.encoding;

  @override
  set encoding(Encoding value) => _socket.encoding = value;

  @override
  void write(Object? object) => _socket.write(object);

  @override
  void writeln([Object? object = '']) => _socket.writeln(object);

  @override
  void writeCharCode(int charCode) => _socket.writeCharCode(charCode);

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _socket.writeAll(objects, separator);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _socket.addError(error, stackTrace);

  @override
  Future flush() => _socket.flush();

  @override
  Future close() => _socket.close();

  @override
  Future get done => _socket.done;

  @override
  void destroy() => _socket.destroy();

  @override
  int get port => _socket.port;

  @override
  int get remotePort => _socket.remotePort;

  @override
  InternetAddress get address => _socket.address;

  @override
  InternetAddress get remoteAddress => _socket.remoteAddress;

  @override
  bool setOption(SocketOption option, bool enabled) =>
      _socket.setOption(option, enabled);

  @override
  Uint8List getRawOption(RawSocketOption option) =>
      _socket.getRawOption(option);

  @override
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);
}

class _Handshake {
  final String name;
  final String version;
  final String publicKey;
  final Uint8List publicKeyRaw;
  final String fingerprint;
  final String nonce;

  _Handshake({
    required this.name,
    required this.version,
    required this.publicKey,
    required this.publicKeyRaw,
    required this.fingerprint,
    required this.nonce,
  });
}

class _Subscription {
  static const List<String> eventTypes = [
    'channel.text',
    'channel.data',
    'direct.text',
    'advert',
  ];

  final Set<String> types;
  final int? channelIndex;
  final String? channelName;
  final Set<int> dataTypes;
  final Set<String> pubkeys;

  _Subscription({
    required this.types,
    required this.channelIndex,
    required this.channelName,
    required Iterable<int> dataTypes,
    required Iterable<String> pubkeys,
  }) : dataTypes = dataTypes.toSet(),
       pubkeys = pubkeys.toSet();

  bool matches(MeshEvent event) {
    final type = switch (event) {
      ChannelTextEvent() => 'channel.text',
      ChannelDataEvent() => 'channel.data',
      DirectTextEvent() => 'direct.text',
      AdvertEvent() => 'advert',
    };
    if (!types.contains(type)) return false;

    if (channelIndex != null) {
      final (index, name) = switch (event) {
        ChannelTextEvent() => (event.channelIndex, event.channelName),
        ChannelDataEvent() => (event.channelIndex, event.channelName),
        _ => (null, null),
      };
      if (index != channelIndex) return false;
      if (channelName != null && name != channelName) return false;
    }

    if (dataTypes.isNotEmpty) {
      if (event is! ChannelDataEvent || !dataTypes.contains(event.dataType)) {
        return false;
      }
    }

    if (pubkeys.isNotEmpty) {
      final pubkey = switch (event) {
        DirectTextEvent() => event.pubkeyHex,
        AdvertEvent() => event.pubkeyHex,
        _ => null,
      };
      if (pubkey == null || !pubkeys.contains(pubkey)) return false;
    }
    return true;
  }
}

class _ApiError implements Exception {
  final String code;
  final String message;

  _ApiError(this.code, this.message);
}
