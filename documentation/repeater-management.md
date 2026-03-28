# Repeater Management

## Overview

Repeater Management provides tools for administering MeshCore repeater and room server nodes. It includes device status monitoring, CLI access, telemetry reading, neighbor discovery, and remote configuration.

## How to Access

From the Contacts screen:
1. Long-press a **Repeater** or **Room** contact
2. Select "Manage Repeater" or "Room Management"
3. Enter the admin password in the login dialog
4. Navigate to the Repeater Hub Screen

### Login Dialog

- Password field with show/hide toggle
- "Save password" checkbox (persists for future logins). If a saved password exists, it is pre-filled and the checkbox is pre-checked, making login one-tap
- Routing mode selector and "Manage Paths" link are available directly in the dialog (configure routing before login)
- Auto-retries up to 5 times on timeout, showing progress ("Attempt 2 of 5"). A wrong password stops immediately after the first attempt — only timeouts trigger retries
- After 5 failed attempts, further login attempts are blocked

---

## Repeater Hub Screen

The central management screen showing:

- **Header card**: Repeater name, short public key, path label, GPS coordinates (if known)
- **Battery chemistry selector**: NMC / LiFePO4 / LiPo (saved per repeater)
- **Management tool cards** (full-width cards with chevron arrows, not a grid). Title dynamically shows "Repeater Management" or "Room Management" based on contact type:

| Card | Destination |
|---|---|
| Status | Repeater Status Screen |
| Telemetry | Telemetry Screen |
| CLI | Repeater CLI Screen |
| Neighbors | Neighbors Screen |
| Settings | Repeater Settings Screen |

---

## Repeater Status

### What the User Sees

Three information cards:

**System Information**:
- Battery percentage
- Uptime
- Queue length
- Error flags
- Clock at login time

**Radio Statistics**:
- Last RSSI and SNR
- Noise floor
- TX and RX airtime

**Packet Statistics**:
- Packets sent, received, and duplicates
- Broken down by flood vs. direct

### Key Interactions
- Auto-queries the repeater on open; shows a loading spinner until data arrives
- On timeout: red snackbar error. On success: data appears with a green snackbar confirmation
- Pull-to-refresh or refresh button to re-query
- Routing mode popup and path management dialog in app bar (these controls appear on **all** management sub-screens, not just Status)

---

## Repeater CLI

A terminal-style interface for sending commands directly to the repeater.

### What the User Sees

- **Quick-command bar** (horizontal scroll): Shortcut buttons for common commands (get name, get radio, get tx, neighbors, ver, advert, clock)
- **Command history list**: Sent commands in primary color, responses in secondary color
- **Input bar**: Up/down history arrows, monospace text field with `> ` prefix, send button

### Key Interactions

- Type a command and press send (or Enter on desktop)
- Up/down arrows navigate through command history
- Quick-command buttons populate and send common commands
- Bug report icon: Shows raw frame debug info for the next typed command (shows error snackbar if input field is empty)
- Help icon: Opens a scrollable reference of all known CLI commands. Tapping any command populates the input field immediately
- Clear icon: Wipes the command/response history
- Failed/timed-out commands are automatically retried once

### Available CLI Commands

**General**: `advert`, `reboot`, `clock`, `password`, `ver`, `clear stats`

**Settings**: `set name`, `set af`, `set tx`, `set repeat`, `set allow.read.only`, `set flood.max`, `set int.thresh`, `set agc.reset.interval`, `set multi.acks`, `set advert.interval`, `set flood.advert.interval`, `set guest.password`, `set lat`, `set lon`, `set radio`, `set rxdelay`, `set txdelay`, `set direct.txdelay`, `set bridge.*`, `set adc.multiplier`, `tempradio`, `setperm`

**Bridge**: `get bridge.type`

**Logging**: `log start`, `log stop`, `log erase`

**Neighbors**: `neighbors`, `neighbor.remove`

**Region Management**: `region`, `region load/get/put/remove/allowf/denyf/home/save`

**GPS**: `gps`, `gps on/off/sync/setloc/advert`

---

## Telemetry

### What the User Sees

A list of Cayenne LPP sensor channel cards:

- **Channel 1** (special): Battery voltage (shown as percentage or raw mV) and MCU temperature
- **Other channels**: Raw sensor values with appropriate labels

Shows "No data" until a response arrives from the repeater.

### Key Interactions
- Auto-queries on open
- Pull-to-refresh
- Temperature respects metric/imperial setting
- Battery readings are stored for the repeater's battery snapshot

---

## Neighbors

### What the User Sees

A card titled "Repeater's Neighbors - N" listing each neighbor as:
- Repeater name (or hex key prefix if unknown)
- Time since last heard
- SNR quality icon with color coding and label

### Key Interactions
- Auto-queries up to 15 neighbors on open
- Matches public key prefixes against known contacts to show names
- Pull-to-refresh

---

## Repeater Settings

### What the User Sees

Five configuration cards:

**1. Basic Settings**
- Name field
- Admin password field
- Guest password field

**2. Radio Settings**
- Frequency (MHz)
- TX Power (dBm)
- Bandwidth dropdown (kHz)
- Spreading Factor (SF5–SF12)
- Coding Rate (4/5–4/8)

**3. Location Settings**
- Latitude and longitude fields

**4. Features**
- Packet forwarding toggle
- Guest access toggle

**5. Advertisement Settings**
- Local advert interval slider (60–240 minutes) with enable/disable toggle
- Flood advert interval slider (3–168 hours) with enable/disable toggle

**6. Danger Zone** (red-styled card)
- Reboot repeater
- Erase filesystem (serial-only warning)

### Key Interactions
- **Settings are NOT auto-fetched on open**. Only name and location are pre-filled from locally cached contact data. You must tap each section's refresh button to fetch live values from the repeater
- TX Power has its own separate refresh button, independent from the main Radio Settings refresh
- Save button appears when changes are detected
- Settings are sent sequentially with 200ms delays between commands (fire-and-forget, no per-command acknowledgment wait)
- Validation prevents invalid values (e.g., frequency range, LoRa parameter compatibility)
- Advertisement interval sliders reset to defaults when re-enabled (local: 60 min, flood: 3 hours)
- **Erase Filesystem** does NOT send any command over the air — tapping it only shows a snackbar explaining the operation requires physical serial access. It is effectively non-functional when connected wirelessly
