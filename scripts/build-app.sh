#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
sdk="$(xcrun --show-sdk-path)"
target="arm64-apple-macosx14.0"
mkdir -p "$root/.build"

toolchain="$(cd "$(dirname "$(xcrun --find swiftc)")/.." && pwd)"
bridging_map="$toolchain/include/swift/bridging.modulemap"
overlay_args=()
if [[ -f "$bridging_map" ]]; then
  overlay="$root/.build/bridging-overlay.yaml"
  cat > "$overlay" <<EOF
{
  "version": 0,
  "roots": [
    {
      "name": "$bridging_map",
      "type": "file",
      "external-contents": "$root/scripts/empty.modulemap"
    }
  ]
}
EOF
  overlay_args=(-vfsoverlay "$overlay")
fi

swiftc -parse-as-library -target "$target" -sdk "$sdk" "${overlay_args[@]}" \
  "$root/Sources/TaskTrackerCore/"*.swift \
  "$root/Tests/CheckMain.swift" \
  -o "$root/.build/tasktracker-checks"
"$root/.build/tasktracker-checks"

swiftc -parse-as-library -module-name TaskTracker \
  -target "$target" -sdk "$sdk" "${overlay_args[@]}" \
  -whole-module-optimization \
  -framework AppKit -framework SwiftUI \
  "$root/Sources/TaskTrackerCore/"*.swift \
  "$root/Sources/TaskTracker/"*.swift \
  -o "$root/.build/TaskTracker"

app="$root/TaskTracker.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$root/.build/TaskTracker" "$app/Contents/MacOS/TaskTracker"
cp "$root/scripts/Info.plist" "$app/Contents/Info.plist"

icon_src="$root/.build/AppIcon.png"
sips -s format png "$root/Resources/AppIcon.png" --out "$icon_src" >/dev/null
iconset="$root/.build/AppIcon.iconset"
rm -rf "$iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$icon_src" --out "$iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" "$icon_src" --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
rm -rf "$iconset"

codesign --force --sign - "$app"
echo "Listo: $app"
