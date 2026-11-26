# Scanner & Connection

## Connect a Radio

**Connect a radio** is the app's home screen until a radio has connected once. After that the app opens on Channels with the last radio's saved data ([offline mode](offline-mode.md)).

### How to Access

- Opens automatically when the app starts and no radio is remembered
- From the main screens: **Connect** (app bar or overflow menu) → **Choose a radio**. It opens on the tab of the last radio's connection type (on web, the USB tab)
- Disconnecting no longer returns here; the main screens stay open, read-only

### What the User Sees

**App Bar**: Centered title "Connect a radio" with **Bluetooth**, **USB** and **TCP** tabs below it. Tap a tab or swipe between them. There is no USB tab on iOS, and no TCP tab on web (Chrome). The tabs stay put while a connection is being made, because leaving a tab cancels its connection.

**Status Chip**: Under the tabs, the same on every tab:

| State | Text | Color |
|---|---|---|
| Disconnected | "Not connected" | Grey |
| Scanning (Bluetooth) | "Scanning for devices..." | Blue |
| Connecting | "Connecting..." | Orange |
| Connected | "Connected to \<device name, USB port or TCP endpoint\>" | Green |
| Disconnecting | "Disconnecting..." | Orange |

**Need a new node? card** (bottom of the page): Shown only when the remote `_banner.meshcoreopen.org` record turns it on, and not on a screen too short for it (under 480 dp, such as a landscape phone). Tapping it opens the shop link. **Close** hides it on every tab until you leave the page; it shows again the next time you open it.

## Bluetooth Tab

**Bluetooth-Off Warning Banner** (conditional): Appears when the Bluetooth adapter is off, showing a `bluetooth_disabled` icon, a warning message, and on Android, an "Enable Bluetooth" button.

**Device List**: When no devices are found, shows a large Bluetooth icon with a prompt: "Searching for MeshCore devices..." while scanning, or "Tap Scan to find MeshCore devices" when idle. When devices are found, shows a scrollable list of `DeviceTile` rows.

**Scan Button** (bottom right): Toggles BLE scanning on/off; shows a spinner when scanning. **Disabled** (greyed out, not tappable) when Bluetooth is off. Leaving the tab stops a scan, so the other tabs can connect straight away. On web, Scan explains that Bluetooth isn't available in the browser.

### Device Tile

Each discovered device is displayed as a list tile showing:
- **Signal strength icon** (color-coded by RSSI):
  - Green: >= -60 dBm (excellent)
  - Light green: -60 to -70 dBm (good)
  - Amber: -70 to -80 dBm (fair)
  - Orange: -80 to -90 dBm (weak)
  - Red: < -90 dBm (poor)
- **RSSI value** in dBm (e.g., "-72 dBm")
- **Device name** (falls back to "Unknown Device")
- **Device ID** (BLE MAC address on Android; a system-assigned UUID on iOS/macOS)
- The whole row is tappable to connect; a progress ring replaces the signal while connecting

Note: The weak (-80 to -90 dBm) and poor (< -90 dBm) tiers share the same icon shape and are only differentiated by color (orange vs. red).

### How Scanning Works

- Filters for devices advertising the Nordic UART Service UUID (so community forks with non-standard names are still found). Known name prefixes used by stock firmware builds for reference: `MeshCore-`, `Whisper-`, `WisCore-`, `Seeed`, `Lilygo`, `HT-`, `LowMesh_MC_`, `NRF52`
- Uses low-latency scan mode on Android
- Scans for 10 seconds then auto-stops
- On iOS/macOS, waits for BLE adapter initialization before starting
- If Bluetooth is turned off during a scan, scanning stops immediately

### Connecting to a Device

Tap a device row:
1. The connector stops scanning and transitions to "connecting"
2. Connects to the device with a 15-second timeout (6 seconds on Linux)
3. Requests MTU 185 bytes for optimal throughput
4. Discovers BLE services and locates the Nordic UART Service
5. Subscribes to TX notifications for receiving data
6. On success, automatically navigates to the Channels screen
7. On failure, shows a red error snackbar

---

## USB Tab

### What the User Sees

- A list of detected USB serial ports, in the same rows as Bluetooth devices:
  - Friendly display name
  - Raw port name (only shown when it differs from the display name)
  - A progress ring on the port being connected
- On web: a **Choose serial port** button opens the browser's port picker; ports you already allowed are listed below it

### Key Interactions

- On desktop (Windows, Linux, macOS): ports are polled every 2 seconds for hot-plug detection (polling pauses while connecting/connected); with nothing plugged in, the list says a radio shows up by itself
- On Android: tap **Refresh** to look for ports again
- Tap a port row to connect
- On successful connection, navigates to Channels screen
- On connection failure, the port list automatically refreshes
- Platform-specific error messages for common USB failures (permission denied, device missing, device detached, device busy, driver missing, port invalid, timeout, and more)

---

## TCP Tab

### What the User Sees

- **Endpoint** text field
- **Port** text field
- **Connect** button

### Key Interactions

- Last-used endpoint and port are pre-populated from saved settings
- On short screens, the tabs and the status chip hide while the keyboard is open
- Tap Connect to validate inputs and connect
  - Endpoint must not be empty
  - Port must be a number between 1 and 65535
  - Validation errors are shown under the fields
- The Connect button shows a spinner and "Connecting..." label while in progress
- On success, navigates to Channels screen and saves the endpoint and port to settings
- On connection, the status chip shows the active TCP endpoint (e.g., "Connected to 192.168.1.1:5000")
- Error messages for timeout, unsupported platform, and connection failures

### Automatic Reconnect

- If an established TCP link drops without you disconnecting (for example Wi-Fi power saving while the app is in the background), the app reconnects to the same host and port automatically, using the same exponential backoff as BLE. The background service keeps running while it retries.
- Only a link that completed its handshake is reconnected; a first connection to a wrong address is not retried. A manual disconnect, or connecting over BLE or USB, cancels it.
- The socket uses TCP keepalive (probes after 30 seconds of silence, every 10 seconds, 3 tries), so a dead link is noticed in about a minute instead of the system default of hours.
- USB is not reconnected automatically: losing a USB link usually means the cable was unplugged.
