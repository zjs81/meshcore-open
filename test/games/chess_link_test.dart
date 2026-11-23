import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/games/chess/chess_link.dart';
import 'package:meshcore_open/games/chess/chess_packets.dart';
import 'package:meshcore_open/games/game_packet.dart';
import 'package:meshcore_open/services/image_chunk_transport.dart';

class _Connector extends MeshCoreConnector {
  final frames = StreamController<Uint8List>.broadcast(sync: true);
  bool mapConfirmed = false;

  @override
  Stream<Uint8List> get receivedFrames => frames.stream;

  @override
  bool get channelMapConfirmed => mapConfirmed;

  @override
  String? channelIdForSlot(int slot) => slot == 2 ? 'chan-two' : null;

  void confirm() {
    mapConfirmed = true;
    notifyListeners();
  }
}

/// A RESP_CODE_CHANNEL_DATA_RECV frame for [payload] on [slot].
Uint8List _frame(int slot, int dataType, Uint8List payload) =>
    Uint8List.fromList([
      respCodeChannelDataRecv,
      8, // SNR
      0,
      0,
      slot,
      0xFF,
      dataType & 0xFF,
      dataType >> 8,
      payload.length,
      ...payload,
    ]);

void main() {
  final payload = ChessDeclinePacket(gameId: 5, declinerName: 'Bob').encode();

  test('passes chess payloads through, keyed by channel id', () async {
    final connector = _Connector()..mapConfirmed = true;
    final link = ConnectorChessLink(connector);
    final heard = <ChessIncoming>[];
    link.incoming.listen(heard.add);

    connector.frames.add(_frame(2, meshcoreOpenDataType, payload));
    connector.frames.add(_frame(2, 0xAE1C, payload)); // images
    connector.frames.add(_frame(3, meshcoreOpenDataType, payload)); // unknown
    connector.frames.add(
      _frame(2, meshcoreOpenDataType, Uint8List.fromList([0x20, 0, 0, 0])),
    ); // another app nibble
    await Future<void>.delayed(Duration.zero);

    expect(heard, hasLength(1));
    expect(heard.single.channelId, 'chan-two');
    expect(heard.single.payload, payload);
    link.dispose();
  });

  test('holds frames until the channel map is confirmed', () async {
    final connector = _Connector();
    final link = ConnectorChessLink(connector);
    final heard = <ChessIncoming>[];
    link.incoming.listen(heard.add);

    connector.frames.add(_frame(2, meshcoreOpenDataType, payload));
    expect(heard, isEmpty);
    connector.confirm();
    // The connector batches change notifications.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(heard, hasLength(1));
    link.dispose();
  });
}
