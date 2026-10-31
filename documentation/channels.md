# Channels

## Overview

Channels are broadcast group-chat spaces secured by a 16-byte pre-shared key (PSK). Devices using the same channel PSK can decrypt matching channel traffic; channel indices are local device slots and need not match between peers. Unlike direct messages, channel messages are broadcast to the entire mesh.

The number of active channels is determined by the firmware (default 40); the device reports its actual limit at login.

## How to Access

QuickSwitchBar tab 1 (middle) from any main screen.

## Channel Types

| Type | Icon | Color | Description |
|---|---|---|---|
| Public | Globe | Green | Fixed well-known PSK; any device can join |
| Hashtag | Hash tag | Blue | PSK derived from the hashtag name via SHA-256; discoverable by convention |
| Private | Lock | Blue | Random PSK; requires out-of-band sharing of the 32-hex key |
| Community | Groups/Tag | Magenta | PSK derived via HMAC-SHA256 from a community's shared secret |

## Channels List Screen

### What the User Sees

- **Search bar** with live text filtering (300ms debounce)
- **Sort/filter button**
- **Scrollable list of channel cards**, each showing:
  - Type icon with color coding (magenta badge overlay for community channels)
  - Channel name (or "Channel N" if unnamed)
  - Unread badge (if messages are unread)
  - Drag handle (when manual sort is active)
- **"+" FAB** to add a new channel
- **Overflow menu**: Disconnect, Manage Communities, Settings

If no channels exist, an empty state with an "Add Public Channel" shortcut is shown. If a search produces no results, a separate "no results" empty state with a search-off icon is shown.

Pull-to-refresh (swipe down) forces a re-fetch of channels from the device firmware.

### Sorting Options

- **Manual** (default): Drag-and-drop reordering, persisted (drag handles are hidden when a search query is active)
- **A–Z**: Alphabetical
- **Latest messages**: Most recent first
- **Unread**: Most unread first

## Adding a Channel

Tap the "+" FAB to open a dialog with six options:

1. **Create Private Channel** — Enter a name (max 31 bytes of UTF-8, so fewer characters for accented letters, Cyrillic, or emoji); a random PSK is generated
2. **Join Private Channel** — Enter a name and a 32-hex PSK (non-hex characters like spaces and dashes are silently stripped, so pasted keys with formatting are accepted)
3. **Join Public Channel** — One tap; uses the well-known public PSK (only shown if no public channel exists)
4. **Join Hashtag Channel** — Enter a hashtag name; PSK is derived from the name. If communities exist, choose between regular hashtag (SHA-256) or community hashtag (HMAC)
5. **Scan a QR Code** — Opens the QR scanner to join a community, or to add a channel from an official MeshCore channel QR code (`meshcore://channel/add?name=…&secret=…`, as shared by the official app and community sites)
6. **Create Community** — Enter a name; generates a random 32-byte secret; optionally adds a community public channel; shows QR code for sharing

Name limits count the `#` and any community prefix, so the name stored on the radio matches what you typed and others derive the same key. Adding a channel is blocked until the channel list has finished syncing from the radio (a snackbar says the channels are still loading), and the free slot is picked when you confirm, so an existing channel is never overwritten.

## Channel Actions (Long-Press / Right-Click)

| Action | Description |
|---|---|
| Edit | Change name, PSK (with a dice icon to generate a random PSK), SMAZ compression toggle (compresses outgoing messages to allow longer text within the byte limit), Cyr2Lat encoding toggle (transliterates Cyrillic to Latin for compatibility), or "Enable URL images" toggle (previews image links; requires internet) |
| Mute / Unmute | Toggle push notification suppression for this channel |
| Delete | Remove the channel from the device and delete its messages, settings, region and images (confirmation required) |

Channel history and settings belong to the channel's key, not its slot on the radio. A slot reused for another channel (here or in another app) starts empty, editing a channel's PSK starts a fresh history, and adding a channel again with its old PSK brings its history back.

## Channel Chat

Tap a channel card to open the channel chat screen.

### App Bar

