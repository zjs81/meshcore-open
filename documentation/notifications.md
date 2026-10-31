# Notifications

## Overview

MeshCore Open provides both **system notifications** (push-style OS alerts) and **in-app unread badges** to inform users of new activity.

## Notification Types

### 1. Direct Message Notifications
- **Triggered when**: A new incoming message arrives from a Chat or Room contact
- **Title**: Contact's name
- **Body**: Message text (reactions show "Reacted [emoji]", GIFs show "Sent a GIF")
- **Priority**: High
- **Android channel**: `messages`
- **Android style**: conversation (MessagingStyle) showing the last few messages, with **Reply** and a hidden **Mark as read** action. When URL images are enabled, an image preview appears as the notification's thumbnail

### 2. Channel Message Notifications
- **Triggered when**: A new message arrives on a non-muted channel
- **Title**: Channel name (or "Channel N" if unnamed)
- **Body**: `"<senderName>: <message text>"`
- **Priority**: High
- **Android channel**: `channel_messages`
- **Android style**: group conversation with each sender shown by name, with **Reply**, **Mute channel**, and a hidden **Mark as read** action

### 3. Advertisement Notifications
- **Triggered when**: A new node is discovered on the mesh for the first time
- **Title**: "New [type] discovered" (e.g., "New Chat discovered")
- **Body**: Contact's name
- **Priority**: Default
- **Android channel**: `adverts`

### 4. Background Service Notification (Android Only)
- A persistent low-priority notification: "MeshCore running — Keeping BLE connected"
- Required by Android for foreground services to keep BLE alive in the background
- Tap to re-launch the app
- **Does not auto-start on reboot** — the user must re-open the app manually after a phone restart

### Replying from Notifications, Watches, and Android Auto (Android)

Message notifications can be answered without opening the app, from the notification shade, a paired Wear OS or Galaxy watch, or Android Auto (which reads messages aloud and takes voice replies).

- **Reply** sends through the connected radio exactly like the chat screen: same length limits, SMAZ and Cyr2Lat handling, and retries. Your reply is then added to the notification.
- **Replies over the message limit** are split at word boundaries into up to 3 messages. Longer replies are not sent; a "Reply not sent" notification asks you to open the app.
- **Mark as read** clears the unread count on the phone only. MeshCore has no read receipts, so nothing is sent over the mesh.
- **Mute channel** (phone and watch) sets that channel to **Muted**, the same as choosing Muted from the bell icon in the channel chat.
- If the radio is disconnected, the conversation is no longer on the radio, the radio reports a send error, or the app isn't running, a "Reply not sent" notification explains why. The reply is not queued. If a split reply fails partway, earlier parts may already have been sent.
- Replies are sent as typed; composer translation is not applied.

iOS notifications do not have reply actions yet.

### Android Auto

MeshCore Open works in Android Auto as a notification-based messaging app. There is no MeshCore screen in the car; Android Auto provides the interface.

Android Auto support is off by default and is compiled in only when the build passes the `androidAuto` Gradle property:

```bash
flutter build apk --release --android-project-arg=androidAuto=true
```

The flag merges `android/app/src/androidAuto/` (the `com.google.android.gms.car.application` manifest entry and `automotive_app_desc.xml`) into the app. Without it, Android Auto does not list the app. Notification replies from the shade and watches work either way.

- New direct and channel messages appear on the car display and can be read aloud.
- Reply by voice or with a suggested reply; replies follow the rules above (splitting, failure notifications, no translation).
- Android Auto shows **Reply** and **Mark as read**. **Mute channel** is marked as a mute action, but Android Auto only documents reply and mark-as-read for messaging apps, so mute may not appear in the car; use the phone, a watch, or the bell icon.
- Setup: none beyond allowing MeshCore Open notifications. The app must be running with the radio connected, as for any notification.

Limitations:

- Only messages that arrive during the Android Auto session are shown; there is no conversation list or message history in the car.
- You can reply to a received message, but you cannot start a new message by voice (for example, "send a MeshCore message to Public"). Android Auto does not currently offer this to third-party messaging apps.
- Sideloaded or debug builds only appear in Android Auto when its developer setting **Unknown sources** is on.

