# Chat & Messaging

## Overview

The app supports two chat modes:
- **Direct messages**: Encrypted point-to-point messages to individual contacts
- **Channel messages**: Broadcast messages to shared channels (see [Channels](channels.md))

This page covers direct messaging. For channel chat, see the Channels documentation.

## How to Access

From the Contacts screen, tap any Chat-type contact to open the ChatScreen.

## Chat Screen Layout

### App Bar

- **Title**: Contact name
- **Subtitle**: Current routing path label (e.g., "2 hops", "flood (auto)", "direct (forced)") and unread count. Tapping the subtitle shows the full path details.
- **Action buttons**:
  - **Search** (magnifier icon): Replaces the title with a search field and lists every message in this conversation's full history whose text (or translation) contains the typed word, newest first, with matches highlighted. Channel search also matches sender names and skips messages caught by the [message filter](message-filter.md). Back, Esc or the arrow closes search. Channel chats have the same button.
  - **Overflow menu** (⋮ icon): Contains Routing, Info, Telemetry, Settings (link images and telemetry permissions), Chat background, Clear Chat, and Remove from contacts (rooms also have Room Server Management). Routing opens the routing sheet where you can switch between Auto, Direct, and Flood routing and manage recent paths (hop count, round-trip time, age, success count, color-coded by repeater). Info shows a dialog with contact type, path, GPS coordinates, and public key. Chat background sets a color or picture (with a fade slider) behind this chat only; see [Chat backgrounds](themes.md#chat-backgrounds).

### Compression Strip

Below the app bar, above the messages, a strip shows **Compression: Off**, **SMAZ** or **Cyr2Lat** for this contact. Tap it to choose a mode in one sheet that explains each: SMAZ is lossless but needs a SMAZ-aware app on the other end and is only used when it makes a message smaller; Cyr2Lat swaps some Cyrillic letters for lookalike Latin ones, stays readable everywhere, but changes the exact characters, using the chosen Cyr2Lat profile. The setting is saved on the phone and can be changed offline. Channel chats show the same strip. See [Compression](additional-features.md#compression-smaz-and-cyr2lat).

### Message List

- Scrollable list with newest messages at the bottom
- **Background**: The chat's own background, or the active theme's chat background when the chat has none (a theme set to **Use in every chat** replaces per-chat backgrounds). See [Chat backgrounds](themes.md#chat-backgrounds)
- **Holiday animations**: A new message with a holiday greeting ("Happy Halloween", "Merry Christmas", and so on, in any app language) plays a short animation. Turn off in App Settings → Appearance; see [Holiday message animations](themes.md#holiday-message-animations)
- **Outgoing messages**: Right-aligned, primary color background. **Failed messages** change to a red-toned error container background
- **Incoming messages**: Left-aligned, grey background with a colored avatar (initial letter or first emoji of sender name; color is deterministic from a hash of the sender name)
- Long-press a message and choose **Bookmark** to show a yellow bookmark on the bubble. **Show bookmarks** in the chat menu toggles a filter for bookmarked messages; use **Bookmarks** in the Channels screen menu to browse saved messages, including those from deleted contacts or channels. From the bookmarks list, copy a message with its copy button. It is ordered oldest-to-newest and opens at the newest message. The Export screen can save or share a dated Markdown file, grouped by contact and then channel, with linked URLs and URL-image embeds. Links remain tappable, and supported URL-image previews are shown when **Load images from links** is enabled in App Settings.
- Bubble width capped at 72% of screen width
- Hyperlinks rendered as tappable underlined text; inline decimal GPS coordinates are rendered as bold underlined links (see [Inline GPS Coordinates](#inline-gps-coordinates))
- Message text follows the system font size (Android/iOS accessibility text size); pinch-to-zoom scales on top of it
- **Pinch-to-zoom**: Two-finger zoom (0.8x–1.8x) and double-tap to reset
- **Jump to bottom**: Floating button appears when scrolled away from the bottom
- **Lazy loading**: Scrolling to top loads older messages from storage. The newest 200 messages are kept in memory, plus any older pages loaded while the chat is open; up to 1000 per conversation are kept in storage
- **Reading position**: Near the bottom, the chat follows new messages. Scrolled up, it stays on the messages you are reading while new ones arrive below, such as a room's backlog right after login, and never pulls a scroll in progress back to the bottom
- **Arrival order**: Messages are ordered by when they arrived on this device, not by the sender's clock. If a message's time is more than 5 minutes in the future, a small clock-warning icon appears next to its time (the sender's clock is probably wrong); tap it for an explanation

### Input Bar

The composer is a rounded bubble at the bottom of the chat with one round button beside it. With a chat background set, the bubble floats over the background.

- **Round button** (right): shows **+** while the field is empty and **Send** once you type. **+** opens the send action menu: **Send GIF** (GIF picker bottom sheet), **Share my location**, **Share contact**, and, when set up, image uploads
- **Share my location**: Sends your radio's current position (from the radio, not the phone's GPS) as a location pin. You're asked for a label (default: your node name) before sending; the keyboard's Send key confirms. If the radio reports no usable position (none set, or 0,0), the item is hidden and a snackbar says "Your radio has no location set". Location shares follow the same send cooldown as typed messages and are never sent as a reply. In channel chat the menu also holds **Send low-res image over radio** when image messages are set up
- **Text field**: Auto-capitalization, enforces the UTF-8 byte limit in real time. It grows to five lines (fewer with very large text while the keyboard is open), then scrolls
- **Byte counter**: appears in the bottom-right of the bubble once a message passes 70 % of the limit, and turns red near the limit
- **Translation button** (inside the bubble, right): Shown only when translation is enabled in App Settings. Tap to configure outgoing-message translation language and on/off toggle.
- **Reply preview**: In channel chat, replying shows the quoted message at the top of the bubble with a **✕** to cancel and, when the original had a region, the region chip
- On desktop: Enter/Numpad Enter also submits
- When a GIF is selected, the bubble shows a GIF preview with a remove button; Enter sends it
- With no radio connected, the bubble says so and a **Connect** button takes the place of the round button

## Message Types

| Type | Wire Format | Display |
|---|---|---|
| Plain text | Raw UTF-8 string | Inline text with URL and decimal coordinate detection |
| URL image preview | Image URL in text (per-contact opt-in; requires internet) | Downloaded inline preview |
| GIF | `g:<giphy-id>` | Inline GIF image from Giphy CDN |
| Location pin | `m:<lat>,<lon>\|<label>\|...` | Location icon + label; tap to open map |
| Reaction | `r:<hash>:<emoji-index>` | Applied to target message as emoji pill |

## Inline GPS Coordinates

Plain-text messages in direct chats, room chats, channel chats, and saved bookmarks (including translated text and shown originals) automatically detect inline decimal GPS coordinates.

### Supported Format

- **Decimal `lat, lon` pairs**: Matches two decimal numbers separated by a comma with optional spaces or tabs after the comma (for example `37.7749, -122.4194` or `-33.86882,151.20929`). Each number may include a leading `+` or `-` sign.
- **WGS84 bounds**: Latitude must be between `-90.0` and `90.0` and longitude between `-180.0` and `180.0` (inclusive).
- **Decimal requirement**: Both latitude and longitude must contain a decimal point with digits on both sides. Plain integer pairs (`10, 20`) and mixed integer/decimal pairs (`37, -122.4194`) are ignored.
- **Non-coordinate exclusions**: Version numbers (`1.2.3, 4.5` or `1.2, 3.4.5`), numbers attached to letters, underscores, or extra signs (`v1.2,3.4`, `id_37.7749,-122.4194`), and coordinates inside URLs, email addresses, or `geo:` URIs remain normal text or standard web links. Surrounding sentence punctuation such as `(37.7749, -122.4194)` or a trailing period (`38.722,-9.139.`) is allowed without breaking detection.

### Tap and Long-Press Behavior

- **Tap**: Opens a dedicated full-screen **Location** map centered on that coordinate at zoom level 15 (zoom range 2–18) with a pin marker and a bottom label card showing the matched coordinate text. Map controls provide **Zoom in** (`+`), **Zoom out** (`-`), and **Center map** buttons (plus arrow/WASD pan and R/F zoom keys on desktop), and the app bar provides **Copy location** and **Open in maps**. Pressing Back returns to the exact same message scroll position. Like the main map, cached tiles work offline while uncached tiles require internet.
- **Long-press**: Opens a coordinate action sheet with **Copy location** (copies the matched coordinate text to the clipboard) and **Open in maps**, instead of the message bubble context menu. Long-pressing non-coordinate text in the same message (or right-clicking on desktop) still opens the normal message actions menu.

### Open in Maps Platform Behavior

**Open in maps** launches an external map application or browser tab depending on the platform:

| Platform | Target launched |
|---|---|
| Android | `geo:<lat>,<lon>?q=<lat>,<lon>` (system default maps app) |
| iOS, macOS | `https://maps.apple.com/?ll=<lat>,<lon>&q=<lat>,<lon>` (Apple Maps) |
| Linux, Windows, Web | `https://www.openstreetmap.org/?mlat=<lat>,<lon>#map=16/<lat>/<lon>` (OpenStreetMap in default browser) |

Launching fails with a snackbar if no maps app or web browser is available to handle the URI.

## Sharing Contacts

A contact can be shared in any direct or channel chat. It is sent as an ordinary text message whose whole text is `<PUBKEYHEX:TYPE:NAME>` (64-hex-character public key, advert type 1 Companion / 2 Repeater / 3 Room / 4 Sensor, then the name, which may contain colons). This is the same format the official MeshCore app uses, so shares work in both directions.

- **Sending**: tap **+** in the input bar, choose **Share contact**, and pick **My contact** or a saved contact (the list has a name search). The token is placed in the text field; press send. Names count toward the message length limit.
- **Receiving**: the message shows as a card with the name, contact type and shortened key. If the key is not saved on your radio yet, tap **Add contact** to add it; the card then shows **Saved** (or **This is you** for your own key). Adding needs a connected radio and uses the same radio command as scanning a contact QR code.
- Notifications and reply previews show "Shared a contact: NAME" instead of the raw text.

## Message Status

Outgoing messages display a status indicator:

| Status | Icon | Meaning |
|---|---|---|
| Pending | Grey double-check | Queued, waiting for device to transmit (visually identical to Sent) |
| Sent | Grey double-check | Device confirmed transmission (visually identical to Pending) |
| Delivered | Green double-check | Remote node acknowledged receipt |
| Failed | Red X | All retries exhausted |

### Message Tracing Mode

When enabled in App Settings, additional metadata appears inside each bubble:
- Timestamp (HH:MM)
- Retry count (e.g., "Retry 2 of 4") — only shown for outgoing messages where at least one retry has occurred
- Status icon (outgoing only)
- Round-trip time in seconds (if delivered)

## Message Length Limits

- **Direct messages**: 156 bytes (UTF-8) — enforced in real-time by the input formatter
- **Channel messages**: 160 minus sender name UTF-8 byte length minus 2 bytes for the `"<name>: "` prefix (the name counts as at most 31 bytes, and as 31 when unknown)
- Over-length paste shows a snackbar error

## Send Queue

Only one message per contact can be in-flight at a time (to avoid overflowing the firmware's 8-entry ACK table). If you send multiple messages rapidly, they are queued and sent sequentially — each waits for the previous one to be delivered, fail, or exhaust retries before transmitting.

## Retry Mechanism

When a direct message is sent:

1. The app computes an expected ACK hash: `SHA256([timestamp][attempt][text][selfPubKey])[0:4]` — matching the firmware's hash calculation. If SMAZ compression is enabled, the compressed text (not the original) is hashed
2. On device acknowledgment (`RESP_CODE_SENT`), the message transitions to "sent" and a timeout timer starts. If that acknowledgment never arrives (for example a dropped BLE notification), a backup timer (the delivery timeout plus 5 seconds) runs the normal retry path instead of leaving the message pending; a late ACK still marks it delivered
3. **Timeout duration**: Preferably from the ML timeout prediction service; otherwise from the device's own `est_timeout` in `RESP_CODE_SENT` (clamped to the physics range); otherwise calculated from LoRa airtime physics: `500 + (airtime × 6 + 250) × (pathLength + 1)` ms for direct paths, `500 + 16 × airtime` ms for flood (airtime is estimated from the radio's current spreading factor, bandwidth, and coding rate). The result is capped at 45 seconds.
4. On timeout, the message is retried with **exponential backoff**: `1000 × 2^retryCount` ms (1s, 2s, 4s, 8s, 16s...), capped at 32 seconds
5. **Direct and flood attempts**: Set separately in App Settings → Routing (defaults 4 direct and 1 flood; up to 15 direct and 10 flood). With auto route rotation on, the direct attempts use known routes and the flood attempts follow. With it off, every attempt stays on the contact's current path and only that path's limit applies. Zero on both still sends once
6. After those attempts, the message is marked "failed" — but a **30-second grace window** remains during which a late ACK can still resolve the message to "delivered"
7. If **Clear Path on Max Retry** is enabled (App Settings → Routing), the contact's stored routing path is automatically cleared when the attempts are exhausted
8. **Auto route rotation**: When enabled (and no manual path override is set), the retry service uses a diversity window to avoid re-using recently tried paths, cycling through known routes on each direct attempt. Flood attempts come after those

### Manual Retry

Long-press a failed message → "Retry" to re-send using the current routing settings.

## Reactions

Add emoji reactions to incoming messages (not your own):

1. Long-press (or right-click on desktop) a message
2. Select "Add reaction" from the context menu
3. Choose from quick emojis (thumbs up, heart, laugh, party, clap, fire) or browse the full emoji picker
4. Reactions appear as pills below the message bubble with emoji and count
5. Pending reactions show at 50% opacity with a spinner
6. Failed reactions show a red retry icon (tap to retry)

## Context Actions (Long-Press / Right-Click)

| Action | Availability | Description |
|---|---|---|
| Add reaction | Incoming messages only | Opens emoji picker |
| View path | All platforms: long-press/right-click menu | Shows message routing path |
| Copy | All messages | Copies text to clipboard |
| Translate | Incoming messages only (when translation is enabled and not yet translated) | Translates the message on-demand using the on-device model |
| Mark as Unread | Incoming messages only | Marks this message and all subsequent incoming messages as unread |
| Delete | All messages | Removes locally (not from mesh) |
| Retry | Failed outgoing messages | Re-sends the message |
| Open chat with sender | Room server chats | Opens 1:1 chat with the message sender |

In channel chats the menu also offers **Mark as spam**, **Filter this sender** and **Filter messages like this…**; see [Message filter](message-filter.md). Direct messages are never filtered.

Long-pressing directly on a detected GPS coordinate opens the coordinate action sheet (**Copy location** and **Open in maps**) instead of this message menu; long-press non-coordinate text in the message (or right-click on desktop) for message actions.

## Image and translation setup

Enable URL images in the contact’s chat settings to preview supported image links; see [URL images](additional-features.md#url-image-previews). Images and files can also be uploaded to a configured IPFS provider from the **+** menu in direct or channel chat; the resulting URL is sent as ordinary text. See [sharing via IPFS](additional-features.md#share-an-image-via-ipfs) and [IPFS provider configuration](settings.md#ipfs-provider-configuration). Mesh image packets are currently sent through channel chat, not the direct-message composer. Set up translation and download a model in [App Settings](settings.md#translation) before using incoming or pre-send translation.
