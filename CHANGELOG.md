# Changelog

All notable changes to MigMouse will be documented here.

## [Unreleased]

### Planned

- Personalized touch calibration
- Additional trackpad-style gestures

## [0.1.2] - 2026-08-26

### Added

- Optional launch at login, enabled automatically for first runs installed in Applications
- Safe process-level restart after Mac wake and from the troubleshooting menu

### Fixed

- Remove the unsafe `MTDeviceStop` teardown path that could crash while touch callbacks were active
- Remove pointer-activity-based stale-device detection that could trigger false reconnects during normal use
- Open Login Items settings when macOS requires user approval instead of letting the launch-at-login toggle silently revert
- Validate and package notarized builds outside file-provider directories so Finder metadata cannot invalidate strict signature checks

## [0.1.1] - 2026-08-25

### Added

- Two-finger pinch-to-zoom using native macOS magnification events
- Developer ID signed and Apple-notarized release packaging

### Fixed

- Prevent app-hosted unit tests from starting and stopping the real Magic Mouse touch device used by another running MigMouse instance
- Preserve the original application bundle identifier so existing macOS permissions remain valid across source builds

## [0.1.0] - 2026-08-25

### Added

- One-finger tap to left-click
- Two-finger and configurable right-zone tap to right-click
- Double-click count handling
- Scroll and physical-click arbitration
- Runtime Magic Mouse discovery and reconnection
- Live touch diagnostics and click-injection test
- Adjustable tap recognition settings
- Accessibility and Input Monitoring permission guidance
- Localizations for 12 languages
- Gesture-recognizer unit tests

[Unreleased]: https://github.com/Eric-kbo/migMouse/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/Eric-kbo/migMouse/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/Eric-kbo/migMouse/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Eric-kbo/migMouse/releases/tag/v0.1.0
