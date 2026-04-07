import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';

class EmojiPicker extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final String? title;

  const EmojiPicker({super.key, required this.onEmojiSelected, this.title});

  static const List<String> quickEmojis = ['👍', '❤️', '😂', '🎉', '👏', '🔥'];

  static const List<String> smileys = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😅',
    '😂',
    '🤣',
    '😊',
    '😇',
    '🙂',
    '🙃',
    '😉',
    '😌',
    '😍',
    '🥰',
    '😘',
    '😗',
    '😙',
    '😚',
    '😋',
    '😛',
    '😝',
    '😜',
    '🤪',
    '🤨',
    '🧐',
    '🤓',
    '😎',
    '🥸',
    '🤩',
    '🥳',
    '😏',
    '😒',
    '😞',
    '😔',
    '😟',
    '😕',
    '🙁',
    '😣',
    '😖',
    '😫',
    '😩',
    '🥺',
    '😢',
    '😭',
    '😤',
    '😠',
    '😡',
    '🤬',
    '🤯',
    '😳',
    '🥵',
    '🥶',
    '😱',
    '😨',
    '😰',
    '😥',
    '😓',
    '🤗',
    '🤔',
    '🤭',
    '🤫',
    '🤥',
    '😶',
  ];
  static const List<String> gestures = [
    '👍',
    '👎',
    '👊',
    '✊',
    '🤛',
    '🤜',
    '🤞',
    '✌️',
    '🤟',
    '🤘',
    '👌',
    '🤌',
    '🤏',
    '👈',
    '👉',
    '👆',
    '👇',
    '☝️',
    '👋',
    '🤚',
    '🖐️',
    '✋',
    '🖖',
    '👏',
    '🙌',
    '👐',
    '🤲',
    '🤝',
    '🙏',
    '✍️',
    '💅',
    '🤳',
    '💪',
  ];
  static const List<String> hearts = [
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '🤍',
    '🤎',
    '💔',
    '❤️‍🔥',
    '❤️‍🩹',
    '💕',
    '💞',
    '💓',
    '💗',
    '💖',
    '💘',
    '💝',
    '💟',
    '💌',
    '💢',
    '💥',
    '💫',
    '💦',
    '💨',
    '🕳️',
    '💬',
    '👁️‍🗨️',
    '🗨️',
    '🗯️',
    '💭',
  ];
  static const List<String> objects = [
    '🎉',
    '🎊',
    '🎈',
    '🎁',
    '🎀',
    '🪅',
    '🪆',
    '🏆',
    '🥇',
    '🥈',
    '🥉',
    '⚽',
    '⚾',
    '🥎',
    '🏀',
    '🏐',
    '🏈',
    '🏉',
    '🎾',
    '🥏',
    '🎳',
    '🏏',
    '🏑',
    '🏒',
    '🥍',
    '🏓',
    '🏸',
    '🥊',
    '🥋',
    '🥅',
    '⛳',
    '🔥',
    '⭐',
    '🌟',
    '✨',
    '⚡',
    '💡',
    '🔦',
    '🏮',
    '🪔',
    '📱',
    '💻',
    '⌚',
    '📷',
    '📺',
    '📻',
    '🎵',
    '🎶',
    '🚀',
  ];

  Map<String, List<String>> _emojiCategories(AppLocalizations l10n) {
    return {
      l10n.emojiCategorySmileys: smileys,
      l10n.emojiCategoryGestures: gestures,
      l10n.emojiCategoryHearts: hearts,
      l10n.emojiCategoryObjects: objects,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final emojiCategories = _emojiCategories(l10n);
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? l10n.chat_addReaction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              children: quickEmojis
                  .map(
                    (emoji) => InkWell(
                      onTap: () {
                        onEmojiSelected(emoji);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: DefaultTabController(
              length: emojiCategories.length,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: emojiCategories.keys
                        .map((cat) => Tab(text: cat))
                        .toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: emojiCategories.values
                          .map(
                            (emojis) => GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 8,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                  ),
                              itemCount: emojis.length,
                              itemBuilder: (context, index) => InkWell(
                                onTap: () {
                                  onEmojiSelected(emojis[index]);
                                  Navigator.pop(context);
                                },
                                child: Center(
                                  child: Text(
                                    emojis[index],
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
