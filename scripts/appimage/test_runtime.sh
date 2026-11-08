#!/usr/bin/env bash
set -euo pipefail

image="$(realpath "$1")"
mkdir -p "$2"
output="$(realpath "$2")"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dependency_checker="${MESHCORE_APPIMAGE_DEPENDENCIES:-$script_dir/dependencies.sh}"
if [[ "$dependency_checker" != /* ]]; then
  dependency_checker="$(realpath -e -- "$dependency_checker")"
fi
exec > >(tee -a "$output/runtime-test.log") 2>&1

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" >&2
}

run_timed() {
  local label="$1" limit="$2" capture="$3" started status
  shift 3
  started=$SECONDS
  log "START $label (timeout $limit)"
  if timeout --signal=TERM --kill-after=5s "$limit" "$@" >"$capture" 2>&1; then
    log "PASS $label ($((SECONDS - started))s)"
    return 0
  else
    status=$?
    tail -n 40 "$capture" >&2 || true
    log "FAIL $label (exit $status after $((SECONDS - started))s)"
    return "$status"
  fi
}

case "$(uname -m)" in
  x86_64) expected_machine='Advanced Micro Devices X86-64' ;;
  aarch64) expected_machine='AArch64' ;;
  *) log "Unsupported runtime-test architecture: $(uname -m)"; exit 1 ;;
esac
log "Runtime test starting: architecture=$(uname -m) image=$image size=$(stat -c %s "$image") bytes"
if ! readelf -h "$image" | grep -Fq "$expected_machine"; then
  log "AppImage runtime is not built for $(uname -m)"
  exit 1
fi

workspace="$(mktemp -d)"
app_pid=''
stop_process() {
  local process_id="$1" attempt
  [[ -n "$process_id" ]] || return 0
  kill -0 "$process_id" 2>/dev/null || return 0
  kill -TERM "$process_id" 2>/dev/null || true
  for ((attempt = 0; attempt < 5; attempt++)); do
    kill -0 "$process_id" 2>/dev/null || break
    sleep 1
  done
  kill -KILL "$process_id" 2>/dev/null || true
  wait "$process_id" 2>/dev/null || true
}
cleanup() {
  log 'Cleanup: stopping application process'
  stop_process "$app_pid"
  rm -rf "$workspace"
}
trap cleanup EXIT
cd "$workspace"

cp "$image" "$workspace/extractor"
printf '\0\0\0' | dd of="$workspace/extractor" bs=1 seek=8 count=3 conv=notrunc status=none
run_timed 'extract AppImage' 120s "$output/extract.log" \
  "$workspace/extractor" --appimage-extract
appdir="$workspace/squashfs-root"
log 'Checking extracted AppImage structure'
[[ -x "$appdir/AppRun" && -f "$appdir/usr/bin/lib/libapp.so" && \
  -f "$appdir/usr/bin/data/icudtl.dat" && -d "$appdir/usr/bin/data/flutter_assets" ]]
[[ -f "$appdir/usr/bin/lib/libonnxruntime.so.1" && \
  -f "$appdir/usr/share/glib-2.0/schemas/gschemas.compiled" ]]

log 'Starting bundled ELF architecture audit'
elf_count=0
while IFS= read -r -d '' library; do
  if readelf -h "$library" >/dev/null 2>&1; then
    elf_count=$((elf_count + 1))
    log "Checking ELF $elf_count: ${library#"$appdir/"}"
    if ! readelf -h "$library" | grep -Fq "$expected_machine"; then
      log "Wrong ELF architecture in AppImage: ${library#"$appdir/"}"
      exit 1
    fi
  fi
done < <(find "$appdir/usr/bin" "$appdir/usr/lib" -type f -print0)
log "ELF architecture audit passed ($elf_count files)"

dependencies="$output/dependencies.log"
: > "$dependencies"
[[ -f "$dependency_checker" ]] || { log "Missing dependency checker: $dependency_checker"; exit 1; }
run_timed 'audit dependency origins' 120s "$workspace/dependency-audit.log" \
  bash "$dependency_checker" audit "$appdir" "$dependencies"
cat "$workspace/dependency-audit.log" >> "$dependencies"
log 'Dependency origin audit passed'

mkdir -p "$workspace/home/Documents" "$workspace/home/config"
printf 'XDG_DOCUMENTS_DIR="%s/Documents"\n' "$workspace/home" > "$workspace/home/config/user-dirs.dirs"
log 'Starting AppRun under a private D-Bus session (also used as the system bus)'
# shellcheck disable=SC2016
env -u LD_LIBRARY_PATH \
  GIO_EXTRA_MODULES=/host/gio/modules GIO_MODULE_DIR=/host/gio/modules \
  GI_TYPELIB_PATH=/host/girepository GTK_PATH=/host/gtk/modules \
  GTK_MODULES=host-module GDK_PIXBUF_MODULE_FILE=/host/pixbuf.loaders \
  GSETTINGS_SCHEMA_DIR=/host/glib-2.0/schemas \
  HOME="$workspace/home" XDG_CONFIG_HOME="$workspace/home/config" \
  XDG_DATA_HOME="$workspace/home/data" XDG_CACHE_HOME="$workspace/home/cache" \
  dbus-run-session -- bash -c \
  'export DBUS_SYSTEM_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS"; exec "$1"' \
  _ "$appdir/AppRun" > "$output/startup.log" 2>&1 &
app_pid=$!
log "AppRun started: pid=$app_pid"

window=''
window_deadline=$((SECONDS + 90))
next_window_report=$((SECONDS + 10))
while ((SECONDS < window_deadline)); do
  if ! kill -0 "$app_pid" 2>/dev/null; then
    log 'AppRun exited before opening a visible window; startup.log follows'
    tail -n 100 "$output/startup.log" >&2 || true
    exit 1
  fi
  if window="$(timeout --signal=TERM --kill-after=2s 5s \
    xdotool search --onlyvisible --limit 1 --name 'MeshCore Open|meshcore_open' 2>/dev/null)"; then
    break
  fi
  if ((SECONDS >= next_window_report)); then
    log "Still waiting for the application window (${SECONDS}s elapsed)"
    next_window_report=$((SECONDS + 10))
  fi
  sleep 1
done
if [[ -z "$window" ]]; then
  log 'Timed out waiting 90s for a visible application window; startup.log follows'
  tail -n 100 "$output/startup.log" >&2 || true
  exit 1
fi
log "Visible application window found: id=$window"

colors=0
screenshot_deadline=$((SECONDS + 60))
next_screenshot_report=$((SECONDS + 10))
while ((SECONDS < screenshot_deadline)); do
  # shellcheck disable=SC2016
  if timeout --signal=TERM --kill-after=5s 15s bash -e -c \
    'xwd -silent -id "$1" -out "$2" && convert "$2" "$3" && identify -format "%k" "$3"' \
    _ "$window" "$workspace/window.xwd" "$output/startup.png" \
    > "$workspace/screenshot.log" 2>&1; then
    colors="$(<"$workspace/screenshot.log")"
  else
    status=$?
    tail -n 40 "$workspace/screenshot.log" >&2 || true
    log "Screenshot capture failed (exit $status)"
    exit "$status"
  fi
  [[ "$colors" =~ ^[0-9]+$ ]] || { log "Unexpected screenshot color count: $colors"; exit 1; }
  ((colors >= 20)) && break
  if ((SECONDS >= next_screenshot_report)); then
    log "Window still appears blank (${colors} colors, $((screenshot_deadline - SECONDS))s remaining)"
    next_screenshot_report=$((SECONDS + 10))
  fi
done
((colors >= 20)) || { log 'Application window remained blank after 60s'; exit 1; }
[[ -s "$output/startup.png" ]]
if grep -Ei 'error while loading shared libraries|cannot open shared object|failed to load asset|unhandled exception' "$output/startup.log"; then
  exit 1
fi
log "Runtime test passed; screenshot: $output/startup.png"