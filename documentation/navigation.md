# Navigation

## App Flow

The app follows this general flow:

```
Launch → Scanner Screen → [Connect via BLE/USB/TCP] → Channels Screen
Launch (a radio connected before) → Channels Screen (offline until connected)
```

After connecting, the three main screens (Contacts, Channels, Map) are accessible via a persistent bottom navigation bar called the **QuickSwitchBar**.

## Quick Switch Bar

The QuickSwitchBar is a Material 3 `NavigationBar` with a frosted-glass visual treatment (blur backdrop, transparent theme, rounded corners). It appears at the bottom of all three main screens.

| Index | Icon | Label | Screen |
|---|---|---|---|
| 0 | People | Contacts | ContactsScreen |
| 1 | Tag | Channels | ChannelsScreen |
| 2 | Map | Map | MapScreen |

Tapping a tab replaces the current screen with a subtle fade + slight horizontal nudge transition (220ms forward, 200ms reverse). The back button is suppressed on all three main screens — navigation between them is flat, not stacked. All icons use outline variants (`people_outline`, `tag`, `map_outlined`) following Material 3 conventions.

## Disconnection

- The disconnect entry in the overflow menu of each main screen shows a confirmation dialog, then leaves you on the same screen, offline. While offline the entry reads **Connect** and opens the connect sheet.
- If the radio disconnects unexpectedly, the screens stay where they are and become read-only; see [offline mode](offline-mode.md).

## Theme and Locale

- **Theme mode** is user-configurable in App Settings (System / Light / Dark) — not locked to system
- **Language** can be overridden to one of 18 supported languages, or follow the system locale
- On web, if a non-Chromium browser is detected, the app shows a `ChromeRequiredScreen` instead of the Scanner (the web client needs Chrome for Web Serial USB)

## Full Navigation Graph

```
ScannerScreen (root when no radio is remembered; otherwise pushed from the connect sheet)
  ├─ [BLE connect] → ChannelsScreen as the only route
  ├─ [TCP icon button] → push → TcpScreen
  │     └─ [TCP connected] → ChannelsScreen as the only route
  └─ [USB icon button] → push → UsbScreen
        └─ [USB connected] → ChannelsScreen as the only route

ContactsScreen (selected=0)
  ├─ [quick-switch 1] → pushReplacement → ChannelsScreen
  ├─ [quick-switch 2] → pushReplacement → MapScreen
  ├─ [tap contact] → push → ChatScreen
  ├─ [overflow > Settings] → push → SettingsScreen
  └─ [overflow > Discovered] → push → DiscoveryScreen

ChannelsScreen (selected=1)
  ├─ [quick-switch 0] → pushReplacement → ContactsScreen
  ├─ [quick-switch 2] → pushReplacement → MapScreen
  ├─ [tap channel] → push → ChannelChatScreen
  └─ [overflow > Settings] → push → SettingsScreen

MapScreen (selected=2)
  ├─ [quick-switch 0] → pushReplacement → ContactsScreen
  ├─ [quick-switch 1] → pushReplacement → ChannelsScreen
  ├─ [radar menu item] → enters in-map path trace mode (push → PathTraceMapScreen after path is built)
  ├─ [Path trace by hashes] → push → ManualPathTraceScreen → push → PathTraceMapScreen
  ├─ [terrain menu item] → push → LineOfSightMapScreen
  └─ [long-press] → share marker sheet

Settings (push from any main screen)
  └─ [App Settings] → push → AppSettingsScreen
        └─ [Offline Map Cache] → push → MapCacheScreen
```

A connection made from the scanner, USB, TCP or review mode replaces the whole stack with ChannelsScreen (`navigateToMainAfterConnect`). Leaving the scanner cancels only a Bluetooth connection it started; a pending automatic reconnect is left alone.

## Additional settings destinations

Settings → Regions opens [region management](regions.md). Settings → Radio stats opens [companion statistics](radio-statistics.md), including self-telemetry access. Settings → Telemetry opens telemetry for your own radio directly. App Settings contains image model setup and translation model controls. Contact QR scanning is available from Contacts; community QR scanning is available from Channels.
