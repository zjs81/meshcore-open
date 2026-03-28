# MeshCore Open - Feature Documentation

MeshCore Open is an open-source Flutter client for MeshCore LoRa mesh networking devices. This documentation covers every user-facing feature, how to access it, and what it does.

## Table of Contents

1. [Scanner & Connection](scanner-and-connection.md) - BLE scanning, USB serial, and TCP connection
2. [Navigation](navigation.md) - App flow, device screen, and quick-switch navigation
3. [Contacts](contacts.md) - Contact management, groups, discovery, and sharing
4. [Chat & Messaging](chat-and-messaging.md) - Direct messages, message status, reactions, and retries
5. [Channels](channels.md) - Broadcast channels, communities, and channel chat
6. [Map & Location](map-and-location.md) - Node map, path tracing, line-of-sight, and offline caching
7. [Settings](settings.md) - Device settings, app settings, radio configuration, and exports
8. [Notifications](notifications.md) - System notifications, unread badges, and notification preferences
9. [Repeater Management](repeater-management.md) - Repeater hub, status, CLI, telemetry, and neighbors
10. [Additional Features](additional-features.md) - GIF picker, localization, debug logs, SMAZ compression, and more
11. [BLE Protocol & Data Layer](ble-protocol.md) - Technical reference for the communication protocol and data architecture

## App Overview

MeshCore Open connects to MeshCore LoRa mesh radios over BLE, USB, or TCP. Once connected, users can:

- **Chat** with other mesh nodes via encrypted direct messages
- **Broadcast** on shared channels (public, hashtag, private, or community-scoped)
- **View nodes on a map** with GPS locations, predicted positions, and path traces
- **Manage repeaters** with CLI access, telemetry, neighbor info, and settings
- **Share contacts** via `meshcore://` URIs and QR codes
- **Configure radio settings** including frequency, power, bandwidth, and spreading factor
- **Cache offline maps** for use without internet connectivity
- **Analyze line-of-sight** between nodes with terrain elevation profiles
