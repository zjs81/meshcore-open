import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/helpers/link_handler.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/channel.dart';
import 'package:meshcore_open/screens/channel_chat_screen.dart';

class _FakeConnector extends MeshCoreConnector {
  _FakeConnector({this.channels = const []});

  @override
  final List<Channel> channels;

  int markReadCalls = 0;
  int lastMarkedIndex = -1;

  @override
  int getUnreadCountForChannelIndex(int channelIndex) => 3;

  @override
  void markChannelRead(int channelIndex) {
    markReadCalls++;
    lastMarkedIndex = channelIndex;
  }
}

class _RouteRecorder extends NavigatorObserver {
  Route<dynamic>? pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed = route;
  }
}

Future<_FakeConnector> _pump(
  WidgetTester tester, {
  required List<Channel> channels,
}) async {
  final connector = _FakeConnector(channels: channels);
  await tester.pumpWidget(
    ChangeNotifierProvider<MeshCoreConnector>.value(
      value: connector,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [_routeRecorder],
        home: const Scaffold(body: SizedBox()),
      ),
    ),
  );
  return connector;
}

final _routeRecorder = _RouteRecorder();

Channel _channel(int index, String name) =>
    Channel(index: index, name: name, psk: Uint8List(16)..[0] = index + 1);

void main() {
  setUp(() => _routeRecorder.pushed = null);

  testWidgets('tapping a known hashtag opens the channel, no dialog', (
    tester,
  ) async {
    final connector = await _pump(tester, channels: [_channel(2, '#Ops')]);
    final context = tester.element(find.byType(Scaffold));

    await LinkHandler.handleHashtagTap(context, 'ops');

    expect(find.byType(AlertDialog), findsNothing);
    expect(connector.markReadCalls, 1);
    expect(connector.lastMarkedIndex, 2);

    final route = _routeRecorder.pushed;
    expect(route, isA<MaterialPageRoute<dynamic>>());
    final opened = (route! as MaterialPageRoute<dynamic>).builder(context);
    expect(opened, isA<ChannelChatScreen>());
    expect((opened as ChannelChatScreen).channel.name, '#Ops');
    expect(opened.initialUnreadCount, 3);

    Navigator.pop(context);
  });

  testWidgets('tapping an unknown hashtag still offers to add it', (
    tester,
  ) async {
    await _pump(tester, channels: [_channel(2, '#Ops')]);
    final context = tester.element(find.byType(Scaffold));

    LinkHandler.handleHashtagTap(context, 'radio');
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(_routeRecorder.pushed, isA<DialogRoute<bool>>());

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
