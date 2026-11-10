import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/message.dart';
import 'package:meshcore_open/storage/channel_message_store.dart';
import 'package:meshcore_open/storage/history_store.dart';
import 'package:meshcore_open/storage/message_store.dart';

const _device = 'abcdef012345';
const _contact = 'contact';
const _channel = 'channel';

class _History extends HistoryStore {
  final data = <String, List<String>>{};
  int reads = 0;
  bool failNextWrite = false;
  bool failNextRemove = false;
  Completer<void>? nextWriteGate;
  Completer<void>? nextWriteStarted;

  @override
  Future<String?> getString(String key) async {
    reads++;
    final entries = data[key];
    return entries == null ? null : '[${entries.join(',')}]';
  }

  @override
  Future<bool> setString(String key, String value) async {
    data[key] = (jsonDecode(value) as List).map(jsonEncode).toList();
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (failNextRemove) {
      failNextRemove = false;
      return false;
    }
    data.remove(key);
    return true;
  }

  @override
  Future<Set<String>> getKeys() async => data.keys.toSet();

  @override
  Future<int> entryCount(String key) async => data[key]?.length ?? 0;

  @override
  Future<List<String>> readEntries(
    String key, {
    int offset = 0,
    int? limit,
  }) async {
    reads++;
    final entries = (data[key] ?? []).skip(offset);
    return (limit == null ? entries : entries.take(limit)).toList();
  }

  @override
  Future<int> replaceTail(
    String key,
    int preservedCount,
    List<String> entries, {
    int maxEntries = 1000,
  }) async {
    final gate = nextWriteGate;
    nextWriteGate = null;
    nextWriteStarted?.complete();
    nextWriteStarted = null;
    await gate?.future;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Disk unavailable');
    }
    final prefix = (data[key] ?? []).take(preservedCount).toList();
    final all = [...prefix, ...entries];
    final dropped = (all.length - maxEntries).clamp(0, all.length);
    data[key] = all.skip(dropped).toList();
    return (prefix.length - dropped).clamp(0, prefix.length);
  }

  List<String> texts(String key) => [
    for (final entry in data[key] ?? [])
      (jsonDecode(entry) as Map)['text'] as String,
  ];
}

Message _dm(int i, {String? id, String? text}) => Message(
  senderKey: Uint8List.fromList([1, 2, 3]),
  text: text ?? 'm$i',
  timestamp: DateTime.fromMillisecondsSinceEpoch(1000 * i),
  isOutgoing: false,
  messageId: id ?? 'id$i',
);

ChannelMessage _ch(int i) => ChannelMessage(
  senderKey: null,
  senderName: 'Bob',
  text: 'c$i',
  timestamp: DateTime.fromMillisecondsSinceEpoch(1000 * i),
  isOutgoing: false,
  status: ChannelMessageStatus.sent,
  channelIndex: 0,
  messageId: 'cid$i',
);

