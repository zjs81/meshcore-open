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
  - **Routing mode** (waves icon): Switch between Auto, Direct, and Flood routing
  - **Path management** (timeline icon): View recent paths with hop count, round-trip time, age, and success count. Paths are color-coded by direct repeater (green/yellow/red/blue for ranked repeaters, grey for unknown). Tap a path to activate it (the device verifies and confirms via snackbar), long-press to view full path details, set custom paths, or force flood mode. A warning banner appears when history reaches 100 entries.
  - **Info** (info icon): Contact info dialog showing type, path, GPS coordinates, public key, and SMAZ compression toggle

### Message List

- Scrollable list with newest messages at the bottom
- **Outgoing messages**: Right-aligned, primary color background. **Failed messages** change to a red-toned error container background
- **Incoming messages**: Left-aligned, grey background with a colored avatar (initial letter or first emoji of sender name; color is deterministic from a hash of the sender name)
- Bubble width capped at 65% of screen width
- Hyperlinks rendered as tappable green underlined text
- **Pinch-to-zoom**: Two-finger zoom (0.8x–1.8x) and double-tap to reset
- **Jump to bottom**: Floating button appears when scrolled away from the bottom
- **Lazy loading**: Scrolling to top loads older messages from storage

### Input Bar

- **GIF button** (left): Opens GIF picker bottom sheet
- **Text field** (center): Auto-capitalization, enforces UTF-8 byte limit in real-time
- **Send button** (right): Submits the message
- On desktop: Enter/Numpad Enter also submits
- When a GIF is selected, the text field shows an inline GIF preview with a dismiss button

## Message Types

| Type | Wire Format | Display |
|---|---|---|
| Plain text | Raw UTF-8 string | Inline text with link detection |
| GIF | `g:<giphy-id>` | Inline GIF image from Giphy CDN |
| Location pin | `m:<lat>,<lon>\|<label>\|...` | Location icon + label; tap to open map |
| Reaction | `r:<hash>:<emoji-index>` | Applied to target message as emoji pill |

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
- Retry count (e.g., "Retry 2 of 4")
- Status icon
- Round-trip time in seconds (if delivered)

## Message Length Limits

- **Direct messages**: 156 bytes (UTF-8) — enforced in real-time by the input formatter
- **Channel messages**: 160 minus sender name length minus 2 bytes for the `"<name>: "` prefix
- Over-length paste shows a snackbar error

## Send Queue

Only one message per contact can be in-flight at a time (to avoid overflowing the firmware's 8-entry ACK table). If you send multiple messages rapidly, they are queued and sent sequentially — each waits for the previous one to be delivered, fail, or exhaust retries before transmitting.

## Retry Mechanism

When a direct message is sent:

1. The app computes an expected ACK hash: `SHA256([timestamp][attempt][text][selfPubKey])[0:4]` — matching the firmware's hash calculation. If SMAZ compression is enabled, the compressed text (not the original) is hashed
2. On device acknowledgment (`RESP_CODE_SENT`), the message transitions to "sent" and a timeout timer starts
3. **Timeout duration**: Preferably from the ML timeout prediction service; otherwise `3000 + 3000 × path_length` milliseconds (15000ms for flood)
4. On timeout, the message is retried with **exponential backoff**: `1000 × 2^retryCount` ms (1s, 2s, 4s, 8s, 16s...)
5. **Max retries**: Configurable (default 5, range 2–10)
6. After max retries, the message is marked "failed" — but a **30-second grace window** remains during which a late ACK can still resolve the message to "delivered"
7. If **Clear Path on Max Retry** is enabled (App Settings), the contact's stored routing path is automatically cleared when max retries are exhausted
8. **Auto route rotation**: When enabled (and no manual path override is set), the retry service uses a diversity window to avoid re-using recently tried paths, cycling through known routes on each attempt

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
| View path | Mobile: tap bubble directly; Desktop: long-press/right-click menu | Shows message routing path |
| Copy | All messages | Copies text to clipboard |
| Delete | All messages | Removes locally (not from mesh) |
| Retry | Failed outgoing messages | Re-sends the message |
| Open chat with sender | Room server chats | Opens 1:1 chat with the message sender |
