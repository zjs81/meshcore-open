import '../helpers/message_url_image_helper.dart';
import '../models/bookmarked_message.dart';

Future<String> buildBookmarksMarkdown(
  List<BookmarkedMessage> bookmarks, {
  required String publicGateway,
  DateTime? exportedAt,
}) async {
  final date = (exportedAt ?? DateTime.now()).toLocal();
  final output = StringBuffer()
    ..writeln('# MeshCore-Open Bookmarks')
    ..writeln()
    ..writeln('Exported: ${_date(date)}')
    ..writeln();

  final contacts = _groupBySource(
    bookmarks.where(
      (bookmark) => bookmark.sourceType == BookmarkSourceType.contact,
    ),
  );
  if (contacts.isNotEmpty) {
    output.writeln('## Contacts');
    for (final group in contacts) {
      output
        ..writeln()
        ..writeln('### ${_safeHeading(group.first.sourceName)}')
        ..writeln();
      await _writeGroup(output, group, publicGateway: publicGateway);
    }
  }

  final channels = _groupBySource(
    bookmarks.where(
      (bookmark) => bookmark.sourceType == BookmarkSourceType.channel,
    ),
  );
  if (channels.isNotEmpty) {
    if (contacts.isNotEmpty) output.writeln();
    output.writeln('## Channels');
    for (final group in channels) {
      final name = _singleLine(group.first.sourceName);
      output
        ..writeln()
        ..writeln('### $name')
        ..writeln();
      await _writeGroup(output, group, publicGateway: publicGateway);
    }
  }

  return '${output.toString().trimRight()}\n';
}

List<List<BookmarkedMessage>> _groupBySource(
  Iterable<BookmarkedMessage> bookmarks,
) {
  final bySource = <String, List<BookmarkedMessage>>{};
  for (final bookmark in bookmarks) {
    bySource.putIfAbsent(bookmark.sourceId, () => []).add(bookmark);
  }
  final groups = bySource.values.toList();
  for (final group in groups) {
    group.sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
  }
  groups.sort((a, b) {
    final byName = a.first.sourceName.compareTo(b.first.sourceName);
    return byName != 0 ? byName : a.first.sourceId.compareTo(b.first.sourceId);
  });
  return groups;
}

Future<void> _writeGroup(
  StringBuffer output,
  List<BookmarkedMessage> bookmarks, {
  required String publicGateway,
}) async {
  for (var i = 0; i < bookmarks.length; i++) {
    final bookmark = bookmarks[i];
    output
      ..writeln(
        '**${_safeInline(bookmark.senderName)} · ${_dateTime(bookmark.receivedAt)}**',
      )
      ..writeln();

    final translation = bookmark.translatedText?.trim();
    if (translation != null &&
        translation.isNotEmpty &&
        translation != bookmark.text) {
      output
        ..write('*${_markdownLinks(bookmark.text)}*')
        ..writeln()
        ..writeln(_markdownLinks(translation));
    } else {
      output.writeln(_markdownLinks(bookmark.text));
    }

    final imageUrl = await MessageUrlImageHelper.parse(
      bookmark.text,
      publicGateway: publicGateway,
      respectLoadSetting: false,
    );
    if (imageUrl != null) {
      final destination = _markdownDestination(imageUrl);
      output
        ..writeln()
        ..writeln('![Image]($destination)')
        ..writeln()
        ..writeln('[Image URL]($destination)');
    }

    if (i < bookmarks.length - 1) output.writeln();
  }
}

String _singleLine(String value) =>
    value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();

String _markdownLinks(String text) {
  final urls = RegExp(
    r'''(?:https?://|ipfs:(?:/{0,2}))[\w\-._~:/?#\[\]@!$&'()*+,;=%]+''',
    caseSensitive: false,
  );
  final linked = text.trim().replaceAllMapped(urls, (match) {
    final raw = match.group(0)!;
    var url = raw;
    while (url.isNotEmpty && RegExp(r'[.,!?;:]$').hasMatch(url)) {
      url = url.substring(0, url.length - 1);
    }
    while (url.endsWith(')') &&
        '('.allMatches(url).length < ')'.allMatches(url).length) {
      url = url.substring(0, url.length - 1);
    }
    if (url.isEmpty) return raw;
    final suffix = raw.substring(url.length);
    final label = url.replaceAll('[', r'\[').replaceAll(']', r'\]');
    return '[$label](${_markdownDestination(url)})$suffix';
  });
  return linked
      .replaceFirst(RegExp(r'^\*+'), '')
      .replaceFirst(RegExp(r'\*+$'), '')
      .trim();
}

String _markdownDestination(String url) => url
    .replaceAll('<', '%3C')
    .replaceAll('>', '%3E')
    .replaceAll(' ', '%20')
    .replaceAll('(', '%28')
    .replaceAll(')', '%29');

String _safeHeading(String value) =>
    value.replaceAll(RegExp(r'[\r\n]+'), ' ').replaceAll('#', r'\#');

String _safeInline(String value) => value
    .replaceAll(RegExp(r'[\r\n]+'), ' ')
    .replaceAll('*', r'\*')
    .replaceAll('_', r'\_');

String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _dateTime(DateTime date) =>
    '${_date(date)} ${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';
