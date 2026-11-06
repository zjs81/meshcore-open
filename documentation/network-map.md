# Network Map

The online network map at [map.meshcoreopen.org](https://map.meshcoreopen.org) shows MeshCore repeaters, room servers, links between them, traffic and measured coverage. It is built from header-only packet records that opted-in MeshCore Open users upload. Viewing the map never requires uploading.

## Viewing the map in the app

Open the map and use the **Local / Online / Both** switch at the top.

| View | Shows |
|---|---|
| Local | Your contacts at the positions their adverts give. This data stays on the device. |
| Online | Repeater and room server hexagons and links from the network map. |
| Both | Online hexagons under your local markers. Repeaters already in your contacts are marked "In your contacts". |

Hexagons are about 2–3 km across and never show a node's exact position. A dashed outline means the repeater has only been reported by one uploader so far ("single source"). When the visible area is larger than 20° the map asks you to zoom in.

Tap a hexagon to see the repeater's name, type, status and last-seen time, plus a reachability hint:

- **Heard by your radio**: your radio knows this node.
- **In your area**: it is within about 50 km of your radio's position.
- **Far away**: management requests won't reach it over the mesh.

**Add to contacts** saves the repeater with flood routing and no location. Its real location arrives with its next advert. **Manage** adds it if needed and opens the normal repeater or room server login.

## Contributing data (opt-in)

Turn on **Settings → App settings → Network map** to upload while a radio is connected. Uploading is off by default.

The first time a radio connects, the app asks once whether to share. **Share** turns uploading on and **No thanks** leaves it off. Either way the question is not asked again; the setting can be changed at any time.

What is uploaded, about once a minute:

- For every packet your radio hears: payload type, route type, path hashes, hop count, SNR, RSSI, size rounded to 16 bytes, a packet hash, and the time rounded to the minute.
- For repeater and room server adverts with a valid signature: public key, name, type and the advertised location snapped to a ~2 km grid.
- Your radio's own position snapped to the same grid (if the radio has one) and its frequency, bandwidth, spreading factor and coding rate.
- A random install ID that changes every 24 hours.

What is never uploaded: message text or payloads, channel or community names and hashes, direct-message sender/recipient hashes, region transport codes, exact coordinates, and anything about chat or sensor nodes beyond the header-only packet record.

The server does not store IP addresses and keeps raw records for 7 days. See the map's [privacy page](https://map.meshcoreopen.org/privacy) for details.

## Hiding a repeater

Repeater and room server owners can hide their node by putting 🚫 anywhere in its name and sending a flood advert. It disappears from the map and appears in the packet viewer only as "Anonymous repeater". To show it again, remove the emoji; it reappears with its first advert after 7 days without one. The delay stops anyone from undoing an owner's opt-out with a faked advert. The emoji uses 4 of the name's 32 bytes.

## Limitations

- Uploading only happens while the app is connected to a radio. On iOS most contributions come from foreground use.
- Packets larger than the companion frame limit (172 bytes) are never forwarded to the app, so they are not counted.
- Coverage shows how well phones hear repeaters; a handheld's own transmissions reach repeaters less reliably.
