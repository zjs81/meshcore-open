# BLE Protocol & Data Layer

This is a technical reference for the communication protocol and data architecture.

## Transport Layer

The app supports three transports, all sharing the same command/response protocol:

| Transport | Method | Implementation |
|---|---|---|
| Bluetooth LE | Nordic UART Service (NUS) GATT | `flutter_blue_plus` |
| USB Serial | Packet-framed serial | `MeshCoreUsbManager` |
| TCP | Packet-framed socket | `MeshCoreTcpConnector` |

### BLE (Nordic UART Service)

- **Service UUID**: `6e400001-b5a3-f393-e0a9-e50e24dcca9e`
- **RX Characteristic** (write to device): `6e400002-b5a3-f393-e0a9-e50e24dcca9e`
- **TX Characteristic** (notify from device): `6e400003-b5a3-f393-e0a9-e50e24dcca9e`

Raw `Uint8List` payloads are written directly to the RX characteristic. Writes use "write without response" if supported, falling back to "write with response".

### USB and TCP Framing

Both use a lightweight packet framing codec:

```
TX (host → device):  [0x3C][len_lo][len_hi][payload...]
RX (device → host):  [0x3E][len_lo][len_hi][payload...]
```

- Frame start: `0x3C` (`<`) for outgoing, `0x3E` (`>`) for incoming
- Length: 2-byte little-endian, payload only
- Max payload: 172 bytes
- TCP: `tcpNoDelay: true` (Nagle disabled), writes serialized to prevent interleaving
- USB: 10ms post-write delay between frames

## Connection State Machine

```
enum MeshCoreConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}
```

## BLE Connection Lifecycle

1. **Scan** with keyword filters `["MeshCore-", "Whisper-"]`
2. **Connect** with 15-second timeout
3. **Request MTU** 185 bytes (non-web only)
4. **Discover services** and locate NUS
5. **Enable TX notifications** (up to 3 attempts on native)
6. **Subscribe** to TX characteristic for incoming frames
7. **Initial sync**: device info query, time sync, channel sync

## Auto-Reconnect (BLE Only)

On unexpected disconnection, auto-reconnect with exponential backoff:
- Delays: 1s, 2s, 4s, 8s, 16s, 30s, 30s...
- Resets on successful connection
- Disabled for manual disconnects
- Not available for USB or TCP

## Protocol Constants

| Constant | Value | Description |
|---|---|---|
| Max frame size | 172 bytes | BLE/USB/TCP payload limit |
| Public key size | 32 bytes | Ed25519 public key |
| Max path size | 64 bytes | Maximum path data |
| Max name size | 32 bytes | Maximum node name |
| Max text payload | 160 bytes | Firmware `MAX_TEXT_LEN` |
| App protocol version | 3 | Sent in device query |
| Contact frame size | 148 bytes | Fixed-size contact record |

## Command Codes (App → Device)

| Code | Name | Description |
|------|------|-------------|
| 1 | CMD_APP_START | Announce app connection |
| 2 | CMD_SEND_TXT_MSG | Send direct text message |
| 3 | CMD_SEND_CHANNEL_TXT_MSG | Send channel text message |
| 4 | CMD_GET_CONTACTS | Request contact list |
| 5 | CMD_GET_DEVICE_TIME | Query device clock |
| 6 | CMD_SET_DEVICE_TIME | Set device clock |
| 7 | CMD_SEND_SELF_ADVERT | Broadcast own advertisement |
| 8 | CMD_SET_ADVERT_NAME | Set node name |
| 9 | CMD_ADD_UPDATE_CONTACT | Add or update a contact |
| 10 | CMD_SYNC_NEXT_MESSAGE | Request next queued message |
| 11 | CMD_SET_RADIO_PARAMS | Set radio parameters |
| 12 | CMD_SET_RADIO_TX_POWER | Set TX power |
| 13 | CMD_RESET_PATH | Reset contact path |
| 14 | CMD_SET_ADVERT_LATLON | Set advertised location |
| 15 | CMD_REMOVE_CONTACT | Remove a contact |
| 16 | CMD_SHARE_CONTACT | Share contact to mesh |
| 17 | CMD_EXPORT_CONTACT | Export contact as bytes |
| 18 | CMD_IMPORT_CONTACT | Import contact from bytes |
| 19 | CMD_REBOOT | Reboot device |
| 20 | CMD_GET_BATT_AND_STORAGE | Query battery and storage |
| 22 | CMD_DEVICE_QUERY | Query device info |
| 26 | CMD_SEND_LOGIN | Login to repeater/room |
| 27 | CMD_SEND_STATUS_REQ | Request repeater status |
| 30 | CMD_GET_CONTACT_BY_KEY | Get contact by public key |
| 31 | CMD_GET_CHANNEL | Get channel definition |
| 32 | CMD_SET_CHANNEL | Set channel name and PSK |
| 36 | CMD_SEND_TRACE_PATH | Request path trace |
| 38 | CMD_SET_OTHER_PARAMS | Set misc parameters |
| 39 | CMD_GET_TELEMETRY_REQ | Request sensor telemetry |
| 40 | CMD_GET_CUSTOM_VAR | Get custom variables |
| 41 | CMD_SET_CUSTOM_VAR | Set a custom variable |
| 50 | CMD_SEND_BINARY_REQ | Send binary request |
| 57 | CMD_SEND_ANON_REQ | Send anonymous request |
| 58 | CMD_SET_AUTO_ADD_CONFIG | Set auto-add configuration |
| 59 | CMD_GET_AUTO_ADD_CONFIG | Get auto-add configuration |

