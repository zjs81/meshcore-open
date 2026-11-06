# Message Filter

The message filter hides spam and repeated messages in channel chats. It runs entirely on your phone or computer: nothing is downloaded, no AI model or internet connection is needed, and nothing is sent over the mesh. Filtered messages are never deleted. You can always view them again.

## Overview

- Works on **channel messages only**. Direct messages are never filtered.
- Your own messages, reactions, GIFs and location pins are never filtered.
- Filtering is on by default, with sensible automatic checks.
- You can add your own rules, tell the app what is spam, and turn filtering off for a single channel.

## How to Access

- **Settings → Message filter**: the full settings screen (listed under App Settings on the Settings screen).
- **Channel chat → ⋮ menu → Filter messages in this channel**: turn filtering on or off for that channel only.
- **Long-press a message** in a channel chat for the Mark as spam, Filter this sender and Filter messages like this… actions.

## How it works

Each new incoming channel message is checked in this order. The first check that matches decides:

1. **Sender rule**: one of your rules matches the sender's name.
2. **Text rule**: one of your rules matches the message text.
3. **Repeated characters** (automatic): the same character 8 or more times in a row, such as "aaaaaaaa" or "!!!!!!!!".
4. **Repeated messages** (automatic):
   - The **same sender** sends the same message again within 10 minutes.
   - The **same text from 3 or more different senders** within 30 minutes. This only applies to longer messages, at least 10 characters and at least 6 words, so short greetings such as "Happy New Year!" are never caught.
5. **Learned from your Spam taps** (automatic): the app compares the message with messages you marked as spam. This needs at least 2 messages marked as spam and 80% confidence.

Details worth knowing:

- Time windows use the time the message was **sent**, not when it reached your phone. History that is synced after you reconnect is not mistaken for a flood.
- Rules ignore capital letters, accents, zero-width (invisible) characters and look-alike letters (for example Cyrillic or Greek letters that look like Latin ones, or fullwidth letters), so spammers cannot easily sneak around a rule.
- Repeated-message checks also ignore punctuation, emoji and `@[name]` mentions.
- A reply's leading `@[name]` mention is not part of the text that is checked.

## Marking messages yourself

Long-press (or right-click) an incoming channel message:

| Action | What it does |
|---|---|
| **Mark as spam** | Hides the message now and teaches the automatic filter ("Marked as spam"). |
| **Not spam** | Shown instead of Mark as spam on a filtered message. Shows it again, stops the same text being caught as a repeat in this channel while the app is running, and teaches the filter ("Marked as not spam"). |
| **Filter this sender** | After a confirmation ("Hide all messages from ...?"), adds a Sender name rule with the Exact match for that name. |
| **Filter messages like this…** | Opens the rule editor with the message text filled in, so you can shorten it to the key phrase and choose how to match. |

These actions are not offered on your own messages, on GIFs or location pins, or in channels where filtering is off.

## Your rules

In **Message filter → Your rules**, tap **Add rule**. Each rule has:

| Option | Choices |
|---|---|
| **Word, phrase or name** | The text to look for (for example `meshos`). |
| **Look in** | **Message text**, **Sender name**, or **Both**. |
| **Match** | **Contains** (anywhere), **Whole word** (not inside a longer word) or **Exact** (the whole text or name). |

Tap a rule to edit it. Each rule has its own on/off switch and a delete button. Deleting shows "Rule deleted" with an Undo button.

## How filtered messages look

Under **Message filter → Filtered messages** choose one of two display modes:

- **Show a small placeholder** (default): hidden messages are replaced by a small line, "Hidden message · Tap to view". Several hidden messages in a row collapse into one line, for example "3 hidden messages · Tap to view".
  - Tap the line to open it with a short animation. The header then reads "Showing hidden message · Tap to hide"; tap it again to close.
  - Each opened message shows why it was filtered (for example `Filtered: matches "meshos"`, `Filtered: repeated message` or `Filtered: you marked this as spam`) with **Not spam** and **Hide** buttons.
- **Hide completely**: nothing is shown in the chat. "Hidden messages stay in the Filtered messages list."

The **Filtered messages (n)** entry on the settings screen opens a list of everything that was filtered, newest first, across all channels. Tap a row to view it, or tap **Not spam** to restore it.

Other effects of filtering:

- Filtered messages never count as **unread** and never send a **notification**.
- They are not **auto-translated**.
- They are not used as the **last-message preview** in the Channels list; the newest message that was not hidden is shown instead.
- If someone replies to a hidden message, the quoted text in the reply is concealed ("Hidden message · Tap to view") until the original is opened.

## Settings

| Setting | Default | Description |
|---|---|---|
| **Filter messages** | On | Master switch. "Applies to channel messages". |
| **Show a small placeholder** / **Hide completely** | Placeholder | How filtered messages appear in chat. |
| **Your rules** | None | Your own rules (see above). |
| **Repeated messages** | On | "The same message sent again, or by several senders". |
| **Repeated characters** | On | Messages like "aaaaaaaa" or "!!!!!!!!". |
| **Learn from Spam taps** | On | Shows how many "spam and not-spam examples" the app is using. |
| **Reset learning** | | Asks for confirmation, then forgets everything learned from your Spam and Not spam taps. Your rules are kept. |

### Channel menu

In a channel chat, open the ⋮ menu and tick or untick **Filter messages in this channel**. This item is only shown while the master switch is on. Channels you untick are not filtered at all (no rules, no automatic checks), and their messages show normally.

## Privacy

Rules, settings and the examples used for learning are stored on your device in the app's preferences. They are **global**: they apply to every radio you connect, unlike most per-radio data. Nothing is uploaded and nothing is shared. The learning is a small statistical check that runs in the app itself; there is no model to download.

## Limitations

- **Channels only.** Direct messages and room chats are not filtered.
- **New messages only.** A new rule or a changed switch applies to messages received from then on, not to messages already in the chat. Use Mark as spam on an old message to hide it.
- **Reveal lasts while the chat is open.** Messages you open stay open until you tap the "Tap to hide" header (or Hide on one of them) or leave the chat; they collapse again next time.
- **Learning is per device.** It is not shared between your phones or computers, and it needs at least 2 Spam taps before it does anything.
- **Repeat tracking is not remembered.** The recent-message memory used for repeat checks is kept only while the app is running.
- **Filtering happens in the app.** Spam still travels over the radio channel and uses airtime; the filter only keeps it from your screen.

See also [Channels](channels.md), [Chat & Messaging](chat-and-messaging.md), [Notifications](notifications.md) and [Settings](settings.md).
