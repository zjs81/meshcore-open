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

### When a message is checked

A channel message is usually heard more than once: the same packet arrives over several repeater paths, and the radio may deliver it both as a channel message and in its RX log. The app first merges all of those copies into one message, and only then runs the filter, **once per message**. Repeats over the mesh are never mistaken for someone sending the same thing twice.

The message is then checked in this order. The first check that matches decides, and the message is stored with that reason. It is never deleted.

1. **Sender rule**: one of your rules matches the sender's name.
2. **Text rule**: one of your rules matches the message text.
3. **Repeated characters** (automatic): one character repeated 20 or more times in a row, such as "aaaaaaaaaaaaaaaaaaaa". Digits and spaces don't count, so long numbers (frequencies, coordinates) are safe. Shorter runs, like "Noooooooo!", a `--------` separator or a row of emoji, are ordinary chat and are left alone.
4. **Repeated messages** (automatic):
   - The **same sender** sends the same message again, each send within 10 minutes of the previous one. By default the second send is caught; **Sends to count as a repeat** (2–5) lets people re-send a few times first, for example when they see no repeat or reply. This applies to messages of any length, so one word sent over and over, such as "hello", is caught too.
   - The **same text from 3 or more different senders** within 30 minutes. This only applies to longer messages, at least 10 characters and at least 6 words, so short greetings such as "Happy New Year!" are never caught.
   - Replies and messages that mention someone (`@[name]`) are never checked for repeats, so asking several people the same question is fine.
5. **Learned from your Spam taps** (automatic): a small classifier scores how much the message looks like the messages you marked as spam (see below). It needs at least 2 messages marked as spam, and it hides a message only when it is at least 80% confident.

### Matching text

Before comparing, both your rule and the message are normalised:

- Capital letters, accents and zero-width (invisible) characters are ignored.
- Look-alike letters are treated as the letter they imitate: Cyrillic or Greek letters that look Latin, fullwidth letters, and "styled" letters such as 𝐛𝐨𝐥𝐝 or 𝘪𝘵𝘢𝘭𝘪𝘤. Swapping in look-alike letters doesn't get a message past a rule.
- Repeated-message checks also ignore punctuation and emoji, so "Meet at the park!" and "meet at the park" count as the same text.
- A reply's leading `@[name]` mention is not part of the text that is checked.

### Repeated-message memory

The app keeps a short in-memory list of recent messages for each channel: up to 1,000 per channel, for 30 minutes. Each new message is compared against it. A message with the same sender, text and send time as one already in the list is the same message seen again (for example, synced again when you connect a different companion) and never counts as a repeat. Every checked message is added, including ones a rule already hid, so a flood keeps being caught even after you add a rule for part of it.

Time windows use the time the message was **sent**, not when it reached your phone. History synced in a burst after you reconnect was sent hours apart, so it is not mistaken for a flood. Old entries are forgotten by the time they *arrived*, so a sender with a wrong clock can't push everyone else out of the list.

### Learning from your taps

The learned check is a small statistical model, a class-balanced logistic regression. It runs entirely in the app; there is nothing to download.

- **What it learns from:**
  - Every message you mark as spam, up to 200.
  - Every message you mark as not spam, up to 200.
  - Up to 300 recent ordinary messages that weren't filtered. These implicit "clean" examples are taken only from channels where filtering is on. Channels you have switched filtering off for are ignored, because their unfiltered messages may well include spam.
- **What it looks at:** short letter sequences (3 to 5 characters within each word), whole words and word pairs, and the sender's name. All of these are normalised the same way as rules. So it recognises a promo that has been reworded or re-spaced, not just an exact copy.
- **When it trains:** whenever you tap Spam or Not spam, when you turn learning on, and when the app starts. Training runs in the background, so the app never freezes while it learns. The previous model keeps working until the new one is ready.
- **Reset learning** forgets every example; your rules are kept.

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
- **Hide completely**: nothing is shown in the chat. "Hidden messages stay in the Filtered messages list." If hidden messages leave too little in a chat to scroll, the app loads older history automatically, up to 20 pages, so earlier conversation stays reachable after a spam burst. If the chat is still empty after that, a **Load older messages** button appears.

The **Filtered messages (n)** entry on the settings screen opens a list of everything that was filtered, newest first, across all channels. Tap a row to view it, or tap **Not spam** to restore it.

Other effects of filtering:

- Filtered messages never count as **unread** and never send a **notification**. This includes a message you mark as spam while it is still being translated: it won't notify when translation finishes. In a channel where filtering is off, earlier-filtered messages show and count as ordinary messages.
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
| **Sends to count as a repeat** | 2 | Which send of the same message by the same sender is hidden (2–5). Available while Repeated messages is on. |
| **Repeated characters** | On | Long runs of one character, like "aaaaaaaaaaaaaaaaaaaa". |
| **Learn from Spam taps** | On | Shows how many "spam and not-spam examples" the app is using. |
| **Reset learning** | | Asks for confirmation, then forgets everything learned from your Spam and Not spam taps. Your rules are kept. |

### Channel menu

In a channel chat, open the ⋮ menu and tick or untick **Filter messages in this channel**. This item is only shown while the master switch is on. Channels you untick are not filtered at all (no rules, no automatic checks), and their messages show normally.

## Privacy

Rules, settings and the examples used for learning are stored on your device in the app's preferences. They are **global**: they apply to every radio you connect, unlike most per-radio data. Nothing is uploaded and nothing is shared. The learning is a small statistical check that runs in the app itself; there is no model to download.

## Limitations

- **Channels only.** Direct messages and room chats are not filtered.
- **Rules apply to existing messages; automatic checks don't.** Adding, editing, turning off or deleting a rule updates messages already in your chats: "Filter this sender" also hides that sender's earlier messages, and deleting a rule shows again what only that rule was hiding. The automatic checks (repeats, repeated characters, learning) only judge messages as they arrive. Use Mark as spam on an old message to hide it.
- **Reveal lasts while the chat is open.** Messages you open stay open until you tap the "Tap to hide" header (or Hide on one of them) or leave the chat; they collapse again next time.
- **Learning is per device.** It is not shared between your phones or computers, and it needs at least 2 Spam taps before it does anything.
- **Repeat tracking is not remembered.** The recent-message memory used for repeat checks is kept only while the app is running.
- **Filtering happens in the app.** Spam still travels over the radio channel and uses airtime; the filter only keeps it from your screen.

See also [Channels](channels.md), [Chat & Messaging](chat-and-messaging.md), [Notifications](notifications.md) and [Settings](settings.md).