Testing with the Desktop Head Unit (DHU): enable Android Auto developer mode (tap **Version** about 10 times in Android Auto settings), turn on **Unknown sources**, choose **Start head unit server**, run `adb forward tcp:5277 tcp:5277`, then start `desktop-head-unit` from the SDK's `extras/google/auto` package. Use DHU 2.1 or newer; version 2.0 disconnects from current Android Auto releases.

### Notification Tap Behavior

Tapping a notification currently re-launches the app at the root route. It does **not** navigate directly to the relevant chat or channel.

## In-App Unread Badges

Red numeric badges appear throughout the UI:
- **Contacts list**: Each contact row shows a red pill badge (e.g., "3") for unread messages
- **Channels list**: Each channel row shows an unread badge
- **Chat screen subtitle**: Shows unread count inline
- Badges cap at "9999+" for display

### App Icon Badge (iOS and macOS)

The app icon (iOS) or dock icon (macOS) badge shows the total unread count. It is set directly by the app, so it clears when you read your messages, and it is re-synced to the real unread total whenever the app returns to the foreground. On Android the launcher badge comes from the active notifications instead.

### How Unread Counts Work

- Stored per contact (by public key) and per channel, **scoped to the connected device's identity** (first 10 hex characters of its public key). Switching between different radios gives each its own independent unread state
- **Suppressed when viewing**: Opening a chat resets the count to 0 and cancels the OS notification
- **Ignored for**: Outgoing messages, CLI messages, and repeater contacts
- Debounced writes (500ms) to avoid excessive storage I/O during message bursts

## Notification Settings

Access via **App Settings → Notifications**:

| Setting | Default | Description |
|---|---|---|
| Enable Notifications | On | Master toggle; requests OS permission when turned on |
| Message Notifications | On | DM alerts (greyed out if master is off) |
| Channel Message Notifications | On | Channel alerts (greyed out if master is off) |
| Advertisement Notifications | On | New node alerts (greyed out if master is off) |

### Per-Channel Notification Modes

Each channel supports three notification modes:

| Mode | Icon | Behavior |
|---|---|---|
| **All messages** | 🔔 | Receive notifications for every message |
| **Mentions only** | 🔔! | Only notify when a message mentions your name (see below) |
| **Muted** | 🔕 | No notifications |

Set the mode from:

- The notifications icon in the channel chat app bar (tap to open the mode picker)
- Long-press a channel in the channels list → **Notification settings** → select mode

The Android **Mute channel** notification action sets the channel to **Muted**; it cannot choose another mode.

A message mentions you if it contains `@[yourname]` or `@yourname`, case-insensitively. The plain `@yourname` form must stand alone as a word, so `@bobby` does not mention `bob` and `x@bob.com` is not a mention; names with spaces must be written in full. Detection (`MeshCoreConnector.textMentionsName`) runs on the original text, before any automatic translation.

## Rate Limiting

The notification system prevents notification storms:
- **Minimum interval**: 3 seconds between alerts
- **Messages**: each direct or channel message always updates its conversation notification, so Reply stays available. Messages arriving within 3 seconds of the last alert update silently instead of alerting again.
- **Advertisements batch window**: If multiple advertisement notifications arrive within 5 seconds, they are combined into a single summary notification on a fourth Android channel (`batch_summary`). The title is "MeshCore Activity" and the body lists the count (e.g., "3 new nodes"). Batch summaries are Android-only; queued notifications that overflow the batch window are silently dropped on other platforms

## Notification Clearing

- **Opening a contact chat**: Cancels the OS notification and resets unread count
- **Opening a channel**: Cancels the channel notification and resets unread count
- **Opening Contacts screen**: Cancels all advertisement notifications

## Translation and image references

Automatic incoming translation can also translate notification text when enabled with a ready local model. GIF and URL-image retrieval still need internet; receiving a notification does not make those references available offline. For image packet progress and reconstruction states, use [channel image chat](image-messages.md).

## Platform Support

| Platform | Message Notifs | Reply / Mute Actions | Android Auto | Badge | Background Service |
|---|---|---|---|---|---|
| Android | Yes | Yes (incl. watches) | Yes | Via notification number | Yes (foreground service) |
| iOS | Yes | No | — | Yes (app badge) | No |
| macOS | Yes | No | — | Yes (dock badge) | No |
| Windows | Yes | No | — | No | No |
| Linux | Yes (if D-Bus available) | No | — | No | No |
