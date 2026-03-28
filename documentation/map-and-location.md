# Map & Location

## Overview

The Map feature is a full-featured node-location visualization and radio-planning tool built on OpenStreetMap tiles. It is one of the three primary views accessible from the QuickSwitchBar.

## How to Access

- **QuickSwitchBar tab 2** (rightmost) from Contacts or Channels
- **Deep-link from a chat message**: Tapping a shared location pin in a chat opens the map centered on that pin
- **Settings → Offline Map Cache**: Opens the tile cache management screen

## What the Map Displays

### Self Location (Teal Circle)
Your own node's position, obtained from the device firmware. Displayed as a teal `person_pin_circle` icon. Only appears if the device has GPS data or a manually-set location.

### Contact / Node Markers (Color-Coded)
All contacts with known GPS coordinates are plotted:

| Type | Color | Icon |
|---|---|---|
| Chat user | Blue | Person |
| Repeater | Green | Router |
| Room | Purple | Meeting room |
| Sensor | Orange | Sensors |

Node name labels appear automatically at zoom level 12 and above.

### Shared Map Pins (Flag Icons)
Location pins shared in chat messages are displayed as flags:
- **Blue flag**: From a direct message
- **Purple flag**: From a private channel
- **Orange flag**: From a public channel

Tap a pin to see its info. Options to "Hide" (session only) or "Remove" (persistent).

### Predicted / Guessed Locations (Semi-Transparent)

Many contacts on the mesh don't have GPS hardware, so the map has no explicit coordinates for them. Instead of leaving these contacts invisible, the app **infers an approximate position** by analyzing the repeater path the contact's messages travel through. These inferred positions are displayed as semi-transparent markers with a `not_listed_location` icon, visually distinct from confirmed-location markers.

#### Why guessed locations exist

In a mesh network, every message hops through one or more repeaters on its way to the destination. Each repeater in the path is identified by the first byte of its public key. If any of those repeaters have a known GPS location (because they advertise it), then a contact that routes through those repeaters must be somewhere within radio range of them. By combining the positions of multiple repeaters a contact is known to use, the app can triangulate a rough area where the contact is likely located.

#### How the algorithm works

1. **Build a repeater index**: The app collects all known contacts of type Repeater that have a valid GPS position and indexes them by the first byte of their public key.

2. **Collect anchor points**: For each contact that lacks GPS, the app looks at the **last-hop byte** of the contact's current path and also searches the `PathHistoryService` for recent paths. Each last-hop byte that matches a located repeater becomes an "anchor point" — a GPS coordinate the contact is likely near.

3. **Resolve ambiguity**: If multiple repeaters share the same first public-key byte (a hash collision), that byte is discarded as ambiguous. Only unambiguous one-to-one matches are kept.

4. **Filter geometric inconsistencies**: Two anchor points separated by more than `2 × maxRangeKm` (the estimated LoRa radio range, computed from the current frequency, bandwidth, spreading factor, and TX power using a free-space path loss model) cannot both be in range of the same node. Outlier anchors are removed to keep only a geometrically consistent set.

5. **Compute the estimated position**:
   - **Single anchor**: The contact is placed on a small circle (330m radius) around the repeater. The angle on the circle is deterministic — derived from an FNV-1a hash of the contact's public key — so the same contact always appears at the same offset, preventing markers from stacking on top of each other.
   - **Two or more anchors**: The position is the average (centroid) of all anchor coordinates, with a smaller offset radius (80–120m) applied for visual separation.

6. **Assign confidence level**:
   - **High confidence** (2+ anchors): Displayed at 55% opacity.
   - **Low confidence** (1 anchor): Displayed at 30% opacity.

7. **Cache the result**: The computation is cached using a key derived from the contact's paths, anchor positions, path-history version, and radio parameters. The cache is only invalidated when any of these inputs change, avoiding recomputation on every UI rebuild.

#### How to read guessed locations on the map

- **Semi-transparent marker** with a `not_listed_location` icon: This is a guessed position, not a confirmed GPS fix.
- **More opaque** (55%): Higher confidence — the contact was seen through 2 or more repeaters with known positions.
- **More transparent** (30%): Lower confidence — based on a single repeater anchor only.
- Coordinates shown in the marker info dialog are prefixed with `~` to indicate they are estimated.
- Guessed locations can be toggled on/off in the map filter dialog (FAB → "Guessed locations" toggle).

## Map Interactions

