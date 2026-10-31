# Contacts

## Overview

The Contacts screen is the primary hub for managing mesh nodes your radio has a relationship with. A "contact" is any node whose cryptographic advertisement has been received — it can be a chat user, repeater, room server, or sensor.

## How to Access

- QuickSwitchBar tab 0 (leftmost) from Channels or Map screens (Channels is shown first after connecting)
- Back navigation from Chat or Settings screens

## Contact Types

| Type | Avatar Color | Icon | Description |
|---|---|---|---|
| Chat | Blue | Initials / emoji | Another user's mesh radio |
| Repeater | Amber | Cell tower | A mesh repeater/relay node |
| Room | Magenta | Meeting room | A room server for group chat |
| Sensor | Teal | Sensors | A sensor device |

## Contact List

Each contact is displayed as a list tile showing:

- **Avatar**: Color-coded circle with type icon (or first emoji of the contact's name if it starts with one)
- **Name**: Contact name on its own line, wrapping to a second line if it's long
- **Favorite star**: Amber star icon after the name if favorited
- **Location pin**: Grey pin icon after the name if the contact has GPS coordinates
- **Key prefix**: The contact's routing hash (public-key prefix) in a small badge, for matching against hops in paths
- **Path label**: "Direct", "N hops", or "Flood" (with forced variants if a path override is active)
- **Last seen**: Relative time at the end of the second line ("recently", "~ 5 min.", "~ 2 hours", "~ 3 days"). It shows whichever is most recent: the last advertisement or telemetry location update, or for chat contacts the last message
- **Unread badge**: Red pill with count at the right edge (if unread messages exist)
- **Manage button**: Shield icon at the right edge for repeaters and rooms

The **Discovered nearby** row at the top of the list opens the Discovery screen and scrolls with the list.

Pull-to-refresh re-fetches the full contact list from the device. Telemetry locations survive the refresh until the node sends a newer advert.

## Search and Filter

A toolbar at the top provides:

**Search**: Matches contact name (case-insensitive) or public key hex prefix. Debounced at 300ms.

**Sort options**:
- Latest Messages (by most recent message)
- Heard Recently (by last seen / last message)
- A–Z (alphabetical)

**Filter options**:
- All, Favorites, Users, Repeaters, Room Servers, Unread Only

## Contact Groups

Groups are a client-side organizational feature for grouping contacts.

- **Create a group**: Tap the group dropdown → "+" icon → enter name → select members → Save
- **Edit a group**: Group dropdown → pencil icon next to the group
- **Delete a group**: Group dropdown → trash icon next to the group
- **Filter by group**: Select a group from the dropdown to show only its members

Groups are stored per radio identity (scoped by public key).

**Validation rules**: Group names cannot be empty, cannot be "all" (reserved, case-insensitive), and must be unique (case-insensitive). The group creation dialog includes a built-in search field to filter contacts when selecting members. Creating a new group automatically selects it as the active filter.

## Tap Actions

| Contact Type | Action on Tap |
|---|---|
| Chat / Sensor | Opens ChatScreen for direct messaging |
| Repeater | Shows password login dialog → opens RepeaterHubScreen |
| Room | Shows password login dialog → opens ChatScreen for room chat |

## Long-Press / Right-Click Menu

| Action | Availability | Description |
|---|---|---|
| Ping | Repeaters only | Opens PathTraceMapScreen targeting the repeater |
| Path Trace | Rooms (always); Chat/Sensor only if `pathLength > 0` | Opens PathTraceMapScreen. For rooms, label shows "Ping" when no path bytes are known, "Path Trace" when path bytes are available |
| Manage Repeater | Repeaters only | Login dialog → RepeaterHubScreen |
| Room Login | Rooms only | Login dialog → ChatScreen |
| Room Management | Rooms only | Login dialog → RepeaterHubScreen (management mode) |
| Add/Remove Favorite | All types | Toggles the favorite flag |
| Share Contact | All types | Requests advert from device → copies `meshcore://<hex>` URI to clipboard |
| Share Contact Zero-Hop | All types | Broadcasts the contact's advertisement one hop |
| Delete Contact | All types | Confirmation dialog → removes from device and clears messages. If auto-add is on for that type, the radio adds it back the next time it advertises; the dialog warns about this |

## App Bar Menus

The Contacts screen has a single **three-dot overflow menu** (`⋮`) in the app bar:

- Discovered Contacts — opens the DiscoveryScreen
- Add Contact from Clipboard — reads a `meshcore://<hex>` URI from clipboard and imports it
- *(divider)*
- Zero-Hop Advert — broadcasts your advertisement to immediately adjacent nodes
- Flood Advert — broadcasts across the full mesh network
- Copy Advert to Clipboard — copies your `meshcore://<hex>` URI for sharing externally
- *(divider)*
- Disconnect — disconnects from the device
- Settings — opens the Settings screen

A **floating action button** (person-add icon) provides a shortcut sheet to "Add Contact from Clipboard" or "Discovered Contacts".

## Adding Contacts

### Automatic (Passive)
When the radio hears an advertisement, the contact appears automatically if auto-add is enabled for that type (configurable in Settings → Contact Settings).

### Import from Clipboard
Overflow menu (or the FAB shortcut) → "Add Contact from Clipboard". Reads a `meshcore://<hex>` URI from clipboard and imports it to the device.

### Import from Discovered Contacts
Overflow menu → "Discovered Contacts". Shows nodes heard passively that haven't been added yet. Tap to immediately import (no confirmation dialog), or long-press for more options (Copy URI, Delete). The Discovery screen has its own search bar, type filters (Users, Repeaters, Rooms), and sort options (Last Seen, A-Z). Its overflow menu has **Export discovered contacts**, **Import discovered contacts**, and "Delete All".

### Scan for Nearby Nodes

On the Discovered Contacts screen, tap the radar icon (**Scan for nearby nodes**) to ask nodes within direct radio range to identify themselves, instead of waiting for their next advert. The button appears only while connected to firmware with version code 8 or newer.

- Repeaters and sensors answer. Room servers and companions usually don't.
- Results appear live for about 12 seconds, sorted by signal. Each shows the node type, signal strength, how well the node heard you ("they heard us at … dB"), and either **Already in contacts** or an add button.
- A node you haven't heard an advert from yet is added with a placeholder name; its real name appears after its next advert.
- Repeaters limit how often they reply. If nothing answers, wait a minute and tap **Scan again**.

### Export and Import Discovered Contacts

Use the Discovered Contacts overflow menu to move the list of heard-but-not-added nodes between devices or radios.

- **Export discovered contacts** writes `meshcore_discovered_contacts.json`. On desktop a save dialog opens; on mobile the OS share sheet opens. The file holds each node's public key, name, type, flags, GPS position, timestamps, and its last advert packet. It contains no private keys and no routing paths (a path is only valid from the radio that learned it). On web the file is shared or downloaded through the browser.
- **Import discovered contacts** opens a file picker for a `.json` export (up to 2 MB) and requires a connected radio; imports go to that radio's discovered list. Nodes already in your contact list or discovered list, duplicates within the file, and your own node are skipped. Entries that can't be read (for example a public key that isn't 32 bytes) are skipped individually instead of failing the whole file. Imported nodes get no routing path, and future timestamps are clamped to now. When discovered-contact eviction is on, the list is trimmed back to its limit afterwards. A snackbar reports how many were imported, skipped, and unreadable, or that the file isn't a discovered-contacts export.
- Imported nodes go into the discovered list of the radio you're connected to. When eviction of discovered contacts is on, the list is trimmed back to the 500 most recently seen nodes the next time it loads.

### Import from a QR Code

Choose **Scan QR Code** from the Contacts overflow menu or the add-contact sheet. Allow camera access and scan a compatible contact QR code, or use **Scan QR from Gallery** on the scanner screen to import a QR code from a saved image. Contact QR import is separate from community QR scanning; use Channels for community codes.

## Contact Sharing Format

Contacts are shared using the `meshcore://` URI scheme:
```
meshcore://<hex-encoded-advertisement-packet>
```
This contains the node's public key and metadata. Paste it into another MeshCore app to import.
