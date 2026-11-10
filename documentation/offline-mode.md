# Offline Mode

When no radio is connected, the app keeps showing the last radio you connected to, read-only.

## What you see

- **Launch.** If a radio has connected before, the app opens on Channels instead of the scanner. With no remembered radio it opens on the scanner, as before.
- **Contacts, channels, messages, unread counts and the map** show that radio's saved data. Chats open, scroll, search and jump as usual.
- **App bar.** The battery and signal indicators are replaced by a **Connect** button (icon only on narrow screens). The subtitle reads "Offline · *radio name*". While the app is connecting, or a dropped link will be retried, a "Reconnecting…" chip shows instead; tapping it opens the same sheet.
- **Message box.** Each chat replaces the message box with "Connect to a radio to send messages" and a Connect button. Text you typed before the link dropped is kept and comes back when the radio reconnects.

## Connecting

The Connect button and the overflow menu's **Connect** entry (it replaces **Disconnect** while offline) open a sheet with:

- **Reconnect to *name*.** For a Bluetooth or TCP radio. It connects directly, without the scanner. Not offered on web.
- **Choose a radio.** Opens the scanner (Bluetooth, USB or TCP). For a USB radio, or on web, it opens the USB screen.
- **Stop reconnecting.** Shown while an automatic reconnect is pending.

After a connection made from the scanner, USB, TCP or review mode, the app shows Channels as its only screen. Reconnecting from the sheet keeps you on the screen you were on.

**Disconnect** asks for confirmation and then leaves you on the same screen, offline. The app no longer returns to the scanner when a radio disconnects.

## What is available offline

Available: reading, scrolling, opening chats, search and jump, copy, message details and paths, path maps, translating a message for reading, notification mode, chat background, text size, channel region labels, contact groups, app settings, message filter settings, themes and language.

Unavailable (shown disabled or hidden):

- Sending: messages, reactions, replies, resend, GIFs, images, location and contact sharing, map pins.
- Channels: add, edit, delete, join or leave a community, pull to refresh.
- Contacts: add (clipboard, QR, discovered), remove, favourite, share, adverts, path trace, forget path, discovered-contact import/export and delete.
- Repeaters and rooms: login, management and telemetry. Tapping a room opens its saved chat without a login, read-only.
- Region fetching, radio settings and other radio commands in Settings.
- Changing stored history: clear chat, delete messages, bulk delete, mark spam / not spam.

Routing overrides in the routing sheet can still be chosen offline; they are saved on the phone and used on the next send ("Path saved locally").

## Notes

- Notification taps open the saved chat even while offline.
- Only one radio is remembered: the last one that completed a connection. Review mode never replaces it, and the remembered radio's data is shown again when a review session ends.
- Connecting to a different radio replaces the shown data with that radio's.
- The remembered radio is stored in the app-wide preference `last_radio`.
- USB radios cannot be reconnected from the sheet; use **Choose a radio**.
