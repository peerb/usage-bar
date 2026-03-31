# Contributing

## Architecture

The entire app lives in a single file: `Sources/UsageBar/main.swift` (~450 lines). There are no external dependencies — only AppKit and Foundation.

Key sections (marked with `// MARK:`):
- **Custom Menu Item Views** — `NSView` subclasses embedded directly into `NSMenuItem`s
- **Data Models** — `Codable` structs mirroring `~/.claude/rate_limits_cache.json`
- **Cache** — reads and decodes the JSON file written by Claude Code
- **Launch Agent Manager** — manages `~/Library/LaunchAgents/com.usagebar.plist`
- **App Delegate** — owns the `NSStatusItem`, 30-second refresh timer, and calls into the UI builders
- **Status Bar** — draws the dual vertical bar icon via Core Graphics
- **Menu** — builds the dropdown `NSMenu` on each refresh

## Testing changes

There is no automated test suite. To test manually:

```bash
swift build -c release
~/Applications/UsageBar.app/Contents/MacOS/UsageBar &
```

The app appears in the menu bar immediately. Kill the previous instance first if one is running:

```bash
pkill UsageBar
```

To test without a real cache file, create a minimal one:

```bash
cat > ~/.claude/rate_limits_cache.json << 'EOF'
{
  "rate_limits": {
    "five_hour": { "used_percentage": 42, "resets_at": 9999999999 },
    "seven_day": { "used_percentage": 75, "resets_at": 9999999999 }
  },
  "model": { "display_name": "Claude Sonnet 4.6" },
  "context_window": { "used_percentage": 30 },
  "cost": { "total_cost_usd": 0.05 },
  "updated_at": 9999999999
}
EOF
```

## Submitting changes

Open a pull request against `main`. Keep changes focused — this is intentionally a minimal app.