void main() {
  late _History history;
  late MessageStore direct;
  late ChannelMessageStore channel;
  late String directKey;
  late String channelKey;

  setUp(() {
    history = _History();
    HistoryStore.use(history);
    direct = MessageStore()..setPublicKeyHex = _device;
    channel = ChannelMessageStore()..setPublicKeyHex = _device;
    directKey = '${direct.keyFor}$_contact';
    channelKey = '${channel.keyFor}_$_channel';
  });

  tearDown(HistoryStore.reset);

  test(
    'reconciled saves preserve prefixes without reading archived JSON',
    () async {
      await direct.saveMessages(_contact, [for (var i = 0; i < 8; i++) _dm(i)]);
      await channel.saveChannelMessages(_channel, [
        for (var i = 0; i < 8; i++) _ch(i),
      ]);
      direct.setArchivedCount(_contact, 6);
      channel.setArchivedCount(_channel, 6);
      history.reads = 0;

      await direct.saveMessages(_contact, [_dm(6), _dm(8)]);
      await channel.saveChannelMessages(_channel, [_ch(6), _ch(8)]);

      expect(history.reads, 0);
      expect(history.texts(directKey), [
        for (var i = 0; i <= 6; i++) 'm$i',
        'm8',
      ]);
      expect(history.texts(channelKey), [
        for (var i = 0; i <= 6; i++) 'c$i',
        'c8',
      ]);
    },
  );

  test('overlapping saves consume each unsaved trim once', () async {
    direct.setArchivedCount(_contact, 0);
    await direct.saveMessages(_contact, [_dm(0), _dm(1), _dm(2)]);
    direct.archive(_contact, [_dm(0)]);
    final gate = Completer<void>();
    final started = Completer<void>();
    history.nextWriteGate = gate;
    history.nextWriteStarted = started;
    final first = direct.saveMessages(_contact, [_dm(1), _dm(2), _dm(3)]);
    await started.future;

    direct.archive(_contact, [_dm(1)]);
    final second = direct.saveMessages(_contact, [_dm(2), _dm(3), _dm(4)]);
    gate.complete();
    await Future.wait([first, second]);

    expect(history.texts(directKey), [for (var i = 0; i <= 4; i++) 'm$i']);
    expect(direct.archivedCount(_contact), 2);
  });

  test('failed writes retain unsaved trims for retry', () async {
    direct.setArchivedCount(_contact, 0);
    await direct.saveMessages(_contact, [_dm(0), _dm(1)]);
    direct.archive(_contact, [_dm(0)]);
    history.failNextWrite = true;
    await expectLater(
      direct.saveMessages(_contact, [_dm(1), _dm(2)]),
      throwsStateError,
    );
    expect(direct.archivedCount(_contact), 1);
    expect(history.texts(directKey), ['m0', 'm1']);

    await direct.saveMessages(_contact, [_dm(1), _dm(2)]);
    expect(history.texts(directKey), ['m0', 'm1', 'm2']);
    expect(direct.archivedCount(_contact), 1);
  });

  test(
    'queued snapshots survive scope switches without restoring old bookkeeping',
    () async {
      direct.setArchivedCount(_contact, 0);
      final messages = [_dm(0)];
      final gate = Completer<void>();
      final started = Completer<void>();
      history.nextWriteGate = gate;
      history.nextWriteStarted = started;
      final pending = direct.saveMessages(_contact, messages);
      await started.future;
      messages.clear();
      direct.forgetArchive();
      direct.setPublicKeyHex = '0123456789abcd';
      final newKey = '${direct.keyFor}$_contact';
      await direct.saveMessages(_contact, [_dm(1)]);
      gate.complete();
      await pending;

      expect(history.texts(directKey), ['m0']);
      expect(history.texts(newKey), ['m1']);
      direct.setPublicKeyHex = _device;
      expect(direct.archivedCount(_contact), isNull);
    },
  );

  test(
    'a clear through another instance is ordered after in-flight saves',
    () async {
      channel.setArchivedCount(_channel, 0);
      final gate = Completer<void>();
      final started = Completer<void>();
      history.nextWriteGate = gate;
      history.nextWriteStarted = started;
      final save = channel.saveChannelMessages(_channel, [_ch(0)]);
      await started.future;
      final clear = (ChannelMessageStore()..setPublicKeyHex = _device)
          .clearChannelMessages(_channel);
      final laterSave = channel.saveChannelMessages(_channel, [_ch(1)]);
      gate.complete();
      await Future.wait([save, clear, laterSave]);

      expect(history.texts(channelKey), ['c1']);
      expect(channel.archivedCount(_channel), 0);
    },
  );

  test('cap reductions remain correct across queued saves', () async {
    const cap = MessageStore.maxStoredMessages;
    await direct.saveMessages(_contact, [for (var i = 0; i < cap; i++) _dm(i)]);
    direct.setArchivedCount(_contact, cap - 2);
    final first = direct.saveMessages(_contact, [
      _dm(cap - 2),
      _dm(cap - 1),
      _dm(cap),
    ]);
    final second = direct.saveMessages(_contact, [
      _dm(cap - 2),
      _dm(cap - 1),
      _dm(cap),
      _dm(cap + 1),
    ]);
    await Future.wait([first, second]);

    expect(history.texts(directKey).first, 'm2');
    expect(history.texts(directKey).last, 'm${cap + 1}');
    expect(history.data[directKey], hasLength(cap));
    expect(direct.archivedCount(_contact), cap - 4);
  });

  test(
    'unreconciled merge preserves distinct duplicates without message IDs',
    () async {
      final duplicate = _dm(0, id: '', text: 'same');
      await direct.saveMessages(_contact, [duplicate, duplicate]);
      direct.forgetArchive();
      await direct.saveMessages(_contact, [duplicate, _dm(1)]);
      expect(history.texts(directKey), ['same', 'same', 'm1']);
    },
  );

  test(
    'backend replacement cannot reuse another backend archive counts',
    () async {
      direct.setArchivedCount(_contact, 100);
      final replacement = _History();
      HistoryStore.use(replacement);
      expect(direct.archivedCount(_contact), isNull);
      await direct.saveMessages(_contact, [_dm(0)]);
      expect(replacement.texts(directKey), ['m0']);
    },
  );
}
