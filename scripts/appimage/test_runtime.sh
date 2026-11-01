#!/usr/bin/env bash
set -euo pipefail

image="$(realpath "$1")"
mkdir -p "$2"
output="$(realpath "$2")"
case "$(uname -m)" in
  x86_64) expected_machine='Advanced Micro Devices X86-64' ;;
  aarch64) expected_machine='AArch64' ;;
  *) printf 'Unsupported runtime-test architecture: %s\n' "$(uname -m)" >&2; exit 1 ;;
esac
if ! readelf -h "$image" | grep -Fq "$expected_machine"; then
  printf 'AppImage runtime is not built for %s\n' "$(uname -m)" >&2
  exit 1
fi
workspace="$(mktemp -d)"
app_pid=''
bus_pid=''
cleanup() {
  [[ -z "$app_pid" ]] || kill "$app_pid" 2>/dev/null || true
  [[ -z "$bus_pid" ]] || kill "$bus_pid" 2>/dev/null || true
  rm -rf "$workspace"
}
trap cleanup EXIT
cd "$workspace"
printf 'AppImage runtime test: extracting image\n'
cp "$image" "$workspace/extractor"
printf '\0\0\0' | dd of="$workspace/extractor" bs=1 seek=8 count=3 conv=notrunc status=none
timeout 60 "$workspace/extractor" --appimage-extract > /dev/null
appdir="$workspace/squashfs-root"
[[ -x "$appdir/AppRun" && -f "$appdir/usr/bin/lib/libapp.so" && \
  -f "$appdir/usr/bin/data/icudtl.dat" && -d "$appdir/usr/bin/data/flutter_assets" ]]
[[ -f "$appdir/usr/bin/lib/libonnxruntime.so.1" && \
  -f "$appdir/usr/share/glib-2.0/schemas/gschemas.compiled" ]]
while IFS= read -r -d '' library; do
  if readelf -h "$library" >/dev/null 2>&1 && \
    ! readelf -h "$library" | grep -Fq "$expected_machine"; then
    printf 'Wrong ELF architecture in AppImage: %s\n' "${library#"$appdir/"}" >&2
    exit 1
  fi
done < <(find "$appdir/usr/bin" "$appdir/usr/lib" -type f -print0)
ldd "$appdir/usr/bin/meshcore_open" > "$output/dependencies.log" 2>&1
while IFS= read -r -d '' library; do
  printf '\n%s\n' "${library#"$appdir/"}" >> "$output/dependencies.log"
  ldd "$library" >> "$output/dependencies.log" 2>&1 || true
done < <(find "$appdir/usr/bin/lib" "$appdir/usr/lib" -type f -name '*.so*' -print0)
if grep 'not found' "$output/dependencies.log"; then
  printf 'Unresolved AppImage dependencies\n' >&2
  exit 1
fi
mkdir -p "$workspace/home/Documents" "$workspace/home/config"
printf 'XDG_DOCUMENTS_DIR="%s/Documents"\n' "$workspace/home" > "$workspace/home/config/user-dirs.dirs"
bus_pid="$(dbus-daemon --session --address="unix:path=$workspace/system-bus" --fork --print-pid)"
printf 'AppImage runtime test: launching application\n'
env -u LD_LIBRARY_PATH -u GTK_PATH -u GSETTINGS_SCHEMA_DIR \
  HOME="$workspace/home" XDG_CONFIG_HOME="$workspace/home/config" \
  XDG_DATA_HOME="$workspace/home/data" XDG_CACHE_HOME="$workspace/home/cache" \
  DBUS_SYSTEM_BUS_ADDRESS="unix:path=$workspace/system-bus" \
  dbus-run-session -- "$appdir/AppRun" > "$output/startup.log" 2>&1 &
app_pid=$!
window="$(timeout 60 xdotool search --sync --onlyvisible --limit 1 --name 'MeshCore Open|meshcore_open')"
colors=0
deadline=$((SECONDS + 60))
while (( SECONDS < deadline )); do
  kill -0 "$app_pid"
  xwd -silent -id "$window" -out "$workspace/window.xwd"
  convert "$workspace/window.xwd" "$output/startup.png"
  colors="$(identify -format '%k' "$output/startup.png")"
  (( colors < 20 )) || break
done
(( colors >= 20 )) || { printf 'Application window remained blank\n' >&2; exit 1; }
[[ -s "$output/startup.png" ]]
if grep -Ei 'error while loading shared libraries|cannot open shared object|failed to load asset|unhandled exception' "$output/startup.log"; then
  exit 1
fi
printf 'Extracted AppImage startup passed; screenshot: %s/startup.png\n' "$output"