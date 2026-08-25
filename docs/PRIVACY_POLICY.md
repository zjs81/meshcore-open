# Privacy Policy for MeshCore Open

**Last Updated:** August 23, 2026

## Introduction

MeshCore Open ("the App") is an open-source Flutter application for communicating with MeshCore LoRa mesh networking devices. This Privacy Policy explains how the App handles your information.

## Data Collection

### Data We Do NOT Collect

MeshCore Open does **not**:
- Collect personal information for the developer
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

Used for features that access third-party internet services, including map tiles, Line-of-Sight elevation lookups, optional model downloads, and optional GIF search.

### Notification Permission
- **POST_NOTIFICATIONS** (Android 13+)

Used to display notifications for incoming messages when the app is in the background.

### Background Service Permissions
- **FOREGROUND_SERVICE, FOREGROUND_SERVICE_CONNECTED_DEVICE, WAKE_LOCK**

Used to maintain BLE connection with your MeshCore device while the app is in the background.

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

GIF search is optional and only activated when you choose to use it. See [Giphy's Privacy Policy](https://support.giphy.com/hc/en-us/articles/360032872931-GIPHY-Privacy-Policy) for more information about how they handle data.

## Mesh Network Communications

Messages sent through the MeshCore mesh network are transmitted over radio frequencies to other mesh devices. The App itself does not control or monitor these communications beyond facilitating the connection between your mobile device and your MeshCore hardware.

## Data Security

All data stored locally on your device uses standard Flutter/Android storage mechanisms. The App does not implement additional encryption for locally stored data beyond what the operating system provides.

## Children's Privacy

The App does not knowingly collect any personal information from children under 13 years of age.

## Open Source

MeshCore Open is open-source software. You can review the complete source code to verify these privacy practices at [the project repository].

## Changes to This Policy

We may update this Privacy Policy from time to time. Any changes will be reflected in the "Last Updated" date at the top of this policy.

## Contact

If you have questions about this Privacy Policy or the App's privacy practices, please open an issue on the project's GitHub repository.

---

**Summary**: MeshCore Open does not use the phone's GPS for location, does not include analytics, and does not collect personal information for the developer. Some optional features communicate with third-party services, including map tile providers, Open-Meteo for LOS elevation lookups, Hugging Face for model downloads, and Giphy for GIF search.
