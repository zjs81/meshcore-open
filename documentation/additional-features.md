# Additional Features

## GIF Picker (Giphy Integration)

### How to Access
In any chat screen (direct or channel), tap the GIF button in the message input bar.

### What the User Sees
A bottom sheet with a search field and a grid of GIF thumbnails.

### Key Interactions
- On open, loads trending GIFs (G-rated, 25 results)
- Type to search and press the keyboard submit button (search triggers on submit, not on each keystroke). Clearing the search field reloads trending GIFs
- On network/API errors, a "Retry" button is shown in-place
- Tap a GIF to select it — the chat input shows an inline preview with an X button to dismiss
- Send the message to transmit the GIF reference (`g:<giphy-id>`)
- Recipients see the GIF rendered inline via Giphy CDN
- "Powered by Giphy" attribution is always shown at the bottom of the picker
- The bottom sheet occupies 70% of screen height

---

## Localization / Multi-Language Support

### How to Access
App Settings → Appearance → Language

### Supported Languages (18)
English, French, Spanish, German, Polish, Slovenian, Portuguese, Italian, Chinese, Swedish, Dutch, Slovak, Bulgarian, Russian, Ukrainian, Hungarian, Japanese, Korean

### How It Works
- All UI strings go through Flutter's ARB localization system
- Language can follow the system locale or be explicitly overridden
- Changes take effect immediately

---

## Discovered Contacts Screen

### How to Access
From Contacts screen → overflow menu → "Discovered Contacts"

### What the User Sees
A list of nodes heard passively over the air but not yet added as contacts. Each shows:
- Color-coded avatar (by type)
- Name
- Short public key
- Last-seen time

