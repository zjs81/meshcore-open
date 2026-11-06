# Review Mode

Review mode is a hidden mode for Google Play and App Store reviewers who have no MeshCore radio. It connects the app to a **simulated radio** that speaks the real companion protocol, so contact and channel sync, messages, ACKs, notifications, and Android Auto replies all run through the normal code paths. All of its code lives in `lib/review_mode/`.

## Entering and Exiting

1. Open the **Connect** (scanner) screen.
2. **Long-press the "MeshCore Open" title.**
3. Tap **Enter** in the dialog. The app connects to the simulated radio and opens the channel list.

While review mode is active, a banner at the top of the channel and contact lists shows **Send test message** and **Exit**. Tap **Exit**, or disconnect as usual, to leave review mode. The simulator is shut down, its data is deleted, and the app returns to the Connect screen.

## What the Simulated Radio Provides

- 6 contacts (4 people, the **Hilltop Repeater** and the **Trailhead Room**), the **Public** channel and 2 more channels (**Hiking Group** and **Local Net**), with seeded message history.
- The room accepts any password. Repeater login always fails, because repeater administration needs real hardware.
- A new incoming message about every 45 seconds, alternating between direct and channel messages.
- Automatic replies to messages you send to a person or the room: the ACK arrives after about 1.5 seconds and the reply about 4 seconds later. Channel messages get a reply from a channel member about 4 seconds after sending.
- A **Send test message** button that delivers one incoming message immediately.

## Data Isolation

The simulated radio uses a fixed, obviously fake public key (starting `ee5e`), so its contacts, channels, messages, and unread counts are stored under their own per-radio scope and never mix with a real radio's data. Review data is cleared when entering and when leaving review mode. The simulated radio never adopts the legacy unscoped keys that older app versions left behind, so that data stays for the next real radio.

Channel mutes are app-wide and stored by channel name, so muting the simulated **Public** channel would also mute a real one. Review mode saves the mute list when it starts and puts it back on exit. Other app settings changed during review (theme, notifications, text size) are kept, as they would be after any other session. If the app is killed while in review mode, the cleanup and mute restore run on the next launch.

## Platforms

Review mode works on Android, iOS, desktop, and web; it is not platform-gated.

- Web has no system notifications.
- On iOS, the simulator's timers run only while the app is in the foreground, so scheduled messages stop in the background. Use **Send test message** in the foreground.
- iOS notifications have no reply actions.

## When Notifications Appear

Simulated messages go through the normal notification pipeline. A notification is shown when all of these hold:

- Notifications are allowed by the OS (Android 13+ requires granting the permission) and **Enable Notifications** is on in App Settings.
- **Message Notifications** (direct) or **Channel Message Notifications** (channel) is on.
- The channel is not muted (there is no per-contact muting).
- The message is incoming and the sender is a known chat or room contact (direct messages from other contact types are not notified).

The app does **not** suppress notifications because it is in the foreground or because that chat is open. Opening a chat clears its unread count and notification. Bursts of messages update the notification silently (rate limited). Reviewers do not need to background the app for notifications to be posted, but notifications are far easier to see from another screen or the home screen.
