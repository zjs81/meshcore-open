import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_open/helpers/message_url_image_helper.dart';
import 'package:meshcore_open/models/bookmarked_message.dart';
import 'package:meshcore_open/utils/bookmark_markdown_export.dart';

BookmarkedMessage _bookmark({
  required BookmarkSourceType type,
  required String sourceId,
  required String sourceName,
  required String id,
  required String text,
  required int hour,
  String? translatedText,
}) {
  final date = DateTime(2026, 11, 12, hour);
  return BookmarkedMessage(
    sourceType: type,
    sourceId: sourceId,
    sourceName: sourceName,
    messageId: id,
    senderName: 'Alex',
    text: text,
    translatedText: translatedText,
    timestamp: date,
    receivedAt: date,
    isOutgoing: false,
  );
}

void main() {
  test('exports grouped bookmarks oldest-to-newest with valid links', () async {
    final previousSetting = MessageUrlImageHelper.loadLinkImages.value;
    MessageUrlImageHelper.loadLinkImages.value = false;
    addTearDown(() {
      MessageUrlImageHelper.loadLinkImages.value = previousSetting;
    });

    final markdown = await buildBookmarksMarkdown(
      [
        _bookmark(
          type: BookmarkSourceType.channel,
          sourceId: 'channel-1',
          sourceName: '#flachwitze',
          id: 'channel-image',
          text: 'See https://example.com/info and ipfs://bafyimage',
          hour: 15,
        ),
        _bookmark(
          type: BookmarkSourceType.contact,
          sourceId: 'contact-b',
          sourceName: 'Bob',
          id: 'bob',
          text: 'Bob message',
          hour: 13,
        ),
        _bookmark(
          type: BookmarkSourceType.contact,
          sourceId: 'contact-a',
          sourceName: 'Alice',
          id: 'alice-new',
          text: 'Contact newest',
          hour: 14,
        ),
        _bookmark(
          type: BookmarkSourceType.contact,
          sourceId: 'contact-a',
          sourceName: 'Alice',
          id: 'alice-old',
          text: ' *Contact oldest* ',
          hour: 12,
          translatedText: 'Oldest translation',
        ),
      ],
      publicGateway: 'https://gateway.example/ipfs/',
      exportedAt: DateTime(2026, 11, 13, 15, 20),
    );

    expect(markdown, contains('# MeshCore-Open Bookmarks'));
    expect(markdown, contains('Exported: 2026-11-13'));
    expect(markdown, contains('## Contacts'));
    expect(markdown, contains('## Channels'));
    expect(markdown, contains('### #flachwitze'));
    expect(
      markdown,
      contains('[https://example.com/info](https://example.com/info)'),
    );
    expect(
      markdown,
      contains('![Image](https://gateway.example/ipfs/bafyimage)'),
    );
    expect(
      markdown,
      contains('[Image URL](https://gateway.example/ipfs/bafyimage)'),
    );
    expect(markdown, isNot(contains('<https://')));
    expect(markdown, contains('*Contact oldest*\nOldest translation'));
    expect(markdown, isNot(contains('*Contact oldest*  ')));
    expect(markdown, isNot(contains('Translation:')));
    expect(
      markdown.indexOf('Contact oldest'),
      lessThan(markdown.indexOf('Contact newest')),
    );
    expect(
      markdown.indexOf('## Contacts'),
      lessThan(markdown.indexOf('## Channels')),
    );
  });
}
