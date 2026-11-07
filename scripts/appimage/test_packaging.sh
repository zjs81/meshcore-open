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
[[ "$(canonical_arch x64)" == x86_64 ]]
[[ "$(canonical_arch aarch64)" == aarch64 ]]
[[ "$(canonical_arch arm64)" == aarch64 ]]
assert_fails canonical_arch riscv64
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
  "$project" /missing "$temporary/output" Release riscv64
# shellcheck disable=SC2218
jq -e '.flutter.source_revision == "c197ca5199e9ee5661e865596c9c07294dfab51c" and
  (.tools.x86_64.linuxdeploy.sha256 | length == 64) and
  (.tools.aarch64.linuxdeploy.sha256 | length == 64) and
  (.tools.aarch64.appimagetool.sha256 | length == 64) and
  (.tools.aarch64.runtime.sha256 | length == 64)' \
  "$project/scripts/appimage-tools.json" >/dev/null

stage_bundle "$project" "$temporary/bundle" "$temporary/AppDir with spaces"
check_bundle "$temporary/AppDir with spaces/usr/bin"
[[ -x "$temporary/AppDir with spaces/AppRun" ]]
[[ -f "$temporary/AppDir with spaces/usr/share/applications/com.meshcore.meshcore_open.desktop" ]]

printf 'fixture\n' > "$temporary/input"
checksum="$(sha256sum "$temporary/input")"
checksum="${checksum%% *}"
# shellcheck disable=SC2218
download_verified "file://$temporary/input" "$checksum" "$temporary/cache/tool"
# shellcheck disable=SC2218
download_verified 'https://invalid.example/offline' "$checksum" "$temporary/cache/tool"
assert_fails download_verified "file://$temporary/input" \
  '0000000000000000000000000000000000000000000000000000000000000000' "$temporary/cache/invalid"
[[ ! -e "$temporary/cache/invalid" ]]
printf 'corruption\n' >> "$temporary/cache/tool"
assert_fails download_verified "file://$temporary/input" "$checksum" "$temporary/cache/tool"

# shellcheck disable=SC2329
download_verified() {
  printf '%s %s\n' "$1" "$3" >> "$temporary/tool-selection"
  mkdir -p "$(dirname "$3")"
  : > "$3"
}

prepare_tools "$project/scripts/appimage-tools.json" "$temporary/tools-x64" x86_64
prepare_tools "$project/scripts/appimage-tools.json" "$temporary/tools-arm64" aarch64
grep -Fq 'linuxdeploy-x86_64.AppImage' "$temporary/tool-selection"
grep -Fq 'appimagetool-x86_64.AppImage' "$temporary/tool-selection"
grep -Fq 'runtime-x86_64' "$temporary/tool-selection"
grep -Fq 'linuxdeploy-aarch64.AppImage' "$temporary/tool-selection"
grep -Fq 'appimagetool-aarch64.AppImage' "$temporary/tool-selection"
grep -Fq 'runtime-aarch64' "$temporary/tool-selection"
unset -f download_verified

mkdir -p "$temporary/project/scripts/appimage"
touch "$temporary/project/pubspec.lock"
cp "$project/scripts/appimage/Dockerfile" "$temporary/project/scripts/appimage/"

# shellcheck disable=SC2329
jq() {
  case "$*" in
    *'.flutter.version'*) printf '3.47.9\n' ;;
    *'.ubuntu'*) printf 'ubuntu:24.04\n' ;;
    *) return 1 ;;
  esac
}

# shellcheck disable=SC2329
podman() {
  # shellcheck disable=SC2317
  case "$1" in
    info) [[ "$mock_engine" == podman ]] ;;
    image) return 0 ;;
    run) printf '%s\n' "$@" > "$temporary/container-arguments" ;;
    *) return 1 ;;
  esac
}

