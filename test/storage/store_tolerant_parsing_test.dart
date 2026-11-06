import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/community.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/community_store.dart';
import 'package:meshcore_open/storage/message_store.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _device = 'abcdef012345';

Future<void> _init(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  PrefsManager.reset();
  await PrefsManager.initialize();
}

const _channelId = '0123456789abcdef';

void main() {
  test(
    'message store skips a malformed record instead of dropping all',
    () async {
      final good = {
        'senderKey': base64Encode([1, 2, 3]),
        'text': 'hello',
        'timestamp': 1000,
        'status': 1,
      };
      await _init({
        'messages_${_device.substring(0, 10)}c1': jsonEncode([
          good,
          {'text': 'no timestamp'},
        ]),
      });
      final store = MessageStore()..setPublicKeyHex = _device;
      final messages = await store.loadMessages('c1');
      expect(messages.map((m) => m.text), ['hello']);
      expect(messages.single.isOutgoing, isFalse);
    },
  );

  test('channel message store skips a malformed record', () async {
    await _init({
      'channel_messages_${_device.substring(0, 10)}_$_channelId': jsonEncode([
        {'text': 'hi', 'timestamp': 1000, 'status': 1},
        'garbage',
      ]),
    });
    final store = ChannelMessageStore()..setPublicKeyHex = _device;
    final messages = await store.loadChannelMessages(_channelId);
    expect(messages.map((m) => m.text), ['hi']);
  });

  test('community store keeps valid communities next to a bad one', () async {
    final community = Community.create(id: 'c1', name: 'Ops');
    await _init({
      'communities_v1${_device.substring(0, 10)}': jsonEncode([
        community.toJson(),
        {'id': 'broken'},
      ]),
    });
    final store = CommunityStore()..setPublicKeyHex = _device;
    final communities = await store.loadCommunities();
    expect(communities.map((c) => c.id), ['c1']);
  });

  test('delivery observations skip malformed entries', () async {
    await _init({
      'delivery_observations': jsonEncode([
        {
          'contact_key': 'k',
          'path_length': 1,
          'message_bytes': 10,
          'delivery_ms': 500,
          'timestamp': DateTime(2026).toIso8601String(),
        },
        {'contact_key': 'bad'},
      ]),
    });
    final observations = await StorageService().loadDeliveryObservations();
    expect(observations, hasLength(1));
    expect(observations.single.isFlood, isFalse);
  });

  test('community hashtag normalization trims before stripping #', () {
    final community = Community.create(id: 'c1', name: 'Ops');
    expect(
      community.deriveCommunityHashtagPsk(' #ops'),
      community.deriveCommunityHashtagPsk('#ops'),
    );
  });
}
