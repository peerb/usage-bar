# Changelog

All notable changes to UsageBar are documented here.

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
