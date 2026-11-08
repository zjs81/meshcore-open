#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 2 ]]; then
  printf 'Usage: verify_image.sh APPIMAGE REPORT\n' >&2
  exit 2
fi

image="$(realpath -e -- "$1")"
report="$2"
dependency_checker="$(dirname "${BASH_SOURCE[0]}")/dependencies.sh"
workspace="$(mktemp -d)"
trap 'rm -rf "$workspace"' EXIT
mkdir -p "$(dirname "$report")"
cp -p -- "$image" "$workspace/extractor"
printf '\0\0\0' | dd of="$workspace/extractor" bs=1 seek=8 count=3 conv=notrunc status=none
(
  cd "$workspace"
  ./extractor --appimage-extract >/dev/null
)
bash "$dependency_checker" audit "$workspace/squashfs-root" "$report"
printf 'AppImage dependency audit passed: %s\n' "$report"