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
["contacts", "advert_send", "regions", "channels_join", "replay", "tx_path_data"]
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

Other features of the specification are not offered. A `path` on `channel.sendText` is refused
with `unsupported` (there is no `tx_path_text`), and so is a subscription to `packet.raw`.

Sends go through the same path as the chat screen: the quiet wait before transmitting, the
channel's flood scope and the radio's command acknowledgement. Texts and channel data sent from
the chat screen also reach subscribed apps as outgoing events.

`hello.server` is `{"name": "meshcore-open", "version": "<app version>"}`.

## Lifetime

The server runs in the app process next to the radio connection. On Android it keeps running in
the background while the foreground service holds the connection. When the process ends, the API
stops with it.
