# Settings

## How to Access

- From the Device Screen: tap the tune/sliders icon in the app bar
- From Contacts or Channels: overflow menu (three-dot) → Settings

Settings are only accessible while a device is connected.

## Settings Screen Layout

The settings screen is a scrollable list of cards:

1. [Device Info](#device-info)
2. [Node Settings](#node-settings)
3. [Location](#location)
4. [App Settings](#app-settings) (link to sub-screen)
5. [Actions](#actions)
6. [Export](#export)
7. [Debug](#debug)
8. [About](#about)

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

## Node Settings

These settings are sent directly to the connected device firmware.

### Node Name
- Opens a dialog with a text field (max 31 characters)
- Sends the new name to the device
- Confirmed via snackbar

### Radio Settings
Opens a dialog pre-populated with the device's current radio settings. Contains:
- **Preset dropdown**: Regional presets — selecting a preset immediately fills all fields below. Includes presets for Australia, Australia (Narrow), Australia (Mid), Australia SA WA QLD, Czech Republic, EU 433MHz, EU/UK (Long Range), EU/UK (Medium Range), EU/UK (Narrow), New Zealand, New Zealand (Narrow), Portugal 433, Portugal 869, numerous Russia city presets, Switzerland, USA Arizona, USA/Canada, and Vietnam
- **Frequency** (MHz): Free text, validated 300–2500 MHz
- **Bandwidth**: Dropdown (7.8 / 10.4 / 15.6 / 20.8 / 31.25 / 41.7 / 62.5 / 125 / 250 / 500 kHz)
- **Spreading Factor**: SF5–SF12
- **Coding Rate**: 4/5, 4/6, 4/7, 4/8
- **TX Power** (dBm): Validated 0 to device max (typically 22 dBm)
- **Client Repeat** toggle: Only shown on firmware v9+; requires frequency to be exactly 433.000, 869.000, or 918.000 MHz (the Off-Grid presets). Save is blocked with a warning if enabled on other frequencies

### Regions

Open region management to add/fetch names and select a default flood scope. Channel chat can override it; clearing an override inherits the default. See [Regions](regions.md), including message labels and temporary reply-region choices.

### Radio stats
Opens the radio statistics screen for the paired radio: noise floor, last RSSI, last SNR, and total TX/RX airtime. Only enabled when connected to a device that supports companion radio stats (firmware code 8+). See the [radio-statistics guide](radio-statistics.md).

---

## Location

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

### Privacy
Opens a dialog with controls for how the node shares telemetry and location data:
- **Advert Location**: Toggle whether the node broadcasts its location in advertisements
- **Multi-Ack**: Toggle multi-ack delivery confirmations
- **Telemetry Base Mode**: Deny All / Allow by Contact / Allow All
- **Telemetry Location Mode**: Deny All / Allow by Contact / Allow All
- **Telemetry Environment Mode**: Deny All / Allow by Contact / Allow All

Settings take effect when saved. A snackbar confirms the update.

---

## App Settings

A dedicated sub-screen for app-level preferences (nothing here is sent to the device). All settings persist locally via SharedPreferences.

### Appearance
- **Theme**: System / Light / Dark
- **Language**: System default or one of 18 languages (English, French, Spanish, German, Polish, Slovenian, Portuguese, Italian, Chinese, Swedish, Dutch, Slovak, Bulgarian, Russian, Ukrainian, Hungarian, Japanese, Korean)

### Notifications
- **Master enable/disable**: Requests OS permission when enabling
- **Message notifications**: New direct message alerts
- **Channel message notifications**: New channel message alerts
- **Advertisement notifications**: New node discovery alerts

Individual channels can be muted from the channel chat bell icon, the channel list, or the channel notification. Replying from notifications, watches, and Android Auto is described in [Notifications](notifications.md).

### Messaging
- **Clear Path on Max Retry**: Erases the stored routing path after all retries fail
- **Jump to Oldest Unread**: When opening a chat, scrolls to the oldest unread message instead of the newest
- **Auto-fetch Repeater Settings** (off by default): Requests every setting when a repeater's settings screen opens. Each setting is a separate request over LoRa, so this is slow and uses airtime; when off, use Refresh All or the per-setting refresh buttons. See [Repeater Settings](repeater-management.md#repeater-settings)
- **Auto Route Rotation**: Enables weighted routing algorithm. When enabled, expands to show five slider sub-settings (hidden when off) and a Reset button:
  - Max Route Weight (1–10, default 5, integer steps)
  - Initial Route Weight (0.5–5.0, default 3.0)
  - Success Increment (0.1–2.0, default 0.5, 0.1 steps)
  - Failure Decrement (0.1–2.0, default 0.2, 0.1 steps)
  - Max Message Retries (2–10, default 5)
  - **Reset Routing Algorithm to Default**: Restores all five routing algorithm settings to their factory default values
- **Enable Message Tracing**: Shows path trace overlays and extra metadata on messages
- **Region next to hop count** (default off): Shows a channel message's region chip on the same line as its hop count instead of below it
- **Resend channel messages until they travel far enough** (default off): If your channel message isn't heard coming back through enough repeaters, it's sent again. Uses more airtime. When on, it shows:
  - Required hops (1–8, default 2)
  - Resend up to (1–5 times, default 1)
  - **Also count different nearby repeaters** (default off): Treats the message as sent once that many *different* first-hop repeaters have repeated it, even if you can't hear it travel further. Useful where only nearby repeaters are audible. See [Channels](channels.md#channel-auto-resend)

### Battery
- **Battery Chemistry**: NMC / LiFePO4 / LiPo (per device, used to calibrate percentage from voltage)

### Map Display
- **Show Repeaters**: Toggle repeater markers on map
- **Show Chat Nodes**: Toggle chat node markers
- **Show Other Nodes**: Toggle room/sensor markers
- **Time Filter**: All time / Last 1h / Last 6h / Last 24h / Last week
- **Units**: Metric / Imperial
- **Raster Tile Source**: Sets the MAP theme and with that from where to get the map tile data:
  - OpenStreetMap (Auto/Standard/Dark) is provided by the free OpenStreetMap tile server. (Can only be used for live view or already cached.)
  - Stamen Terrain / AlidadeSmooth Dark / Outdoors / OSM Bright are [StadiaMaps.com raster tile maps](https://stadiamaps.com/products/maps/interactive-basemaps/) for which you can choose an Hosted Endpoint (Worldwide / Europe hosted) and have to provide the API key to your subscription. (You can cache these maps for offline Map usage.)
  There will be no account provided by meshcore-open. You will have to get you own subscription. Check [current Stadia Maps plans and terms](https://stadiamaps.com/pricing/) for quotas and offline-use permissions.
- **Offline Map Cache**: Navigate to tile download screen

### Translation
Not shown on web. Controls on-device message translation powered by a locally-downloaded ML model:
- **Enable translation**: Enables message translation controls
- **Auto-translate incoming messages**: Automatically translates incoming messages for chat/channel display and notifications
- **Translate before sending**: Sets the default state of the composer's translate icon (on means messages are translated before sending)
- **Target language**: Language to translate into (searchable list; defaults to the app language)
- **Downloaded model**: Dropdown to select among already-downloaded translation models
- **Preset Hugging Face model**: Download a curated preset model with one tap
- **Manual model URL**: Enter a URL to download a custom GGUF-format model; shows download progress and a cancel button

The auto-translate and composer toggles are disabled until **Enable translation** is on.

### IPFS Provider Configuration

Open **App Settings → IPFS provider configuration** to configure IPFS uploads and previews:

- **Public IPFS gateway**: Select Pinata, Filebase, a custom gateway, or deactivate it. This gateway lets the app load bare IPFS content IDs in image links.
- **Upload provider**: Select Pinata, Filebase, a custom provider, or deactivate uploads. Presets fill in the provider’s upload endpoint and upload gateway; custom setups can edit both.
- **API key**: Enter the credential required by the selected provider. The value is masked in the settings dialog. Pinata and Filebase presets require provider credentials.

For a self-hosted Kubo node, choose **Custom (Kubo)** and configure its RPC upload endpoint and HTTP gateway. The preset defaults use `http://127.0.0.1:5001/api/v0/add` and `http://127.0.0.1:8080/ipfs/`; replace these with addresses reachable from the device running MeshCore Open. Do not expose Kubo’s unauthenticated RPC API to the public internet.

When an **upload gateway** is configured, uploaded content is added to the draft as an HTTP(S) gateway URL in the form `http://gateway/ipfs/CID`. If it is blank, the app uses `ipfs://CID`. The public gateway setting is separate and is used to retrieve bare IPFS content IDs in incoming links.

Save the settings before sharing. The upload action is shown in the chat composer only when an upload endpoint is configured. Provider accounts, credentials, limits, and terms are managed by the provider, not MeshCore Open. See [sharing images via IPFS](additional-features.md#share-an-image-via-ipfs) for the chat workflow.

### Image Messages

Image message controls live in App Settings → Messaging. Turn on **Enable image messages** first; **Process images automatically** and the image model download/cancel/removal controls then appear. Automatic processing reconstructs every image as it arrives and uses about 2 GB of memory for a second each time; leave it off to reconstruct with a tap. See [Image Messages](image-messages.md) for firmware, native-runtime, storage, and memory requirements.

### Cyrillic-to-Latin (Cyr2Lat)
Controls character substitution profiles used to render Cyrillic text in Latin characters. A dropdown selects the active profile; Add, Edit, and Delete buttons manage the profile list (the last remaining profile cannot be deleted). Each profile stores a JSON character map.

### Debug
- **App Debug Logging**: Enable the in-app debug log

---

## Actions

One-tap device operations:

| Action | Description |
|---|---|
| Sync Time | Sends current Unix timestamp to the device |
| Refresh Contacts | Re-requests the full contact list |
| Reboot Device | Confirmation dialog → reboots the device (shown in warning color) |
| Delete All Paths | Confirmation dialog → clears all stored routing paths (shown in alert color) |

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

## About

Shows the standard Flutter about dialog with app name, version, and legal notice.
