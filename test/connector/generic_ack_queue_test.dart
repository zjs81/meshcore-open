import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';

void main() {
  group('takeFirstPendingChannelGenericAck', () {
    test('does not consume a non-channel ack entry at the head of the queue', () {
      final queue = <PendingCommandAck>[
        const PendingCommandAck(commandCode: cmdSetDeviceTime),
        const PendingCommandAck(
          commandCode: cmdSendChannelTxtMsg,
          channelSendQueueId: 'channel-1',
        ),
      ];

      final ack = takeFirstPendingChannelGenericAck(queue);

      expect(ack, isNull);
      expect(queue, hasLength(2));
      expect(queue.first.commandCode, cmdSetDeviceTime);
    });

    test('consumes the first channel ack entry when it has a queue id', () {
      final queue = <PendingCommandAck>[
        const PendingCommandAck(
          commandCode: cmdSendChannelTxtMsg,
          channelSendQueueId: 'channel-1',
        ),
      ];

      final ack = takeFirstPendingChannelGenericAck(queue);

      expect(ack, isNotNull);
      expect(ack!.channelSendQueueId, 'channel-1');
      expect(queue, isEmpty);
    });
  });
}
