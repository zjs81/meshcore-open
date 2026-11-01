#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'AppImage: %s\n' "$*" >&2
  return 1
}

packaging_enabled() {
  [[ "${MESHCORE_BUILD_APPIMAGE:-1}" != 0 && "$1" == Release ]]
}

check_bundle() {
  local bundle="$1"
  [[ -x "$bundle/meshcore_open" && -f "$bundle/lib/libapp.so" && \
    -f "$bundle/data/icudtl.dat" && -d "$bundle/data/flutter_assets" ]] || \
    fail "Incomplete release bundle: $bundle"
}

download_verified() {
  local url="$1" checksum="$2" destination="$3" temporary
  mkdir -p "$(dirname "$destination")"
  if [[ -f "$destination" ]]; then
    if printf '%s  %s\n' "$checksum" "$destination" | sha256sum --check --status; then
      return
    fi
    fail "Cached tool checksum mismatch: $destination; remove it and retry"
    return 1
  fi
  temporary="$(mktemp "$destination.download.XXXXXX")"
  if ! curl --fail --location --retry 3 --connect-timeout 20 --max-time 600 \
    --output "$temporary" "$url"; then
    rm -f "$temporary"
    fail "Cannot download $url; populate the verified cache or disable packaging with MESHCORE_BUILD_APPIMAGE=0"
    return 1
  fi
  if ! printf '%s  %s\n' "$checksum" "$temporary" | sha256sum --check --status; then
    rm -f "$temporary"
    fail "Downloaded tool checksum mismatch: $url"
    return 1
  fi
  mv "$temporary" "$destination"
}

require_tools() {
  local tool
  for tool in "$@"; do
    command -v "$tool" >/dev/null || {
      fail "Missing $tool; see README Linux AppImage prerequisites or set MESHCORE_BUILD_APPIMAGE=0"
      return 1
    }
  done
}

prepare_tools() {
  local manifest="$1" cache="$2" tool url checksum
  mkdir -p "$cache"
  exec {cache_lock}>"$cache/tools.lock"
  flock "$cache_lock"
  for tool in linuxdeploy appimagetool gtk runtime; do
    url="$(jq -er --arg tool "$tool" '.tools[$tool].url' "$manifest")"
    checksum="$(jq -er --arg tool "$tool" '.tools[$tool].sha256' "$manifest")"
    download_verified "$url" "$checksum" "$cache/$tool"
    chmod +x "$cache/$tool"
  done
  flock -u "$cache_lock"
  exec {cache_lock}>&-
}

extract_tool() {
  local tool="$1" destination="$2"
  mkdir -p "$destination"
  cp "$tool" "$destination/extractor"
  printf '\0\0\0' | dd of="$destination/extractor" bs=1 seek=8 count=3 conv=notrunc status=none
  (cd "$destination" && ./extractor --appimage-extract >/dev/null)
}

stage_bundle() {
  local project="$1" bundle="$2" appdir="$3" identity=com.meshcore.meshcore_open
  mkdir -p "$appdir/usr/bin" "$appdir/usr/share/applications" \
    "$appdir/usr/share/icons/hicolor/256x256/apps"
  cp -a "$bundle/." "$appdir/usr/bin/"
  install -m 644 "$project/scripts/appimage/$identity.desktop" "$appdir/usr/share/applications/"
  install -m 644 "$project/mesh-icon.png" "$appdir/usr/share/icons/hicolor/256x256/apps/$identity.png"
  install -m 755 "$project/scripts/appimage/AppRun" "$appdir/AppRun"
}

audit_appdir() {
  local appdir="$1" report="$2" library rpath interpreter needed
  : > "$report"
  while IFS= read -r -d '' library; do
    readelf -h "$library" >/dev/null 2>&1 || continue
    rpath="$(patchelf --print-rpath "$library")"
    interpreter="$(patchelf --print-interpreter "$library" 2>/dev/null || true)"
    needed="$(patchelf --print-needed "$library")"
    if [[ "$rpath$interpreter$needed" == *'/nix/store/'* || \
      "$rpath" == *"$appdir"* ]]; then
      fail "Non-relocatable ELF: $library"
      return 1
    fi
    printf '%s\n  interpreter: %s\n  rpath: %s\n%s\n' \
      "${library#"$appdir/"}" "$interpreter" "$rpath" "$needed" >> "$report"
  done < <(find "$appdir" -type f -print0)
}

