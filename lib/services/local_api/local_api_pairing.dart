import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A client asking for access. Shown to the user before anything is allowed.
class PairingRequest {
  final String id;
  final String name;
  final String version;
  final String publicKey;
  final String fingerprint;
  final DateTime requestedAt;

  /// Set when an already paired app asks to add this hashtag channel rather
  /// than to connect.
  final String? channelName;

  PairingRequest({
    required this.id,
    required this.name,
    required this.version,
    required this.publicKey,
    required this.fingerprint,
    required this.requestedAt,
    this.channelName,
  });
}

/// The UI half of pairing: the server asks, the app answers.
///
/// Prompts are bounded so a local process cannot flood the user with dialogs:
/// one open request per key, [maxPending] overall, a key may repeat a prompt
/// (to connect, or to add one channel) only after [keyInterval], and at most
/// [promptsPerMinute] prompts start per minute.
class PairingBroker {
  final int maxPending;
  final Duration keyInterval;
  final int promptsPerMinute;
  final Duration timeout;

  PairingBroker({
    this.maxPending = 3,
    this.keyInterval = const Duration(seconds: 30),
    this.promptsPerMinute = 4,
    this.timeout = const Duration(minutes: 2),
  });

  final StreamController<PairingRequest> _requests =
      StreamController<PairingRequest>.broadcast();
  final StreamController<String> _cancelled =
      StreamController<String>.broadcast();
  final Map<String, _PendingPrompt> _pending = {};
  final Map<String, DateTime> _lastPromptByKey = {};
  final List<DateTime> _recentPrompts = [];
  var _nextId = 1;

  Stream<PairingRequest> get requests => _requests.stream;

  /// Ids of requests that ended without an answer (timeout or the client left);
  /// a dialog showing one should close.
  Stream<String> get cancelled => _cancelled.stream;

  int get pendingCount => _pending.length;

  /// Why [publicKey] may not prompt now (`pairing_pending` or `rate_limited`),
  /// or null when it may. [channelName] is set for a channel prompt.
  String? refusal(String publicKey, {String? channelName}) {
    if (_pending.values.any((prompt) => prompt.publicKey == publicKey)) {
      return 'pairing_pending';
    }
    final now = DateTime.now();
    _recentPrompts.removeWhere(
      (at) => now.difference(at) >= const Duration(minutes: 1),
    );
    final last = _lastPromptByKey[_intervalKey(publicKey, channelName)];
    if (_pending.length >= maxPending ||
        _recentPrompts.length >= promptsPerMinute ||
        (last != null && now.difference(last) < keyInterval)) {
      return 'rate_limited';
    }
    return null;
  }

  /// Shows a prompt; completes with the user's answer, or false on timeout or
  /// [cancel]. Call [refusal] first.
  Future<bool> ask({
    required String name,
    required String version,
    required String publicKey,
    required String fingerprint,
    String? channelName,
    void Function(String id)? onStarted,
  }) {
    final now = DateTime.now();
    final request = PairingRequest(
      id: 'p${_nextId++}',
      name: name,
      version: version,
      publicKey: publicKey,
      fingerprint: fingerprint,
      requestedAt: now,
      channelName: channelName,
    );
    final prompt = _PendingPrompt(publicKey);
    _pending[request.id] = prompt;
    _lastPromptByKey[_intervalKey(publicKey, channelName)] = now;
    _recentPrompts.add(now);
    prompt.timer = Timer(timeout, () => cancel(request.id));
    onStarted?.call(request.id);
    _requests.add(request);
    return prompt.completer.future;
  }

  static String _intervalKey(String publicKey, String? channelName) =>
      channelName == null ? publicKey : '$publicKey $channelName';

  /// Answers a request. False when it is no longer waiting, so the UI can
  /// tell the user the answer arrived too late.
  bool resolve(String id, bool allow) {
    final prompt = _pending.remove(id);
    if (prompt == null) return false;
    prompt.finish(allow);
    return true;
  }

  void cancel(String id) {
    final prompt = _pending.remove(id);
    if (prompt == null) return;
    prompt.finish(false);
    _cancelled.add(id);
  }

  Future<void> dispose() async {
    for (final id in List<String>.of(_pending.keys)) {
      cancel(id);
    }
    await _requests.close();
    await _cancelled.close();
  }
}

class _PendingPrompt {
  final String publicKey;
  final Completer<bool> completer = Completer<bool>();
  Timer? timer;

  _PendingPrompt(this.publicKey);

  void finish(bool allow) {
    timer?.cancel();
    if (!completer.isCompleted) completer.complete(allow);
  }
}

class PairedClient {
  final String name;
  final String publicKey;
  final String fingerprint;
  final DateTime pairedAt;

  PairedClient({
    required this.name,
    required this.publicKey,
    required this.fingerprint,
    required this.pairedAt,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'publicKey': publicKey,
    'fingerprint': fingerprint,
    'pairedAt': pairedAt.toUtc().toIso8601String(),
  };

  static PairedClient? fromJson(Object? value) {
    if (value is! Map) return null;
    final name = value['name'];
    final publicKey = value['publicKey'];
    final fingerprint = value['fingerprint'];
    final pairedAt = value['pairedAt'];
    if (name is! String || publicKey is! String || fingerprint is! String) {
      return null;
    }
    final at = pairedAt is String ? DateTime.tryParse(pairedAt) : null;
    return PairedClient(
      name: name,
      publicKey: publicKey,
      fingerprint: fingerprint,
      pairedAt: at ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

abstract class PairingStore {
  Future<void> load();

  List<PairedClient> get clients;

  bool isPaired(String publicKey);

  Future<void> add(PairedClient client);

  Future<void> remove(String publicKey);
}

class MemoryPairingStore implements PairingStore {
  final List<PairedClient> _clients = [];

  @override
  List<PairedClient> get clients => List.unmodifiable(_clients);

  @override
  Future<void> load() async {}

  @override
  bool isPaired(String publicKey) =>
      _clients.any((client) => client.publicKey == publicKey);

  @override
  Future<void> add(PairedClient client) async {
    _clients.removeWhere((existing) => existing.publicKey == client.publicKey);
    _clients.add(client);
  }

  @override
  Future<void> remove(String publicKey) async {
    _clients.removeWhere((client) => client.publicKey == publicKey);
  }
}

/// Persisted in SharedPreferences as a JSON list. No secrets: these are public
/// keys of apps the user explicitly allowed.
class PrefsPairingStore implements PairingStore {
  static const String _key = 'local_api_paired_clients';

  final List<PairedClient> _clients = [];

  @override
  List<PairedClient> get clients => List.unmodifiable(_clients);

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _clients.clear();
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _clients.addAll(
        decoded.map(PairedClient.fromJson).whereType<PairedClient>(),
      );
    } on FormatException {
      _clients.clear();
    }
  }

  @override
  bool isPaired(String publicKey) =>
      _clients.any((client) => client.publicKey == publicKey);

  @override
  Future<void> add(PairedClient client) async {
    _clients.removeWhere((existing) => existing.publicKey == client.publicKey);
    _clients.add(client);
    await _save();
  }

  @override
  Future<void> remove(String publicKey) async {
    _clients.removeWhere((client) => client.publicKey == publicKey);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_clients.map((client) => client.toJson()).toList()),
    );
  }
}
