#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🧪 Building and Running Requestly Test Suite..."

BUILD_DIR="$DIR/build/test"
mkdir -p "$BUILD_DIR"

CORE_SRCS=$(find Sources/RequestlyCore -name '*.swift')
TEST_SRCS=$(find Tests/RequestlyTests -name '*.swift')

echo "Compiling RequestlyCore..."
swiftc -emit-module -module-name RequestlyCore -emit-library \
    -o "$BUILD_DIR/libRequestlyCore.dylib" $CORE_SRCS

echo "Compiling Test Runner..."
swiftc -parse-as-library \
    -I "$BUILD_DIR" -L "$BUILD_DIR" -lRequestlyCore \
    -Xlinker -rpath -Xlinker "$BUILD_DIR" \
    $TEST_SRCS -o "$BUILD_DIR/test-runner"

echo "Executing Tests..."
"$BUILD_DIR/test-runner"