# shellcheck disable=SC2329
docker() {
  # shellcheck disable=SC2317
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
unset -f jq podman docker

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

mkdir -p "$temporary/audit-appdir/usr/bin" "$temporary/audit-appdir/usr/lib" \
  "$temporary/host" "$temporary/fakebin"
cp "$(type -P true)" "$temporary/audit-appdir/usr/bin/fixture"
printf 'test library\n' > "$temporary/host/libgpg-error.so.0.37.0"
ln -s libgpg-error.so.0.37.0 "$temporary/host/libgpg-error.so.0"
printf 'host display library\n' > "$temporary/host/libwayland-client.so.0"
cat > "$temporary/fakebin/ldd" <<'EOF'
#!/usr/bin/env bash
if [[ "${MESHCORE_TEST_LDD_VERSION_FAILURE:-0}" == 1 ]]; then
  printf "%s: /lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.39' not found (required by %s)\n" \
    "$MESHCORE_TEST_APPDIR/usr/bin/fixture" "$MESHCORE_TEST_APPDIR/usr/bin/fixture"
  exit 1
fi
if [[ -e "$MESHCORE_TEST_HOST_WAYLAND" ]]; then
  printf 'libwayland-client.so.0 => %s (0x0)\n' "$MESHCORE_TEST_HOST_WAYLAND"
else
  printf 'libwayland-client.so.0 => not found\n'
fi
if [[ -e "$MESHCORE_TEST_APPDIR/usr/lib/libgpg-error.so.0" ]]; then
  printf 'libgpg-error.so.0 => %s/usr/lib/libgpg-error.so.0 (0x0)\n' "$MESHCORE_TEST_APPDIR"
else
  printf 'libgpg-error.so.0 => %s (0x0)\n' "$MESHCORE_TEST_HOST_LIBRARY"
fi
EOF
chmod +x "$temporary/fakebin/ldd"
MESHCORE_TEST_APPDIR="$temporary/audit-appdir" \
  MESHCORE_TEST_HOST_LIBRARY="$temporary/host/libgpg-error.so.0" \
  MESHCORE_TEST_HOST_WAYLAND="$temporary/host/libwayland-client.so.0" \
  PATH="$temporary/fakebin:$PATH" \
  bash "$project/scripts/appimage/dependencies.sh" bundle \
  "$temporary/audit-appdir" "$temporary/dependency-audit.log"
[[ -L "$temporary/audit-appdir/usr/lib/libgpg-error.so.0" ]]
[[ -f "$temporary/audit-appdir/usr/lib/libgpg-error.so.0.37.0" ]]
[[ ! -e "$temporary/audit-appdir/usr/lib/libwayland-client.so.0" ]]
grep -Fq 'libgpg-error.so.0 =>' "$temporary/dependency-audit.log"
grep -Fq 'libwayland-client.so.0 =>' "$temporary/dependency-audit.log"

mkdir -p "$temporary/audit AppDir/usr/bin" "$temporary/audit AppDir/usr/lib"
cp "$temporary/audit-appdir/usr/bin/fixture" "$temporary/audit AppDir/usr/bin/fixture"
MESHCORE_TEST_APPDIR="$temporary/audit AppDir" \
  MESHCORE_TEST_HOST_LIBRARY="$temporary/host/libgpg-error.so.0" \
  MESHCORE_TEST_HOST_WAYLAND="$temporary/host/libwayland-client.so.0" \
  PATH="$temporary/fakebin:$PATH" \
  bash "$project/scripts/appimage/dependencies.sh" bundle \
  "$temporary/audit AppDir" "$temporary/dependency-audit-spaces.log"
[[ -L "$temporary/audit AppDir/usr/lib/libgpg-error.so.0" ]]
grep -Fq 'libgpg-error.so.0 =>' "$temporary/dependency-audit-spaces.log"

mkdir -p "$temporary/audit-missing/usr/bin" "$temporary/audit-missing/usr/lib"
cp "$temporary/audit-appdir/usr/bin/fixture" "$temporary/audit-missing/usr/bin/fixture"
MESHCORE_TEST_APPDIR="$temporary/audit-missing" \
  MESHCORE_TEST_HOST_LIBRARY="$temporary/host/libgpg-error.so.0" \
  MESHCORE_TEST_HOST_WAYLAND="$temporary/host/missing-libwayland-client.so.0" \
  PATH="$temporary/fakebin:$PATH" \
  assert_fails bash "$project/scripts/appimage/dependencies.sh" audit \
  "$temporary/audit-missing" "$temporary/dependency-rejected.log"
grep -Fq 'unexpected host dependency' "$temporary/dependency-rejected.log"
grep -Fq 'libwayland-client.so.0 => NOT PRESENT ON AUDIT HOST [host interface]' \
  "$temporary/dependency-rejected.log"
MESHCORE_TEST_APPDIR="$temporary/audit-appdir" \
  MESHCORE_TEST_HOST_LIBRARY="$temporary/host/libgpg-error.so.0" \
  MESHCORE_TEST_HOST_WAYLAND="$temporary/host/libwayland-client.so.0" \
  MESHCORE_TEST_LDD_VERSION_FAILURE=1 \
  PATH="$temporary/fakebin:$PATH" \
  assert_fails bash "$project/scripts/appimage/dependencies.sh" audit \
  "$temporary/audit-appdir" "$temporary/dependency-version-rejected.log"
grep -Fq "version 'GLIBC_2.39' not found" "$temporary/error"

mkdir -p "$temporary/launcher-appdir/usr/bin"
cp "$project/scripts/appimage/AppRun" "$temporary/launcher-appdir/AppRun"
cat > "$temporary/launcher-appdir/usr/bin/meshcore_open" <<'EOF'
#!/usr/bin/env bash
env | sort
EOF
chmod +x "$temporary/launcher-appdir/usr/bin/meshcore_open"
env APPDIR="$temporary/launcher-appdir" \
  GIO_EXTRA_MODULES=/host/gio/modules GIO_MODULE_DIR=/host/gio/modules \
  GI_TYPELIB_PATH=/host/girepository GTK_PATH=/host/gtk/modules \
  GTK_MODULES=host-module GDK_PIXBUF_MODULE_FILE=/host/pixbuf.loaders \
  bash "$temporary/launcher-appdir/AppRun" > "$temporary/launcher-environment"
for variable in GIO_EXTRA_MODULES GIO_MODULE_DIR GI_TYPELIB_PATH GTK_PATH \
  GTK_MODULES GDK_PIXBUF_MODULE_FILE; do
  if grep -q "^$variable=" "$temporary/launcher-environment"; then
    printf 'Host plugin environment leaked through AppRun: %s\n' "$variable" >&2
    exit 1
  fi
done

printf 'AppImage packaging contract tests passed\n'