### Key Interactions
- Search bar with debounced filtering
- Sort by last seen or name; filter by type
- **Tap**: Import the contact (adds to your contact list)
- **Long-press**: Add Contact, Copy `meshcore://` URI to clipboard, or Delete
- Overflow menu → "Export discovered contacts", "Import discovered contacts", or "Delete All" (with confirmation). See [Contacts](contacts.md#export-and-import-discovered-contacts)
- Radar icon → **Scan for nearby nodes** (firmware version code 8+). See [Contacts](contacts.md#scan-for-nearby-nodes)
- Already-known contacts and your own node are filtered out

---

## SMAZ Compression

### What It Is
An optional per-contact and per-channel text compression feature using the SMAZ algorithm (optimized for short English text).

### How to Enable
- **Per contact**: Chat screen → overflow menu → Contact Settings → toggle "SMAZ compression"
- **Per channel**: Long-press channel → Edit → toggle "SMAZ compression"

### How It Works
- When enabled, compression is applied using a "compress only if smaller" strategy — the message is only transmitted compressed if the encoded result is actually shorter than the original. Otherwise, the original text is sent uncompressed
- Compressed messages are transmitted with a `s:` prefix followed by base64-encoded data
- Recipients using MeshCore Open will decompress automatically. **Recipients using other software** that is not SMAZ-aware will see garbled `s:...` text
- The codec operates on ASCII. Non-ASCII / non-English text generally does not benefit from compression and may even expand. Best suited for short English messages
- Disabled by default

---

## Channel and Community QR Scanner

### How to Access
From Channels screen → "+" FAB → "Scan a QR Code"

### What the User Sees
A live QR scanner view with instruction text overlay.

### Key Interactions
- **Community QR code** (shared by another member):
  - On valid scan: confirmation dialog showing community name and ID
  - Option to "Add public channel to device" on join
  - If already a member: shows an "Already a member" dialog
- **Channel QR code** (official MeshCore format, `meshcore://channel/add?name=…&secret=…`, as shared by the official app and sites like ipnt.uk):
  - On valid scan: confirmation dialog asking to add the named channel to the radio
  - The channel goes into the next free slot; if every slot is used, or the channel list is still syncing from the radio, a snackbar explains why and nothing is written
  - If a channel with the same secret is already on the radio, a snackbar says so and scanning continues
  - Names longer than the radio's 31-byte limit are shortened
  - The optional `region_scope` parameter is not applied; set the channel's region manually afterwards
- Invalid QR: shows an orange error snackbar

---

## Channel Message Path Viewing

### How to Access
In a channel chat, long-press a message (or right-click on desktop) and choose Path.

### What the User Sees
- Summary card: sender, time, repeat count, path type, observed hops, and region when known (see [Regions](regions.md))
- "Other Observed Paths" section (if multiple paths detected)
- "Repeater Hops" section listing each hop with hex prefix, resolved name, and GPS coordinates

### Actions
- **Radar icon**: Opens path trace map for live trace
- **Map icon**: Opens a map with hop markers and polyline
- **Path dropdown**: Switch between observed path variants (if multiple)

---

## Debug Logging

### BLE Debug Log
**Access**: Settings → BLE Debug Log

Two views:
- **Frames**: Each BLE frame with direction, description, hex preview, timestamp. Long-press to copy hex.
- **Raw Log RX**: Decoded LoRa packets with route type, payload type, path bytes, and summary.

### App Debug Log
**Access**: Settings → App Debug Log (must be enabled first in App Settings → Debug)

Structured log entries with level (Info/Warning/Error), tag, message, and timestamp.

Both logs support copy-all and clear operations.

---

## Chrome Required Screen

### When It Appears
Automatically shown on web platforms when a non-Chromium browser is detected.

### What the User Sees
A full-screen informational page explaining that the web client requires Chrome. On web the app connects over USB via Web Serial only; Bluetooth is not available in the browser. No interactive elements — purely informational.

---

## Path History Service

### What It Does (Background Service)
Maintains an in-memory LRU cache of up to 50 contacts, each with up to 100 route history entries, tracking:
- Hop count and trip time
- Success/failure counts and route weights
- Flood vs. direct discovery

### Path Scoring
Paths are scored using a weighted formula: reliability (45%), route weight (20%), latency (25%), and freshness (10%). These weights are internal and not user-configurable. Paths whose weight drops to zero or below are automatically deleted. Flood deliveries that receive an ACK give a weight boost (+0.5) to the specific return path.

Used internally for:
- **Auto route rotation**: Cycles through known paths using configurable weights on retries, with a diversity window to avoid re-using recently tried paths
- **Path selection**: Picks the best-scored path for each retry attempt
- **Flood statistics**: Tracks flood vs. direct discovery ratios

---

## Message Retry Service

### What It Does (Background Service)
Handles reliable delivery of outgoing direct messages:
1. Assigns a UUID and sends immediately. Only one message per contact can be in-flight at a time (avoids overflowing the firmware's 8-entry ACK table); subsequent messages are queued
2. Listens for ACK frames matched via SHA-256 hash of `[timestamp][attempt][text][sender_pubkey]`
3. On timeout, retries with exponential backoff: `1000 × 2^retryCount` ms (1s, 2s, 4s, 8s...)
4. Each retry may use a different path (via path history diversity window)
5. After max retries: marks failed but keeps a **30-second grace window** during which a late ACK can still resolve the message to "delivered". Optionally clears the contact's path
6. Reports RTT and path data for quality learning
7. Maintains an ACK hash history (last 50 entries) to handle duplicate ACKs

### Configurable Settings (App Settings → Messaging)
- Max retries (2–10, default 5)
- Clear path on max retry (on/off)
- Auto route rotation with weight parameters

---

## Timeout Prediction (ML)

### What It Does (Background Service)
An ML-based service that predicts expected delivery timeouts:
- Collects delivery observations (path length, message size, time since last RX, delivery time) in a sliding window of up to 100 observations (oldest evicted first)
- Requires **10 minimum observations** before first training. After that, retrains every 5 new observations
- Applies a **1.5x safety margin** to raw predictions (the actual timeout issued is 1.5× the model's predicted delivery time)
- Features with zero variance are automatically excluded from training
- Blends per-contact statistics with ML predictions
- Falls back to `3000 + 3000 × pathLength` ms when insufficient data. Note: `pathLength` here refers to the stored hop count in the app's model/storage (number of hops), not the on-air encoded byte length.
- Observations are persisted to storage via a 2-second debounced timer (observations within 2s of app termination may be lost)

---

## On-Device Message Translation

### What It Is
An optional on-device translation service powered by an embedded LLM (llamadart, running GGUF models). Translation inference runs on-device; messages are not uploaded for inference. Installing models requires internet access.

### How to Access
Open App Settings → Translation, download/select a model, and enable translation. Then long-press an incoming message and choose "Translate message" (right-click on desktop). Automatic incoming translation is a separate toggle; pre-send translation has its own composer control.

### How It Works
- Model files are managed by `TranslationFileStore`; download progress is shown in-place
- Before translating, the source language is automatically detected using the `flutter_langdetect` package. If the detected language already matches the target language, translation is skipped
- Translation runs via `TranslationService` using llamadart. Android APKs currently ship ARM64 only; backend support does not imply an x64 APK is distributed
- Translated text is shown in `TranslatedMessageContent` as an inline overlay on the original message bubble
- The translation is stored with the message, so it is shown again without re-running inference

---

## Emoji Reactions

### How to Access
Long-press a message bubble in any direct or channel chat, then select a reaction emoji.

### What the User Sees
An emoji picker inline with common reactions. Selected reactions appear below the message bubble with a count.

### How It Works
- Implemented via `emoji_picker.dart` and `reaction_helper.dart`
- Reactions are transmitted as a special message type visible to all participants with MeshCore Open

---

## Linkification

### What It Does
URLs and `meshcore://` URIs in received messages are automatically detected and rendered as tappable links.

### How It Works
- Powered by the `flutter_linkify` package via `link_handler.dart`
- Tapping a URL opens the system browser; tapping a `meshcore://` URI imports the contact

---

## GPX Export

### How to Access
Settings → Export section (three options: Export Repeaters, Export Contacts, Export All).

### What It Does
Exports contacts with GPS coordinates to a `.gpx` file via the OS share sheet. Not available on web.

---

## Pinch-to-Zoom Chat Text

### What It Does
Users can pinch to scale all chat text up or down within a session.

### How It Works
- Implemented via `ChatTextScaleService` and `ChatZoomWrapper`
- Scale range: 0.8× to 1.8×
- The chosen scale persists across the session via the service

---

## Background Service (Android)

### What It Does
On Android, a foreground service (`background_service.dart`) keeps the BLE connection and message handling alive when the app is in the background. On other platforms this is a no-op.

### User Impact
- A persistent notification appears while the service is running
- Messages are received and retry logic continues even when the app is not in the foreground

## URL Image Previews

Enable URL images per contact in Chat → overflow → Contact Settings, or per channel in Channels → long-press (right-click on desktop) → Edit. Supported references include direct PNG/JPEG/WebP URLs, pyx.li links, ibb.co sharing pages, and IPFS references/gateway URLs.

The message sends a reference; image retrieval needs internet access and makes requests to the relevant host or gateway. This differs from [image packets transmitted over the mesh](image-messages.md). With previews disabled, the chat may indicate that a message contains a possible image URL.

## Share an Image via IPFS

1. Configure **App Settings → IPFS provider configuration**. Choose Pinata, Filebase, or **Custom (Kubo)** for self hosted or other, then set the upload endpoint, upload gateway, and any required API key. See [IPFS provider configuration](settings.md#ipfs-provider-configuration).
2. In a direct or channel chat, open the composer’s **+** menu and choose **Send image or file via IPFS**.
3. Pick an image or file. The app uploads it to the configured provider and inserts the resulting link into the draft. When an upload gateway is configured, the link is `http://gateway/ipfs/CID`; otherwise it is `ipfs://CID`. Review or edit the draft, then send it as a normal text message; uploading does not send the chat message automatically.

Uploads and image previews need internet access. The file is stored with the selected provider; the mesh carries only the text link, not the file bytes. IPFS content is publicly addressable, so only upload content suitable for sharing publicly. A recipient needs internet access and a working IPFS gateway to retrieve it. If the upload link plus existing draft exceeds the message limit, the app may shorten the existing draft to make room for the link.

## Regions, Mesh Images, and Radio Statistics

See [Regions](regions.md) for default scopes, per-message labels, and reply-region inheritance; [Image Messages](image-messages.md) for model installation and reconstruction; and [Companion Radio Statistics](radio-statistics.md) for connected-radio measurements.
