# Message Filter

The message filter hides spam and repeated messages in channel chats. It runs entirely on your phone or computer: nothing is downloaded, no AI model or internet connection is needed, and nothing is sent over the mesh. The filter never deletes messages, so you can view hidden ones again.

## Overview

- Works on **channel messages only**. Direct messages are never filtered.
- Your own messages, reactions, GIFs and location pins are never filtered.
- Filtering is on by default, with sensible automatic checks.
- You can add your own rules, tell the app what is spam, and turn filtering off for a single channel.

## How to Access

- **Settings → Message Filter**: the full settings screen (listed under App Settings on the Settings screen). A note at the top says what the filter does. All settings stay visible and can be changed while **Filter Messages** is off.
- **Channel chat → ⋮ menu → Filter messages in this channel**: turn filtering on or off for that channel only.
- **Long-press a message** in a channel chat for the Mark as spam, Filter this sender and Filter messages like this… actions.

## How it works

### When a message is checked

A channel message is usually heard more than once: the same packet arrives over several repeater paths, and the radio may deliver it both as a channel message and in its RX log. The app first merges all of those copies into one message, and only then runs the filter, **once per message**. Repeats over the mesh are never mistaken for someone sending the same thing twice.

The message is then checked in this order. The first check that matches decides, and the message is stored with that reason. The filter does not delete it.

1. **Sender rule**: one of your rules matches the sender's name.
2. **Text rule**: one of your rules matches the message text.
3. **Repeated characters** (automatic): one character repeated 20 or more times in a row, such as "aaaaaaaaaaaaaaaaaaaa". Digits and spaces don't count, so long numbers (frequencies, coordinates) are safe. Shorter runs, like "Noooooooo!", a `--------` separator or a row of emoji, are ordinary chat and are left alone.
4. **Repeated messages** (automatic):
   - The **same sender** sends the same message again, each send within 10 minutes of the previous one. By default the second send is caught; **Sends to Count as a Repeat** (2-5) lets people re-send a few times first, for example when they see no repeat or reply. This applies to messages of any length, so one word sent over and over, such as "hello", is caught too.
   - The **same text from 3 or more different senders** within 30 minutes. This only applies to longer messages, at least 10 characters and at least 6 words, so short greetings such as "Happy New Year!" are never caught.
   - Replies and messages that mention someone (`@[name]`) are never checked for repeats, so asking several people the same question is fine.
5. **Learned from your spam reports** (automatic): a small classifier scores how much the message looks like the messages you marked as spam (see below). It needs at least 2 messages marked as spam, and it hides a message only when it is at least 80% confident.

### Matching text

Before comparing, both your rule and the message are normalised:

- Capital letters, accents and zero-width (invisible) characters are ignored.
- Look-alike letters are treated as the letter they imitate: Cyrillic or Greek letters that look Latin, fullwidth letters, and "styled" letters such as 𝐛𝐨𝐥𝐝 or 𝘪𝘵𝘢𝘭𝘪𝘤. Swapping in look-alike letters doesn't get a message past a rule.
- Repeated-message checks also ignore punctuation and emoji, so "Meet at the park!" and "meet at the park" count as the same text.
- A reply's leading `@[name]` mention is not part of the text that is checked.

### Repeated-message memory

The app keeps a short in-memory list of recent messages for each channel: up to 1,000 per channel, for 30 minutes. Each new message is compared against it. A message with the same sender, text and send time as one already in the list is the same message seen again (for example, synced again when you connect a different companion) and never counts as a repeat. Every checked message is added, including ones a rule already hid, so a flood keeps being caught even after you add a rule for part of it.

Time windows use the time the message was **sent**, not when it reached your phone. History synced in a burst after you reconnect was sent hours apart, so it is not mistaken for a flood. Old entries are forgotten by the time they *arrived*, so a sender with a wrong clock can't push everyone else out of the list.

### Learning from spam reports

The learned check is a small statistical model, a class-balanced logistic regression. It runs entirely in the app; there is nothing to download.

- **What it learns from:**
  - Every message you mark as spam, up to 200.
  - Every message you mark as not spam, up to 200.
  - Up to 300 recent ordinary messages that weren't filtered. These implicit "clean" examples are taken only from channels where filtering is on. Channels you have switched filtering off for are ignored, because their unfiltered messages may well include spam.
- **What it looks at:** short letter sequences (3 to 5 characters within each word), whole words and word pairs, and the sender's name. All of these are normalised the same way as rules. So it recognises a promo that has been reworded or re-spaced, not just an exact copy.
- **When it trains:** whenever you mark a message as spam or not spam, when you turn learning on, and when the app starts. Training runs in the background, so the app never freezes while it learns. The previous model keeps working until the new one is ready.
- **Reset Learning** forgets every example; your rules are kept.

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

On **Message Filter**, the **Rules (n)** row under **Your Rules** shows how many rules you have and opens the **Rules** page. Tap the **Add rule** button at the bottom of that page. Each rule has:

| Option | Choices |
|---|---|
| **Word, phrase or name** | The text to look for (for example `meshos`). |
| **Look in** | **Message text**, **Sender name**, or **Both**. |
| **Match** | **Contains** (anywhere), **Whole word** (not inside a longer word) or **Exact** (the whole text or name). |

Tap a rule to edit it. Each rule has its own on/off switch and a delete button.

