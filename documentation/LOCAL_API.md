# Local API: letting other apps use the radio

A MeshCore radio takes one connection, and MeshCore Open holds it. The local API lets other apps
on the same device share that connection: they subscribe to the traffic they care about and send
through MeshCore Open, while chat keeps working. It is off by default and not available on web.
It was proposed in zjs81/meshcore-open#616.

The protocol is the **MeshCore Local API**, protocol 1. Its specification, test vectors and client
libraries are at [github.com/jooray/meshcore-local-api](https://github.com/jooray/meshcore-local-api)
([SPEC.md](https://github.com/jooray/meshcore-local-api/blob/main/SPEC.md)). Messages, methods,
events, errors and limits are defined there. This page only covers what is specific to MeshCore
Open.

## Turning it on

Open **Settings → Local API** and switch it on. The server then listens on
`ws://127.0.0.1:8787/api/v1`, on loopback only. The screen shows the address and the list of
allowed apps. Switching the API off closes the port and every open connection.

Builds made with `--dart-define=LOCAL_API_ENABLED=true` have it on until the user changes the
setting. The test builds use this.

## Pairing

The first time an app connects with a key MeshCore Open has not seen, a dialog asks **Allow
connection?** It shows the name the app gave itself and the fingerprint of its key, so the user
can compare it with what the app shows, and warns that the app will be able to read messages and
transmit on the radio. Allow stores the key. Deny, closing the dialog, or two minutes without an
answer refuse it.

If MeshCore Open is in the background when a request arrives, a system notification names the
app, and tapping it opens the dialog. The app has to keep its connection open meanwhile.

Allowed apps are listed under **Allowed apps** with their fingerprint and the date they were
paired. Removing one forgets its key, closes its connections with reason `revoked` and drops the
channel data kept only for it. Its next connection asks again.

A key is identified by its decoded bytes, so the same key written in the other base64 alphabet is
the same app.

## Adding a hashtag channel

`channels.join` opens a dialog **Add a channel?** that names the app and the channel, with the
same notification when MeshCore Open is in the background. On Add the channel goes into the first
free slot on the radio.

## Archive

So that an app started later still gets channel data that arrived while it was not running,
MeshCore Open keeps received channel data for the `(channel, dataType)` pairs some allowed app has
subscribed to, at most 200 frames and 24 hours. It is stored in the app's support directory under
`local_api/archive.json`, a directory that is excluded from Android backups. **Clear stored radio
data** on the Local API screen empties it.

## What this server offers

`hello.capabilities` is:

```json
["contacts", "advert_send", "regions", "channels_join", "replay", "tx_path_data", "rx_meta", "rx_path",
 "rx_scope", "rx_queued", "tx_now"]
```

* `contacts`: `contacts.list`, `direct.sendText`, the `direct.text` and `advert` events and the
  `pubkeys` filter. `direct.sendText` also takes a unique key prefix of 12 or more hex characters.
* `advert_send`: `advert.send`.
* `regions`: `regions.list`, `regions.resolve` and `region` on `channel.sendText` and
  `channel.sendData`. The catalogue is `assets/mesh_regions.json`, an editable list of
  flood-scope areas with a centre and a radius, shown on the Local API screen as suggested
  regions. A `region` must be a name from that catalogue or a region the user saved in
  **Settings → Regions**. The names are suggestions: they only work where repeaters are
  configured with the same names.
* `channels_join`: `channels.join`, always confirmed by the user in the dialog above.
* `replay`: the archive above and `since` in `events.subscribe`. Only channel data is archived,
  not texts.
* `tx_path_data`: `path` and `pathHashSize` on `channel.sendData`. `"path": ""` sends zero-hop and
  a non-empty path sends direct along it, both through `CMD_SEND_CHANNEL_DATA` with a packed
  `path_len`. Every firmware that can send channel data (ver 11 and newer) takes it, so the
  capability is always listed; on older firmware `channel.sendData` fails with
  `unsupported_firmware` whether or not it has a path.
* `rx_meta` and `rx_path`: received `channel.data` events carry `routeType` (`flood`, `direct`,
  `tflood`, `tdirect`), `rssiDbm`, `path` (hex, repeater hashes in the order the packet
  travelled) and `pathHashSize`, next to `snrDb` and `hops`. The decrypted frame
  (`RESP_CODE_CHANNEL_DATA_RECV`) only says flood or not, with the hop count; the rest comes from
  the raw RX log push (`PUSH_CODE_LOG_RX_DATA`, 0x88) the radio sends for every packet it hears.
  The server decrypts that packet with the channel key and pairs it with the frame by plaintext,
  keeping only the first copy, which is the one the firmware delivers. Frames drained from the
  radio's offline queue were heard while no app was connected, so they have `routeType` (`flood`
  or `direct`), `hops` and `pathHashSize` from the frame but no `path` or `rssiDbm`. A packet sent
  zero-hop arrives with `routeType: "direct"`, `hops: null` and `path: ""`; a direct packet that
  came along a path also ends with an empty path, since each hop removes its own hash. Channel
  texts and direct texts do not carry these fields yet.
  `receivedAt` of a frame paired with its raw packet is the time that push arrived, which is when
  the radio heard it; otherwise it is the time the app fetched the frame.
* `rx_scope`: a `tflood` or `tdirect` event carries `transportCode`, the packet's first transport
  code (`code[0]`, little-endian) as an integer, and `scope`, the flood-scope name (without `#`)
  whose key gives that code, when exactly one of the regions the app knows does (saved regions,
  channel scopes and the radio's default scope). Both come from the raw packet, so frames from
  the offline queue have neither.
* `rx_queued`: `queued: true` on a `channel.data` event the radio held in its offline queue while
  no app was reading it: drained after a connect, before the first `RESP_CODE_NO_MORE_MESSAGES`,
  and not heard in the raw RX log meanwhile. Its `receivedAt` is the time it was fetched, not
  when it was heard. Live events have no `queued` field. Channel data that arrives while the app
  is still loading the channel list after a connect is held and then delivered, whatever the
  image-message setting.
* `tx_now`: `"priority": "now"` on `channel.sendData` skips the post-receive back-off and the wait
  for a quiet radio (the firmware still listens before it talks) for packets of at most 40 bytes
  on air, counting the transport codes for every flood; a direct or zero-hop priority send also
  does not queue behind other channel sends. A larger packet is sent normally. `"priority":
  "normal"` or no `priority` is the default; another value is `bad_request`. When `priority` was
  given, the result says which one applied. Every `channel.sendData` result carries `sentAt`, the
  time the radio acknowledged the command:
  `{"queued": true, "sentAt": "2026-11-26T12:00:12.215Z", "priority": "now"}`.

Other features of the specification are not offered. A `path` on `channel.sendText` is refused
with `unsupported` (there is no `tx_path_text`), and so is a subscription to `packet.raw`.

`hello.limits` has `minSendGapExemptBytes: 32`: a `channel.sendData` payload of at most 32 bytes
may follow the previous send of the same connection closer than `minSendGapMs`, so an
acknowledgement and a command can leave 300 ms apart. It still counts in `sendsPerMinute`.

Sends go through the same path as the chat screen: the quiet wait before transmitting, the
channel's flood scope and the radio's command acknowledgement. Texts and channel data sent from
the chat screen also reach subscribed apps as outgoing events.

`hello.server` is `{"name": "meshcore-open", "version": "<app version>"}`.

## Traffic log

Every send through the API (`channel.sendData`, `channel.sendText`, `direct.sendText`), every
received channel-data frame and every change of the radio link writes one line: UTC time, `tx`,
`rx` or `link`, then `key=value` pairs, for example

```
2026-11-26T12:00:09.010Z rx type=channel.data ch=#roadstr dataType=336 len=21 route=flood hops=2 path=a10b hashSize=1 snr=-7.25 rssi=-101 receivedAt=2026-11-26T12:00:08.950Z clients=Roadbeacon
2026-11-26T12:00:12.215Z tx type=channel.data ch=#roadstr dataType=336 len=13 air=21 route=zero-hop path= pathLen=0 hashSize=1 prio=now req=2026-11-26T12:00:12.104Z lockMs=0 quietMs=0 ackMs=111 client=Roadbeacon result=ok
2026-11-26T12:05:00.000Z link state=down from=ready reason=transport_disconnected
```

`clients` names the apps that got the event (`-` for none); `result` is `ok` or the error code.
An `rx` line also has `queued=true`, `transport` and `scope` when the event carries them. A
`tx` line for channel data has the request time `req`, `lockMs` (waiting behind other channel
sends and setting the flood scope), `quietMs` (back-off and quiet wait), `ackMs` (request to the
radio's acknowledgement), the on-air size `air` and the path length `pathLen` in hops. `link` states
are `down`, `syncing` (connected, channel list loading) and `ready`.
The lines go to the app debug log when it is on, and to `local_api/traffic.log` (two files of
at most 512 KB) in the app's external files directory on Android, so
`adb pull /sdcard/Android/data/com.meshcore.meshcore_open/files/local_api/traffic.log` reads it
from a release build. It holds no payloads or texts.

## Lifetime

The server runs in the app process next to the radio connection. On Android it keeps running in
the background while the foreground service holds the connection. When the process ends, the API
stops with it.
