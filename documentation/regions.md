# Regions

Regions limit which configured repeaters forward a channel flood. They are routing scopes, not geographic fences or encryption keys. A region does not create a private channel: recipients still need the channel PSK, and forwarding depends on repeater configuration.

## Add and select regions

1. While connected, open Settings → Regions.
2. Add a region name manually, or choose Fetch from repeaters and add names from the results. Discovery queries nearby responding repeaters already present in your contacts; an empty result does not prove that no regions exist on the wider mesh.
3. Manual names accept lowercase letters, digits, and hyphens, up to 30 characters. Use the exact name configured by your local repeater operators.
4. Choose a Default region to use for channels without their own override. None means the app sets no default scope (the radio default region, if any, applies).
5. In channel chat, tap the title or landscape icon to select an override. The subtitle shows the effective region, with `(default)` when inherited from the app default or `(radio default)` when the radio's own default applies.

Tapping the selected region again, or choosing Clear region, removes the channel override. **If a default exists, clearing an override falls back to that default; it does not force an unscoped send.** To send a channel truly unscoped, pick **No region (unscoped)** instead (see below).

## Radio default region

Companion firmware v1.15.0 (firmware code 11) and later can store a default flood scope on the radio itself. The radio uses it for every flood sent without a scope override, by this app or any other app connected to the radio.

- On supported firmware, Settings → Regions shows **Radio default region**. Choosing a region writes it to the radio (`CMD_SET_DEFAULT_FLOOD_SCOPE`, 63); choosing None clears it. The app reads it back after connecting and after each change (`CMD_GET_DEFAULT_FLOOD_SCOPE`, 64 → `RESP_CODE_DEFAULT_FLOOD_SCOPE`, 28). The key written is derived the same way as for app regions.
- On older firmware the setting is hidden and these commands are never sent.

## Precedence and "No region"

The scope used for a channel flood is decided in this order:

1. **The channel's own assignment**: a region, or **No region (unscoped)**.
2. **The app default region**: a region, None, or **No region (unscoped)**.
3. **The radio default region**, when the app sets no scope (channel cleared and app default None).
4. Otherwise the flood is unscoped.

**No region (unscoped)** is offered only on firmware code 12 and later (companion v1.16.0+), where the app can override the radio default with `[54, 1]` around the send. On firmware code 11 the option is hidden: floods without a region use the radio default, and the channel region picker says so when a radio default is set. On firmware without a radio default, None and No region behave the same.

Replying with a message's original region (below) is a one-off override at step 1.

The saved region-name list is global to the app. Default and channel assignments are stored per connected radio identity. Removing a region from the list also clears matching assignments stored for every radio; it does not change repeater configuration or the radio default region stored on a radio.

## Regions displayed on messages

Channel text messages show a region label beside routing metadata when a region is known. The label appears in the message bubble only when the message has path data; message tracing does not otherwise need to be enabled. The message-path screen always shows the known region.

Outgoing messages retain the effective region used when they were sent. Changing a channel or default region does not relabel earlier messages. Region metadata persists with message history; older records may have no region.

Incoming region names are inferred from raw **transport-flood** packets by testing locally known names (saved regions, channel overrides, the app default, and the radio default region). The name is not sent as plain text in the packet. Unknown names, ambiguous matches, and messages without suitable raw transport metadata do not get a region label. `foo` and `#foo` are treated as the same candidate for matching.

**No label does not prove a message was unscoped.** It can mean that its region could not be identified. A region label is routing metadata, not proof of the sender’s location or identity.

## Reply using the original region

When you reply to a message with a non-empty known region, the reply banner selects that region by default. Tap its region chip to turn this off; the chip becomes crossed out. Sending then uses the channel’s effective region instead. Canceling the reply clears this temporary choice; it does not change the channel setting.

Example: a channel defaults to `arizona`, but you reply to a message labeled `phoenix`. The reply uses `phoenix` while the reply-region chip is selected. If you cross out the chip, it uses `arizona`.

If the original message has no known region, the reply uses the channel’s effective region. This behavior applies to channel text replies; it is not a region selector for direct messages or a claim that image messages expose the same region metadata.

## Technical reference

Scoped sends temporarily set the companion’s flood scope (`[54, 0, key]`, or `[54, 1]` for No region on firmware code 12+), send the message, and then clear the scope override (`buildSetFloodScopeFrame('')`, `[54, 0]`); they do not restore a previously set scope. Channels with no scope to apply send without any scope command, so the radio default region applies. Channel sends are serialized to prevent another channel from inheriting the temporary setting. Repeaters and companion firmware must support the relevant scope functionality.

See [channels](channels.md), [routing paths](routing-paths.md), and [protocol metadata](ble-protocol.md#regions-and-image-data).
