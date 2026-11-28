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
4. [App Settings](#app-settings) and [Local API](#local-api) (links to sub-screens)
5. [Actions](#actions)
6. [Backup & Restore and Export Data](#backup--restore-and-export-data)
7. [Debug](#debug)
8. [About](#about)

Every entry opens its own page. Settings stored on the radio (Node Name, Radio Settings, Location, Contact Settings, Privacy) are sent only when you tap **Save**, which appears once something changes. Leaving with unsaved changes asks to discard or save. While disconnected, the page stays open with a banner and Save is disabled. A failed save keeps your edits.

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
Name field with a byte counter (`x / 31`). Special characters and emojis take more than one byte. A longer name can be typed, but the counter turns red, the field says how many bytes it is over, and Save stays disabled. **Message length** updates as you type:
- **Channel messages**: 158 bytes minus the name, which is sent as `Name: ` with each message (127 with a 31-byte name)
- **Direct messages**: 156 bytes, independent of the name

### Radio Settings
Opens a page pre-populated with the radio's current settings.

**Parameters**, in two cards:
- **Presets**: Australia (four variants), Czech Republic, EU 433MHz, EU/UK (Long Range, Medium Range, Narrow), New Zealand (two variants), Portugal 433 and 869, Russian city presets, Slovakia, Switzerland, USA Arizona, USA Philly, USA Sacramento-Foothills, USA Southern California, USA/Canada and Vietnam. Selecting one fills in frequency, bandwidth, SF, CR and TX power. Shows **Custom** when the values match no preset
- **Frequency** (MHz): 150-2500 MHz
- **Bandwidth**: 7.8 / 10.4 / 15.6 / 20.8 / 31.25 / 41.7 / 62.5 / 125 / 250 / 500 kHz
- **Spreading Factor**: SF5-SF12
- **Coding Rate**: 4/5, 4/6, 4/7, 4/8
- **TX Power** (dBm): -9 up to the radio's maximum (22 dBm if it doesn't report one)
- **ID hash size**: 1, 2 or 3 bytes per node ID hash in the paths of flood packets this radio sends. Only shown when the firmware supports it

**Off-Grid Repeat Mode** (only shown when the firmware reports it): lets this radio repeat packets, for places without repeater coverage. It only works on the off-grid frequencies the radio reports (433.000, 869.495 or 918.000 MHz by default), so turning it on moves the frequency to the nearest one and likely disconnects you from the wider mesh. Nodes that talk to each other need the same frequency, bandwidth and SF; only CR can differ. Turning it off reverts to the previous frequency; if you can't reach the mesh afterwards, check the preset and parameters. Save is blocked with a warning on any other frequency.

**Save** sends the settings and checks that the radio reports them back; if not, a snackbar says so and the edits stay.

### Regions

Open region management to add/fetch names and select a default flood scope. Channel chat can override it; clearing an override inherits the default. See [Regions](regions.md), including message labels and temporary reply-region choices.

### Radio stats
Opens the radio statistics screen for the paired radio: noise floor, last RSSI, last SNR, and total TX/RX airtime. Only enabled when connected to a device that supports companion radio stats (firmware code 8+). See the [radio-statistics guide](radio-statistics.md).

---

## Location

### Location
The location is shown on the map, used when you share your location, and sent in adverts when Advert Location is on (Privacy).

- **Latitude** / **Longitude** (decimal, 6 places). One empty field keeps the radio's value for that axis; both empty clears the location. Validation: ±90 / ±180
- **Pick on map**: full-screen map with a centre pin; **Use this location** fills both fields
- With GPS hardware (`gps` custom variable): **Enable GPS** keeps the location updated from the radio's GPS; **Update interval** (60-86399 s, default 900)

**Save** validates all fields, then sends the GPS switch (if changed), the interval and the coordinates.

### Contact Settings
- **Auto-add contacts**: users, repeaters, room servers and sensors. Newly heard nodes of the enabled types are added to the radio's contacts; others can be added later from Discovered Contacts
- **Contact List Limits**:
  - **Overwrite oldest** (radio): when the radio's contact list is full, the oldest non-favorited contact is replaced
  - **Hop limit** (radio): dropdown with No limit (default), 1 (direct only) and 2-64. The radio only auto-adds contacts heard in fewer hops than this; contacts beyond it still appear in Discovered Contacts. Only shown when the firmware reports the setting
  - **Limit discovered contacts** (app, not the radio; saved with the rest): keeps up to 500 discovered contacts, removing the ones heard longest ago. When off, there's no limit

### Privacy
- **Advert Location**: include the node's location in adverts. When on, **Auto Zero-Hop Advert On GPS Update** (app setting) expands below it
- **Multi-ACKs**: the radio sends 2 acknowledgments (ACKs) instead of 1 when the ACK goes back over a direct path. Messages received by flood, or with no known route back, still get one. More reliable, more airtime
- **Telemetry**: an info box explains that per-contact permissions are in each chat's Contact Settings; then the Base, Location and Environment modes (Deny All / Allow by Contact / Allow All)

---

## Local API

Not on web. Open **Settings → Local API** to let other apps on the same device send and receive through this app's radio connection. It is off by default. Each app asks once in a dialog showing its name and key fingerprint; allowed apps are listed here and can be removed, which also disconnects them. **Clear stored radio data** deletes channel data kept for apps that were not running. See [Local API](LOCAL_API.md).

---

## App Settings

A dedicated sub-screen for app-level preferences (nothing here is sent to the device). All settings persist locally via SharedPreferences.

### Appearance
- **Theme**: System / Light / Dark, the brightness of the standard MeshCore theme. While a custom, preset, or holiday theme is active, no option is selected; tapping one returns to the standard theme
- **Color theme**: Opens the Themes screen: the standard MeshCore theme, built-in presets, holiday themes, and your own themes (create, edit, share codes, `.jsonl` import/export). See [Themes](themes.md)
- **Automatic holiday themes** (on by default, toggled on the Themes screen as **Switch automatically**): Shows the Halloween, Thanksgiving, Christmas, or New Year's theme from 17 days before each holiday through the day itself, then restores your own theme. Picking any theme or Light/Dark keeps your choice for the rest of that holiday; turn the toggle off to stop it entirely. See [Automatic holiday themes](themes.md#automatic-holiday-themes)
- **Holiday message animations** (on by default): Plays a short animation when a holiday greeting arrives in or is sent from an open chat. See [Holiday message animations](themes.md#holiday-message-animations)
- **Language**: System default or one of 19 languages (English, French, Spanish, German, Polish, Slovenian, Portuguese, Italian, Chinese, Swedish, Dutch, Slovak, Czech, Bulgarian, Russian, Ukrainian, Hungarian, Japanese, Korean)

### Notifications
- **Master enable/disable**: Requests OS permission when enabling
- **Message notifications**: New direct message alerts
- **Channel message notifications**: New channel message alerts
- **Advertisement notifications**: New node discovery alerts

Individual channels can be muted from the channel chat bell icon, the channel list, or the channel notification. Replying from notifications, watches, and Android Auto is described in [Notifications](notifications.md).

### Messaging
- **Jump to Oldest Unread**: When opening a chat, scrolls to the oldest unread message instead of the newest
- **Enable Message Tracing**: Shows path trace overlays and extra metadata on messages
- **Region next to hop count** (default off): Shows a channel message's region chip on the same line as its hop count instead of below it
- **Compression indicator** (default off): Shows an icon on direct and channel messages that were compressed with SMAZ

### Routing
What happens when a message is sent. Each slider shows its selected number in the title. Turning a switch on reveals its extra controls with the same animation.

- **Clear Path on Max Retry**: Erases the stored routing path after every send attempt fails
- **Direct attempts** (0–15, default 4): How many times to try a known route. Available whether or not auto route rotation is on
- **Flood attempts** (0–10, default 1): How many times to flood. Floods use more airtime. With rotation on, these run after the direct attempts. With it off, they apply only when the contact's path is already Flood
- **Auto Route Rotation**: Lets the app choose each direct attempt's route from the routes that have worked for that contact (see [Auto route selection](routing-paths.md#auto-route-selection)). Off keeps the contact's current path for every attempt
- **Resend channel messages until they travel far enough** (default off): If your channel message isn't heard coming back through enough repeaters, it's sent again. Uses more airtime. When on, it shows:
  - Required hops (1–8, default 2)
  - Resend up to (1–5 times, default 1)
  - **Also count different nearby repeaters** (default off): Treats the message as sent once that many *different* first-hop repeaters have repeated it, even if you can't hear it travel further. Useful where only nearby repeaters are audible. See [Channels](channels.md#channel-auto-resend)
- **Reset routing settings to defaults**: Restores every control in this section (the toggles, the attempt limits, and the stored route-weight constants) to the factory defaults

If both direct and flood attempts are 0, the message is still sent once on the current path. A saved `max_message_retries` value from an older version becomes that many attempts minus one direct, plus one flood, which keeps the old "last attempt floods" behaviour for the previous default of 5 (4 direct + 1 flood).

### Repeaters and Rooms
- **Sync repeater clock on login** (off by default): After a successful repeater login, send `clock sync`. Off is the previous default: a repeater only synced when its own switch was on. Each repeater can override this with Default, On, or Off. Default follows this switch. A saved per-repeater on or off stays an override
- **Focus the password field** (off by default): On keeps the previous login dialog: the cursor goes into an empty password field (room login still skips this on a phone). Off waits until you tap the field, so the keyboard does not cover the dialog
- **Login attempts** (1–10, default 5): How many times to try logging in to a repeater or room server. Telemetry fetches are sent once and have no retry setting
- **Auto-fetch Repeater Settings** (off by default): Requests every setting when a repeater's settings screen opens. Each setting is a separate request over LoRa, so this is slow and uses airtime; when off, use Refresh All or the per-setting refresh buttons. See [Repeater Settings](repeater-management.md#repeater-settings)
- **Reset repeater and room settings to defaults**: Restores the controls in this section. Choices saved on individual repeaters are left alone

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
Not shown on web. Controls on-device message translation powered by a locally-downloaded ML model. Turn on **Enable translation** first; the translation options and model rows then appear:
- **Auto-translate incoming messages**: Automatically translates incoming messages for chat/channel display and notifications
- **Translate before sending**: Sets the default state of the composer's translate icon (on means messages are translated before sending)
- **Target language**: Language to translate into (searchable list; defaults to the app language)
- **Models**: The same model rows used for the image codec. Each preset is one row with its name, size once known, and status (not downloaded, downloading with progress, ready, or couldn't download). The model in use is marked Active; tap another ready row to switch. Download, cancel, and remove are the row's action. A manual model URL under the list downloads a custom GGUF file into the same list.

### IPFS Provider Configuration

Open **App Settings → IPFS provider configuration** to configure IPFS uploads and previews:

- **Public IPFS gateway**: Select Filebase (the default), Pinata, a custom gateway, or deactivate it. This gateway lets the app load bare IPFS content IDs in image links.
- **Upload provider**: Select Pinata, Filebase, a custom provider, or deactivate uploads. Presets fill in the provider’s upload endpoint and upload gateway; custom setups can edit both.
- **API key**: Enter the credential required by the selected provider. The value is masked in the settings dialog. Pinata and Filebase presets require provider credentials.

For a self-hosted Kubo node, choose **Custom (Kubo)** and configure its RPC upload endpoint and HTTP gateway. The preset defaults use `http://127.0.0.1:5001/api/v0/add` and `http://127.0.0.1:8080/ipfs/`; replace these with addresses reachable from the device running MeshCore Open. Do not expose Kubo’s unauthenticated RPC API to the public internet.

When an **upload gateway** is configured, uploaded content is added to the draft as an HTTP(S) gateway URL in the form `http://gateway/ipfs/CID`. If it is blank, the app uses `ipfs://CID`. The public gateway setting is separate and is used to retrieve bare IPFS content IDs in incoming links.

Save the settings before sharing. The upload action is shown in the chat composer only when an upload endpoint is configured. Provider accounts, credentials, limits, and terms are managed by the provider, not MeshCore Open. See [sharing images via IPFS](additional-features.md#share-an-image-via-ipfs) for the chat workflow.

### Image Messages

Image message controls live in App Settings → Messaging. Turn on **Enable image messages** first; **Process images automatically** and the image model row then appear. That row is the same model list used for translation: name, size, status (not downloaded, downloading with progress, ready, or couldn't download), and one action (download, cancel, or remove). A finished install is marked Active. Automatic processing reconstructs every image as it arrives and uses about 2 GB of memory for a second each time; leave it off to reconstruct with a tap. See [Image Messages](image-messages.md) for firmware, native-runtime, storage, and memory requirements.

### Cyrillic-to-Latin (Cyr2Lat)
Controls character substitution profiles used to render Cyrillic text in Latin characters. A dropdown selects the active profile; Add, Edit, and Delete buttons manage the profile list (the last remaining profile cannot be deleted). Each profile stores a JSON character map. The active profile is the default; each chat can pick its own in its **Compression** strip (see [Compression](additional-features.md#compression-smaz-and-cyr2lat)).

### Debug
- **App Debug Logging**: Enable the in-app debug log

---

### Message filter

On the Settings screen, below App Settings, **Message filter** opens a page to hide spam and repeated channel messages: a master switch, display mode, your own rules, automatic checks, and learning. See [Message Filter](message-filter.md).

## Actions

One-tap device operations. While an action waits for the radio, its row shows a spinner and the app bar a progress bar. Each action ends with a short message.

| Action | Description |
|---|---|
| Sync Time | Sends the phone's time to the radio |
| Refresh Contacts | Re-requests the full contact list |
| Reboot Device | Confirmation dialog → reboots the device; a message confirms the command was sent (shown in warning color) |
| Delete All Paths | Confirmation dialog → clears the app's path history for all contacts, not the paths stored on the radio (shown in error color) |

---

## Backup & Restore and Export Data

The settings card links to **Backup & Restore** and **Export Data** subpages.

### Backup & Restore

Choose individual items to include in a backup or restore. Location settings include the saved coordinates, GPS enable state and interval, contact discovery options, and privacy/adverts settings. When importing, only items found in the selected file can be selected. Backups from the official MeshCore app are supported; those files do not include app preferences, groups, filters, or message history, so those choices are unavailable. A radio connection is required to restore radio settings and contact or channel lists. Restoring contacts or channels replaces the selected list on the radio, then reloads it from the device. If you also restore the radio identity, reconnect afterward to reload its data. Message history and groups are restored in the app.

The private-key option is off by default because it changes the radio's identity. Select it only when you intend to restore that identity; the app asks for confirmation before proceeding. Some radios do not allow identity backup or restore, and the app will let you know if this feature is unavailable.

A password protects the backup file. Leave the password blank to create an unprotected file. Backups may contain your radio's private key, channel keys, messages and saved passwords, so store them carefully. Model settings are backed up, but model files are not; after restoring, the app offers to download selected models that are missing. Download progress appears in that prompt, and closing it cancels an active download. Received image files and cached map tiles are not included.

### Export Data

Two sections:

- **Messages**: **Bookmarks** saves your bookmarked messages as a Markdown file
- **Contact locations**: saves contacts with a known location as a GPX file for map apps: **Repeaters and Rooms**, **Users / Companions**, or **All contacts** (not available on web)

Each opens the share sheet (or a save dialog on desktop). A snackbar reports success, nothing to export, not available, or an error.

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

Opened from **About the App** in Settings. App icon, name, version and description; **Source code** (GitHub), **License** (MIT) and **Open-source licenses** (third-party libraries); **Credits**: **Contributors** (the GitHub contributors page) and the Open-Meteo credit; the legal notice. The version comes from the installed app and the notice uses the current year, so neither needs updating by hand.
