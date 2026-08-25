# Changelog

All notable changes to MigMouse will be documented here.

## [Unreleased]

### Added

- Two-finger pinch-to-zoom using native macOS magnification events

### Fixed

- Prevent app-hosted unit tests from starting and stopping the real Magic Mouse touch device used by another running MigMouse instance
- Preserve the original application bundle identifier so existing macOS permissions remain valid across source builds

### Planned

- Personalized touch calibration
- Additional trackpad-style gestures

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

[Unreleased]: https://github.com/Eric-kbo/migMouse/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Eric-kbo/migMouse/releases/tag/v0.1.0
