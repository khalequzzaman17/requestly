#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🌐 Building Requestly Universal 2 Binary (arm64 + x86_64)..."

BUILD_DIR="$DIR/build/universal"
APP_BUNDLE="$BUILD_DIR/Requestly.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

TMP_ARM="$BUILD_DIR/tmp_arm64"
TMP_X86="$BUILD_DIR/tmp_x86_64"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$RESOURCES_DIR" "$TMP_ARM" "$TMP_X86"

CORE_SRCS=$(find Sources/RequestlyCore -name '*.swift')
APP_SRCS=$(find Sources/RequestlyApp -name '*.swift')

echo "Compiling RequestlyCore for arm64..."
swiftc -O -target arm64-apple-macosx13.0 -emit-module -module-name RequestlyCore -emit-library \
    -Xlinker -install_name -Xlinker "@rpath/libRequestlyCore.dylib" \
    -o "$TMP_ARM/libRequestlyCore.dylib" $CORE_SRCS

echo "Compiling Requestly executable for arm64..."
swiftc -O -target arm64-apple-macosx13.0 -parse-as-library \
    -I "$TMP_ARM" -L "$TMP_ARM" -lRequestlyCore \
    -Xlinker -rpath -Xlinker "@executable_path/../Frameworks" \
    $APP_SRCS -o "$TMP_ARM/Requestly"

echo "Compiling RequestlyCore for x86_64..."
swiftc -O -target x86_64-apple-macosx13.0 -emit-module -module-name RequestlyCore -emit-library \
    -Xlinker -install_name -Xlinker "@rpath/libRequestlyCore.dylib" \
    -o "$TMP_X86/libRequestlyCore.dylib" $CORE_SRCS

echo "Compiling Requestly executable for x86_64..."
swiftc -O -target x86_64-apple-macosx13.0 -parse-as-library \
    -I "$TMP_X86" -L "$TMP_X86" -lRequestlyCore \
    -Xlinker -rpath -Xlinker "@executable_path/../Frameworks" \
    $APP_SRCS -o "$TMP_X86/Requestly"

echo "Merging binaries with lipo into Universal 2..."
lipo -create "$TMP_ARM/libRequestlyCore.dylib" "$TMP_X86/libRequestlyCore.dylib" -output "$FRAMEWORKS_DIR/libRequestlyCore.dylib"
lipo -create "$TMP_ARM/Requestly" "$TMP_X86/Requestly" -output "$MACOS_DIR/Requestly"

rm -rf "$TMP_ARM" "$TMP_X86"

echo "Installing metadata..."
cp Resources/Info.plist "$CONTENTS_DIR/Info.plist"
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "Signing Universal application bundle..."
codesign --force --deep -s - "$APP_BUNDLE"

echo "Verifying Universal architectures:"
lipo -info "$MACOS_DIR/Requestly"
lipo -info "$FRAMEWORKS_DIR/libRequestlyCore.dylib"

echo "✅ Successfully built Universal 2 Application: $APP_BUNDLE"
