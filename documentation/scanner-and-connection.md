# Scanner & Connection

## BLE Scanner (Home Screen)

The BLE Scanner is the app's home screen, displayed immediately on launch.

### How to Access

- Opens automatically when the app starts
- Returns here when disconnecting from any device
- Accessible by navigating back from a connected session

### What the User Sees

**App Bar**: Centered title "Scanner".

**Bluetooth-Off Warning Banner** (conditional): Appears when the Bluetooth adapter is off, showing a `bluetooth_disabled` icon, a warning message, and on Android, an "Enable Bluetooth" button.

**Status Bar**: A full-width colored strip reflecting the current connection state:

| State | Text | Color |
|---|---|---|
| Disconnected | "Not connected" | Grey |
| Scanning | "Scanning..." | Blue |
| Connecting | "Connecting..." | Orange |
| Connected | "Connected to \<device name\>" | Green |
| Disconnecting | "Disconnecting..." | Orange |

**Device List**: When no devices are found, shows a large Bluetooth icon with a prompt. The prompt text is dynamic: "Searching for devices..." while actively scanning, or "Tap Scan to search" when idle. When devices are found, shows a scrollable list of `DeviceTile` widgets.

**App Bar Actions**: Icon buttons in the top-right corner of the app bar:
- **USB** icon button - Opens USB connection screen (Android, Windows, Linux, macOS, Chrome web only)
- **TCP/IP** icon button - Opens TCP connection screen (all non-web platforms)

**Bottom FAB**: A single floating action button:
- **BLE Scan** button - Toggles BLE scanning on/off; shows a spinner when scanning. **Disabled** (greyed out, not tappable) when Bluetooth is off

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
- **Connect button** (the entire tile row is also tappable — both trigger connection)

Note: The weak (-80 to -90 dBm) and poor (< -90 dBm) tiers share the same icon shape and are only differentiated by color (orange vs. red).

### How Scanning Works

- Filters for devices advertising the Nordic UART Service UUID (so community forks with non-standard names are still found). Known name prefixes used by stock firmware builds for reference: `MeshCore-`, `Whisper-`, `WisCore-`, `Seeed`, `Lilygo`, `HT-`, `LowMesh_MC_`, `NRF52`
- Uses low-latency scan mode on Android
- Scans for 10 seconds then auto-stops
- On iOS/macOS, waits for BLE adapter initialization before starting
- If Bluetooth is turned off during a scan, scanning stops immediately

### Connecting to a Device

Tap a device tile or its Connect button:
1. The connector stops scanning and transitions to "connecting"
2. Connects to the device with a 15-second timeout (6 seconds on Linux)
3. Requests MTU 185 bytes for optimal throughput
4. Discovers BLE services and locates the Nordic UART Service
5. Subscribes to TX notifications for receiving data
6. On success, automatically navigates to the Channels screen
7. On failure, shows a red error snackbar

---

## USB Connection

### How to Access

From the Scanner screen, tap the **USB** icon button in the app bar.

### What the User Sees

- A colored status bar at the top (same color scheme as BLE scanner)
- A list of detected USB serial ports, each showing:
  - Friendly display name
  - Raw port name (subtitle, only shown when it differs from the display name)
  - Chevron trailing icon (the entire tile is tappable to connect)
- Transport switcher buttons (outlined, not FABs) to switch to BLE or TCP (these use `pushReplacement`, so back navigation returns to Scanner, not between USB/TCP)

### Key Interactions

- On desktop (Windows, Linux, macOS): ports are polled every 2 seconds for hot-plug detection (polling pauses while connecting/connected)
- On mobile: tap the "Scan" FAB to manually refresh
- Tap a port tile to connect
- On successful connection, navigates to Channels screen
- On connection failure, the port list automatically refreshes
- Platform-specific error messages for common USB failures (permission denied, device missing, device detached, device busy, driver missing, port invalid, timeout, and more)

---

## TCP Connection

### How to Access

From the Scanner screen, tap the **TCP/IP** icon button in the app bar.

### What the User Sees

- A colored status bar at the top
- **Host address** text field
- **Port number** text field
- **Connect** button
- Transport switcher buttons (outlined, not FABs) to switch to USB or BLE

### Key Interactions

- Last-used host and port are pre-populated from saved settings
- Tap Connect to validate inputs and connect
  - Host must not be empty
  - Port must be a number between 1 and 65535
  - Validation errors are shown as red snackbars
- The Connect button shows a spinner and "Connecting..." label while in progress
- The status bar shows the specific host:port being connected to (e.g., "Connecting to 192.168.1.1:5000")
- On success, navigates to Channels screen and saves the host/port to settings
- On connection, the status bar shows the active TCP endpoint (e.g., "Connected to 192.168.1.1:5000")
- Error messages for timeout, unsupported platform, and connection failures

### Automatic Reconnect

- If an established TCP link drops without you disconnecting (for example Wi-Fi power saving while the app is in the background), the app reconnects to the same host and port automatically, using the same exponential backoff as BLE. The background service keeps running while it retries.
- Only a link that completed its handshake is reconnected; a first connection to a wrong address is not retried. A manual disconnect, or connecting over BLE or USB, cancels it.
- The socket uses TCP keepalive (probes after 30 seconds of silence, every 10 seconds, 3 tries), so a dead link is noticed in about a minute instead of the system default of hours.
- USB is not reconnected automatically: losing a USB link usually means the cable was unplugged.
