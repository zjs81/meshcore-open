# Settings

## How to Access

- From the Device Screen: tap the tune/sliders icon in the app bar
- From Contacts or Channels: overflow menu (three-dot) → Settings

Settings are only accessible while a device is connected.

## Settings Screen Layout

The settings screen is a scrollable list of cards:

1. [Device Info](#device-info)
2. [App Settings](#app-settings) (link to sub-screen)
3. [Node Settings](#node-settings)
4. [Actions](#actions)
5. [Debug](#debug)
6. [Export](#export)
7. [About](#about)

---

## Device Info

A collapsible card showing read-only device information. **Collapsed by default** — tap the header to expand with an animated chevron indicator:

| Field | Description |
|---|---|
| Name | Connected device's display name |
| ID | Device identifier |
| Status | Connected / Disconnected |
| Battery | Percentage or voltage (tap to toggle) |
| Node Name | The node's mesh identity name |
| Public Key | First 16 hex characters + "..." |
| Contacts Count | Number of known contacts |
| Channel Count | Number of configured channels |

Battery shows an alert icon and orange text when at 15% or below. The toggle only works when millivolt data is available from the firmware.

---

## App Settings

A dedicated sub-screen for app-level preferences (nothing here is sent to the device). All settings persist locally via SharedPreferences.

### Appearance
- **Theme**: System / Light / Dark
- **Language**: System default or one of 15 languages (English, French, Spanish, German, Polish, Slovenian, Portuguese, Italian, Chinese, Swedish, Dutch, Slovak, Bulgarian, Russian, Ukrainian)
- **Enable Message Tracing**: Shows path trace overlays and extra metadata on messages

### Notifications
- **Master enable/disable**: Requests OS permission when enabling
- **Message notifications**: New direct message alerts
- **Channel message notifications**: New channel message alerts
- **Advertisement notifications**: New node discovery alerts

### Messaging
- **Clear Path on Max Retry**: Erases the stored routing path after all retries fail
- **Auto Route Rotation**: Enables weighted routing algorithm. When enabled, expands to show five slider sub-settings (hidden when off):
  - Max Route Weight (1–10, default 5, integer steps)
  - Initial Route Weight (0.5–5.0, default 3.0)
  - Success Increment (0.1–2.0, default 0.5, 0.1 steps)
  - Failure Decrement (0.1–2.0, default 0.2, 0.1 steps)
  - Max Message Retries (2–10, default 5)

### Battery
- **Battery Chemistry**: NMC / LiFePO4 / LiPo (per device, used to calibrate percentage from voltage)

### Map Display
- **Show Repeaters**: Toggle repeater markers on map
- **Show Chat Nodes**: Toggle chat node markers
- **Show Other Nodes**: Toggle room/sensor markers
- **Time Filter**: All time / Last 1h / Last 6h / Last 24h / Last week
- **Units**: Metric / Imperial
- **Offline Map Cache**: Navigate to tile download screen

### Debug
- **App Debug Logging**: Enable the in-app debug log

---

## Node Settings

These settings are sent directly to the connected device firmware.

### Node Name
- Opens a dialog with a text field (max 31 characters)
- Sends the new name to the device
- Confirmed via snackbar

### Radio Settings
Opens a dialog pre-populated with the device's current radio settings. Contains:
- **Preset dropdown**: 19 regional presets — selecting a preset immediately fills all fields below. Full list: Australia, Australia (Narrow), Australia SA/WA/QLD, Czech Republic, EU 433MHz, EU/UK (Long Range), EU/UK (Medium Range), EU/UK (Narrow), New Zealand, New Zealand (Narrow), Portugal 433, Portugal 869, Switzerland, USA Arizona, USA/Canada, Vietnam, Off-Grid 433, Off-Grid 869, Off-Grid 918
- **Frequency** (MHz): Free text, validated 300–2500 MHz
- **Bandwidth**: Dropdown (7.8 / 10.4 / 15.6 / 20.8 / 31.25 / 41.7 / 62.5 / 125 / 250 / 500 kHz)
- **Spreading Factor**: SF5–SF12
- **Coding Rate**: 4/5, 4/6, 4/7, 4/8
- **TX Power** (dBm): Validated 0 to device max (typically 22 dBm)
- **Client Repeat** toggle: Only shown on firmware v9+; requires frequency to be exactly 433.000, 869.000, or 918.000 MHz (the Off-Grid presets). Save is blocked with a warning if enabled on other frequencies

### Location
Opens a dialog pre-populated with the device's current coordinates (if known):
- Latitude and longitude fields (decimal, 6 decimal places). If only one field is provided, the other uses the device's current value
- If GPS-capable hardware (detected via `gps` custom variable):
  - GPS Update Interval (seconds, 60–86399, default 900 = 15 minutes). Validated and sent separately before lat/lon
  - Enable GPS toggle (takes effect immediately, not deferred to Save)
- Validation: lat ±90, lon ±180

### Contact Settings
Five toggles controlling which node types are auto-added when heard:
- Auto-add Chat Users
- Auto-add Repeaters
- Auto-add Room Servers
- Auto-add Sensors
- Overwrite Oldest (when contact list is full)

### Privacy Mode
Opens a confirmation dialog with three buttons: Cancel, Enable, and Disable. Both states can be set from the same dialog regardless of current state. A snackbar confirms which state was applied. When on, the node stops broadcasting its location in advertisements.

---

## Actions

One-tap device operations:

| Action | Description |
|---|---|
| Send Advertisement | Floods the mesh with your node's advertisement |
| Sync Time | Sends current Unix timestamp to the device |
| Refresh Contacts | Re-requests the full contact list |
| Reboot Device | Confirmation dialog → reboots the device (shown in orange) |

---

## Debug

Two log viewers accessible via list tiles:

### BLE Debug Log
Two views (togglable via segmented button):
- **Frames view**: Direction icon, description, hex preview, timestamp per frame. Long-press to copy hex.
- **Raw Log RX view**: Decoded LoRa packets with route type, payload type, path, and summary.
- Copy-all and Clear buttons in the app bar.

### App Debug Log
Structured log entries (Info / Warning / Error), with tag, message, and timestamp.
- Must be enabled first in App Settings → Debug
- Copy-all and Clear buttons

---

## Export

Three GPX export options (not available on web):

| Option | Exports |
|---|---|
| Export Repeaters | Repeaters and Rooms with GPS coordinates |
| Export Contacts | Chat contacts with GPS coordinates |
| Export All | All contacts with GPS coordinates |

Each creates a `.gpx` file and opens the OS share sheet. Feedback via snackbar for four outcomes: success, no contacts with coordinates, feature not available (web), or error.

---

## About

Shows the standard Flutter about dialog with app name, version, and legal notice.