package_direct() {
  local project="$1" bundle="$2" output="$3" manifest="$4" cache="$5"
  local work appdir library relative linuxdeploy appimagetool
  local dependencies=()
  require_tools curl jq sha256sum flock file readelf patchelf pkg-config \
    desktop-file-validate glib-compile-schemas gdk-pixbuf-thumbnailer xdg-user-dir
  pkg-config --exists gtk+-3.0 librsvg-2.0 gobject-introspection-1.0 || \
    { fail 'Missing GTK, librsvg or GObject introspection development files'; return 1; }
  prepare_tools "$manifest" "$cache"
  work="$(mktemp -d "$output/appimage.XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -rf -- $(printf '%q' "$work")" EXIT
  appdir="$work/AppDir"
  extract_tool "$cache/linuxdeploy" "$work/linuxdeploy"
  extract_tool "$cache/appimagetool" "$work/appimagetool"
  linuxdeploy="$work/linuxdeploy/squashfs-root/AppRun"
  appimagetool="$work/appimagetool/squashfs-root/AppRun"
  install -m 755 "$cache/gtk" "$work/linuxdeploy/squashfs-root/linuxdeploy-plugin-gtk.sh"
  export PATH="$work/linuxdeploy/squashfs-root:$PATH"
  stage_bundle "$project" "$bundle" "$appdir"
  install -m 755 "$(command -v xdg-user-dir)" "$appdir/usr/bin/xdg-user-dir"
  gdk-pixbuf-thumbnailer --size 256 "$project/mesh-icon.png" \
    "$appdir/usr/share/icons/hicolor/256x256/apps/com.meshcore.meshcore_open.png"
  desktop-file-validate "$appdir/usr/share/applications/com.meshcore.meshcore_open.desktop"
  export DEPLOY_GTK_VERSION=3 NO_STRIP=1
  "$linuxdeploy" --appdir "$appdir" --executable "$appdir/usr/bin/meshcore_open" \
    --library "$(pkg-config --variable=libdir harfbuzz)/libharfbuzz.so.0" \
    --library "$(pkg-config --variable=libdir freetype2)/libfreetype.so.6" \
    --library "$(pkg-config --variable=libdir fontconfig)/libfontconfig.so.1" \
    --library "$(pkg-config --variable=libdir fribidi)/libfribidi.so.0" \
    --desktop-file "$appdir/usr/share/applications/com.meshcore.meshcore_open.desktop" \
    --icon-file "$appdir/usr/share/icons/hicolor/256x256/apps/com.meshcore.meshcore_open.png" \
    --plugin gtk
  while IFS= read -r -d '' library; do
    readelf -h "$library" >/dev/null 2>&1 || continue
    dependencies+=(--deploy-deps-only "$library")
  done < <(find "$appdir/usr/bin/lib" -type f -print0)
  "$linuxdeploy" --appdir "$appdir" "${dependencies[@]}"
  while IFS= read -r -d '' library; do
    readelf -h "$library" >/dev/null 2>&1 || continue
    relative="$(realpath --relative-to="$(dirname "$library")" "$appdir/usr/lib")"
    patchelf --set-rpath "\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/$relative" "$library"
  done < <(find "$appdir" -type f -print0)
  install -m 755 "$project/scripts/appimage/AppRun" "$appdir/AppRun"
  mkdir -p "$appdir/usr/share/doc/meshcore-open"
  cp "$project/LICENSE" "$appdir/usr/share/doc/meshcore-open/"
  while IFS= read -r -d '' library; do
    relative="${library#/usr/share/doc/}"
    mkdir -p "$appdir/usr/share/doc/meshcore-open/$(dirname "$relative")"
    cp -L "$library" "$appdir/usr/share/doc/meshcore-open/$relative"
  done < <(find -L /usr/share/doc -name copyright -type f -print0)
  while IFS= read -r -d '' library; do
    relative="$(realpath --relative-to="$project" "$library")"
    mkdir -p "$appdir/usr/share/doc/meshcore-open/build-notices/$(dirname "$relative")"
    cp -L "$library" "$appdir/usr/share/doc/meshcore-open/build-notices/$relative"
  done < <(find "$(dirname "$bundle")/plugins" -type f \
    \( -iname LICENSE -o -iname NOTICE -o -name ThirdPartyNotices.txt \) -print0)
  if [[ -n "${PUB_CACHE:-}" && -d "$PUB_CACHE/hosted" ]]; then
    while IFS= read -r -d '' library; do
      relative="${library#"$PUB_CACHE/"}"
      mkdir -p "$appdir/usr/share/doc/meshcore-open/packages/$(dirname "$relative")"
      cp -L "$library" "$appdir/usr/share/doc/meshcore-open/packages/$relative"
    done < <(find "$PUB_CACHE/hosted" -maxdepth 4 -type f \
      \( -iname LICENSE -o -iname NOTICE \) -print0)
  fi
  if [[ -f "${MESHCORE_APPIMAGE_FLUTTER_ROOT:-}/LICENSE" ]]; then
    cp "$MESHCORE_APPIMAGE_FLUTTER_ROOT/LICENSE" "$appdir/usr/share/doc/meshcore-open/Flutter-LICENSE"
  fi
  audit_appdir "$appdir" "$work/audit.txt"
  ARCH=x86_64 "$appimagetool" --runtime-file "$cache/runtime" --no-appstream \
    "$appdir" "$work/meshcore-open-x86_64.AppImage"
  chmod +x "$work/meshcore-open-x86_64.AppImage"
  mv "$work/meshcore-open-x86_64.AppImage" "$output/meshcore-open-x86_64.AppImage"
  mv "$work/audit.txt" "$output/appimage-audit.txt"
  cp "$manifest" "$output/appimage-tools.json"
  rm -rf "$work"
  trap - EXIT
}

