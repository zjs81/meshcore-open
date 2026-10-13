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
- **Action button**:
  - **Overflow menu** (⋮ icon): Contains Routing, Info, Telemetry, Settings, and Clear Chat. Routing opens the routing sheet where you can switch between Auto, Direct, and Flood routing and manage recent paths (hop count, round-trip time, age, success count, color-coded by repeater). Info shows a dialog with contact type, path, GPS coordinates, and public key.

### Message List

- Scrollable list with newest messages at the bottom
- **Outgoing messages**: Right-aligned, primary color background. **Failed messages** change to a red-toned error container background
- **Incoming messages**: Left-aligned, grey background with a colored avatar (initial letter or first emoji of sender name; color is deterministic from a hash of the sender name)
- Bubble width capped at 72% of screen width
- Hyperlinks rendered as tappable green underlined text
- Message text follows the system font size (Android/iOS accessibility text size); pinch-to-zoom scales on top of it
- **Pinch-to-zoom**: Two-finger zoom (0.8x–1.8x) and double-tap to reset
- **Jump to bottom**: Floating button appears when scrolled away from the bottom
- **Lazy loading**: Scrolling to top loads older messages from storage. The newest 200 messages are kept in memory; up to 1000 per conversation are kept in storage
- **Arrival order**: Messages are ordered by when they arrived on this device, not by the sender's clock. If a message's time is more than 5 minutes in the future, a small clock-warning icon appears next to its time (the sender's clock is probably wrong); tap it for an explanation

### Input Bar

- **Send action button** (left, ⊕ icon): Opens a menu with **Send GIF** (GIF picker bottom sheet) and **Share my location**
- **Share my location**: Sends your radio's current position (from the radio, not the phone's GPS) as a location pin. You're asked for a label (default: your node name) before sending; the keyboard's Send key confirms. If the radio reports no usable position (none set, or 0,0), the item is hidden and a snackbar says "Your radio has no location set". Location shares follow the same send cooldown as typed messages and are never sent as a reply. In channel chat the menu also holds **Send low-res image over radio** when image messages are set up
- **Translation button** (optional, between GIF and text field): Shown only when translation is enabled in App Settings. Tap to configure outgoing-message translation language and on/off toggle.
- **Text field** (center): Auto-capitalization, enforces UTF-8 byte limit in real-time
- **Send button** (right): Submits the message
- On desktop: Enter/Numpad Enter also submits
- When a GIF is selected, the text field shows an inline GIF preview with a dismiss button

## Message Types

| Type | Wire Format | Display |
|---|---|---|
| Plain text | Raw UTF-8 string | Inline text with link detection |
| URL image preview | Image URL in text (per-contact opt-in; requires internet) | Downloaded inline preview |
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
| View path | All platforms: long-press/right-click menu | Shows message routing path |
| Copy | All messages | Copies text to clipboard |
| Translate | Incoming messages only (when translation is enabled and not yet translated) | Translates the message on-demand using the on-device model |
| Mark as Unread | Incoming messages only | Marks this message and all subsequent incoming messages as unread |
| Delete | All messages | Removes locally (not from mesh) |
| Retry | Failed outgoing messages | Re-sends the message |
| Open chat with sender | Room server chats | Opens 1:1 chat with the message sender |

## Image and translation setup

Enable URL images in the contact’s chat settings to preview supported image links; see [URL images](additional-features.md#url-image-previews). Images and files can also be uploaded to a configured IPFS provider from the **+** menu in direct or channel chat; the resulting URL is sent as ordinary text. See [sharing via IPFS](additional-features.md#share-an-image-via-ipfs) and [IPFS provider configuration](settings.md#ipfs-provider-configuration). Mesh image packets are currently sent through channel chat, not the direct-message composer. Set up translation and download a model in [App Settings](settings.md#translation) before using incoming or pre-send translation.
