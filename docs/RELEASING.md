# Releasing MigMouse

MigMouse is distributed outside the Mac App Store as a Developer ID signed and Apple-notarized application.

## Prerequisites

- An active Apple Developer Program membership
- Xcode signed in to the release team's Apple Account
- Permission for Xcode to manage Developer ID certificates
- Developer team ID `W7QQ8937A7`, or set `MIGMOUSE_TEAM_ID` to another team

No Apple Account password, app-specific password, certificate, or private key belongs in this repository. Xcode retrieves the signing identity and submits the archive using its signed-in account.

## Build and notarize

Update `CFBundleShortVersionString` and `CFBundleVersion` in `MigMouse/Supporting/Info.plist`, update `CHANGELOG.md`, then run:

```sh
./scripts/release_macos.sh
```

The script runs unit tests, creates a universal Release archive, signs it with Developer ID, uploads it to Apple, waits for notarization, exports the stapled app, checks it with Gatekeeper, and creates:

```text
dist/v<VERSION>/MigMouse-v<VERSION>.zip
dist/v<VERSION>/MigMouse-v<VERSION>.zip.sha256
```

Do not publish an artifact unless all three checks succeed:

- `codesign --verify --deep --strict`
- `spctl` reports `accepted` and `source=Notarized Developer ID`
- `stapler validate` reports that validation worked

## Publish

Create an annotated tag named `v<VERSION>` from the release commit and publish a GitHub Release with the ZIP and SHA-256 file. Download the ZIP from GitHub again and repeat the signature, Gatekeeper, stapler, and checksum checks on the downloaded artifact.