container_build() {
  local workspace arguments=() definitions=() encoded decoded
  workspace="$(mktemp -d /tmp/meshcore-appimage.XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf -- $(printf '%q' "$workspace")" EXIT
  rsync -aL --exclude '/build' --exclude '/.dart_tool' --exclude '/.git' \
    --exclude '/.pub-cache' --exclude '/.pub' --exclude '/.env' \
    --exclude '/linux/flutter/ephemeral' --exclude '/android' --exclude '/ios' \
    --exclude '/macos' --exclude '/windows' /source/ "$workspace/"
  mkdir -p "$HOME"
  git config --global --add safe.directory /opt/flutter
  flutter config --no-analytics >/dev/null
  cd "$workspace"
  flutter pub get --enforce-lockfile
  IFS=',' read -r -a definitions <<< "${MESHCORE_APPIMAGE_DART_DEFINES:-}"
  for encoded in "${definitions[@]}"; do
    [[ -n "$encoded" ]] || continue
    decoded="$(printf '%s' "$encoded" | base64 --decode)"
    case "$decoded" in
      FLUTTER_BUILD_NAME=*) arguments+=("--build-name=${decoded#*=}") ;;
      FLUTTER_BUILD_NUMBER=*) arguments+=("--build-number=${decoded#*=}") ;;
      FLUTTER_VERSION=*|FLUTTER_CHANNEL=*|FLUTTER_GIT_URL=*|FLUTTER_FRAMEWORK_REVISION=*|FLUTTER_ENGINE_REVISION=*|FLUTTER_DART_VERSION=*) ;;
      *) arguments+=("--dart-define=$decoded") ;;
    esac
  done
  if [[ "${MESHCORE_APPIMAGE_TREE_SHAKE_ICONS:-true}" == false ]]; then
    arguments+=(--no-tree-shake-icons)
  fi
  flutter build linux --release --no-pub "${arguments[@]}"
  cp build/linux/x64/release/meshcore-open-x86_64.AppImage /output/
  cp build/linux/x64/release/appimage-audit.txt /output/
  cp build/linux/x64/release/appimage-tools.json /output/
  rm -rf "$workspace"
  trap - EXIT
}

