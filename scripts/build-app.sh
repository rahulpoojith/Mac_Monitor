#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_DIR="$ROOT_DIR/dist/MacTempChecker.app"
ICONSET_DIR="$ROOT_DIR/.build/MacTempChecker.iconset"
ICON_PNG="$ROOT_DIR/.build/MacTempChecker.png"

cd "$ROOT_DIR"
swift build -c release
swift scripts/generate-icon.swift "$ICON_PNG"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$ICONSET_DIR"
cp "$ROOT_DIR/.build/release/MacTempChecker" "$APP_DIR/Contents/MacOS/MacTempChecker"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

create_icon() {
	size="$1"
	name="$2"
	sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET_DIR/$name" >/dev/null
}

create_icon 16 icon_16x16.png
create_icon 32 icon_16x16@2x.png
create_icon 32 icon_32x32.png
create_icon 64 icon_32x32@2x.png
create_icon 128 icon_128x128.png
create_icon 256 icon_128x128@2x.png
create_icon 256 icon_256x256.png
create_icon 512 icon_256x256@2x.png
create_icon 512 icon_512x512.png
create_icon 1024 icon_512x512@2x.png

rm -f "$APP_DIR/Contents/Resources/AppIcon.icns"
iconutil --convert icns --output "$APP_DIR/Contents/Resources/AppIcon.icns" "$ICONSET_DIR"

printf 'Created %s\n' "$APP_DIR"