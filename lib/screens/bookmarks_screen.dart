import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/message_url_image_helper.dart';
import '../l10n/l10n.dart';
import '../models/bookmarked_message.dart';
import '../services/app_settings_service.dart';
import '../widgets/chat_send_pipeline.dart';
import '../widgets/empty_state.dart';
import '../widgets/translated_message_content.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<BookmarkedMessage>> _bookmarks;

  @override
  void initState() {
    super.initState();
    _bookmarks = context.read<MeshCoreConnector>().loadBookmarkedMessages();
  }

  void _reload() {
    setState(() {
      _bookmarks = context.read<MeshCoreConnector>().loadBookmarkedMessages();
    });
  }

  Future<void> _remove(BookmarkedMessage bookmark) async {
    await context.read<MeshCoreConnector>().setBookmarkedMessage(
      bookmark,
      isBookmarked: false,
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final publicIpfsGateway = context
        .watch<AppSettingsService>()
        .settings
        .publicIpfsGateway;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookmarks_title), centerTitle: true),
      body: FutureBuilder<List<BookmarkedMessage>>(
        future: _bookmarks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final bookmarks = snapshot.data ?? const <BookmarkedMessage>[];
          if (bookmarks.isEmpty) {
            return EmptyState(
              icon: Icons.bookmark_border,
              title: l10n.bookmarks_empty,
            );
          }
          bookmarks.sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(12),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[bookmarks.length - 1 - index];
              final sourceType =
                  bookmark.sourceType == BookmarkSourceType.channel
                  ? l10n.bookmarks_channel
                  : l10n.bookmarks_contact;
              final receivedAt = bookmark.receivedAt.toLocal();
              final localizations = MaterialLocalizations.of(context);
              final time = localizations.formatTimeOfDay(
                TimeOfDay.fromDateTime(receivedAt),
                alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                  context,
                ),
              );
              final dateTime =
                  '${localizations.formatShortDate(receivedAt)} $time';
              final translation = bookmark.translatedText?.trim();
              final displayText = translation?.isNotEmpty == true
                  ? translation!
                  : bookmark.text;
              final textStyle =
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
              final textContent = TranslatedMessageContent(
                displayText: displayText,
                originalText: displayText == bookmark.text
                    ? null
                    : bookmark.text,
                style: textStyle,
                originalStyle: textStyle.copyWith(fontStyle: FontStyle.italic),
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2, right: 8),
                            child: Icon(
                              Icons.bookmark,
                              size: 20,
                              color: Color(0xFFFFE54A),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$sourceType · ${bookmark.sourceName}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${bookmark.senderName} · $dateTime',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.common_copy,
                            onPressed: () =>
                                copyChatMessageText(context, bookmark.text),
                            icon: const Icon(Icons.copy),
                          ),
                          IconButton(
                            tooltip: l10n.bookmarks_remove,
                            onPressed: () => _remove(bookmark),
                            icon: const Icon(Icons.bookmark_remove_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (MessageUrlImageHelper.hasPotentialImageUrl(
                        bookmark.text,
                      ))
                        MessageUrlImageFutureBuilder(
                          messageId: bookmark.messageId,
                          text: bookmark.text,
                          publicGateway: publicIpfsGateway,
                          builder: (context, snapshot) {
                            final imageUrl = snapshot.data;
                            if (imageUrl == null) return textContent;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: MessageUrlImagePreview(
                                    imageUrl: imageUrl,
                                  ),
                                ),
                                textContent,
                              ],
                            );
                          },
                        )
                      else
                        textContent,
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
