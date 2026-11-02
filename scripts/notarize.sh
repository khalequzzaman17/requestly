#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🔐 Apple Notarization Script for Requestly..."

DMG_PATH="$DIR/build/Requestly-Universal.dmg"

if [ ! -f "$DMG_PATH" ]; then
    echo "DMG not found at $DMG_PATH. Running package-dmg.sh first..."
    "$DIR/scripts/package-dmg.sh"
fi

echo "=========================================================="
echo "Apple Notarization Requirements:"
echo "1. Apple Developer Program Membership"
echo "2. Developer ID Application Certificate in Keychain"
echo "3. App-Specific Password or Keychain Profile configured"
echo "=========================================================="

if [ -n "$KEYCHAIN_PROFILE" ]; then
    echo "Submitting DMG for notarization using keychain profile '$KEYCHAIN_PROFILE'..."
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait
elif [ -n "$APPLE_ID" ] && [ -n "$TEAM_ID" ] && [ -n "$APP_SPECIFIC_PASSWORD" ]; then
    echo "Submitting DMG for notarization using Apple ID: $APPLE_ID (Team: $TEAM_ID)..."
    xcrun notarytool submit "$DMG_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --wait
else
    echo "⚠️  Missing Notarization Credentials."
    echo "To notarize your build for distribution, export either:"
    echo "  export KEYCHAIN_PROFILE=\"YOUR_KEYCHAIN_PROFILE_NAME\""
    echo "or:"
    echo "  export APPLE_ID=\"developer@apple.com\""
    echo "  export TEAM_ID=\"TEAM_ID_HERE\""
    echo "  export APP_SPECIFIC_PASSWORD=\"abcd-efgh-ijkl-mnop\""
    echo ""
    echo "Once set, re-run this script: ./scripts/notarize.sh"
    exit 0
fi

echo "Stapling notarization ticket to DMG..."
xcrun stapler staple "$DMG_PATH"

echo "Verifying notarization ticket..."
spctl --assess --type open --context context:primary-signature -v "$DMG_PATH" || true

echo "✅ Notarization and stapling complete for: $DMG_PATH"

