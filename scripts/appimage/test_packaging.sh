#!/usr/bin/env bash
set -euo pipefail

project="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$project/scripts/build_appimage.sh"
temporary="$(mktemp -d)"
trap 'rm -rf "$temporary"' EXIT

assert_fails() {
  if "$@" >"$temporary/error" 2>&1; then
    printf 'Expected failure: %s\n' "$*" >&2
    exit 1
  fi
}

assert_fails packaging_enabled Debug
assert_fails packaging_enabled Profile
packaging_enabled Release
MESHCORE_BUILD_APPIMAGE=0 assert_fails packaging_enabled Release
assert_fails check_bundle "$temporary/missing"

mkdir -p "$temporary/bundle/lib" "$temporary/bundle/data/flutter_assets"
touch "$temporary/bundle/meshcore_open" "$temporary/bundle/lib/libapp.so" \
  "$temporary/bundle/data/icudtl.dat"
chmod +x "$temporary/bundle/meshcore_open"
check_bundle "$temporary/bundle"
rm "$temporary/bundle/lib/libapp.so"
assert_fails check_bundle "$temporary/bundle"
touch "$temporary/bundle/lib/libapp.so"
MESHCORE_BUILD_APPIMAGE=0 bash "$project/scripts/build_appimage.sh" \
  "$project" /missing "$temporary/output" Release x64
bash "$project/scripts/build_appimage.sh" "$project" /missing "$temporary/output" Debug x64
[[ ! -d "$temporary/output" ]]
assert_fails bash "$project/scripts/build_appimage.sh" \
  "$project" /missing "$temporary/output" Release arm64

stage_bundle "$project" "$temporary/bundle" "$temporary/AppDir with spaces"
check_bundle "$temporary/AppDir with spaces/usr/bin"
[[ -x "$temporary/AppDir with spaces/AppRun" ]]
[[ -f "$temporary/AppDir with spaces/usr/share/applications/com.meshcore.meshcore_open.desktop" ]]

printf 'fixture\n' > "$temporary/input"
checksum="$(sha256sum "$temporary/input")"
checksum="${checksum%% *}"
download_verified "file://$temporary/input" "$checksum" "$temporary/cache/tool"
download_verified 'https://invalid.example/offline' "$checksum" "$temporary/cache/tool"
assert_fails download_verified "file://$temporary/input" \
  '0000000000000000000000000000000000000000000000000000000000000000' "$temporary/cache/invalid"
[[ ! -e "$temporary/cache/invalid" ]]
printf 'corruption\n' >> "$temporary/cache/tool"
assert_fails download_verified "file://$temporary/input" "$checksum" "$temporary/cache/tool"

printf 'AppImage packaging contract tests passed\n'