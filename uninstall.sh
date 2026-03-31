#!/bin/bash
set -e

PLIST="$HOME/Library/LaunchAgents/com.usagebar.plist"
BUNDLE="/Applications/UsageBar.app"

launchctl unload "$PLIST" 2>/dev/null || true
rm -f "$PLIST"
rm -rf "$BUNDLE"

echo "UsageBar uninstalled."
