# Map & Location

## Overview

The Map feature is a full-featured node-location visualization and radio-planning tool built on OpenStreetMap tiles. It is one of the three primary views accessible from the QuickSwitchBar.

The colors and markers below describe the standard theme. A custom, preset, or holiday theme recolors the map panels and accent, tints the tiles, and can replace the node and self-location markers; see [Themes](themes.md#map).

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

Node name labels appear automatically at zoom level 14 and above.

### Shared Map Pins (Flag Icons)
Location pins shared in chat messages are displayed as flags:
- **Blue flag**: From a direct message
- **Purple flag**: From a private channel
- **Orange flag**: From a public channel

Tap a pin to see its info. Options to "Hide" (session only) or "Remove" (persistent).

Pins from the same sender in the same chat or channel with the same label (case-insensitive) are treated as one marker: a newer message moves it and keeps the earlier positions as its track. To update a pin you shared before, share again with the same label.

### Predicted / Guessed Locations

Many contacts on the mesh don't have GPS hardware, so the map has no explicit coordinates for them. Instead of leaving these contacts invisible, the app **infers an approximate position** by analyzing the repeater path the contact's messages travel through. These inferred positions are displayed as markers with a `not_listed_location` icon and a muted grey or colored border, visually distinct from confirmed-location markers.

#### Why guessed locations exist

In a mesh network, every message hops through one or more repeaters on its way to the destination. Each repeater in the path is identified by a prefix of its public key whose width is recorded with the path. If any of those repeaters have a known GPS location (because they advertise it), then a contact that routes through those repeaters must be somewhere within radio range of them. By combining the positions of multiple repeaters a contact is known to use, the app can place a rough marker near the anchors. This is a routing heuristic, not measured triangulation or a reliable estimate of physical location.

#### How the algorithm works

1. **Build an anchor index**: The app collects known Repeater and Room contacts that have a valid GPS position and indexes them by the public-key prefixes (1–3 bytes) that paths can use. Only contacts without GPS that were seen within the last 7 days are candidates for a guess.

2. **Walk each path**: For each candidate, the app takes its current path plus recent paths from `PathHistoryService`. Each path is walked hop by hop, starting from your own radio's position, and the last hop that resolves to an anchor is the repeater that heard the contact directly.

3. **Resolve ambiguity**: If several anchors share a hop's prefix (a hash collision), the hop resolves to the candidate nearest the previous hop that is within the maximum link range. Without a self position there is no reference point, so ambiguous prefixes are dropped and only unambiguous matches are kept. The maximum link range is the estimated LoRa range (computed from the current frequency, bandwidth, spreading factor, and TX power using a free-space path loss model), capped at a plausible 150 km.

4. **Vote and filter inconsistencies**: Each observed path contributes one vote for the anchor it ended on. Two anchors more than `2 × max link range` apart cannot both be in range of the same node, so outliers are removed; if no anchors agree, the most-voted anchor wins.

5. **Compute the estimated position**:
   - **Single anchor**: The contact is placed on a small circle (330m radius) around the repeater. The angle on the circle is deterministic — derived from an FNV-1a hash of the contact's public key — so the same contact always appears at the same offset, preventing markers from stacking on top of each other.
   - **Two or more anchors**: The position is the average of the anchor coordinates weighted by their vote counts, with a smaller offset radius (120m for 2 anchors, 80m for 3+) applied for visual separation.

6. **Assign confidence level**:
   - **High confidence** (2+ anchors): The marker border uses the node's type color (brighter border).
   - **Low confidence** (1 anchor): The marker border is rendered in a muted grey.

7. **Cache the result**: The computation runs in a background isolate and is cached using a key derived from the contacts' paths, anchor positions, path-history version, radio parameters, and your own position. The cache is only invalidated when any of these inputs change, avoiding recomputation on every UI rebuild.

#### How to read guessed locations on the map

- **Marker with `not_listed_location` icon**: This is a guessed position, not a confirmed GPS fix.
- **Colored border** (type color): Higher confidence — the contact was seen through 2 or more repeaters with known positions.
- **Grey border**: Lower confidence — based on a single repeater anchor only.
- Coordinates shown in the marker info dialog are prefixed with `~` to indicate they are estimated.
- Guessed locations can be toggled on/off in the map filter dialog (FAB → "Guessed locations" toggle).

## Map Interactions

### Zoom and Pan
Standard pinch-to-zoom (range 2–18). Initial camera position is calculated from the statistical spread of all plotted points.

### Tap on a Node Marker
Opens a card at the bottom of the map showing the node's status, type, last-seen time, path, node ID, and coordinates, with buttons to center on the node or close the card. Action buttons vary by type:
- **Chat nodes**: "Open Chat"
- **Repeaters**: "Manage Repeater"
- **Rooms**: "Join Room" and "Manage Server"
- **Chat nodes and sensors in your contacts**: "Update location" (see below)
- **All nodes**: "Details" opens the full node info sheet

### Update Location
**Update location** asks the node for its telemetry. If the reply includes a GPS position, the marker moves there right away and the last-seen time updates; a snackbar confirms it. You can also refresh a node's position from its Telemetry screen: any telemetry reply with a GPS position updates the map the same way.

The node decides whether to include its position:
- **Companion radios** only include a position if they have a working GPS module and their owner allows location in telemetry, for everyone or only for favourites (**Settings → Privacy → Telemetry Location Mode**). A companion without GPS hardware never sends one, even if its adverts carry a manually set location. The app then says the node replied without a location.
- **Sensors** include their position (if they have GPS) for any client they accept, including guests. A sensor only answers clients it knows, so you may need to log in to it first.
- **Repeaters and rooms** only send their position to logged-in admins, so the button isn't shown for them. Their position normally comes from their adverts.

If the node doesn't answer before the request times out, the app says there was no reply. The node has to be in your contacts (not only discovered) for the button to appear.

A telemetry position stays on the map until the node sends a newer advert, which then replaces it. Refreshing or re-syncing the contact list from the radio keeps it.

### Long-Press on Empty Map Area
Shows a bottom sheet with:
- **Share marker here**: Prompts for a label (default: "Point of interest"), then pick a DM contact or channel to send the location to. Wire format: `m:<lat>,<lon>|<label>|poi`; a `|` in the label is replaced with `/` and line breaks with spaces. The label field shows a live byte counter so the whole pin fits in one message, and a hint that reusing a previous label updates that marker for MeshCore Open recipients. To share your radio's own position, use **Share my location** from the ⊕ menu in chat (see [Chat & Messaging](chat-and-messaging.md#input-bar))
- **Set as my location**: Updates your device's advertised location

### Filter Dialog (FAB)
Toggle visibility of: chat nodes, repeaters, other nodes, guessed locations, discovery contacts, overlapping markers (stacked markers at similar coordinates), and shared map pins (flag markers).
Additional filters:
- **Key prefix filter**: Show only contacts whose public key starts with a given prefix
- **Last-seen time slider**: Exponential scale from near-zero to 6 months, with "all time" at the top end

### Legend Card (Top-Right)
Shows node count and pin count. Tappable to expand a legend of all marker types.

---

## Path Trace Map

### How to Access
- From the main map's menu → **Path Trace** (build your own route, see below)
- From a contact's long-press menu → "Path Trace / Ping"
- From a message's path view → radar icon

### Building a Custom Trace on the Map
1. Open the map menu and choose **Path Trace**. A panel appears at the top of the map.
2. Tap nodes on the map in the order the trace should travel. **Remove Last** and **Clear** edit the list.
3. Choose **Round trip** (the trace comes back along the same hops) or **As entered** (the hops are used exactly as listed, so add the return hops yourself).
4. Tap **Run path trace**. Nothing is sent until you press this button.

Returning from the result keeps your hops, mode and the last result (**View last result** reopens it without sending again). **Close** or the back button hides the panel without discarding the hops; reopening **Path Trace** during the same session resumes where you left off. The hops are dropped when you connect to a different radio.

### What the User Sees
A map with a polyline showing the route from your node through repeater hops to the target:
- **Green circles**: Hops with known GPS coordinates
- **Orange circles** (`~HH`): Inferred positions (no GPS but deducible from contacts)
- **Red endpoint**: Target contact with known GPS
- **Magenta endpoint**: Target with guessed position

A bottom panel shows each hop pair with SNR quality icons and total path distance. When multiple observed paths are available, a **Single / Combined** toggle appears at the top of the map. In Combined view, all paths are overlaid; shared segments are highlighted with a white halo and a path count badge appears on shared nodes.

The bottom panel also provides **packet animation controls**:
- **Animation toggle** (on/off)
- **Step back / Play / Step forward / Replay** buttons
- **Follow packet lock** — keeps the map camera centered on the moving packet dot
- **Speed selector** (0.5×, 1×, 2×, 4×)
- A live **"Hop x of y · from → to"** label that tracks the active segment

### How It Works
Sends a trace request frame over the mesh. The repeater network traces the path hop-by-hop and returns per-hop SNR data. For hops without GPS, positions are inferred by averaging GPS coordinates of contacts sharing that last-hop prefix.

---

## Line-of-Sight (LOS) Analysis

### How to Access
From the main map, tap the terrain/antenna icon.

### What the User Sees
A full-screen map with a draggable bottom sheet containing:
- **Elevation profile chart**: Terrain fill (green), LOS beam line (white), radio horizon line (yellow); obstruction points are marked as clickable dots on the chart
- **Status summary**: Clear (green), Marginal (amber, within 5 m of obstruction), or Blocked (red) with distance and clearance/obstruction amount
- **Options section** (collapsible): Node toggles, endpoint dropdowns, antenna height sliders (0–400 ft), Run LOS button

### Key Interactions
- **Long-press the map** to add custom endpoints (pushpin markers, renameable/deleteable)
- **Tap a marker** to select it as Point A or B; LOS runs automatically when both are set
- **Antenna heights** are adjustable for both endpoints
- **Map line** between endpoints is colored green (clear), amber (marginal), or red (blocked)
- Terrain elevation is fetched from the Open-Meteo API (21, 41, or 81 sample points depending on link distance, cached 24 hours)
- K-factor is adjusted per radio frequency from a baseline of 4/3 at 915 MHz

---

## Offline Map Cache

### How to Access
Settings → App Settings → Map Display → Offline Map Cache

### What the User Sees
- Map with a blue polygon overlay showing previously selected cache bounds
- Bounding box coordinates card
- **Cache Area** controls: "Use Current View" and Clear buttons
- **Zoom Range** range slider (3–18, dual-handle for min and max) with estimated tile count
- **Download progress** bar (when downloading)
- **Download Tiles** and **Clear Cache** buttons

### Key Interactions
1. Pan/zoom the map to the desired area
2. Tap "Use Current View" to capture the viewport as cache bounds
3. Adjust the zoom range slider
4. Tap "Download Tiles" (confirmation dialog shows estimated count)
5. Tiles are downloaded with up to 8 concurrent connections
6. Once cached, tiles are served without internet where supported by the cache backend. Select a Stadia Maps source with a configured API key for bulk offline downloads; OpenStreetMap is for live viewing/already cached tiles. Check the provider’s current terms and quotas.

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
3. **Telemetry replies**: A GPS position in a node's telemetry (from **Update location** or the Telemetry screen) replaces its advert position until the node adverts again. Telemetry positions have about 11 m precision (Cayenne LPP).

## Regions and offline use

A [message region](regions.md) is a forwarding scope, not a coordinate or GPS boundary. The map does not establish that a sender is physically inside that region. Cached tiles can be used offline; uncached tiles and uncached LOS elevation lookups require internet.
