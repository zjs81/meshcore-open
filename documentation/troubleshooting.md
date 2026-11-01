# Connection and Feature Troubleshooting

## BLE radio not found

Confirm that Bluetooth is enabled, the app has Bluetooth permissions, and the radio is running companion firmware advertising the Nordic UART Service UUID. Custom names are supported. Stop other clients that may already hold the connection, bring the radio closer, and scan again. Older Android systems may require location permission for BLE scanning; the app does not use phone GPS for node locations.

On Linux, check that BlueZ is running and the adapter is enabled. Pairing may fall back to `bluetoothctl`; complete the system pairing prompt when requested. Include the pairing error and app log in a bug report.

## USB connection fails

Use a data-capable cable and a supported companion serial firmware. Close terminal programs or other apps using the port. On Linux, check port ownership and the serial-access group required by your distribution. For missing devices, check drivers and OS enumeration. For permission denied, busy, or detached errors, fix the reported cause and refresh the port list.

## Browser connection fails

Use Chrome (or a Chromium browser that identifies as Chrome) and HTTPS (or an appropriate local development secure context). Allow device access through the browser’s serial port chooser. The web build connects over USB via Web Serial only; BLE scanning is not available in the browser and TCP is not supported on web. Native model inference is unavailable on web.

## Unexpected disconnect

BLE and TCP retry an unexpected disconnect with exponential backoff; manual disconnects do not trigger reconnect. USB requires reconnection through its connection screen. If a TCP companion still drops in the background on Android, allow background activity (App Settings → Notifications → **Background Activity**) and check the phone's Wi-Fi power-saving settings. Navigation returns to the scanner when a connection is lost. If reconnect continues to fail, check power, firmware, adapter state, and competing clients.

## Feature unavailable or no data

Companion stats require firmware code 8+, and image channel data requires code 11+. Image inference also needs an enabled, complete model bundle and adequate memory. A missing incoming region label can mean unknown or unavailable metadata, not an unscoped message. See [images](image-messages.md), [regions](regions.md), and [radio stats](radio-statistics.md).

## Linux AppImage build or launch fails

Linux Release builds package an x86_64 AppImage automatically. Missing
packaging dependencies, failed downloads or checksum mismatches fail the build;
see [Linux AppImage prerequisites](../README.md#linux-appimage). A checksum
mismatch must not be bypassed: remove the named corrupted cache file and retry.
Tools are pinned in `scripts/appimage-tools.json`; cached tools can be reused
offline, but dependency downloads and first-time container setup still need
network access. Use `MESHCORE_BUILD_APPIMAGE=0 flutter build linux --release`
for a bundle-only build, including ARM builds.

For a Nix build or a host with glibc newer than the pinned Ubuntu baseline,
verify that your user can access Podman or Docker without interactive
privilege escalation. The image is rebuilt in Ubuntu, not made from the
host-linked executable. The regular native bundle remains available if
packaging fails. Custom targets, obfuscation and split-debug-info are not
supported by the container rebuild.

The initial compatibility baseline is Ubuntu 24.04. The host must provide
compatible glibc, graphics drivers, and X11/XWayland; Bluetooth still requires
BlueZ and USB still requires device permissions. If FUSE mounting is
unavailable, try the image's `--appimage-extract-and-run` option, or extract
with `--appimage-extract` and launch `squashfs-root/AppRun`. On NixOS, the
distribution's `appimage-run` support may be required. Include
`appimage-audit.txt` and `appimage-tools.json` from the Release output directory
when reporting packaging failures. Never include private message/model data.

## Useful bug-report details

Include app version, OS/device, radio board and firmware version, transport, reproduction steps, expected behavior, and the exact error. Where relevant, include entries from the **Companion Debug Log** in Settings (frame traffic for BLE, TCP, and USB) or the **App Debug Log**. The App Debug Log only records after you enable App Settings → Debug → **App Debug Logging**. Inspect logs before sharing: they can contain message content, identifiers, and location data.

Run the relevant automated tests when reporting a source/build failure. Submit reports to the [project issue tracker](https://github.com/zjs81/meshcore-open/issues).
