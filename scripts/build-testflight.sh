#!/usr/bin/env bash
# Build an App Store–ready IPA for TestFlight upload.
#
# Required environment variables:
#   DEVELOPMENT_TEAM — Apple Developer Team ID (10-character string)
#
# Optional:
#   CONFIGURATION — Release (default) or Debug
#   ARCHIVE_PATH  — override archive output path
#   EXPORT_PATH   — override IPA export directory
#
# Prerequisites:
#   - Full Xcode installed (xcode-select -p)
#   - Apple ID signed in under Xcode → Settings → Accounts
#   - App ID ai.swarm.game with Game Center enabled in Developer portal
#
# Example:
#   DEVELOPMENT_TEAM=ABCDE12345 ./scripts/build-testflight.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS="$ROOT/ios"
SCHEME="SWARM"
CONFIGURATION="${CONFIGURATION:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT/build/SWARM.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT/build/export}"
EXPORT_OPTIONS="${EXPORT_PATH}/ExportOptions.plist"
IPA_PATH="$EXPORT_PATH/SWARM.ipa"

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  echo "error: DEVELOPMENT_TEAM is required (your Apple Developer Team ID)" >&2
  exit 1
fi

command -v xcodegen >/dev/null || { echo "error: install xcodegen (brew install xcodegen)" >&2; exit 1; }
command -v xcodebuild >/dev/null || { echo "error: install Xcode and run xcode-select --install" >&2; exit 1; }

mkdir -p "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH"

echo "→ Regenerating Xcode project…"
(cd "$IOS" && xcodegen generate)

echo "→ Writing export options (team $DEVELOPMENT_TEAM)…"
cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store</string>
	<key>teamID</key>
	<string>${DEVELOPMENT_TEAM}</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>uploadSymbols</key>
	<true/>
	<key>destination</key>
	<string>export</string>
</dict>
</plist>
PLIST

echo "→ Archiving ($CONFIGURATION) for generic iOS device…"
xcodebuild archive \
  -project "$IOS/SWARM.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  -allowProvisioningUpdates

echo "→ Exporting IPA…"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  -allowProvisioningUpdates

if [[ ! -f "$IPA_PATH" ]]; then
  echo "error: expected IPA not found at $IPA_PATH" >&2
  exit 1
fi

echo "✓ IPA ready: $IPA_PATH"
echo "  Upload with Apple Transporter (drag IPA) or:"
echo "  xcrun iTMSTransporter -m upload -assetFile $IPA_PATH -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD"