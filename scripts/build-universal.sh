#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🌐 Building Requestly Universal 2 Binary (arm64 + x86_64)..."

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

# Unregister any existing build apps from LaunchServices
$LSREGISTER -u "$DIR/build/Requestly.app" 2>/dev/null || true
$LSREGISTER -u "$DIR/build/universal/Requestly.app" 2>/dev/null || true

BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/Requestly.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

TMP_BUILD="$BUILD_DIR/tmp_compile"
TMP_ARM="$TMP_BUILD/arm64"
TMP_X86="$TMP_BUILD/x86_64"

# Clean up duplicate paths and temporary directories completely
rm -rf "$APP_BUNDLE" "$DIR/build/universal" "$TMP_BUILD"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$RESOURCES_DIR" "$TMP_ARM" "$TMP_X86"

# Instruct macOS Spotlight to NEVER index the build output folder as an installed app
touch "$BUILD_DIR/.metadata_never_index"

# Generate application icon on-the-fly if needed
if [ ! -f "Resources/AppIcon.icns" ] || [ "scripts/generate-icon.swift" -nt "Resources/AppIcon.icns" ]; then
    echo "🎨 Generating application icon with generate-icon.swift..."
    swift scripts/generate-icon.swift
fi

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

rm -rf "$TMP_BUILD"

echo "Installing metadata..."
cp Resources/Info.plist "$CONTENTS_DIR/Info.plist"
cp Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

echo "Signing Universal application bundle with Hardened Runtime..."
codesign --force --options runtime --entitlements Resources/Requestly.entitlements -s - "$FRAMEWORKS_DIR/libRequestlyCore.dylib"
codesign --force --options runtime --entitlements Resources/Requestly.entitlements -s - "$APP_BUNDLE"

echo "Verifying Universal architectures:"
lipo -info "$MACOS_DIR/Requestly"
lipo -info "$FRAMEWORKS_DIR/libRequestlyCore.dylib"

echo "✅ Successfully built single Universal 2 Application: $APP_BUNDLE"