## Response / Push Codes (Device → App)

| Code | Name | Description |
|------|------|-------------|
| 0 | RESP_CODE_OK | Generic success |
| 1 | RESP_CODE_ERR | Generic error |
| 2 | RESP_CODE_CONTACTS_START | Contact list begins |
| 3 | RESP_CODE_CONTACT | Single contact data |
| 4 | RESP_CODE_END_OF_CONTACTS | Contact list complete |
| 5 | RESP_CODE_SELF_INFO | Device self-info response |
| 6 | RESP_CODE_SENT | Message transmitted; carries `[1]=is_flood, [2–5]=ack_hash, [6–9]=estimated_timeout_ms` |
| 7 | RESP_CODE_CONTACT_MSG_RECV | Incoming direct message (v2) |
| 8 | RESP_CODE_CHANNEL_MSG_RECV | Incoming channel message (v2) |
| 10 | RESP_CODE_NO_MORE_MESSAGES | No more queued messages |
| 11 | RESP_CODE_EXPORT_CONTACT | Exported contact data |
| 9 | RESP_CODE_CURR_TIME | Current device time |
| 12 | RESP_CODE_BATT_AND_STORAGE | Battery mV (uint16 LE) + storage used/total (uint32 LE each) |
| 13 | RESP_CODE_DEVICE_INFO | Firmware info |
| 16 | RESP_CODE_CONTACT_MSG_RECV_V3 | Incoming direct message (v3) |
| 17 | RESP_CODE_CHANNEL_MSG_RECV_V3 | Incoming channel message (v3) |
| 18 | RESP_CODE_CHANNEL_INFO | Channel definition |
| 21 | RESP_CODE_CUSTOM_VARS | Custom variables |
| 25 | RESP_CODE_AUTO_ADD_CONFIG | Auto-add flags |
| 0x80 | PUSH_CODE_ADVERT | Known contact re-seen |
| 0x81 | PUSH_CODE_PATH_UPDATED | Better path found; carries the 32-byte public key of the updated contact |
| 0x82 | PUSH_CODE_SEND_CONFIRMED | Delivery ACK from remote; carries ACK hash (4 bytes) + trip time (4 bytes) |
| 0x83 | PUSH_CODE_MSG_WAITING | Offline messages queued |
| 0x85 | PUSH_CODE_LOGIN_SUCCESS | Repeater/room login succeeded |
| 0x86 | PUSH_CODE_LOGIN_FAIL | Repeater/room login failed |
| 0x87 | PUSH_CODE_STATUS_RESPONSE | Repeater status response |
| 0x88 | PUSH_CODE_LOG_RX_DATA | Radio RX data with SNR (int8, units 1/4 dB), RSSI, and raw radio packet |
| 0x89 | PUSH_CODE_TRACE_DATA | Path trace result |
| 0x8A | PUSH_CODE_NEW_ADVERT | New node discovered |
| 0x8B | PUSH_CODE_TELEMETRY_RESPONSE | Sensor telemetry data |
| 0x8C | PUSH_CODE_BINARY_RESPONSE | Binary data response |

