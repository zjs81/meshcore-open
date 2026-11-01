import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../models/mesh_event.dart';
import '../../utils/app_logger.dart';

/// A received channel-data frame kept for a client that was not connected
/// when it arrived.
class ArchivedChannelData {
  final String channel;
  final int channelIndex;
  final int dataType;
  final Uint8List payload;
  final int snrRaw;
  final DateTime receivedAt;

  ArchivedChannelData({
    required this.channel,
    required this.channelIndex,
    required this.dataType,
    required this.payload,
    required this.snrRaw,
    required this.receivedAt,
  });

  ChannelDataEvent toEvent() => ChannelDataEvent(
    channelIndex: channelIndex,
    channelName: channel,
    dataType: dataType,
    payload: payload,
    snrRaw: snrRaw,
    outgoing: false,
    receivedAt: receivedAt,
  );

  Map<String, Object?> toJson() => {
    'channel': channel,
    'channelIndex': channelIndex,
    'dataType': dataType,
    'payload': base64Encode(payload),
    'snrRaw': snrRaw,
    'receivedAt': receivedAt.toUtc().toIso8601String(),
  };

  static ArchivedChannelData? fromJson(Object? value) {
    if (value is! Map) return null;
    final channel = value['channel'];
    final channelIndex = value['channelIndex'];
    final dataType = value['dataType'];
    final payload = value['payload'];
    final snrRaw = value['snrRaw'];
    final receivedAt = value['receivedAt'];
    if (channel is! String ||
        channelIndex is! int ||
        dataType is! int ||
        payload is! String ||
        snrRaw is! int ||
        receivedAt is! String) {
      return null;
    }
    final at = DateTime.tryParse(receivedAt);
    if (at == null) return null;
    try {
      return ArchivedChannelData(
        channel: channel,
        channelIndex: channelIndex,
        dataType: dataType,
        payload: base64Decode(payload),
        snrRaw: snrRaw,
        receivedAt: at,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Channel-data history, kept only for (channel, dataType) pairs at least one
/// paired app has subscribed to.
///
/// The radio's own offline queue is drained destructively when this app
/// connects; if the frame is not kept here, a client that starts later can
/// never see it. Interests are persisted per client so the archive works while
/// that client is not running. The file lives in its own directory so it can
/// be excluded from Android backups.
class LocalApiArchive {
  static const int maxEntries = 200;
  static const Duration maxAge = Duration(hours: 24);

  /// Stored for a subscription without `dataTypes`. The API only accepts
  /// 1..0xFFFF, so it cannot collide with a real type.
  static const int _anyDataType = -1;

  final Future<File> Function() _file;

  /// client public key -> channel name -> data types
  final Map<String, Map<String, Set<int>>> _interests = {};
  final List<ArchivedChannelData> _entries = [];
  Timer? _saveTimer;

  LocalApiArchive({Future<File> Function()? file})
    : _file = file ?? _defaultFile;

  static Future<File> _defaultFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/local_api/archive.json');
  }

  Future<void> load() async {
    _interests.clear();
    _entries.clear();
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      final interests = decoded['interests'];
      if (interests is Map) {
        interests.forEach((key, value) {
          if (key is! String || value is! Map) return;
          final channels = <String, Set<int>>{};
          value.forEach((channel, types) {
            if (channel is! String || types is! List) return;
            channels[channel] = types.whereType<int>().toSet();
          });
          _interests[key] = channels;
        });
      }
      final entries = decoded['entries'];
      if (entries is List) {
        _entries.addAll(
          entries
              .map(ArchivedChannelData.fromJson)
              .whereType<ArchivedChannelData>(),
        );
      }
      _prune();
    } catch (error) {
      appLogger.warn('archive unreadable: $error', tag: 'LocalApi');
      _interests.clear();
      _entries.clear();
    }
  }

  /// [pubkey] subscribed to [channel] for [dataTypes]; empty means all types.
  void noteInterest(String pubkey, String channel, Set<int> dataTypes) {
    final types = _interests
        .putIfAbsent(pubkey, () => {})
        .putIfAbsent(channel, () => <int>{});
    types.addAll(dataTypes.isEmpty ? const {_anyDataType} : dataTypes);
    _scheduleSave();
  }

  /// Forgets a revoked client and every frame only it was interested in.
  void forgetClient(String pubkey) {
    if (_interests.remove(pubkey) == null) return;
    _entries.removeWhere(
      (entry) => !_interests.keys.any((key) => _wants(key, entry)),
    );
    _scheduleSave();
  }

  bool _wants(String pubkey, ArchivedChannelData entry) {
    final types = _interests[pubkey]?[entry.channel];
    if (types == null) return false;
    return types.contains(_anyDataType) || types.contains(entry.dataType);
  }

  /// Keeps a received frame if some paired client registered an interest.
  void record(ChannelDataEvent event) {
    if (event.outgoing) return;
    final entry = ArchivedChannelData(
      channel: event.channelName,
      channelIndex: event.channelIndex,
      dataType: event.dataType,
      payload: event.payload,
      snrRaw: event.snrRaw,
      receivedAt: event.receivedAt,
    );
    if (!_interests.keys.any((key) => _wants(key, entry))) return;
    _entries.add(entry);
    _prune();
    _scheduleSave();
  }

  /// Frames [pubkey] registered an interest in, received at or after [since]
  /// (inclusive; clients dedupe), oldest first, optionally narrowed to one
  /// [channel] and to [dataTypes].
  List<ArchivedChannelData> replay(
    String pubkey, {
    required DateTime since,
    String? channel,
    Set<int> dataTypes = const {},
  }) {
    _prune();
    return _entries.where((entry) {
      if (!_wants(pubkey, entry)) return false;
      if (channel != null && entry.channel != channel) return false;
      if (dataTypes.isNotEmpty && !dataTypes.contains(entry.dataType)) {
        return false;
      }
      return !entry.receivedAt.isBefore(since);
    }).toList()..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
  }

  Future<void> clear() async {
    _entries.clear();
    await flush();
  }

  void _prune() {
    final cutoff = DateTime.now().toUtc().subtract(maxAge);
    _entries.removeWhere((entry) => entry.receivedAt.isBefore(cutoff));
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () => unawaited(flush()));
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'interests': _interests.map(
            (key, channels) => MapEntry(
              key,
              channels.map((channel, types) => MapEntry(channel, [...types])),
            ),
          ),
          'entries': [for (final entry in _entries) entry.toJson()],
        }),
      );
    } catch (error) {
      appLogger.warn('archive save failed: $error', tag: 'LocalApi');
    }
  }
}
