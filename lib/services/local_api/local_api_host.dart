import 'dart:async';
import 'dart:typed_data';

import '../../connector/meshcore_connector.dart';
import '../../models/channel.dart';
import '../../models/contact.dart';
import '../../models/mesh_event.dart';
import '../../storage/region_store.dart';
import '../image_chunk_transport.dart' show outPathUnknown;

/// An explicit route for `channel.sendData`: hop hashes in send order, each
/// [hashSize] bytes (1–3). No hashes means zero-hop.
class ChannelDataPath {
  /// The packet header keeps the hop count in 6 bits and the firmware takes at
  /// most 64 path bytes.
  static const int maxHops = 63;
  static const int maxBytes = 64;

  final Uint8List hashes;
  final int hashSize;

  ChannelDataPath(this.hashes, {this.hashSize = 1})
    : assert(hashSize >= 1 && hashSize <= 3),
      assert(hashes.length % hashSize == 0),
      assert(hashes.length ~/ hashSize <= maxHops),
      assert(hashes.length <= maxBytes);

  bool get isZeroHop => hashes.isEmpty;

  /// The firmware's packed `path_len`: hash size - 1 in the top two bits, the
  /// hop count in the low six.
  int get pathLenByte => ((hashSize - 1) << 6) | (hashes.length ~/ hashSize);
}

/// What the local API needs from the radio, separated from the connector so the
/// server can be tested without BLE.
abstract class LocalApiHost {
  bool get isConnected;

  /// Connected and the radio's channels are loaded, so channel names resolve.
  bool get isReady;

  /// Fires when the connection, the channel list or the node identity may
  /// have changed. The server compares snapshots, so spurious ticks are fine.
  Stream<void> get changes;

  /// Whether the connected firmware can send channel data.
  bool get supportsChannelData;

  /// Node identity, firmware, battery, radio parameters and channels.
  Map<String, Object?> deviceInfo();

  List<Map<String, Object?>> channels();

  List<Map<String, Object?>> contacts({int limit = 200});

  /// Live traffic, including this app's own sends (flagged `outgoing`).
  Stream<MeshEvent> get events;

  /// The channel in slot [index], or null.
  Channel? channelAt(int index);

  /// Every channel whose name is exactly [name].
  List<Channel> channelsNamed(String name);

  /// The one contact whose key is [pubkeyHex] (see [matchPubkey]), or null.
  Contact? resolveContact(String pubkeyHex);

  /// Region names the user saved in the app (Settings → Regions).
  List<String> savedRegions();

  /// [region] overrides the channel's flood scope for this message only.
  Future<void> sendChannelText(Channel channel, String text, {String? region});

  /// Returns false when the transport cannot send (disconnected, firmware too
  /// old); throws on a firmware error or command timeout. Without [path] the
  /// data floods; with one it goes direct along it, and an empty path is
  /// zero-hop (heard only by radios in range, forwarded by none).
  /// [priority] skips the post-receive back-off and the quiet wait (and, for
  /// a direct send, the queue behind other channel sends); [trace] gets the
  /// timings.
  Future<bool> sendChannelData(
    Channel channel,
    int dataType,
    Uint8List payload, {
    String? region,
    ChannelDataPath? path,
    bool priority = false,
    ChannelSendTrace? trace,
  });

  Future<void> sendDirectText(Contact contact, String text);

  Future<void> sendAdvert({bool flood = true});

  /// Adds the hashtag channel [name] (`#…`) in the first free slot, its key
  /// derived from the name. Returns the slot, or null when none is free.
  Future<int?> addHashtagChannel(String name);
}

class ConnectorLocalApiHost implements LocalApiHost {
  final MeshCoreConnector connector;

  ConnectorLocalApiHost(this.connector);

  @override
  bool get isConnected => connector.isConnected;

  @override
  bool get isReady =>
      connector.isConnected &&
      connector.hasLoadedChannels &&
      !connector.isSyncingChannels;

  @override
  Stream<void> get changes {
    late final StreamController<void> controller;
    void tick() => controller.add(null);
    controller = StreamController<void>.broadcast(
      onListen: () => connector.addListener(tick),
      onCancel: () => connector.removeListener(tick),
    );
    return controller.stream;
  }

