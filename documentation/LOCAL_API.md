# Local API — letting other apps use the radio

Status: proposed in zjs81/meshcore-open#616. Off by default; Android, iOS, macOS, Linux and
Windows. Not available on web.

## Why

A MeshCore radio has exactly one BLE (or USB/serial/TCP) connection, and this app owns it.
Any other app that wants to send or receive mesh traffic today has two bad options: take the
radio over (then the chat app stops working), or reimplement the companion protocol and ask the
user to disconnect us. Both make MeshCore a single-app transport.

A small, opt-in **local API** turns this app into the radio daemon: it keeps the connection and
other applications on the same device subscribe to the traffic they care about and send through
it. The radio protocol does not change; nothing is exposed off the device. Reticulum works the
same way: `rnsd` holds the interfaces and every app on the machine talks to the network through it.

## Design constraints

* **Opt-in, off by default.** No listener and no port until the user turns it on in
  **Settings → Local API**.
* **Loopback only.** `127.0.0.1`; never a LAN or public interface. Browsers are refused.
* **Explicit pairing, once per app.** The client proves possession of a P-256 key; the user
  approves the app in a dialog and the key is remembered. No shared secret to copy around.
* **No new dependencies.** `dart:io` `HttpServer` and `WebSocket`.
* **The radio keeps its own limits.** Sends go through the same quiet-wait, flood-scope and
  command-ack path as the UI; the API cannot bypass them or take over the connection.
* **Opaque content.** Channel data is `dataType` plus payload bytes, carried unchanged in both
  directions. The API does not parse application formats.

## Transport

A WebSocket server bound to `127.0.0.1` on port `8787`:

```
ws://127.0.0.1:8787/api/v1
```

* An upgrade request that carries an `Origin` header is refused with HTTP 403. Native clients do
  not send one; browsers always do, so a web page cannot reach the radio through loopback.
* Compression is not negotiated.
* A message (all fragments together) may be at most 16 KiB; a larger one closes the connection
  with 1009.
* Only text frames carry requests; a binary frame closes the connection with 1003.

WebSocket rather than AIDL or a custom socket because it is available on every native platform
from the same Dart code, usable from Kotlin, Swift, Rust, Python and JS without a platform plugin,
and testable in `flutter test` against an in-process server. An Android bound-service wrapper
could be added later as a second transport for the same messages.

## Pairing

Each client generates a **P-256 key pair** and keeps the private half; the public key is its
identity to this app.

1. The client connects and sends `hello` with its name (1–64 characters), version (up to 32) and
   public key: base64 of the raw 64-byte `X||Y` point. A key that is not a point on P-256 is
   refused.
2. The server answers `pairing.challenge` with a random `nonce`. The challenge looks the same
   whether or not the key is already paired.
3. The client signs the UTF-8 string `meshcore-open-pair-v1:<nonce>` with `SHA256withECDSA` and
   sends `pair`. The signature is base64 of either DER (what `java.security.Signature` returns)
   or the raw 64-byte `r||s`. The challenge's `message` field holds the same string.
4. A key seen for the first time opens a dialog: **“Allow *Roadbeacon* to connect?”** with the key
   fingerprint. On Allow the key is stored and the connection continues; on Deny, or after two
   minutes without an answer, the connection is closed. A paired key never prompts. If MeshCore
   Open is in the background, a notification says which app is asking; tapping it brings up the
   dialog. The client must keep its connection open meanwhile: disconnecting withdraws the request.
5. Paired apps are listed in **Settings → Local API**. Removing one forgets its key, closes its
   open connections (4003, reason `revoked`) and drops the channel data kept for it; its next
   connection asks again.

`hello` and `pair` are accepted once per connection; any other frame before pairing completes
closes it. `pair` must arrive within 10 seconds of
connecting (the challenge expires with that timeout; the dialog has its own two minutes). Dialogs
are rate limited: one open request per key, three waiting overall, a key may ask again 30 seconds
after its previous request, and at most four requests start per minute. A request that cannot be
shown gets `pairing_pending` or `rate_limited` and the connection closes. A dialog closes by
itself when its request times out or the app disconnects.

