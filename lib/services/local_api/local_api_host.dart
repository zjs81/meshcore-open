import 'dart:async';
import 'dart:typed_data';

import '../../connector/meshcore_connector.dart';
import '../../models/channel.dart';
import '../../models/contact.dart';
import '../../models/mesh_event.dart';

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

  Future<void> sendChannelText(Channel channel, String text);

  /// Returns false when the transport cannot send (disconnected, firmware too
  /// old); throws on a firmware error or command timeout.
  Future<bool> sendChannelData(
    Channel channel,
    int dataType,
    Uint8List payload,
  );

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
  Future<void> sendChannelText(Channel channel, String text) =>
      connector.sendChannelMessage(channel, text);

  @override
  Future<bool> sendChannelData(
    Channel channel,
    int dataType,
    Uint8List payload,
  ) => connector.sendChannelData(
    channelIndex: channel.index,
    dataType: dataType,
    payload: payload,
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
