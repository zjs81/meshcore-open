# MeshCore Open - Feature Documentation

MeshCore Open is an open-source Flutter client for MeshCore LoRa mesh networking devices. These guides describe current user-facing features and their requirements. Reviewed against app `9.5.0+18` on October 11, 2026. Hardware behavior still depends on platform, radio, and firmware.

## Start here

1. Use compatible MeshCore companion firmware and [connect a radio](scanner-and-connection.md).
2. Wait for synchronization, then open a [channel](channels.md) or [contact chat](chat-and-messaging.md).
3. For scoped floods, configure [regions](regions.md). For image packets, install the [image model](image-messages.md).
4. If a device or feature is unavailable, use [troubleshooting](troubleshooting.md).

## Table of Contents

1. [Scanner & Connection](scanner-and-connection.md) - BLE scanning, USB serial, and TCP connection with automatic reconnect
2. [Navigation](navigation.md) - App flow, device screen, and quick-switch navigation
3. [Contacts](contacts.md) - Contact management, groups, discovery, nearby-node scan, discovered-contact import/export, and sharing
4. [Chat & Messaging](chat-and-messaging.md) - Direct messages, location sharing, message status, reactions, and retries
5. [Channels](channels.md) - Broadcast channels, communities, channel chat, and auto-resend
6. [Map & Location](map-and-location.md) - Node map, shared pins, path tracing, line-of-sight, and offline caching
7. [Settings](settings.md) - Device settings, app settings, radio configuration, and exports
8. [Notifications](notifications.md) - System notifications, replies from watches and Android Auto, unread badges, and notification preferences
9. [Repeater Management](repeater-management.md) - Repeater hub, status, CLI, telemetry, and neighbors
10. [Additional Features](additional-features.md) - GIF picker, localization, debug logs, SMAZ compression, and more
11. [Routing Paths](routing-paths.md) - Path encoding, validation, device capability detection, and storage
12. [BLE Protocol & Data Layer](ble-protocol.md) - Technical reference for the communication protocol and data architecture
13. [Regions](regions.md) - App and radio default regions, unscoped sends, message labels, and reply regions
14. [Image Messages](image-messages.md) - Model setup, mesh image sending, recovery, and reconstruction
15. [Companion Radio Statistics](radio-statistics.md) - Noise, signal metrics, and airtime
16. [Troubleshooting](troubleshooting.md) - BLE, USB, browser, and firmware issues
17. [Review Mode](review-mode.md) - Simulated radio and reviewer instructions for Google Play and App Store review
18. [Network Map](network-map.md) - Online repeater map, adding and managing repeaters from it, opt-in uploads, and hiding a repeater

## App Overview

MeshCore Open connects to MeshCore LoRa mesh radios over BLE, USB, or TCP. Once connected, users can:

- **Chat** with other mesh nodes via encrypted direct messages
- **Broadcast** on shared channels (public, hashtag, private, or community-scoped)
- **View nodes on a map** with GPS locations, predicted positions, and path traces
- **Manage repeaters** with CLI access, telemetry, neighbor info, and settings
- **Share contacts** via `meshcore://` URIs and QR codes
- **Share locations** as map pins from chat or the map
- **Scan for nearby nodes** and import/export discovered contacts
- **Configure radio settings** including frequency, power, bandwidth, and spreading factor
- **Cache offline maps** for use without internet connectivity
- **Analyze line-of-sight** between nodes with terrain elevation profiles
- **Use Android Auto** to hear new messages and reply by voice while driving (Android)

## What needs internet?

| Feature | Internet requirement |
|---|---|
| Radio messaging, region-scoped sends | No internet needed for the mesh transport |
| Mesh image encoding/reconstruction | Local after model installation |
| On-device translation | Local after model installation |
| Model downloads | Internet required |
| GIF search/display, URL image previews, and IPFS image/file uploads | Internet required to upload or retrieve content |
| Map display | Cached tiles work offline; uncached tiles need internet |
| Online network map and opt-in uploads | Internet required |
| Terrain LOS analysis | Elevation lookup needs internet unless the required data is already cached |

## Keeping documentation current

When changing a feature, update its access steps, defaults, platform/firmware requirements, failure states, and screenshots. Keep binary framing details in the protocol reference and implementation links. See [contribution guidelines](../CONTRIBUTING.md).
