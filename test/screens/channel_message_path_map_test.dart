import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/models/channel_message.dart';
import 'package:meshcore_open/models/contact.dart';
import 'package:meshcore_open/screens/channel_message_path_screen.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/map_tile_cache_service.dart';
import 'package:provider/provider.dart';

class _FakeConnector extends MeshCoreConnector {
  _FakeConnector(this._contacts, {this.lat = 33.4484, this.lon = -112.0740});

  final List<Contact> _contacts;
  final double? lat;
  final double? lon;

  @override
  List<Contact> get allContacts => _contacts;

  @override
  double? get selfLatitude => lat;

  @override
  double? get selfLongitude => lon;
}

Contact _repeater({
  required int prefix,
  required String name,
  required double latitude,
  required double longitude,
}) {
  return Contact(
    publicKey: Uint8List(32)..first = prefix,
    name: name,
    type: advTypeRepeater,
    pathLength: 0,
    path: Uint8List(0),
    latitude: latitude,
    longitude: longitude,
    lastSeen: DateTime.utc(2026),
  );
}

Widget _wrapWithProviders(MeshCoreConnector connector, Widget child) {
  final settings = AppSettingsService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MeshCoreConnector>.value(value: connector),
      ChangeNotifierProvider<AppSettingsService>.value(value: settings),
      ChangeNotifierProvider<MapTileCacheService>(
        create: (_) => MapTileCacheService(appSettingsService: settings),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets(
    'ChannelMessagePathMapScreen ignores impossible distant hop in polylines, markers, bounds, distance, and hop list',
    (tester) async {
      final localHop3 = _repeater(
        prefix: 0x53,
        name: "Rod's Repeater",
        latitude: 33.46300,
        longitude: -111.65000,
      );
      final localHop4 = _repeater(
        prefix: 0x48,
        name: 'Twain - Clearview',
        latitude: 33.60097,
        longitude: -112.02457,
      );
      final bogusEastCoastHop5 = _repeater(
        prefix: 0x9C,
        name: 'Beacon Hill 1W Repeater',
        latitude: 42.3601,
        longitude: -71.0589,
      );
      final connector = _FakeConnector([
        localHop3,
        localHop4,
        bogusEastCoastHop5,
      ]);

      final message = ChannelMessage(
        senderName: 'Alice',
        text: 'test',
        timestamp: DateTime.utc(2026),
        isOutgoing: false,
        pathBytes: Uint8List.fromList([
          0x6C,
          0x84,
          0x53,
          0x48,
          0x9C,
          0x21,
          0xC9,
          0xEA,
        ]),
        channelIndex: 0,
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          connector,
          ChannelMessagePathMapScreen(message: message, channelMessage: true),
        ),
      );
      await tester.pumpAndSettle();

      // East Coast repeater must not appear as a resolved repeater or in markers.
      expect(find.textContaining('Beacon Hill 1W Repeater'), findsNothing);
      expect(find.textContaining('42.36010'), findsNothing);

      // Expand the hop list panel so all 8 hops in the ListView are built.
      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.text('(9C) Unknown Repeater'), findsOneWidget);

      // Local repeaters should still be listed and plotted.
      expect(find.text("(53) Rod's Repeater"), findsOneWidget);
      expect(find.text('(48) Twain - Clearview'), findsOneWidget);

      // Collapse back so map assertions (PolylineLayer, MarkerLayer, header distance) are visible.
      await tester.tap(find.byIcon(Icons.close_fullscreen));
      await tester.pumpAndSettle();

      // Polyline points and markers must stay in Arizona (no East Coast jump).
      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      final allPolylinePoints = polylineLayer.polylines
          .expand((p) => p.points)
          .toList();
      expect(allPolylinePoints, isNotEmpty);
      for (final point in allPolylinePoints) {
        expect(point.latitude, inInclusiveRange(33.0, 34.0));
        expect(point.longitude, inInclusiveRange(-113.0, -111.0));
      }

      // Segment across unresolved/ignored hops (4 -> You) must be dashed while
      // adjacent local hops (3 -> 4) remain solid.
      expect(
        polylineLayer.polylines.any((p) => p.pattern != StrokePattern.solid()),
        isTrue,
      );

      final markerLayer = tester.widget<MarkerLayer>(
        find.byType(MarkerLayer).first,
      );
      for (final marker in markerLayer.markers) {
        expect(marker.point.latitude, inInclusiveRange(33.0, 34.0));
        expect(marker.point.longitude, inInclusiveRange(-113.0, -111.0));
      }

      // Camera bounds must stay local, not continental.
      final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final fit = flutterMap.options.initialCameraFit as FitBounds;
      expect(fit.bounds.north, lessThan(34.0));
      expect(fit.bounds.east, lessThan(-111.0));

      // Reported path distance must be local (~50-65 km), not thousands of km.
      final distanceFinder = find.textContaining(' km)');
      expect(distanceFinder, findsOneWidget);
      final distanceText = tester.widget<Text>(distanceFinder).data!;
      final kmMatch = RegExp(r'\((\d+\.\d+) km\)').firstMatch(distanceText);
      expect(kmMatch, isNotNull);
      final kmValue = double.parse(kmMatch!.group(1)!);
      expect(kmValue, lessThan(200.0));
      expect(kmValue, greaterThan(10.0));
    },
  );

  testWidgets(
    'ChannelMessagePathMapScreen without self GPS rejects leading outlier and keeps local cluster',
    (tester) async {
      final bogusEastCoast = _repeater(
        prefix: 0x9C,
        name: 'Beacon Hill 1W Repeater',
        latitude: 42.3601,
        longitude: -71.0589,
      );
      final localHop1 = _repeater(
        prefix: 0x48,
        name: 'Twain - Clearview',
        latitude: 33.60097,
        longitude: -112.02457,
      );
      final localHop2 = _repeater(
        prefix: 0x53,
        name: "Rod's Repeater",
        latitude: 33.46300,
        longitude: -111.65000,
      );
      final connector = _FakeConnector(
        [bogusEastCoast, localHop1, localHop2],
        lat: null,
        lon: null,
      );

      final message = ChannelMessage(
        senderName: 'Alice',
        text: 'test',
        timestamp: DateTime.utc(2026),
        isOutgoing: false,
        pathBytes: Uint8List.fromList([0x53, 0x48, 0x9C]),
        channelIndex: 0,
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          connector,
          ChannelMessagePathMapScreen(message: message, channelMessage: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.textContaining('Beacon Hill 1W Repeater'), findsNothing);
      expect(find.text('(9C) Unknown Repeater'), findsOneWidget);
      expect(find.text('(48) Twain - Clearview'), findsOneWidget);
      expect(find.text("(53) Rod's Repeater"), findsOneWidget);

      final polylineLayer = tester.widget<PolylineLayer>(
        find.byType(PolylineLayer),
      );
      final allPoints = polylineLayer.polylines
          .expand((p) => p.points)
          .toList();
      expect(allPoints.length, 2);
      for (final point in allPoints) {
        expect(point.latitude, inInclusiveRange(33.0, 34.0));
        expect(point.longitude, inInclusiveRange(-113.0, -111.0));
      }
    },
  );

  testWidgets(
    'ChannelMessagePathScreen timeline treats impossible distant hop as unknown',
    (tester) async {
      final localHop = _repeater(
        prefix: 0x48,
        name: 'Twain - Clearview',
        latitude: 33.60097,
        longitude: -112.02457,
      );
      final bogusHop = _repeater(
        prefix: 0x9C,
        name: 'Beacon Hill 1W Repeater',
        latitude: 42.3601,
        longitude: -71.0589,
      );
      final connector = _FakeConnector([localHop, bogusHop]);

      final message = ChannelMessage(
        senderName: 'Alice',
        text: 'test',
        timestamp: DateTime.utc(2026),
        isOutgoing: false,
        pathBytes: Uint8List.fromList([0x48, 0x9C]),
        channelIndex: 0,
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          connector,
          ChannelMessagePathScreen(message: message, channelMessage: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('(48) Twain - Clearview'), findsOneWidget);
      expect(find.text('(9C) Unknown Repeater'), findsOneWidget);
      expect(find.textContaining('Beacon Hill 1W Repeater'), findsNothing);
    },
  );
}
