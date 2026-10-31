# MeshCore Open — development guide

MeshCore Open is a Flutter client for MeshCore radios over BLE, USB serial, or TCP. It supports direct/channel messaging, communities, region-scoped floods, channel image messages, maps, repeater administration, and optional on-device translation.

Read [AGENTS.md](AGENTS.md) for repository rules and [CONTRIBUTING.md](CONTRIBUTING.md) for contribution workflow. Target `dev` and discuss changes before submitting a PR.

## Commands

Use Flutter and Dart on PATH (or your SDK’s absolute path):

```bash
flutter pub get
flutter run
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter build apk --release
flutter build ios --release
flutter build web --release
```

The versioned web build uses `dart run build_pipe:build` (also `bun run build`). Web deployment pins Flutter 3.41.2; other CI jobs track stable. Read `pubspec.yaml` for current app version and dependencies rather than copying them into this guide.

For Linux, use `nix develop`; see [Linux with Nix](README.md#linux-with-nix) for the pinned SDK, native build checks, cache troubleshooting, and Sysprof host prerequisites.

## Architecture and important files

| Area | Source |
|---|---|
| Entry point, providers, themes and locale | `lib/main.dart` |
| Shared BLE/TCP/USB state and frame dispatch | `lib/connector/meshcore_connector.dart` |
| Protocol constants and builders | `lib/connector/meshcore_protocol.dart` |
| NUS UUIDs; reference device name prefixes | `lib/connector/meshcore_uuids.dart` |
| Serial marker/length framing | `lib/services/usb_serial_frame_codec.dart` |
| ACK tracking and retry scheduling | `lib/services/message_retry_service.dart` |
| Route scoring/history | `lib/services/path_history_service.dart` |
| Preferences and JSON stores | `lib/storage/` |
| Region list and channel/default assignments | `lib/storage/region_store.dart`, `lib/storage/channel_region_store.dart` |
| Translation models/inference | `lib/services/translation_service.dart` |
| Image models/inference and GRP_DATA chunks | `lib/services/image_codec_service.dart`, `lib/services/image_chunk_transport.dart` |
| Image reassembly and file persistence | `lib/services/received_image_store.dart`, `lib/services/received_image_blob_store_io.dart` |
| Material themes | `lib/theme/mesh_theme.dart` |
| Screens and reusable UI | `lib/screens/`, `lib/widgets/` |
| Localization | `lib/l10n/` (18 locales) |

`Provider`/`ChangeNotifier` drives UI state. `main.dart` wires `MeshTheme.light()` and `MeshTheme.dark()` and uses the saved theme preference. Its `MultiProvider` exposes `MeshCoreConnector`, `MessageRetryService`, `PathHistoryService`, `AppSettingsService`, `BleDebugLogService`, `AppDebugLogService`, `ChatTextScaleService`, `TranslationService`, `UiViewStateService`, `StorageService` (plain `Provider`), `MapTileCacheService`, `TimeoutPredictionService`, `ImageCodecService`, and `ReceivedImageStore`; screens read them with `Consumer<T>`, `context.watch<T>()`, or `context.read<T>()`.

Most JSON stores scope keys by the first 10 hex chars of the connected device's public key, so per-radio data stays isolated; some preferences, including the saved region-name list, are global. Model bundles, received images, and caches use files.

## Localization

Use `context.l10n` (from `lib/l10n/l10n.dart`) for all user-facing strings. `lib/l10n/app_en.arb` is the template; add new keys there first. Keys missing from other locales are written to `untranslated.json` (configured in `l10n.yaml`). Contact-type names live in `lib/l10n/contact_localization.dart`.

## Transport and platform notes

BLE scans by NUS service UUID, not advertised-name prefix. USB uses `[marker][length uint16 LE][payload]`, not COBS. TCP uses the same packet framing. See the [protocol reference](documentation/ble-protocol.md).

Web supports USB via Web Serial in Chrome only, over a secure origin. BLE is not available in the browser (the scanner shows a snackbar instead of scanning), and TCP is not supported on web (`tcp_transport_service_web.dart` always throws). Translation and image inference have no web backend.

Transport entry points on `MeshCoreConnector`: `connectTcp(host:, port:)`, `connectUsb(portName:, baudRate: 115200)`, and `listUsbPorts()`. On Linux, `lib/services/linux_ble_pairing_service.dart` falls back to `bluetoothctl` when BlueZ pairing prompts fail.

Android builds currently include ARM64 only and use Java 17. iOS targets 16.4. Read platform build files for current constraints; hardware testing remains necessary for transport changes.

## Documentation

Use the [feature index](documentation/README.md), [regions](documentation/regions.md), [image messages](documentation/image-messages.md), and [routing reference](documentation/routing-paths.md). Keep protocol details in the canonical reference rather than maintaining competing command tables.
