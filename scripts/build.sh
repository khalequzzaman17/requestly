#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🔨 Building Requestly for native host architecture..."

BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/Requestly.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

TMP_DIR="$BUILD_DIR/tmp_build"
rm -rf "$APP_BUNDLE" "$DIR/build/universal" "$TMP_DIR"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$RESOURCES_DIR" "$TMP_DIR"
touch "$BUILD_DIR/.metadata_never_index"

# Generate application icon on-the-fly if needed
if [ ! -f "Resources/AppIcon.icns" ] || [ "scripts/generate-icon.swift" -nt "Resources/AppIcon.icns" ]; then
    echo "🎨 Generating application icon with generate-icon.swift..."
    swift scripts/generate-icon.swift
fi

CORE_SRCS=$(find Sources/RequestlyCore -name '*.swift')
APP_SRCS=$(find Sources/RequestlyApp -name '*.swift')

echo "Compiling RequestlyCore..."
swiftc -O -emit-module -module-name RequestlyCore -emit-library \
    -Xlinker -install_name -Xlinker "@rpath/libRequestlyCore.dylib" \
    -o "$TMP_DIR/libRequestlyCore.dylib" $CORE_SRCS

cp "$TMP_DIR/libRequestlyCore.dylib" "$FRAMEWORKS_DIR/libRequestlyCore.dylib"

echo "Compiling Requestly executable..."
swiftc -O -parse-as-library \
    -I "$TMP_DIR" -L "$TMP_DIR" -lRequestlyCore \
    -Xlinker -rpath -Xlinker "@executable_path/../Frameworks" \
    $APP_SRCS -o "$MACOS_DIR/Requestly"

rm -rf "$TMP_DIR"

echo "Installing metadata and resources..."
cp Resources/Info.plist "$CONTENTS_DIR/Info.plist"
cp Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "Signing application bundle with Hardened Runtime..."
codesign --force --options runtime --entitlements Resources/Requestly.entitlements -s - "$FRAMEWORKS_DIR/libRequestlyCore.dylib"
codesign --force --options runtime --entitlements Resources/Requestly.entitlements -s - "$APP_BUNDLE"

echo "✅ Successfully built: $APP_BUNDLE"
