# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- **Build release binary:** `swift build -c release`
- **Build debug:** `swift build`
- **Full install (build + app bundle + LaunchAgent):** `./install.sh`
- **Generate app icon:** `swift scripts/generate_icon.swift`

There are no automated tests or linting commands.

## Architecture

UsageBar is a single-file macOS menu bar app (`Sources/UsageBar/main.swift`) that reads Anthropic API rate limit data from Claude Code's local cache and displays it as dual vertical progress bars in the menu bar.

**Data flow:**
```
Primary:   Keychain credentials → OAuthUsageFetcher → UsageData → refreshUI() → NSStatusItem
Fallback:  ~/.claude/rate_limits_cache.json → StatusCache → CachedStatus → UsageData → refreshUI()
```

OAuth usage data is fetched every 5 minutes via `OAuthUsageFetcher`. When credentials are unavailable or the fetch fails, the app falls back to reading Claude Code's local cache file.

**Key components in `main.swift`:**

- **Custom NSView subclasses** — `ProgressBarView`, `MenuHeaderItemView`, `MenuSubtitleItemView`, `MenuRateLimitItemView` — used as embedded views inside NSMenuItems
- **Unified model** — `UsageData`, `UsageWindow` — common representation for both OAuth and cache data
- **Codable structs** — `CachedStatus`, `RateLimits`, `RateLimitWindow`, `ModelInfo`, `ContextWindow`, `CostInfo` — mirror the JSON schema of the cache file
- **`OAuthUsageFetcher`** — fetches live usage data from the Anthropic OAuth API
- **`KeychainReader`** — reads Claude Code OAuth credentials from the macOS Keychain
- **`StatusCache`** — reads and decodes `~/.claude/rate_limits_cache.json`
- **`LaunchAgentManager`** — generates and manages `~/Library/LaunchAgents/com.usagebar.plist` for login auto-start
- **`AppDelegate`** — owns the `NSStatusItem`, refresh timer, and delegates to `makeStatusImage()` and `makeMenu()`

**Menu bar icon** (`makeStatusImage()`): draws two 4×13pt vertical bars (one per rate-limit window) with a 5px gap, filling from bottom up. Colors use the system label color at full (bar) vs 0.15 (track) alpha, switching to orange >70% and red >90% usage.

**Deployment paths:**
- App bundle: `~/Applications/UsageBar.app/Contents/MacOS/UsageBar`
- LaunchAgent plist: `~/Library/LaunchAgents/com.usagebar.plist`
- Logs: `~/.claude/usagebar.log`

**Tech:** AppKit + Core Graphics, Swift Package Manager, macOS 12+ minimum, no external dependencies.
