import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpx/gpx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/connector/meshcore_protocol.dart';
import 'package:meshcore_open/helpers/message_url_image_helper.dart';
import 'package:meshcore_open/models/bookmarked_message.dart';
import 'package:meshcore_open/review_mode/review_radio.dart';
import 'package:meshcore_open/services/app_settings_service.dart';
import 'package:meshcore_open/services/message_retry_service.dart';
import 'package:meshcore_open/services/path_history_service.dart';
import 'package:meshcore_open/services/storage_service.dart';
import 'package:meshcore_open/services/translation_service.dart';
import 'package:meshcore_open/storage/prefs_manager.dart';
import 'package:meshcore_open/utils/bookmark_markdown_export.dart';
import 'package:meshcore_open/utils/gpx_export.dart';

// The Export page's data: which contacts each GPX option picks and what the
// file holds, and bookmarks round-tripping into the Markdown export. Uses the
// review-mode radio's sample contacts and messages.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('export_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempDir.path,
      );

  late MeshCoreConnector connector;

  // Created here, outside any test's fake time, so its futures always run.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    final settings = AppSettingsService();
    await settings.loadSettings();
    connector = MeshCoreConnector()
      ..initialize(
        retryService: MessageRetryService(),
        pathHistoryService: PathHistoryService(StorageService()),
        appSettingsService: settings,
        translationService: TranslationService(settings),
      )
      ..reviewRadioFactoryForTest = () => ReviewRadio(
        scheduledMessageInterval: const Duration(hours: 1),
        ackDelay: const Duration(milliseconds: 50),
        replyDelay: const Duration(hours: 1),
      );
    await connector.connectReview();
    final end = DateTime.now().add(const Duration(seconds: 8));
    while (connector.selfName == null && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });

  Set<String> names(Iterable<ContactExport> contacts) =>
      contacts.map((c) => c.name).toSet();

  test('GPX: repeaters and rooms, users / companions, all contacts', () async {
    final located = connector.allContacts
        .where((c) => c.latitude != null && c.longitude != null)
        .toList();
    Set<String> expected(bool Function(int type) keep) =>
        located.where((c) => keep(c.type)).map((c) => c.name.trim()).toSet();

    final repeaters = GpxExport(connector)..addRepeaters();
    expect(
      names(repeaters.contacts),
      expected((t) => t == advTypeRepeater || t == advTypeRoom),
    );
    expect(
      names(repeaters.contacts),
      containsAll(['Hilltop Repeater', 'Trailhead Room']),
    );

    final users = GpxExport(connector)..addContacts();
    expect(names(users.contacts), expected((t) => t == advTypeChat));
    expect(names(users.contacts), contains('Maya'));
    expect(names(users.contacts), isNot(contains('Hilltop Repeater')));

    final all = GpxExport(connector)..addAll();
    expect(names(all.contacts), expected((_) => true));
    expect(
      all.contacts.length,
      repeaters.contacts.length + users.contacts.length,
    );

    // One waypoint per contact with its name, position, type, public key and
    // meshcore:// link.
    final xml = all.buildGpx('All contacts', 'Locations');
    final gpx = GpxReader().fromString(xml);
    expect(gpx.metadata?.name, 'All contacts');
    expect(gpx.wpts, hasLength(located.length));
    for (final c in located) {
      final wpt = gpx.wpts.singleWhere((w) => w.name == c.name.trim());
      expect(wpt.lat, closeTo(c.latitude!, 1e-9));
      expect(wpt.lon, closeTo(c.longitude!, 1e-9));
      expect(wpt.desc, contains(c.publicKeyHex));
      expect(wpt.desc, contains(c.typeLabelRaw));
      if (c.rawPacket != null) expect(xml, contains('meshcore://'));
    }

    // Nothing selected: "no contacts", and no file is written.
    expect(
      await GpxExport(connector).exportGPX('n', 'd', 'f', 't', 's'),
      gpxExportNoContacts,
    );
  });

  test('Bookmarks: a bookmarked message is found and exported', () async {
    final previous = MessageUrlImageHelper.loadLinkImages.value;
    MessageUrlImageHelper.loadLinkImages.value = false;
    addTearDown(() => MessageUrlImageHelper.loadLinkImages.value = previous);

    final contact = connector.contacts.firstWhere(
      (c) => connector.getMessages(c).any((m) => m.text.isNotEmpty),
    );
    final message = connector
        .getMessages(contact)
        .firstWhere((m) => m.text.isNotEmpty);
    final bookmark = BookmarkedMessage.fromContact(
      message: message,
      contactKey: contact.publicKeyHex,
      contactName: contact.name,
      senderName: contact.name,
    );

    await connector.setBookmarkedMessage(bookmark, isBookmarked: true);
    final saved = await connector.loadBookmarkedMessages();
    expect(saved.map((b) => b.messageId), contains(message.messageId));

    final markdown = await buildBookmarksMarkdown(
      saved,
      publicGateway: '',
      exportedAt: DateTime(2026, 11, 23),
    );
    expect(markdown, contains(contact.name));
    expect(markdown, contains(message.text));

    await connector.setBookmarkedMessage(bookmark, isBookmarked: false);
    final after = await connector.loadBookmarkedMessages();
    expect(after.map((b) => b.messageId), isNot(contains(message.messageId)));
  });
}