  @override
  bool get supportsChannelData => connector.supportsChannelData;

  @override
  Map<String, Object?> deviceInfo() {
    final pubkey = connector.selfPublicKey;
    return {
      'connected': connector.isConnected,
      'name': connector.selfName,
      'pubkey': pubkey == null ? null : _hex(pubkey),
      'firmwareVerCode': connector.firmwareVerCode,
      'batteryMv': connector.batteryMillivolts,
      'batteryPercent': connector.batteryPercent,
      'radio': {
        'freqHz': connector.currentFreqHz,
        'bwHz': connector.currentBwHz,
        'sf': connector.currentSf,
        'cr': connector.currentCr,
        'txPowerDbm': connector.currentTxPower,
      },
    };
  }

  @override
  List<Map<String, Object?>> channels() => [
    for (final channel in connector.channels)
      {
        'index': channel.index,
        'name': channel.name,
        'isPublic': channel.isPublicChannel,
        'storageId': channel.storageId,
      },
  ];

  @override
  List<Map<String, Object?>> contacts({int limit = 200}) {
    final list = connector.contacts.take(limit);
    return [
      for (final contact in list)
        {
          'pubkey': contact.publicKeyHex,
          'name': contact.name,
          'type': contact.type,
          'lastSeen': contact.lastSeen.toUtc().toIso8601String(),
        },
    ];
  }

  @override
  Stream<MeshEvent> get events => connector.meshEvents;

  @override
  Channel? channelAt(int index) {
    for (final channel in connector.channels) {
      if (channel.index == index) return channel;
    }
    return null;
  }

  @override
  List<Channel> channelsNamed(String name) =>
      connector.channels.where((channel) => channel.name == name).toList();

  @override
  Contact? resolveContact(String pubkeyHex) => matchPubkey(
    connector.contacts,
    (contact) => contact.publicKeyHex,
    pubkeyHex,
  );

  @override
  List<String> savedRegions() => RegionStore().loadRegions();

  @override
  Future<void> sendChannelText(
    Channel channel,
    String text, {
    String? region,
  }) => connector.sendChannelMessage(channel, text, region: region);

  @override
  Future<bool> sendChannelData(
    Channel channel,
    int dataType,
    Uint8List payload, {
    String? region,
    ChannelDataPath? path,
    bool priority = false,
    ChannelSendTrace? trace,
  }) => connector.sendChannelData(
    channelIndex: channel.index,
    dataType: dataType,
    payload: payload,
    region: region,
    pathLen: path?.pathLenByte ?? outPathUnknown,
    path: path?.hashes,
    priority: priority,
    trace: trace,
  );

  @override
  Future<void> sendDirectText(Contact contact, String text) =>
      connector.sendMessage(contact, text);

  @override
  Future<void> sendAdvert({bool flood = true}) =>
      connector.sendSelfAdvert(flood: flood);

  @override
  Future<int?> addHashtagChannel(String name) async {
    final used = {
      ...connector.channels.map((channel) => channel.index),
      ...connector.unconfirmedChannelSlots,
    };
    for (var index = 0; index < connector.maxChannels; index++) {
      if (used.contains(index)) continue;
      await connector.setChannel(
        index,
        name,
        Channel.derivePskFromHashtag(name),
      );
      return index;
    }
    return null;
  }
}

/// The one item whose hex key equals [query], compared case-insensitively,
/// or else the one whose key starts with it when [query] has at least 12
/// hex characters. Null when nothing or more than one item matches.
T? matchPubkey<T>(
  Iterable<T> items,
  String Function(T item) keyOf,
  String query,
) {
  final wanted = query.toLowerCase();
  if (!_hexKey.hasMatch(wanted)) return null;
  T? prefixMatch;
  var prefixMatches = 0;
  for (final item in items) {
    final key = keyOf(item).toLowerCase();
    if (key == wanted) return item;
    if (wanted.length >= 12 && key.startsWith(wanted)) {
      prefixMatch = item;
      prefixMatches++;
    }
  }
  return prefixMatches == 1 ? prefixMatch : null;
}

final RegExp _hexKey = RegExp(r'^[0-9a-f]{1,64}$');

String _hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
