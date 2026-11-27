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

Build from the release commit with no uncommitted changes to tracked files. Create an annotated tag named `v<VERSION>` from that same commit and publish a GitHub Release with the ZIP and SHA-256 file.

For releases under AGPL-3.0-only, provide the complete corresponding source for the exact binary version at no additional charge. Verify that the release's automatically generated **Source code (zip)** and **Source code (tar.gz)** downloads contain the matching source, Xcode project, build scripts, and `LICENSE`. Add a direct link to that tag's source archive beside the binary download in the release notes, and keep the source available for as long as the binary is offered. Do not substitute a link to the changing default branch.

The app bundle includes the license text at `MigMouse.app/Contents/Resources/LICENSE`; retain it when packaging the app, along with the copyright information and required notices. If a modified version supports remote user interaction over a computer network, section 13 also requires prominently offering those users free access to that version's corresponding source. Earlier releases published under MIT retain their original license and permissions.

Download the ZIP from GitHub again and repeat the signature, Gatekeeper, stapler, and checksum checks on the downloaded artifact. Also verify that the bundled `LICENSE` matches the release tag and that the linked source archive can be downloaded.
