#!/usr/bin/env bash
# Switch ONNX Runtime (the image codec's inference engine) on or off.
#
#   scripts/onnx.sh off     build without ORT: no native plugin, no downloads
#   scripts/onnx.sh on      default build with ORT
#   scripts/onnx.sh status  print the current mode
#
# "off" writes pubspec_overrides.yaml, pointing flutter_onnxruntime at the
# pure-Dart stub in third_party/flutter_onnxruntime_stub; "on" removes it.
# Both run `flutter pub get` (set FLUTTER to use another flutter binary).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
overrides="$root/pubspec_overrides.yaml"
marker='# Written by scripts/onnx.sh'
flutter_bin="${FLUTTER:-flutter}"

is_ours() {
  [[ -f "$overrides" ]] && grep -Fq "$marker" "$overrides"
}

case "${1:-}" in
  off)
    if [[ -f "$overrides" ]] && ! is_ours; then
      echo "pubspec_overrides.yaml exists and was not written by this script; edit it by hand." >&2
      exit 1
    fi
    cat > "$overrides" <<EOF
$marker off. Remove with: scripts/onnx.sh on
dependency_overrides:
  flutter_onnxruntime:
    path: third_party/flutter_onnxruntime_stub
EOF
    ;;
  on)
    if [[ -f "$overrides" ]] && ! is_ours; then
      echo "pubspec_overrides.yaml was not written by this script; remove the flutter_onnxruntime override by hand." >&2
      exit 1
    fi
    rm -f "$overrides"
    ;;
  status)
    if is_ours; then echo off; else echo on; fi
    exit 0
    ;;
  *)
    echo "usage: $0 off|on|status" >&2
    exit 2
    ;;
esac

cd "$root"
"$flutter_bin" pub get
echo "ONNX Runtime: $1"
