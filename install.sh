#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY_NAME="UsageBar"
BUNDLE_NAME="UsageBar.app"
APP_DIR="$HOME/Applications"
BUNDLE="$APP_DIR/$BUNDLE_NAME"
BINARY_IN_BUNDLE="$BUNDLE/Contents/MacOS/$BINARY_NAME"
PLIST_NAME="com.usagebar"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"

echo "Building $BINARY_NAME..."
cd "$SCRIPT_DIR"
swift build -c release

echo "Installing to $BUNDLE..."
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"
cp ".build/release/$BINARY_NAME" "$BINARY_IN_BUNDLE"
cp "Info.plist" "$BUNDLE/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"
chmod +x "$BINARY_IN_BUNDLE"

# Create LaunchAgent for auto-start at login
mkdir -p "$LAUNCH_AGENTS"
cat > "$LAUNCH_AGENTS/$PLIST_NAME.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_IN_BUNDLE</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>$HOME/.claude/usagebar.log</string>
</dict>
</plist>
EOF

# Stop existing instance and restart
launchctl unload "$LAUNCH_AGENTS/$PLIST_NAME.plist" 2>/dev/null || true
launchctl load "$LAUNCH_AGENTS/$PLIST_NAME.plist"

echo "Done! $BINARY_NAME is running from $BUNDLE"
echo "You can also open it anytime via Spotlight or Finder."
