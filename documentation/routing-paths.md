# Routing Paths

This page covers how MeshCore Open represents, selects, validates, and stores routing paths in the UI and data layer.

## Path Routing

MeshCore supports variable-length multi-byte routing paths so the app can scale from small meshes to very large node sets.

### Hash Width and Multi-Byte Paths

The device capability determines the hash width (number of bytes per hop):

| Width | Max Unique Nodes | Typical Use |
|-------|-----------------|-------------|
| 1 byte | 256 | Single-byte node IDs |
| 2 bytes | 65,536 | Medium meshes |
| 3 bytes | 16.7M | Large networks |
| 4 bytes | 4.3G | Very large meshes / future-proofing |

### Device Capability Detection

On device connection, the app reads the firmware capability to set `pathHashByteWidth`:

```dart
// Read from device info response (offset 81)
final modeRaw = firmwareBytes.length >= 82
    ? (firmwareBytes[81] & 0xFF)
    : 0;
final mode = modeRaw.clamp(0, 3);
_pathHashByteWidth = mode + 1; // 1, 2, 3, or 4 bytes per hop
```

The connector reads a single-mode byte and clamps to `0..3`, so the supported hop width is `1..4` bytes. UI code also clamps widths when rendering (typically to `1..4`) so 4-byte hops are handled end-to-end in the current codebase.

### Path Data Structure

Paths in messages and storage consist of:

 - **`pathLength` (model/storage)**: Hop count (number of hops). Negative values (e.g. `-1`) are used as a flood sentinel.
 - **On-air `path_len` byte**: A packed byte that encodes hop count + hash width and is decoded into `pathLength` + `pathBytes` when parsing frames.
 - **`pathBytes`**: Raw bytes of the path (concatenated hop prefixes), grouped by `pathHashByteWidth`.
 - **`hopCount`**: Derived display value computed from bytes and width: `(byteCount + hashByteWidth - 1) ~/ hashByteWidth`.
 - **Example**: With `pathHashByteWidth=2`, a 3-hop path has 6 bytes (`pathBytes.length = 6`) and `pathLength = 3`:
  - `pathBytes = [0xA1, 0xA2, 0xB1, 0xB2, 0xC1, 0xC2]`
  - Hops: `[0xA1A2]`, `[0xB1B2]`, `[0xC1C2]`

### Hop Count Calculation

Convert path byte length to hop count:

```dart
int hopCount = (byteCount + hashByteWidth - 1) ~/ hashByteWidth;
```

Use this consistently when displaying hop counts in UI. Do not treat `pathLength` as a hop count when the path uses multi-byte hop hashes.

### Path Usage in Different Message Types

- **Direct messages**: Extract path from decrypted payload to trace sender route.
- **Channel messages**: Decrypt hop-by-hop routing chain from payload; the header carries the encoded byte length for the path blob, not the derived hop count.
- **Contact storage**: Path length in byte 32, raw path bytes in bytes 33-96, grouped by detected `pathHashByteWidth`.

### UI Hop Count Display

⚠️ **Important**: In screens like "Channel Message Path", prefer the actual decoded `pathBytes` hop count over `pathLength` metadata:

```dart
// Preferred: use actual observed path length
final effectiveHopCount = (pathBytes.length + width - 1) ~/ width;

// Avoid: using encoded byte length as if it were a hop count
// pathLength is bytes; converting it twice causes inflated counts
```

Example scenario:
- Radio header reports `pathLength: 32` bytes
- Decoded path bytes: `[0xAB, 0xCD]` (2 bytes = 1 hop with width=2)
- **Display**: "1 hop" (from `pathBytes`), not "32 hops" (which would double-count the encoded length)

