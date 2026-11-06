# Privacy Policy for MeshCore Open

**Last Updated:** October 11, 2026

## Introduction

MeshCore Open ("the App") is an open-source Flutter application for communicating with MeshCore LoRa mesh networking devices. This Privacy Policy explains how the App handles your information.

## Data Collection

### Data We Do NOT Collect

MeshCore Open does **not**:
- Collect personal information for the developer. The optional network map upload described below sends anonymized radio data only if you turn it on
- Track your usage or behavior
- Use analytics services
- Require account creation
- Sell personal information

The App does make limited requests to third-party services when you use features that require internet access, as described below.

### Data Stored Locally on Your Device

The App stores the following data **locally on your device**:

- **Messages**: Chat messages sent and received through the mesh network
- **Contacts**: Names and identifiers of mesh network contacts
- **App Settings**: Your preferences (theme, language, notification settings)
- **Channel Settings**: Configuration for mesh network channels
- **Message History**: Path history for message routing
- **Debug Logs**: Optional BLE and app debug logs (if enabled by user)
- **Cached Map Tiles**: Offline map data for the mapping feature
- **Images and Models**: Received image bitstreams, reconstructed images, and downloaded translation/image model files
- **Communities and Credentials**: Community secrets and repeater passwords when you choose to save them
- **Regions**: Saved region names, per-radio default/channel selections, and message-region metadata

This locally stored data is not transmitted to the MeshCore Open developer. Some features may send specific data to third-party services as described in the Third-Party Services section.

## Permissions

The App requires certain device permissions to function:

### Bluetooth Permissions
- **BLUETOOTH, BLUETOOTH_ADMIN** (Android 11 and below)
- **BLUETOOTH_SCAN, BLUETOOTH_CONNECT, BLUETOOTH_ADVERTISE** (Android 12+)

These permissions are used solely to discover and communicate with MeshCore hardware devices via Bluetooth Low Energy (BLE).

### Location Permission
- **ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION**

Required by Android for BLE scanning on Android 11 and below. MeshCore Open does not use the phone's GPS to determine your location. Location data shown in the App comes from MeshCore devices and mesh advertisements. Location data may also be optionally shared over the mesh network if you choose to enable location sharing features.

### Internet Permission
- **INTERNET**

Used for features that access third-party internet services, including map tiles, the MeshCore Open network map, Line-of-Sight elevation lookups, optional model downloads, GIF search/display, and optional URL image previews.

### Notification Permission
- **POST_NOTIFICATIONS** (Android 13+)

Used to display notifications for incoming messages when the app is in the background.

### Background Service Permissions
- **FOREGROUND_SERVICE, FOREGROUND_SERVICE_CONNECTED_DEVICE, WAKE_LOCK**

Used to maintain BLE connection with your MeshCore device while the app is in the background.

### Camera and Photo Library

Camera access is used for contact and community QR scanning. Photo-library access is used when you select a photo for mesh image messaging. Selected photos are encoded locally for transmission over the mesh; the App does not upload them to a model service for inference.

## MeshCore Open Network Map

