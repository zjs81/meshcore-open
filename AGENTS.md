# Repository Guidelines

## Project Structure & Module Organization
- Core Flutter code is in `lib/`, with BLE protocol definitions in `lib/connector/meshcore_protocol.dart` and BLE transport/state in `lib/connector/meshcore_connector.dart`.
- UI lives in `lib/screens/` and `lib/widgets/`, models in `lib/models/`, tests in `test/`, and platform runners in `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`.

## BLE Frames & Protocol Notes
- Nordic UART Service (NUS) UUIDs: Service `6e400001-b5a3-f393-e0a9-e50e24dcca9e`, RX `6e400002-b5a3-f393-e0a9-e50e24dcca9e`, TX `6e400003-b5a3-f393-e0a9-e50e24dcca9e`.
- Discovery: scans for the Nordic UART Service UUID; known name prefixes are reference values, not filters.
- Frames are capped at `maxFrameSize = 172` bytes; byte 0 is the command/response/push code. I/O is `MeshCoreConnector.sendFrame` and `MeshCoreConnector.receivedFrames`.
- Command codes (to device): `cmdAppStart`=1, `cmdSendTxtMsg`=2, `cmdSendChannelTxtMsg`=3, `cmdGetContacts`=4, `cmdGetDeviceTime`=5, `cmdSetDeviceTime`=6, `cmdSendSelfAdvert`=7, `cmdSetAdvertName`=8, `cmdAddUpdateContact`=9, `cmdSyncNextMessage`=10, `cmdSetRadioParams`=11, `cmdSetRadioTxPower`=12, `cmdResetPath`=13, `cmdSetAdvertLatLon`=14, `cmdRemoveContact`=15, `cmdShareContact`=16, `cmdExportContact`=17, `cmdImportContact`=18, `cmdReboot`=19, `cmdSendLogin`=26, `cmdGetChannel`=31, `cmdSetChannel`=32, `cmdGetStats`=56, `cmdSendAnonReq`=57, `cmdSetAutoAddConfig`=58, `cmdGetAutoAddConfig`=59, `cmdSetPathHashMode`=61, `cmdSendChannelData`=62.
- Response codes (from device): `respCodeOk`=0, `respCodeErr`=1, `respCodeContactsStart`=2, `respCodeContact`=3, `respCodeEndOfContacts`=4, `respCodeSelfInfo`=5, `respCodeSent`=6, `respCodeContactMsgRecv`=7, `respCodeChannelMsgRecv`=8, `respCodeCurrTime`=9, `respCodeNoMoreMessages`=10, `respCodeContactMsgRecvV3`=16, `respCodeChannelMsgRecvV3`=17, `respCodeChannelInfo`=18, `respCodeStats`=24, `respCodeAutoAddConfig`=25, `respCodeChannelDataRecv`=27.
- Push codes (async): `pushCodeAdvert`=0x80, `pushCodePathUpdated`=0x81, `pushCodeSendConfirmed`=0x82, `pushCodeMsgWaiting`=0x83, `pushCodeLoginSuccess`=0x85, `pushCodeLoginFail`=0x86, `pushCodeLogRxData`=0x88, `pushCodeNewAdvert`=0x8A.
- Device info: `cmdAppStart` triggers `respCodeSelfInfo` with tx power, pubkey, lat/lon, telemetry flags, radio params, and node name (see offsets in `lib/connector/meshcore_connector.dart`).
- Radio/time helpers: radio settings come from self-info; companion stats use `cmdGetStats` → `respCodeStats`; `cmdGetDeviceTime` → `respCodeCurrTime`; `cmdSetDeviceTime` updates device time.
- Reboot: companion Settings calls `rebootDevice()` → `buildRebootFrame()`; remote repeater management uses CLI `reboot`.
- Companion radio format: `cmdSendTxtMsg` expects `[cmd][txt_type][attempt][timestamp x4][pub_key_prefix x6][text...]` (no flags/full pubkey). CLI commands use `txtTypeCliData` in the same format, and the app maps `forceFlood` to attempt `3` when sending.
- Group text packets (`PAYLOAD_TYPE_GRP_TXT`): payload is `[channel_hash (1)][MAC (2)][encrypted data...]`. Decrypted data layout is `[timestamp x4][txt_type][text...]` where text is `"sender: message"` (see MeshCore `BaseChatMesh::sendGroupMessage`). Sender identity is not in the payload; use `PUSH_CODE_LOG_RX_DATA` raw packet path bytes for origin hash when available.
- Routing hashes are public-key prefixes. Firmware negotiation currently supports 1–3 bytes per hop; packed path metadata must be decoded before counting or reversing hops. Use per-path hash width, not a fixed one-byte stride. See [routing paths](documentation/routing-paths.md).
- Regions: channel messages retain their send region; incoming regions are resolved from raw transport-flood codes against locally known names. Replies use a known original region by default, with an opt-out chip. See [regions](documentation/regions.md).
- Images: channel GRP_DATA framing is defined in `lib/services/image_chunk_transport.dart`. Native codec/model requirements are documented in [image messages](documentation/image-messages.md).

## Build, Test, and Development Commands
- Commands assume Flutter/Dart on PATH (or use your SDK's absolute path); see [CLAUDE.md](CLAUDE.md) for the full list.
- `flutter pub get` installs dependencies; `flutter run` launches the app; `flutter build apk --release` / `flutter build ios --release` produce release builds.
- CI checks: `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings`, and `flutter test`.

## Coding Style & Naming Conventions
- Follow `flutter_lints`, use `lowerCamelCase`/`UpperCamelCase`/`snake_case`, prefer `StatelessWidget` + `Consumer`, and use `const` constructors.
- Material widgets only (no Cupertino); center app bar titles (`centerTitle: true`); prefix private members with `_`.
- Keep screens simple, keep the main screens open and read-only when the radio disconnects (see `documentation/offline-mode.md`), and avoid premature abstractions (don't add a helper until it is needed in 3+ places).
- Avoid unnecessary comments, feature flags, and backwards-compatibility shims.

## Testing Guidelines
- Tests use `flutter_test`; add `*_test.dart` under `test/` and run `flutter test` before UI/protocol changes.

## Commit & Pull Request Guidelines
- Keep commit subjects short and action-focused; PRs should describe behavior changes, link issues, include screenshots for UI changes, and call out BLE protocol changes explicitly.

## Documentation maintenance

Keep user instructions in `documentation/` and use [ble-protocol.md](documentation/ble-protocol.md) as the canonical protocol reference. Update affected guides, feature limitations, and screenshots when changing user-facing behavior. Read [CONTRIBUTING.md](CONTRIBUTING.md) for branch and review requirements.