- Type icon: globe for public channels, tag (#) for all other channel types
- Channel name
- Subtitle: channel type and effective region when set, with `(default)` when inherited
- Tap the title or landscape icon to select a region; see [Regions](regions.md)
- Bell icon: mute or unmute notifications for this channel (crossed-out bell when muted)
- Overflow menu (⋮) → **Chat background**: a color or picture, with a fade slider, behind this channel only. See [Chat backgrounds](themes.md#chat-backgrounds). Holiday greetings in new messages play a short animation, as in [direct chat](chat-and-messaging.md#message-list)

### Message Display

- Reverse-scrolling list (newest at bottom)
- **Incoming messages**: Colored avatar with sender's initial (or first emoji if name starts with one; color is deterministic from sender name hash), sender name in primary color, message bubble
- **Outgoing messages**: Primary container color bubble with a small status icon: pending (clock), sent (checkmark), or failed (red error circle)
- Automatic older-message loading on scroll-to-top
- Jump-to-bottom button when scrolled up
- **Pinch-to-zoom**: Two-finger zoom (0.8x–1.8x) and double-tap to reset text size
- **Message tracing mode** (when enabled in App Settings): Each bubble additionally shows path prefix bytes (`via XX,YY,...`), a timestamp, and a repeat count icon

Messages also show a region label when known, independently of message tracing. By default the region chip sits below the hop count; turn on **Region next to hop count** in App Settings → Messaging to show both on one line. The [message-region guide](regions.md#regions-displayed-on-messages) explains why some incoming messages have no label.

### Message Types in Chat

- **Plain text** with linkified URLs
- **GIFs** (`g:{gifId}`) rendered inline via Giphy CDN
- **Location pins** (`m:{lat},{lon}|{label}|`) shown as tappable location cards
- **Mesh images** sent as GRP_DATA chunks and reconstructed locally ([setup and limitations](image-messages.md))
- **URL image previews** when enabled per channel; content is fetched over the internet
- **Reactions** displayed as emoji pills below target messages

### Replies (Channel Chat Only)

- **Mobile**: Swipe an **incoming** message left to trigger reply (with haptic feedback). You cannot swipe your own outgoing messages. Swipe reply is not available on desktop.
- **All platforms**: Long-press → "Reply"
- Reply banner appears above the input bar with the quoted message (tap X to cancel)
- A known original region is selected for the reply by default. Tap the region chip to cross it out and use the channel’s effective region instead. This temporary choice does not change channel settings; see [reply regions](regions.md#reply-using-the-original-region).
- Sent replies are prefixed `@[{senderName}] {text}`
- Received replies show a bordered quote block inside the bubble; tapping scrolls to the original. Reply previews render GIF thumbnails and location pin icons, not just text.

### Message Path Viewing

- **All platforms**: Long-press (or right-click on desktop) a message bubble → "Path"
- Opens the Channel Message Path Screen (see [Additional Features](additional-features.md))

### Channel Auto-Resend

With **Resend channel messages until they travel far enough** on (App Settings → Messaging), the app waits after each channel send and checks how far the message was heard repeated. If no repeat reached the required hop count, it sends the message again, up to the configured number of times.

Where your radio only hears nearby repeaters, turn on **Also count different nearby repeaters**: the message then also counts as sent once the required number of *different* first-hop repeaters have repeated it, across all attempts. Your own radio's echo and zero-hop echoes don't count.

### Context Actions (Long-Press / Right-Click)

| Action | Availability | Description |
|---|---|---|
| Reply | All messages | Triggers reply mode |
| Path | All messages | Opens message path view |
| Add Reaction | Incoming messages only | Opens emoji picker (cannot react to your own messages) |
| Copy | All messages | Copies text to clipboard |
| Mark as Unread | Incoming messages only | Marks this message and all subsequent incoming messages as unread |
| Delete | All messages | Removes locally (not from mesh) |

## Communities

Communities are a layer above channels that provide a private namespace.

### What is a Community?

A community has a name and a 32-byte random secret. Channel PSKs are derived from this secret:
- **Public channel**: `HMAC-SHA256(secret, "channel:v1:__public__")[:16]`
- **Hashtag channel**: `HMAC-SHA256(secret, "channel:v1:{hashtag}")[:16]`

Outsiders who don't know the secret cannot discover or join community channels.

### Sharing a Community

Communities are shared via QR codes containing a JSON payload:
```json
{"v": 1, "type": "meshcore_community", "name": "...", "k": "<base64url-secret>"}
```

### Managing Communities

From the channels screen overflow menu → "Manage Communities". Opens a draggable scrollable sheet (resizable 30–90% of screen height):

- Each community shows its name and a short community ID (first 8 hex characters)
- **Tap a community** to directly show its QR code for sharing
- **Popup menu** per community:
  - **Show QR** — displays the QR code for sharing with new members
  - **Leave Community** — removes the community locally and deletes all associated device channels (confirmation dialog warns how many channels will be removed)

## How Channels Differ from Direct Messages

| Aspect | Channels | Direct Messages |
|---|---|---|
| Addressing | Broadcast to all nodes with matching PSK | Point-to-point to a specific contact |
| Encryption | Shared PSK (symmetric) | Contact's public key (asymmetric) |
| Sender identity | Plain text prefix in payload | Verified via public key |
| Replies | Supported (swipe or long-press) | Not supported |
| Retry mechanism | No automatic retry | Exponential backoff with path rotation |
