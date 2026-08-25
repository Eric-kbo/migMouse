#!/bin/zsh

set -euo pipefail

ROOT_DIR="${0:A:h:h}"
PROJECT_PATH="$ROOT_DIR/MigMouse.xcodeproj"
SCHEME="MigMouse"
TEAM_ID="${MIGMOUSE_TEAM_ID:-W7QQ8937A7}"
PLIST_PATH="$ROOT_DIR/MigMouse/Supporting/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST_PATH")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST_PATH")"
if [[ ! "$VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' || ! "$BUILD" =~ '^[0-9]+$' ]]; then
  echo "Info.plist contains an invalid release version or build number." >&2
  exit 1
fi

OUTPUT_DIR="$ROOT_DIR/dist/v$VERSION"
ARCHIVE_PATH="$OUTPUT_DIR/MigMouse.xcarchive"
UPLOAD_PATH="$OUTPUT_DIR/upload"
NOTARIZED_PATH="$OUTPUT_DIR/notarized"
ZIP_NAME="MigMouse-v$VERSION.zip"
ZIP_PATH="$OUTPUT_DIR/$ZIP_NAME"
TEMP_DIR="$(mktemp -d -t MigMouseRelease)"
EXPORT_OPTIONS="$TEMP_DIR/ExportOptions.plist"
NOTARY_LOG="$TEMP_DIR/Notarization.log"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"
rm -rf "$ARCHIVE_PATH" "$UPLOAD_PATH" "$NOTARIZED_PATH" "$ZIP_PATH" "$ZIP_PATH.sha256"

cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
</dict>
</plist>
PLIST

echo "Testing MigMouse v$VERSION ($BUILD)…"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test

echo "Archiving with Developer ID team $TEAM_ID…"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive

echo "Uploading to Apple for notarization…"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$UPLOAD_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -allowProvisioningUpdates

echo "Waiting for Apple notarization…"
for attempt in {1..120}; do
  rm -rf "$NOTARIZED_PATH"
  mkdir -p "$NOTARIZED_PATH"

  if xcodebuild \
    -exportNotarizedApp \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$NOTARIZED_PATH" >"$NOTARY_LOG" 2>&1; then
    cat "$NOTARY_LOG"
    break
  fi

  if ! grep -q 'processing and not ready for distribution' "$NOTARY_LOG"; then
    cat "$NOTARY_LOG" >&2
    exit 1
  fi

  if (( attempt == 120 )); then
    echo "Apple notarization did not finish within 30 minutes." >&2
    exit 1
  fi

  sleep 15
done

APP_PATH="$NOTARIZED_PATH/MigMouse.app"
test -d "$APP_PATH"

# Finder can attach this metadata when the output directory is synced by a
# file provider. It is not application content and strict code validation
# rejects it even though the Apple-notarized signature is otherwise valid.
xattr -d com.apple.FinderInfo "$APP_PATH" 2>/dev/null || true

echo "Validating Developer ID signature, notarization, and stapled ticket…"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"
xcrun stapler validate "$APP_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
(
  cd "$OUTPUT_DIR"
  shasum -a 256 "$ZIP_NAME" | tee "$ZIP_NAME.sha256"
)

echo
echo "Release artifact: $ZIP_PATH"
echo "Version: v$VERSION ($BUILD)"
