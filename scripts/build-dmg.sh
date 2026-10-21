#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_DIR="$ROOT_DIR/dist/MacTempChecker.app"
DIST_DIR="$ROOT_DIR/dist"

"$ROOT_DIR/scripts/build-app.sh"

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")
ARCH=$(uname -m)
DMG_PATH="$DIST_DIR/MacMonitor-$VERSION-$ARCH.dmg"

mkdir -p "$ROOT_DIR/.build/dmg" "$DIST_DIR"
STAGING_DIR=$(mktemp -d "$ROOT_DIR/.build/dmg/staging.XXXXXX")
trap 'rm -rf "$STAGING_DIR"' EXIT HUP INT TERM

ditto "$APP_DIR" "$STAGING_DIR/Mac Monitor.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -ov -volname "Mac Monitor" -srcfolder "$STAGING_DIR" -format UDZO "$DMG_PATH"
hdiutil verify "$DMG_PATH"

printf 'Created %s\n' "$DMG_PATH"