A key is not a package name: an app could call itself anything. The dialog shows the name and a
fingerprint the user can compare, and the grant is always explicit.

## Messages

UTF-8 JSON text frames. Requests carry an `id` (any JSON value); responses echo it.
Server-initiated events have `type: "event"`. Unknown fields in requests are ignored.

### Client → server

```json
{"type":"hello","client":{"name":"Roadbeacon","version":"0.4.0","publicKey":"<base64 X||Y>"}}
{"type":"pair","signature":"<base64 DER or r||s>"}
{"id":1,"method":"device.info"}
{"id":2,"method":"events.subscribe","params":{"events":["channel.data"],"channel":"#roadstr","dataTypes":[65362,336]}}
{"id":3,"method":"channel.sendData","params":{"channel":"#roadstr","dataType":65362,"payload":"<base64>"}}
{"id":4,"method":"channels.join","params":{"name":"#roadstr"}}
```

### Server → client

```json
{"type":"pairing.challenge","protocol":1,"nonce":"…","fingerprint":"AB12 CD34 5678 9ABC","message":"meshcore-open-pair-v1:…"}
{"type":"hello","protocol":1,"client":{"name":"Roadbeacon","fingerprint":"…"},"device":{"name":"…","pubkey":"…","firmwareVerCode":11,"connected":true},"eventTypes":["channel.text","channel.data","direct.text","advert"],"limits":{…}}
{"id":1,"ok":true,"result":{"connected":true,"name":"…","batteryMv":4012,"radio":{"freqHz":869525000,"bwHz":250000,"sf":11,"cr":5,"txPowerDbm":22},"channels":[{"index":0,"name":"#roadstr","isPublic":false,"storageId":"…"}]}}
{"id":2,"ok":true,"result":{"subscriptionId":"s1"}}
{"type":"event","subscriptionId":"s1","event":{"type":"channel.data","channel":"#roadstr","channelIndex":0,"dataType":65362,"payload":"<base64>","snrDb":-7.25,"hops":2,"receivedAt":"2026-10-26T12:00:00.000Z","outgoing":false}}
{"id":3,"ok":false,"error":{"code":"payload_too_large","message":"payload is 190 bytes; the limit is 163"}}
{"id":4,"ok":true,"result":{"index":19,"name":"#roadstr","created":true}}
{"type":"device","device":{"name":"…","pubkey":"…","firmwareVerCode":11,"connected":false},"channels":[]}
```

Before pairing completes, errors have no `id`:

```json
{"type":"error","error":{"code":"unauthorized","message":"bad signature"}}
```

`limits` in `hello` reports `maxPayloadBytes`, `maxMessageBytes`, `maxQueuedBytes`,
`sendsPerMinute`, `minSendGapMs`, `maxSubscriptions` and `maxFilterEntries`.

### Methods (v1)

| Method | Params | Result |
|---|---|---|
| `device.info` | — | `connected`, `name`, `pubkey`, `firmwareVerCode`, `batteryMv`, `batteryPercent`, `radio{freqHz,bwHz,sf,cr,txPowerDbm}`, `channels` |
| `channels.list` | — | `{channels:[{index,name,isPublic,storageId}]}` |
| `contacts.list` | `{limit?}` (1–500, default 200) | `{contacts:[{pubkey,name,type,lastSeen}]}` |
| `events.subscribe` | `{events?, channel?, dataTypes?, pubkeys?, since?}` | `{subscriptionId}` |
| `events.unsubscribe` | `{subscriptionId}` | `{}` |
| `channel.sendText` | `{channel, text}` | `{queued:true}` |
| `channel.sendData` | `{channel, dataType, payload}` | `{queued:true}` |
| `direct.sendText` | `{pubkey, text}` | `{queued:true}` |
| `advert.send` | `{flood?}` (default `true`) | `{queued:true}` |
| `channels.join` | `{name}` (a hashtag channel, `#` + 1–31 of `a-z`, `0-9`, `-`) | `{index, name, created}` |

`channel` is the channel **name** (e.g. `#roadstr`) or its slot number as a string; in
`events.subscribe` it may also be the slot number as an integer. Names are matched
case-sensitively against `channels.list`; an unknown or ambiguous name is an error. `text` is
1–2000 characters. `payload` is base64 of 1–163 bytes. `dataType` is 1–65535.

