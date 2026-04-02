# Changelog

All notable changes to UsageBar are documented here.

## [1.0.4] - 2026-04-02

### Added
- Error logging for OAuth fetch failures and LaunchAgent operations (visible in `~/.claude/usagebar.log`)

### Changed
- Credentials are now reloaded from Keychain on every refresh — no restart needed after re-login
- UI resets cleanly when OAuth token is unavailable instead of showing stale data
- Install script stops the running instance before overwriting the binary
- Unified internal data model for OAuth and cache rate limit data
- Extracted shared constants for refresh interval and color thresholds
- Deduplicated label setup code in menu item views
- Made ISO8601 date formatter static for efficiency

### Fixed
- Cache file was read twice per refresh cycle instead of once
- Info.plist version was stuck at 1.0 instead of matching the release version

## [1.0.3] - 2026-04-02

### Added
- Live usage data via Anthropic OAuth API — works for both Claude Pro and Claude Max
- Stale indicator shown when data is more than 5 minutes old

### Changed
- OAuth data is fetched first; local cache is used as fallback for users without Keychain credentials
- Menu layout aligned to match native macOS menu item padding

### Fixed
- Multiple instances no longer accumulate after quit
- LaunchAgent no longer uses KeepAlive, preventing restart loop on quit

## [1.0.2] - 2026-03-31

### Fixed
- Uninstall script now correctly removes `/Applications/UsageBar.app`

## [1.0.1] - 2026-03-31

### Fixed
- Single-instance guard added at startup

## [1.0.0] - 2026-03-31

Initial release.

- Dual vertical progress bars in menu bar (5-hour and 7-day windows)
- Reads from `~/.claude/rate_limits_cache.json`
- Auto-installs LaunchAgent on first launch
- Homebrew cask distribution
