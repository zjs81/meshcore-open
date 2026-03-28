# Navigation

## App Flow

The app follows this general flow:

```
Launch → Scanner Screen → [Connect via BLE/USB/TCP] → Contacts Screen
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

## Device Screen

The Device Screen is a transitional hub that shows after connection. In practice, the app navigates directly to Contacts after connecting, but the Device Screen is reachable via the QuickSwitchBar.

### What the User Sees

**App Bar**:
- Left: Battery indicator chip (tappable — toggles between percentage and voltage display). Icon changes based on level: `battery_unknown` when data unavailable, `battery_alert` (orange) at 15% or below, `battery_full` otherwise
- Left-aligned title (`centerTitle: false`): Two-line layout — small grey "MeshCore" label above the device name in bold
- Right: Disconnect button (`bluetooth_disabled` crossed-out icon) and Settings button (tune icon)

**Body**:
- **Connection Card**: Device avatar, device name, device ID, "Connected" chip, and battery chip
- **Quick Switch** section: The QuickSwitchBar widget for navigating to Contacts/Channels/Map

### Disconnection

- The disconnect button shows a confirmation dialog before disconnecting
- If the device disconnects unexpectedly, the app automatically navigates back to the Scanner screen (fires after the current frame completes via a post-frame callback)
- This auto-navigation behavior (`DisconnectNavigationMixin`) is shared across all main screens

## Theme and Locale

- **Theme mode** is user-configurable in App Settings (System / Light / Dark) — not locked to system
- **Language** can be overridden to one of 15 supported languages, or follow the system locale
- On web, if a non-Chromium browser is detected, the app shows a `ChromeRequiredScreen` instead of the Scanner (Web Bluetooth requires Chromium)

## Full Navigation Graph

```
ScannerScreen (root, always on stack)
  ├─ [BLE connect] → push → ContactsScreen
  ├─ [TCP FAB] → push → TcpScreen
  │     └─ [TCP connected] → pushReplacement → ContactsScreen
  └─ [USB FAB] → push → UsbScreen
        └─ [USB connected] → pushReplacement → ContactsScreen

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
  ├─ [radar button] → push → PathTraceMapScreen
  ├─ [terrain button] → push → LineOfSightMapScreen
  └─ [long-press] → share marker / set location

Settings (push from any main screen)
  └─ [App Settings] → push → AppSettingsScreen
        └─ [Offline Map Cache] → push → MapCacheScreen
```

Any disconnection from any screen triggers `popUntil(route.isFirst)`, returning to the Scanner.