### Events

| `type` | Fields |
|---|---|
| `channel.text` | `channel`, `channelIndex`, `senderName`, `senderKeyHex`, `text`, `sentAt`, `messageId`, `outgoing` |
| `channel.data` | `channel`, `channelIndex`, `dataType`, `payload` (base64), `snrDb`, `hops`, `outgoing` |
| `direct.text` | `pubkey`, `name`, `text`, `sentAt`, `messageId`, `outgoing` |
| `advert` | `pubkey`, `name`, `nodeType`, `lastSeen` |

Every event also has `receivedAt` (ISO-8601 UTC). `senderKeyHex`, `name` and `lastSeen` may be
null. `hops` is the flood hop count the radio reports (0: heard from the sender's own radio); it is
null for a packet that came by a direct path and for this app's own sends.

Filters are conjunctive. `events` lists event types (omitted: all four). `channel` limits
channel events to one channel and drops direct messages and adverts. `dataTypes` keeps only
channel data of those types. `pubkeys` keeps only direct messages and adverts from those keys.
`dataTypes` and `pubkeys` hold at most 32 entries each.

`outgoing` marks what this app sent: channel data after the radio accepted the command, chat
and direct text when the message is added to the conversation (before the radio answers). The
radio never confirms delivery of channel traffic; `queued` only means the command was accepted.

### Radio state

`hello.device.connected` and the `device` message say whether the radio can be used: connected,
with its channels loaded, so channel names resolve. While it is not, `events.subscribe` with a
`channel` answers `unknown_channel` like a missing channel would.

The server sends `{"type":"device","device":{…},"channels":[…]}` to every paired connection,
without a subscription, whenever that state, the node identity or the channel list changes after
`hello`. `device` has the fields of `hello.device`; `channels` is what `channels.list` returns.
Identical messages are not repeated. A client whose subscription failed waits for a `device`
message with `connected: true` and its channel listed, then subscribes again; it does not need to
reconnect or poll. Subscriptions themselves stay in place across a radio reconnect.

### Joining a hashtag channel

`channels.join` asks the user to add a hashtag channel. Its key is derived from the name
(`SHA-256(name)`, first 16 bytes), so no secret crosses the API, and only such channels can be
added. If a channel with that name and key exists, the answer comes at once with
`created: false`. Otherwise a dialog asks **“Add a channel?”**, naming the app and the channel,
with the same notification as pairing when MeshCore Open is in the background, and the same rate
limits (a key may repeat a request for the same channel 30 seconds after the previous one). On Add
the channel goes into the first free slot; a `device` message with the new channel list follows.

The answer can take up to two minutes, so a client should allow a longer timeout for this request
and keep its connection open; disconnecting withdraws the request. A client should ask once, when
`events.subscribe` fails with `unknown_channel` while `connected` is true, and not ask again after
`denied` until the user does something.

### Payloads are opaque

`channel.sendData` hands the payload to the radio unchanged and `channel.data` events carry the
received bytes unchanged. What they mean is up to the applications that share a `dataType`. For
example, Roadstr and Roadbeacon put road-event frames on `#roadstr` with `dataType` 65362 (0xFF52,
MeshCore's development range) and listen on 336 (0x0150), the value requested in MeshCore's
`docs/number_allocations.md`. That format is specified in its own repository
([road-events](https://github.com/jooray/roadbeacon/blob/main/nips/road-events.md)), not here.

### History and replay

The radio queues channel traffic while no phone is connected and drains that queue
destructively when this app connects. So that an app started later can still see channel data,
the server keeps a small archive while the API is enabled:

* Only received channel data is kept, never this app's own sends.
* Only `(channel, dataType)` pairs some paired app subscribed to with a `channel` are kept;
  without `dataTypes` that is every type on the channel. These interests survive restarts.
* At most 200 frames and 24 hours.
* Stored in the app's files under `local_api/`, which is excluded from Android backups.
* Removing an app forgets its interests and every frame only it wanted. **Clear stored radio
  data** in Settings empties the archive.

`events.subscribe` with `since` (ISO-8601, or epoch seconds or milliseconds) replays archived
frames that match the subscription **and** the client's own interests. The order is fixed: the
subscription ack, then the replayed frames oldest first, then live events. `since` is inclusive,
so a client that passes the `receivedAt` of the last frame it saw gets that frame again and should
deduplicate.

### Errors

| Code | Meaning |
|---|---|
| `unauthorized` | Handshake out of order, bad signature, pairing denied or timed out |
| `pairing_pending` | This key already has a dialog open |
| `rate_limited` | Too many sends, subscriptions or pairing requests |
| `too_many_clients` | Four apps are already connected |
| `bad_request` | Missing or malformed parameter, bad JSON, invalid public key |
| `unknown_method` | No such method |
| `not_connected` | The radio is not connected |
| `unsupported_firmware` | The radio firmware cannot send channel data (needs firmware ver 11) |
| `unknown_channel`, `ambiguous_channel`, `unknown_contact` | Lookup failed |
| `invalid_params` | `channels.join` with a name that is not a lowercase hashtag channel |
| `denied` | The user did not add the channel, or did not answer within two minutes |
| `no_free_slot` | The radio has no free channel slot |
| `channel_conflict` | A channel with that name but a different key exists |
| `payload_too_large` | Payload over 163 bytes |
| `invalid_data_type` | A `dataType` outside 1–65535 |
| `radio_error` | The radio refused the command or did not answer |
| `internal` | Anything else |

Close codes: 1001 server stopping, 1003 binary frame, 1009 message too big, 4001 handshake out of
order or timed out, 4003 rejected key, signature or pairing, or `revoked`, 4013 slow consumer or
too many clients. (4013 stands in for 1013, which `dart:io` will not send.)

## Limits

* Payload: 1–163 bytes, the BLE notification bound already used for image chunks. MeshCore's
  radio-side limit is 165.
* Sends: 30 per minute and one per 2 s per connection, plus the radio's own quiet-wait. A send the
  radio refuses (`not_connected`, `radio_error`) does not count.
* Connections: 4 paired at a time, plus 2 that have not finished pairing.
* Subscriptions: 16 per connection.
* Outbound queue: 256 KiB per connection not yet taken by the OS. A client that stops reading is
  closed with 4013 instead of growing memory.
* Inbound message: 16 KiB.
* Archive: 200 frames, 24 hours.

## Security

* Off by default; enabling it is a deliberate action, and every app is approved by the user with a
  visible name and key fingerprint before it can read or transmit.
* Loopback bind only, browsers refused. No UDP broadcast, no mDNS, no LAN.
* Only public keys are stored; private keys never leave the client apps. Message contents and
  keys are not logged.
* The API cannot change radio settings, contacts or keys. The only change to channels is adding a
  hashtag channel, after the user agrees in a dialog. Reads are limited to what a chat client
  shows.
* An approved app can transmit on the user's radio and read their messages. That is the same power
  the user's own chat app has; approval is the boundary, so the dialog states it and every grant is
  revocable.
* The server runs in the main isolate next to the connector, so it is only alive while the app
  process is (including the Android foreground service).

## Non-goals (v1)

* Remote/network access.
* Sending raw packets or bypassing the command queue.
* Channel/contact/radio administration, beyond asking the user to add a hashtag channel.
* Reading chat history (only live events and the channel-data archive).
* Image transfers as such: they are channel data with `dataType` 0xAE1C, which a client can
  subscribe to, but no reassembly is provided.

## Compatibility

`protocol: 1`. Additive fields are allowed without a version bump; a new method or event is
additive, a changed field meaning is not. Clients must ignore unknown fields and event types.

## Open questions for the maintainer

1. WebSocket on loopback plus key pairing versus an Android bound service (AIDL) with a runtime
   permission: WS is cross-platform and testable; AIDL gives the OS dialog and a verified package.
2. Whether a *read-only* grant (subscribe, no send) is worth a second switch per app.
3. Whether the API should run while the app is in the background only via the foreground service,
   or always while the process is alive.
4. Naming: `local API`, `radio bridge`, `companion API`.
