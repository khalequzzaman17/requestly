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

rm -rf "$APP_BUNDLE" "$DIR/build/universal"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$RESOURCES_DIR"
touch "$BUILD_DIR/.metadata_never_index"

CORE_SRCS=$(find Sources/RequestlyCore -name '*.swift')
APP_SRCS=$(find Sources/RequestlyApp -name '*.swift')

echo "Compiling RequestlyCore..."
swiftc -O -emit-module -module-name RequestlyCore -emit-library \
    -Xlinker -install_name -Xlinker "@rpath/libRequestlyCore.dylib" \
    -o "$FRAMEWORKS_DIR/libRequestlyCore.dylib" $CORE_SRCS

echo "Compiling Requestly executable..."
swiftc -O -parse-as-library \
    -I "$FRAMEWORKS_DIR" -L "$FRAMEWORKS_DIR" -lRequestlyCore \
    -Xlinker -rpath -Xlinker "@executable_path/../Frameworks" \
    $APP_SRCS -o "$MACOS_DIR/Requestly"

echo "Installing metadata and resources..."
cp Resources/Info.plist "$CONTENTS_DIR/Info.plist"
cp Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "Signing application bundle with Hardened Runtime..."
codesign --force --options runtime --entitlements Resources/Requestly.entitlements -s - "$FRAMEWORKS_DIR/libRequestlyCore.dylib"
codesign --force --options runtime --entitlements Resources/Requestly.entitlements -s - "$APP_BUNDLE"

echo "✅ Successfully built: $APP_BUNDLE"