## Data Models

### Contact
32-byte public key (primary identity), name, type (chat/repeater/room/sensor), flags, path data, GPS coordinates, last-seen timestamp. Parsed from 148-byte firmware frames with this layout:

```
[0]     = resp_code
[1–32]  = public key (32 bytes)
[33]    = type (1=chat, 2=repeater, 3=room, 4=sensor)
[34]    = flags (bit 0 = favorite)
[35]    = path_length
[36–99] = path (64 bytes)
[100–131] = name (32 bytes, null-padded)
[132–135] = timestamp (uint32 LE)
[136–139] = latitude (int32 LE, × 1e-6 degrees)
[140–143] = longitude (int32 LE, × 1e-6 degrees)
[144–147] = last_modified (uint32 LE)
```

### Message (Direct)
Sender key, text, timestamp, outgoing flag, status (pending/sent/delivered/failed), message ID (UUID), retry count, ACK hash, trip time, path data, reactions.

### Channel Message
Sender name, text, timestamp, status (pending/sent/failed), repeater hops, path variants, channel index, reactions, reply threading fields.

### Channel
Index (0–7), name, 16-byte PSK, unread count. PSK derivation methods for hashtag (SHA-256) and community (HMAC-SHA256) channels.

### Community
UUID, name, 32-byte secret, hashtag channel list. Shared via QR code.

## Persistence

All data is stored via `SharedPreferences` (JSON-serialized). No SQLite or other database.

| Data | Storage Key Pattern | Scope |
|---|---|---|
| Contacts | `contacts<pubKey10>` | Per device identity |
| Messages | `messages_<pubKey10><contactKey>` | Per device + contact |
| Channel Messages | `channel_messages_<pubKey10><index>` | Per device + channel |
| Channels | `channels<pubKey10>` | Per device identity |
| Channel Order | `channel_order_<pubKey10>` | Per device identity |
| Contact Groups | `contact_groups<pubKey10>` | Per device identity |
| Communities | `communities_v1<pubKey10>` | Per device identity |
| Unread Counts | `contact_unread_count<pubKey10>` | Per device identity |
| Discovered Contacts | `discovered_contacts` | Global |
| App Settings | `app_settings` | Global |
| Path History | `path_history_<contactKey>` | Per contact |

## Auto-Add Configuration Bitmask

Used by `CMD_SET_AUTO_ADD_CONFIG` (58) and `RESP_CODE_AUTO_ADD_CONFIG` (25):

| Bit | Flag | Description |
|-----|------|-------------|
| 0 | 0x01 | Overwrite oldest contact when list is full |
| 1 | 0x02 | Auto-add chat users |
| 2 | 0x04 | Auto-add repeaters |
| 3 | 0x08 | Auto-add room servers |
| 4 | 0x10 | Auto-add sensors |

## Radio Packet Payload Types

Seen inside `PUSH_CODE_LOG_RX_DATA` raw packets:

| Code | Type |
|------|------|
| 0x00 | REQ (request) |
| 0x01 | RESPONSE |
| 0x02 | TXTMSG (text message) |
| 0x03 | ACK |
| 0x04 | ADVERT |
| 0x05 | GRPTXT (group/channel text) |
| 0x06 | GRPDATA (group data) |
| 0x07 | ANONREQ (anonymous request) |
| 0x08 | PATH |
| 0x09 | TRACE |
| 0x0A | MULTIPART |
| 0x0B | CONTROL |
| 0x0F | RAW_CUSTOM |

## State Management

Uses Flutter `Provider` with `ChangeNotifier`. The central state holder is `MeshCoreConnector`, which owns all in-memory collections and fires debounced (50ms) `notifyListeners()` to update the UI. In-memory conversations are windowed to 200 messages per contact; older messages remain on disk and are loaded on demand.

### Data Flow

1. Raw frames arrive over BLE/USB/TCP
2. First byte is parsed as response/push code
3. Appropriate model factory (`fromFrame()`) parses the data
4. In-memory collections are updated
5. Storage stores are persisted (async)
6. `notifyListeners()` triggers UI rebuilds
7. Screens read current state via getters
