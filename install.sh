#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY_NAME="UsageBar"
BUNDLE_NAME="UsageBar.app"
APP_DIR="/Applications"
BUNDLE="$APP_DIR/$BUNDLE_NAME"
BINARY_IN_BUNDLE="$BUNDLE/Contents/MacOS/$BINARY_NAME"

echo "Building $BINARY_NAME..."
cd "$SCRIPT_DIR"
swift build -c release

echo "Stopping running instance..."
pkill -x "$BINARY_NAME" 2>/dev/null && sleep 1 || true

echo "Installing to $BUNDLE..."
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"
cp ".build/release/$BINARY_NAME" "$BINARY_IN_BUNDLE"
cp "Info.plist" "$BUNDLE/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"
chmod +x "$BINARY_IN_BUNDLE"

xattr -dr com.apple.quarantine "$BUNDLE" 2>/dev/null || true

open "$BUNDLE"

echo "Done! $BINARY_NAME is running from $BUNDLE"
echo "It will launch automatically at login."
