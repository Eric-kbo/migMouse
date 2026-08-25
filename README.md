<p align="center">
  <img src="docs/banner.svg" alt="MigMouse — trackpad-style tapping for Magic Mouse" width="100%">
</p>

<p align="center">
  <a href="https://github.com/Eric-kbo/migMouse/actions/workflows/build.yml"><img src="https://github.com/Eric-kbo/migMouse/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-6e56cf.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-111827?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white" alt="Swift 5">
</p>

<p align="center">
  Make Apple Magic Mouse tapping feel like trackpad tapping.
  <br>
  <a href="README.zh-CN.md">简体中文</a>
</p>

## Why MigMouse?

Magic Mouse has an excellent multi-touch surface, yet macOS does not offer the trackpad's **Tap to click** setting for it. MigMouse fills that gap while leaving Apple's native pointer movement, scrolling, and gestures intact.

## Features

- One-finger tap to left-click
- Two-finger tap or right-side tap to right-click
- Natural double-click behavior with correct click counts
- Arbitration with scrolling and physical clicks to prevent accidental taps
- Adjustable timing, movement, pressure, and right-click zone
- Live touch diagnostics and a synthetic-click test
- Native menu bar app with no network access or analytics
- System-following UI in 12 languages: English, Simplified and Traditional Chinese, Japanese, Korean, French, German, Spanish, Brazilian Portuguese, Italian, Russian, and Arabic

## Requirements

- macOS 14 Sonoma or later
- Apple Magic Mouse with a multi-touch surface
- Accessibility and Input Monitoring permission
- Xcode 16 or later to build from source

## Build and run

1. Clone this repository and open `MigMouse.xcodeproj` in Xcode.
2. Select your development team if Xcode asks for one.
3. Run the `MigMouse` scheme.
4. Grant Accessibility and Input Monitoring access when prompted, then restart MigMouse.

Command-line verification:

```sh
xcodebuild \
  -project MigMouse.xcodeproj \
  -scheme MigMouse \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## How it works

```text
Magic Mouse touch frames
          │
          ▼
   Tap recognizer ───── scroll / physical-click arbitration
          │
          ▼
 Core Graphics mouse event
          │
          ▼
       macOS app
```

MigMouse dynamically loads Apple's private `MultitouchSupport.framework` to read touch frames and uses Core Graphics to emit standard mouse events. The application sandbox must therefore remain disabled. This private API also means MigMouse is intended for source distribution and is not suitable for the Mac App Store.

## Privacy

All touch processing happens locally. MigMouse has no network client, telemetry, analytics, or account system. See the source and [Security Policy](SECURITY.md) for details.

## Project status

Milestone 1 is complete and usable. Tap-and-drag, drag lock, personalized calibration, and additional gestures are planned for later milestones. See [CHANGELOG.md](CHANGELOG.md).

Because MigMouse depends on an undocumented Apple framework, a future macOS update may require compatibility work. Bug reports with macOS version and Magic Mouse model are especially helpful.

## Contributing

Issues and pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before contributing.

## License

MigMouse is available under the [MIT License](LICENSE).
