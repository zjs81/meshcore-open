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

mkdir -p "$temporary/project/scripts/appimage"
touch "$temporary/project/pubspec.lock"
cp "$project/scripts/appimage/Dockerfile" "$temporary/project/scripts/appimage/"

# shellcheck disable=SC2329
podman() {
  case "$1" in
    info) [[ "$mock_engine" == podman ]] ;;
    image) return 0 ;;
    run) printf '%s\n' "$@" > "$temporary/container-arguments" ;;
    *) return 1 ;;
  esac
}

# shellcheck disable=SC2329
docker() {
  case "$1" in
    info|image) return 0 ;;
    run) printf '%s\n' "$@" > "$temporary/container-arguments" ;;
    *) return 1 ;;
  esac
}

mock_engine=podman
package_container "$temporary/project" "$temporary/output" \
  "$project/scripts/appimage-tools.json" "$temporary/container-cache"
grep -Fxq -- '--userns=keep-id' "$temporary/container-arguments"
grep -Fxq -- "$(id -u):$(id -g)" "$temporary/container-arguments"

mock_engine=docker
package_container "$temporary/project" "$temporary/output" \
  "$project/scripts/appimage-tools.json" "$temporary/container-cache"
assert_fails grep -Fxq -- '--userns=keep-id' "$temporary/container-arguments"
grep -Fxq -- "$(id -u):$(id -g)" "$temporary/container-arguments"
unset -f podman docker

# shellcheck disable=SC2329
readelf() {
  printf '%s\n' "$mock_interpreter"
}

# shellcheck disable=SC2329
getconf() {
  printf 'glibc %s\n' "$mock_glibc"
}

mock_interpreter=/lib64/ld-linux-x86-64.so.2
mock_glibc=2.39
assert_fails requires_container_rebuild "$temporary/bundle/meshcore_open" 2.39
mock_glibc=2.43
requires_container_rebuild "$temporary/bundle/meshcore_open" 2.39
mock_interpreter=/nix/store/glibc/lib/ld-linux-x86-64.so.2
mock_glibc=2.39
requires_container_rebuild "$temporary/bundle/meshcore_open" 2.39
unset -f readelf getconf

printf 'AppImage packaging contract tests passed\n'