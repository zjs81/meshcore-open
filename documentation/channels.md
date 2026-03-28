# Channels

## Overview

Channels are broadcast group-chat spaces secured by a 16-byte pre-shared key (PSK). Any device with the same channel index and PSK will receive and decrypt channel messages. Unlike direct messages, channel messages are broadcast to the entire mesh.

Up to 8 channels (indices 0–7) can be active simultaneously on one device.

## How to Access

QuickSwitchBar tab 1 (middle) from any main screen.

## Channel Types

| Type | Icon | Color | Description |
|---|---|---|---|
| Public | Globe | Green | Fixed well-known PSK; any device can join |
| Hashtag | Hash tag | Blue | PSK derived from the hashtag name via SHA-256; discoverable by convention |
| Private | Lock | Blue | Random PSK; requires out-of-band sharing of the 32-hex key |
| Community | Groups/Tag | Purple | PSK derived via HMAC-SHA256 from a community's shared secret |

## Channels List Screen

### What the User Sees

- **Search bar** with live text filtering (300ms debounce)
- **Sort/filter button**
- **Scrollable list of channel cards**, each showing:
  - Type icon with color coding (purple badge overlay for community channels)
  - Channel name (or "Channel N" if unnamed)
  - Subtitle: "Public channel", "Hashtag channel", "Private channel", or "Community channel - {name}"
  - Unread badge (if messages are unread)
  - Drag handle (when manual sort is active)
- **"+" FAB** to add a new channel
- **Overflow menu**: Disconnect, Manage Communities (only shown when at least one community exists), Settings

If no channels exist, an empty state with an "Add Public Channel" shortcut is shown. If a search produces no results, a separate "no results" empty state with a search-off icon is shown.

Pull-to-refresh (swipe down) forces a re-fetch of channels from the device firmware.

### Sorting Options

- **Manual** (default): Drag-and-drop reordering, persisted (drag handles are hidden when a search query is active)
- **A–Z**: Alphabetical
- **Latest messages**: Most recent first
- **Unread**: Most unread first

## Adding a Channel

Tap the "+" FAB to open a dialog with six options:

1. **Create Private Channel** — Enter a name (max 31 characters); a random PSK is generated
2. **Join Private Channel** — Enter a name and a 32-hex PSK (non-hex characters like spaces and dashes are silently stripped, so pasted keys with formatting are accepted)
3. **Join Public Channel** — One tap; uses the well-known public PSK (only shown if no public channel exists)
4. **Join Hashtag Channel** — Enter a hashtag name; PSK is derived from the name. If communities exist, choose between regular hashtag (SHA-256) or community hashtag (HMAC)
5. **Scan Community QR** — Opens QR scanner to join a community
6. **Create Community** — Enter a name; generates a random 32-byte secret; optionally adds a community public channel; shows QR code for sharing

## Channel Actions (Long-Press / Right-Click)

| Action | Description |
|---|---|
| Edit | Change name, PSK (with a dice icon to generate a random PSK), or SMAZ compression toggle (compresses outgoing messages to allow longer text within the byte limit) |
| Mute / Unmute | Toggle push notification suppression for this channel |
| Delete | Remove the channel from the device (confirmation required) |

## Channel Chat

Tap a channel card to open the channel chat screen.

### App Bar

- Type icon (public/private/hashtag)
- Channel name
- Subtitle: "{type} - {N} unread"

### Message Display

- Reverse-scrolling list (newest at bottom)
- **Incoming messages**: Colored avatar with sender's initial (or first emoji if name starts with one; color is deterministic from sender name hash), sender name in primary color, message bubble
- **Outgoing messages**: Primary container color bubble with a small status icon: pending (clock), sent (checkmark), or failed (red error circle)
- Automatic older-message loading on scroll-to-top
- Jump-to-bottom button when scrolled up
- **Pinch-to-zoom**: Two-finger zoom (0.8x–1.8x) and double-tap to reset text size
- **Message tracing mode** (when enabled in App Settings): Each bubble additionally shows path prefix bytes (`via XX,YY,...`), a timestamp, and a repeat count icon

### Message Types in Chat

- **Plain text** with linkified URLs
- **GIFs** (`g:{gifId}`) rendered inline via Giphy CDN
- **Location pins** (`m:{lat},{lon}|{label}|`) shown as tappable location cards
- **Reactions** displayed as emoji pills below target messages

### Replies (Channel Chat Only)

- **Mobile**: Swipe an **incoming** message left to trigger reply (with haptic feedback). You cannot swipe your own outgoing messages. Swipe reply is not available on desktop.
- **All platforms**: Long-press → "Reply"
- Reply banner appears above the input bar with the quoted message (tap X to cancel)
- Sent replies are prefixed `@[{senderName}] {text}`
- Received replies show a bordered quote block inside the bubble; tapping scrolls to the original. Reply previews render GIF thumbnails and location pin icons, not just text.

### Message Path Viewing

- **Mobile**: Tap a message bubble to view its routing path
- **Desktop**: Long-press/right-click → "Path" (tapping the bubble does nothing on desktop)
- Opens the Channel Message Path Screen (see [Additional Features](additional-features.md))

### Context Actions (Long-Press / Right-Click)

| Action | Availability | Description |
|---|---|---|
| Reply | All messages | Triggers reply mode |
| Path | Desktop only | Opens message path view |
| Add Reaction | Incoming messages only | Opens emoji picker (cannot react to your own messages) |
| Copy | All messages | Copies text to clipboard |
| Delete | All messages | Removes locally (not from mesh) |

### Message Path Viewing

Tap a message bubble to open the Channel Message Path Screen, which shows:
- Each hop in the path as a visual chain
- Known contacts identified by name at each hop
- Observed vs. declared hop counts
- Alternative path variants (if received via multiple paths)
- Map view buttons for geographic path visualization

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
  - **Delete** — removes the community locally and deletes all associated device channels (confirmation dialog warns how many channels will be removed)

## How Channels Differ from Direct Messages

| Aspect | Channels | Direct Messages |
|---|---|---|
| Addressing | Broadcast to all nodes with matching PSK | Point-to-point to a specific contact |
| Encryption | Shared PSK (symmetric) | Contact's public key (asymmetric) |
| Sender identity | Plain text prefix in payload | Verified via public key |
| Replies | Supported (swipe or long-press) | Not supported |
| Retry mechanism | No automatic retry | Exponential backoff with path rotation |
