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
# Example:
#   DEVELOPMENT_TEAM=ABCDE12345 ./scripts/build-testflight.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS="$ROOT/ios"
SCHEME="SWARM"
CONFIGURATION="${CONFIGURATION:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT/build/SWARM.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT/build/export}"
EXPORT_OPTIONS="$IOS/ExportOptions.plist"

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  echo "error: DEVELOPMENT_TEAM is required (your Apple Developer Team ID)" >&2
  exit 1
fi

command -v xcodegen >/dev/null || { echo "error: install xcodegen (brew install xcodegen)" >&2; exit 1; }

mkdir -p "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH"

echo "→ Regenerating Xcode project…"
(cd "$IOS" && xcodegen generate)

echo "→ Archiving ($CONFIGURATION)…"
xcodebuild archive \
  -project "$IOS/SWARM.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
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

echo "✓ IPA ready: $EXPORT_PATH/SWARM.ipa"
echo "  Upload with Transporter or: xcrun altool --upload-app -f $EXPORT_PATH/SWARM.ipa -t ios"