package_container() {
  local project="$1" output="$2" manifest="$3" cache="$4" engine image pin key
  [[ "${MESHCORE_APPIMAGE_IN_CONTAINER:-0}" != 1 ]] || \
    { fail 'The container bundle unexpectedly contains Nix-linked executables'; return 1; }
  [[ "${MESHCORE_APPIMAGE_FLUTTER_TARGET:-lib/main.dart}" == lib/main.dart && \
    "${MESHCORE_APPIMAGE_DART_OBFUSCATION:-false}" == false && \
    -z "${MESHCORE_APPIMAGE_SPLIT_DEBUG_INFO:-}" ]] || \
    { fail 'Nix AppImage rebuilding supports main.dart without obfuscation/split-debug-info; set MESHCORE_BUILD_APPIMAGE=0 for other builds'; return 1; }
  [[ -f "$project/pubspec.lock" ]] || \
    { fail 'The container rebuild requires pubspec.lock from flutter pub get'; return 1; }
  engine=''
  for key in podman docker; do
    if command -v "$key" >/dev/null && "$key" info >/dev/null 2>&1; then
      engine="$key"
      break
    fi
  done
  [[ -n "$engine" ]] || \
    { fail 'Nix AppImage packaging requires a usable Podman or Docker engine; set MESHCORE_BUILD_APPIMAGE=0 to opt out'; return 1; }
  mkdir -p "$cache" "$cache/pub"
  pin="$(sha256sum "$manifest" "$project/scripts/appimage/Dockerfile" | sha256sum)"
  image="meshcore-open-appimage:${pin:0:16}"
  printf 'AppImage: rebuilding in Ubuntu with %s (Flutter %s); native Nix bundle is unchanged\n' \
    "$engine" "$(jq -r '.flutter.version' "$manifest")"
  if ! "$engine" image inspect "$image" >/dev/null 2>&1; then
    "$engine" build --target build --platform linux/amd64 --tag "$image" \
      --build-arg "BASE_IMAGE=$(jq -er '.ubuntu' "$manifest")" \
      --file "$project/scripts/appimage/Dockerfile" "$project/scripts"
  fi
  local environment=(--env MESHCORE_APPIMAGE_IN_CONTAINER=1 --env HOME=/tmp/home \
    --env XDG_CACHE_HOME=/cache --env PUB_CACHE=/cache/pub)
  for key in FLUTTER_TARGET DART_DEFINES DART_OBFUSCATION SPLIT_DEBUG_INFO TREE_SHAKE_ICONS; do
    environment+=(--env "MESHCORE_APPIMAGE_$key")
  done
  "$engine" run --rm --platform linux/amd64 --user "$(id -u):$(id -g)" \
    "${environment[@]}" --mount "type=bind,source=$(realpath "$project"),target=/source,readonly" \
    --mount "type=bind,source=$output,target=/output" \
    --mount "type=bind,source=$cache,target=/cache" \
    "$image" bash /source/scripts/build_appimage.sh --container-build
}

main() {
  [[ $# == 5 ]] || { fail 'Expected: project bundle output configuration architecture'; return 1; }
  local project="$1" bundle="$2" output="$3" configuration="$4" architecture="$5"
  packaging_enabled "$configuration" || return 0
  [[ "$architecture" == x64 || "$architecture" == x86_64 ]] || \
    { fail 'Only x86_64 AppImages are supported; set MESHCORE_BUILD_APPIMAGE=0 for other architectures'; return 1; }
  mkdir -p "$output"
  output="$(realpath "$output")"
  exec {output_lock}>"$output/appimage.lock"
  flock "$output_lock"
  rm -f "$output/meshcore-open-x86_64.AppImage" "$output/appimage-audit.txt" "$output/appimage-tools.json"
  check_bundle "$bundle"
  require_tools jq readelf sha256sum
  local manifest="$project/scripts/appimage-tools.json" pin cache
  pin="$(sha256sum "$manifest")"
  pin="${pin%% *}"
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/meshcore-open/appimage/$pin/x86_64"
  if [[ "$(readelf -l "$bundle/meshcore_open")" == *'/nix/store/'* ]]; then
    package_container "$project" "$output" "$manifest" "$cache"
  else
    package_direct "$project" "$bundle" "$output" "$manifest" "$cache"
  fi
  printf 'AppImage created: %s/meshcore-open-x86_64.AppImage\n' "$output"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ "${1:-}" == --container-build ]]; then
    container_build
  else
    main "$@"
  fi
fi