The MeshCore Open project runs a public network map at [map.meshcoreopen.org](https://map.meshcoreopen.org). It shows MeshCore repeaters, room servers, the links between them, traffic and measured coverage.

### Viewing the map
When you use the Online or Both view on the App's map, the App requests map data for the area on screen from `map.meshcoreopen.org`. These requests include the visible map area and expose your device's IP address to the server as part of normal internet communication. Viewing the map never uploads anything.

### Sharing data (opt-in)
Uploading is **off by default**. The first time a radio connects, the App asks once whether you want to share; you can also turn it on or off at any time in **Settings → App settings → Network map**. Turning it off stops uploads immediately and discards anything waiting to be sent.

While sharing is on and a radio is connected, the App sends the following about once a minute:

- **Packet headers** for packets your radio hears: payload type, route type, the repeater path hashes, hop count, signal strength (SNR/RSSI), size rounded to 16 bytes, a one-way packet fingerprint used to count duplicates, and the time rounded to the minute.
- **Repeater and room server adverts** with a valid signature: public key, name, node type and advertised location.
- **Your radio's position and settings**, if the radio has a position: rounded to a grid of about 2 km, plus its frequency, bandwidth, spreading factor and coding rate.
- **A random install ID** that changes every 24 hours.

All locations are rounded to the ~2 km grid on your phone before upload, and the map shows them only as hexagons.

The App never uploads message text or payloads, channel or community names, keys or hashes, direct-message sender or recipient hashes, region transport codes, exact coordinates, your contact list, or information about chat or sensor nodes beyond the header-only packet records above.

### How the server handles uploads
- **IP addresses are not stored or logged.** The server uses your IP address in memory to rate-limit uploads and to check whether a request comes from a hosting provider. To count how many independent people reported something, it keeps a keyed hash of your network prefix (the /24 IPv4 or /48 IPv6 block) until the end of the day. The key changes daily and is discarded, after which these hashes cannot be linked to an address; they are then deleted.
- **Retention:** individual packet and advert records are deleted after 7 days. Hourly and daily totals (for example, the number of packets a link carried in a day) are kept longer to draw 30-day views.
- **Public data:** repeater names, rough locations, links, traffic totals and coverage are shown publicly on the map and in the App.

Uploaded records are not linked to an account, name or device identity, so the project cannot find or delete a particular person's records; they expire on the schedule above.

### Hiding a repeater
Repeater and room server owners can remove their node from the map by putting the 🚫 emoji anywhere in its name and sending a flood advert. Its name and location are then removed from the map, and the packet viewer shows it only as an anonymous repeater with its public key. Location traces tied to it, such as which areas heard it, are deleted too. To show it again, remove the emoji; it reappears with its first advert after 7 days without one.

See the map's [privacy page](https://map.meshcoreopen.org/privacy) for more detail.

## Third-Party Services

### Map Tiles
The App uses OpenStreetMap and, when selected in settings, Stadia Maps tile servers to display maps. Map tile requests include tile coordinates that identify the geographic area being viewed, and your device's IP address may be visible to the tile provider.

See [OpenStreetMap's Privacy Policy](https://wiki.osmfoundation.org/wiki/Privacy_Policy) and [Stadia Maps' Privacy Policy](https://stadiamaps.com/privacy/) for more information.

### Line-of-Sight Elevation Lookups (Open-Meteo)
When you use the Line-of-Sight (LOS) analysis feature, the App sends latitude and longitude coordinates for points along the selected radio path to the Open-Meteo Elevation API. These coordinates come from MeshCore node positions or locations selected in the map, not from the phone's GPS.

Open-Meteo uses these coordinates to return terrain elevation data needed for the LOS calculation. The request also exposes your device's IP address to Open-Meteo as part of normal internet communication.

LOS elevation lookups are only made when the LOS feature is used. See [Open-Meteo's Terms and Privacy information](https://open-meteo.com/en/terms) for more information.

### Model Downloads (Hugging Face)
The App can download optional translation models and the optional neural image-codec model bundle from Hugging Face when you choose to install or update those models in Settings.

When a model download is requested, the App sends standard HTTP requests for the selected model files to `huggingface.co`. Your device's IP address is visible to Hugging Face as part of normal internet communication. The App does not upload your messages, contacts, mesh location data, or other locally stored content to Hugging Face as part of these model downloads.

Model-download requests are only made when you choose to download or update a model. See [Hugging Face's Privacy Policy](https://huggingface.co/privacy) for more information.

### GIF Search (Giphy)
The App includes a GIF picker feature powered by Giphy. When you use the GIF search feature:
- Your search queries are sent to Giphy's API servers
- Your device's IP address is visible to Giphy
- Giphy may collect usage data according to their privacy policy

GIF search is optional and activated through the picker. Displaying a GIF reference received in a chat also requests image content from Giphy’s CDN, even if you did not perform a search. See [Giphy's Privacy Policy](https://support.giphy.com/hc/en-us/articles/360032872931-GIPHY-Privacy-Policy) for more information about how they handle data.

### Device Purchase Link (Seeed Studio)
The connection screen shows a link to buy a MeshCore device from Seeed Studio. The link contains a MeshCore Open affiliate code, so the project may earn a commission on purchases made through it, at no extra cost to you. The App sends nothing to Seeed Studio unless you tap the link; tapping it opens Seeed Studio's website in your browser, where Seeed Studio's own privacy policy applies.

### URL Image Previews and Custom Model URLs

When URL images are enabled for a contact or channel, supported links in messages can cause requests to the referenced image host, sharing-page provider, or IPFS gateway. These services receive the requested URL and normal connection information, including your IP address. Requests may occur when chat content is displayed rather than only after tapping the link. Disable URL images in the contact/channel settings to disable this preview feature.

If you choose a custom model URL, model requests go to that host rather than only Hugging Face. Translation and mesh-image inference run locally after model installation; message content and selected photos are not sent to the model host for inference.

## Mesh Network Communications

Messages sent through the MeshCore mesh network are transmitted over radio frequencies to other mesh devices. The App itself does not control or monitor these communications beyond facilitating the connection between your mobile device and your MeshCore hardware.

## Data Security

Local data uses standard platform storage: preferences/JSON for metadata and files for models, images, and caches. Saved secrets and passwords are local data too. The App does not implement additional encryption for locally stored data beyond what the operating system provides.

## Children's Privacy

The App does not knowingly collect any personal information from children under 13 years of age.

## Open Source

MeshCore Open is open-source software. You can review the complete source code to verify these privacy practices at [the project repository](https://github.com/zjs81/meshcore-open).

## Changes to This Policy

We may update this Privacy Policy from time to time. Any changes will be reflected in the "Last Updated" date at the top of this policy.

## Contact

If you have questions about this Privacy Policy or the App's privacy practices, please open an issue on the [project issue tracker](https://github.com/zjs81/meshcore-open/issues).

---

**Summary**: MeshCore Open does not use the phone's GPS for location, does not include analytics, and does not collect personal information for the developer. If you opt in, the App uploads anonymized packet headers, repeater adverts and ~2 km rounded locations to the MeshCore Open network map; the server does not store IP addresses and deletes raw records after 7 days. Some optional features communicate with third-party services, including map tile providers, Open-Meteo for LOS elevation lookups, Hugging Face for model downloads, Giphy for GIF search/display, and image hosts/gateways for enabled URL previews.
