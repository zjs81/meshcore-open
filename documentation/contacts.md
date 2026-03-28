# Contacts

## Overview

The Contacts screen is the primary hub for managing mesh nodes your radio has a relationship with. A "contact" is any node whose cryptographic advertisement has been received — it can be a chat user, repeater, room server, or sensor.

## How to Access

- Automatically shown after connecting to a device
- QuickSwitchBar tab 0 (leftmost) from Channels or Map screens
- Back navigation from Chat or Settings screens

## Contact Types

| Type | Avatar Color | Icon | Description |
|---|---|---|---|
| Chat | Blue | Chat bubble | Another user's mesh radio |
| Repeater | Orange | Cell tower | A mesh repeater/relay node |
| Room | Purple | Group | A room server for group chat |
| Sensor | Green | Sensors | A sensor device |

## Contact List

Each contact is displayed as a list tile showing:

- **Avatar**: Color-coded circle with type icon (or first emoji of the contact's name if it starts with one)
- **Name**: Contact name (single line)
- **Path label**: "Direct", "N hops", or "Flood" (with forced variants if a path override is active)
- **Public key**: Shortened hex format `<XXXXXXXX...XXXXXXXX>`
- **Unread badge**: Red pill with count (if unread messages exist)
- **Last seen**: Relative timestamp ("Now", "5 mins ago", "2 hours ago", "3 days ago"). For chat contacts, this shows whichever is more recent: the last advertisement time or the last message time
- **Favorite star**: Amber star icon if favorited
- **Location pin**: Grey pin icon if the contact has GPS coordinates

Pull-to-refresh re-fetches the full contact list from the device.

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
| Path Trace / Ping | Repeaters, Rooms (always); Chat if `pathLength > 0` | Opens PathTraceMapScreen. Label shows "Ping" when no path bytes are known, "Path Trace" otherwise |
| Manage Repeater | Repeaters only | Login dialog → RepeaterHubScreen |
| Room Login | Rooms only | Login dialog → ChatScreen |
| Room Management | Rooms only | Login dialog → RepeaterHubScreen (management mode) |
| Open Chat | Chat/Sensor | Same as single tap |
| Add/Remove Favorite | All types | Toggles the favorite flag |
| Share Contact | All types | Copies `meshcore://<hex>` URI to clipboard |
| Share Contact Zero-Hop | All types | Broadcasts the contact's advertisement one hop |
| Delete Contact | All types | Confirmation dialog → removes from device and clears messages |

## App Bar Menus

The Contacts screen has **two separate popup menus** in the app bar:

**Antenna icon menu** (contact sharing):
- Zero-Hop Advert — broadcasts your advertisement to immediately adjacent nodes
- Flood Advert — broadcasts across the full mesh network
- Copy Advert to Clipboard — copies your `meshcore://<hex>` URI for sharing externally
- Add Contact from Clipboard — reads a `meshcore://<hex>` URI from clipboard and imports it

**Three-dot overflow menu**:
- Disconnect — disconnects from the device
- Discovered Contacts — opens the DiscoveryScreen
- Settings — opens the Settings screen

## Adding Contacts

### Automatic (Passive)
When the radio hears an advertisement, the contact appears automatically if auto-add is enabled for that type (configurable in Settings → Contact Settings).

### Import from Clipboard
Antenna menu → "Add Contact from Clipboard". Reads a `meshcore://<hex>` URI from clipboard and imports it to the device.

### Import from Discovered Contacts
Overflow menu → "Discovered Contacts". Shows nodes heard passively that haven't been added yet. Tap to immediately import (no confirmation dialog), or long-press for more options (Add, Copy URI, Delete). The Discovery screen has its own search bar, type filters (Users, Repeaters, Rooms, Favorites), and sort options (Last Seen, A-Z). An overflow "Delete All" option clears all discovered contacts.

## Contact Sharing Format

Contacts are shared using the `meshcore://` URI scheme:
```
meshcore://<hex-encoded-advertisement-packet>
```
This contains the node's public key and metadata. Paste it into another MeshCore app to import.
