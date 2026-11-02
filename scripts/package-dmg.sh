#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "📦 Packaging Requestly into Universal DMG..."

APP_BUNDLE="$DIR/build/universal/Requestly.app"
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Universal app not found. Running build-universal.sh first..."
    "$DIR/scripts/build-universal.sh"
fi

DMG_STAGE="$DIR/build/dmg_staging"
DMG_OUTPUT="$DIR/build/Requestly-Universal.dmg"

rm -rf "$DMG_STAGE" "$DMG_OUTPUT"
mkdir -p "$DMG_STAGE"

echo "Copying Requestly.app to staging area..."
cp -R "$APP_BUNDLE" "$DMG_STAGE/"

echo "Creating /Applications symlink for drag-and-drop installer..."
ln -s /Applications "$DMG_STAGE/Applications"

echo "Generating compressed DMG image with hdiutil..."
hdiutil create -volname "Requestly" \
    -srcfolder "$DMG_STAGE" \
    -ov -format UDZO \
    "$DMG_OUTPUT"

rm -rf "$DMG_STAGE"

echo "Checking DMG file size and signature..."
ls -lh "$DMG_OUTPUT"

echo "✅ Created distributable DMG: $DMG_OUTPUT"