- **Search**: tap the search button and type part of a rule's word, phrase or name. Capital letters are ignored. Back, Esc or the arrow closes the search.
- **Select several rules**: tap the select button or long-press a rule, then tap rules to select them. **Select all** selects the rules shown (while searching, only the matching ones). Delete them (after a confirmation), or use the ⋮ menu to turn them on or off. Back leaves the selection.
- **Undo**: adding, editing or deleting a rule, and deleting or turning several rules on or off, shows a message with an **Undo** button for a few seconds ("Rule saved", "Rule deleted", "2 rules deleted", "2 rules turned off"). Undo puts deleted rules back in their places and restores what the change touched; undoing an edit keeps the rule's current on/off state. Deleting selected rules asks first; a rule's own delete button does not, because Undo brings it back. Flipping one rule's switch shows no message; flip it back instead.

## How filtered messages look

In the **Filtered Messages** section of **Message Filter**, the **Hide Completely** switch (off by default) chooses how filtered messages look in chat:

- **Off**: hidden messages are replaced by a small line, "Hidden message · Tap to view". Several hidden messages in a row collapse into one line, for example "3 hidden messages · Tap to view".
  - Tap the line to open it with a short animation. The header then reads "Showing hidden message · Tap to hide"; tap it again to close.
  - Each opened message shows why it was filtered (for example `Filtered: matches "meshos"`, `Filtered: repeated message` or `Filtered: you marked this as spam`) with **Not spam** and **Hide** buttons.
- **On**: "Hide filtered messages instead of showing a placeholder". Nothing is shown in the chat; the messages stay in the Filtered Messages list. If hidden messages leave too little in a chat to scroll, the app loads older history automatically, up to 20 pages, so earlier conversation stays reachable after a spam burst. If the chat is still empty after that, a **Load older messages** button appears.

The **Filtered Messages (n)** entry, under the switch, opens a list of recent filtered messages, newest first, across all channels: up to 200, from the history loaded for each channel. Each row shows the channel, when it arrived, why it was hidden, the sender and the text. Tap **Not spam** to restore it.

- **Search** (search icon in the top bar) shows only the messages whose channel, sender or text contains what you type. Back, Esc or the arrow closes the search.
- **Select** (checklist icon, or long-press a row) to restore or delete several messages at once. **Select all** selects the messages shown, so during a search only the matches. Delete asks first.
- After **Not spam** or **Delete**, the messages leave the list and a message with **Undo** shows for a few seconds. The change is made when that message closes, or when you leave the list or the app. Undo puts the messages back unchanged. A change made while the radio was connected is still made if the radio disconnects before then.
- Without a connected radio the list can still be read, searched and selected, but Not spam and Delete are disabled (see [Offline mode](offline-mode.md)).

Other effects of filtering:

- Filtered messages never count as **unread** and never send a **notification**. This includes a message you mark as spam while it is still being translated: it won't notify when translation finishes. In a channel where filtering is off, earlier-filtered messages show and count as ordinary messages.
- They are not **auto-translated**.
- They are not used as the **last-message preview** in the Channels list; the newest message that was not hidden is shown instead.
- If someone replies to a hidden message, the quoted text in the reply is concealed ("Hidden message · Tap to view") until the original is opened.

## Settings

The page has four sections: **Filtering** (the master switch), **Filtered Messages** (Hide Completely and the list), **Your Rules** and **Automatic**.

| Setting | Default | Description |
|---|---|---|
| **Filter Messages** | On | Master switch. "Applies to every channel unless turned off in its menu". |
| **Hide Completely** | Off | Hides filtered messages in chat instead of showing a placeholder (Filtered Messages section). |
| **Rules (n)** | None | Under the Your Rules header. Opens the Rules page with your own rules (see above). |
| **Repeated Messages** | On | "Sent again by one person, or by 3 or more people". Both checks are described under Repeated messages above. |
| **Sends to Count as a Repeat** | 2 | A slider (2-5, the number shows in the title) for which send of the same message by the same sender is hidden. Shown under Repeated Messages while it is on. |
| **Repeated Characters** | On | Long runs of one character, like "aaaaaaaaaaaaaaaaaaaa". |
| **Learn from Spam Reports** | On | Shows how many messages you have marked, for example "2 marked as spam, 1 as not spam". Recent ordinary messages used for learning are not counted. |
| **Reset Learning** | | Asks first ("Forget everything the filter has learned?"), then forgets the messages you marked as spam or not spam, the recent messages the filter learned from and the trained model. Your rules and settings are kept. Shows "Nothing learned yet" and is unavailable while no message is marked as spam or not spam. |

### Channel menu

In a channel chat, open the ⋮ menu and tick or untick **Filter messages in this channel**. This item is only shown while the master switch is on. Channels you untick are not filtered at all (no rules, no automatic checks), and their messages show normally.

## Privacy

Rules, settings and the examples used for learning are stored on your device in the app's preferences. They are **global**: they apply to every radio you connect, unlike most per-radio data. Nothing is uploaded and nothing is shared. The learning is a small statistical check that runs in the app itself; there is no model to download.

## Limitations

- **Channels only.** Direct messages and room chats are not filtered.
- **Rules apply to existing messages; automatic checks don't.** Adding, editing, turning off or deleting a rule updates messages already in your chats: "Filter this sender" also hides that sender's earlier messages, and deleting a rule shows again what only that rule was hiding. The automatic checks (repeats, repeated characters, learning) only judge messages as they arrive. Use Mark as spam on an old message to hide it.
- **Reveal lasts while the chat is open.** Messages you open stay open until you tap the "Tap to hide" header (or Hide on one of them) or leave the chat; they collapse again next time.
- **Learning is per device.** It is not shared between your phones or computers, and it needs at least 2 messages marked as spam before it does anything.
- **Repeat tracking is not remembered.** The recent-message memory used for repeat checks is kept only while the app is running.
- **Filtering happens in the app.** Spam still travels over the radio channel and uses airtime; the filter only keeps it from your screen.

See also [Channels](channels.md), [Chat & Messaging](chat-and-messaging.md), [Notifications](notifications.md) and [Settings](settings.md).