### Zoom and Pan
Standard pinch-to-zoom (range 2–18). Initial camera position is calculated from the statistical spread of all plotted points.

### Tap on a Node Marker
Opens a dialog showing: type, path (hop chain), coordinates, last-seen time, and public key. Action buttons vary by type:
- **Chat nodes**: "Open Chat"
- **Repeaters**: "Manage Repeater"
- **Rooms**: "Join Room"

### Long-Press on Empty Map Area
Shows a bottom sheet with:
- **Share marker here**: Prompts for a label, then pick a DM contact or channel to send the location to. Wire format: `m:<lat>,<lon>|<label>|poi`
- **Set as my location**: Updates your device's advertised location

### Filter Dialog (FAB)
Toggle visibility of: chat nodes, repeaters, other nodes, guessed locations, discovery contacts.
Additional filters:
- **Key prefix filter**: Show only contacts whose public key starts with a given prefix
- **Last-seen time slider**: From 1 hour to "all time"

### Legend Card (Top-Right)
Shows node count and pin count. Tappable to expand a legend of all marker types.

---

## Path Trace Map

### How to Access
- From the main map's radar icon
- From a contact's long-press menu → "Path Trace / Ping"
- From a message's path view → radar icon

### What the User Sees
A map with a polyline showing the route from your node through repeater hops to the target:
- **Green circles**: Hops with known GPS coordinates
- **Orange circles** (`~HH`): Inferred positions (no GPS but deducible from contacts)
- **Red endpoint**: Target contact with known GPS
- **Purple semi-transparent endpoint**: Target with guessed position

A legend card at the bottom lists each hop pair with SNR quality icons and total path distance.

### How It Works
Sends a trace request frame over the mesh. The repeater network traces the path hop-by-hop and returns per-hop SNR data. For hops without GPS, positions are inferred by averaging GPS coordinates of contacts sharing that last-hop byte.

---

## Line-of-Sight (LOS) Analysis

### How to Access
From the main map, tap the terrain/antenna icon.

### What the User Sees
A full-screen map with a collapsible control panel containing:
- **Elevation profile chart**: Terrain fill (green), LOS beam line (white), radio horizon line (yellow)
- **Status**: Clear (green) or blocked (red) with distance and minimum clearance
- **Options panel**: Node toggles, endpoint dropdowns, antenna height sliders (0–400 ft), Run LOS button

### Key Interactions
- **Long-press the map** to add custom endpoints (orange pushpin markers, renameable/deleteable)
- **Tap a marker** to select it as Point A or B; LOS runs automatically when both are set
- **Antenna heights** are adjustable for both endpoints
- **Map line** between endpoints is colored green (clear) or red (blocked)
- Terrain elevation is fetched from the Open-Meteo API (21–81 sample points, cached 24 hours)
- K-factor is adjusted per radio frequency from a baseline of 4/3 at 915 MHz

---

## Offline Map Cache

### How to Access
Settings → App Settings → Map Display → Offline Map Cache

### What the User Sees
- Map with a blue polygon overlay showing previously selected cache bounds
- Bounding box coordinates card
- **Cache Area** controls: "Use Current View" and Clear buttons
- **Zoom Range** slider (3–18) with estimated tile count
- **Download progress** bar (when downloading)
- **Download Tiles** and **Clear Cache** buttons

### Key Interactions
1. Pan/zoom the map to the desired area
2. Tap "Use Current View" to capture the viewport as cache bounds
3. Adjust the zoom range slider
4. Tap "Download Tiles" (confirmation dialog shows estimated count)
5. Tiles are downloaded with up to 8 concurrent connections
6. Once cached, tiles are served from disk without internet (365-day stale period)

---

## GPX Export

### How to Access
Settings → Export section

### What It Does
Exports contacts with GPS coordinates to a `.gpx` file via the OS share sheet. Three export options:
- **Export Repeaters**: Repeater and Room contacts with locations
- **Export Contacts**: Chat contacts with locations
- **Export All**: All contacts with locations

Each waypoint includes: name, lat/lon, type label, and public key hex.

---

## Location Data Sources

The phone's own GPS is **never used**. All location data comes from the mesh:

1. **Device self-location**: Read from firmware device-info response. Set manually in Settings → Location, or updated automatically if the device has a GPS module.
2. **Remote node locations**: Extracted from advertisement packets received over the mesh. Encoded as integer lat/lon × 1,000,000.
