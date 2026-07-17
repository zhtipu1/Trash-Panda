#!/bin/bash
# Builds "Trash Panda - App Manager.app" from the Swift package in ./dist/
# Run this from a Mac: ./Scripts/build_app.sh
set -e

cd "$(dirname "$0")/.."

APP_NAME="Trash Panda - App Manager"
EXECUTABLE_NAME="AppManager"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "→ Building universal release binary…"
swift build -c release --arch arm64 --arch x86_64

BIN_PATH=".build/apple/Products/Release/$EXECUTABLE_NAME"
if [ ! -f "$BIN_PATH" ]; then
  # Fallback for toolchains that don't support multi-arch builds (e.g. Rosetta-only Macs).
  echo "→ Universal build unavailable, falling back to a single-arch release build…"
  swift build -c release
  BIN_PATH=".build/release/$EXECUTABLE_NAME"
fi

ICON_SRC="Resources/Icon.png"
ICON_ICNS="Resources/AppIcon.icns"
if [ -f "$ICON_SRC" ]; then
  echo "→ Generating AppIcon.icns from Icon.png…"
  ICONSET="Resources/AppIcon.iconset"
  rm -rf "$ICONSET"
  mkdir -p "$ICONSET"
  sips -z 16 16     "$ICON_SRC" --out "$ICONSET/icon_16x16.png"      > /dev/null
  sips -z 32 32     "$ICON_SRC" --out "$ICONSET/icon_16x16@2x.png"   > /dev/null
  sips -z 32 32     "$ICON_SRC" --out "$ICONSET/icon_32x32.png"      > /dev/null
  sips -z 64 64     "$ICON_SRC" --out "$ICONSET/icon_32x32@2x.png"   > /dev/null
  sips -z 128 128   "$ICON_SRC" --out "$ICONSET/icon_128x128.png"    > /dev/null
  sips -z 256 256   "$ICON_SRC" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
  sips -z 256 256   "$ICON_SRC" --out "$ICONSET/icon_256x256.png"    > /dev/null
  sips -z 512 512   "$ICON_SRC" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
  sips -z 512 512   "$ICON_SRC" --out "$ICONSET/icon_512x512.png"    > /dev/null
  sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET/icon_512x512@2x.png" > /dev/null
  iconutil -c icns "$ICONSET" -o "$ICON_ICNS"
  rm -rf "$ICONSET"
fi

echo "→ Assembling $APP_BUNDLE…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$ICON_ICNS" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"

echo "→ Ad-hoc signing (fine for local use — see note below for distribution)…"
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "✅  Done. Open '$APP_BUNDLE'"
echo ""
echo "⚠️  First launch: grant Full Disk Access in"
echo "   System Settings → Privacy & Security → Full Disk Access"
echo ""
echo "ℹ️  This build is ad-hoc signed, which is enough to run locally and grant"
echo "   Full Disk Access on this Mac. To distribute it to others, sign it with"
echo "   a Developer ID certificate instead:"
echo "   codesign --force --deep --sign \"Developer ID Application: Your Name (TEAMID)\" \"$APP_BUNDLE\""
