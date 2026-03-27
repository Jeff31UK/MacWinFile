#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="MacWinFile"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Find all Swift source files
SWIFT_FILES=$(find "$PROJECT_DIR/MacWinFile" -name "*.swift" -type f)

echo "Compiling $APP_NAME..."
echo "Swift files:"
echo "$SWIFT_FILES" | while read f; do echo "  $(basename "$f")"; done

# Compile
swiftc \
    -o "$MACOS/$APP_NAME" \
    -target arm64-apple-macosx14.0 \
    -sdk $(xcrun --show-sdk-path) \
    -framework AppKit \
    -framework SwiftUI \
    -swift-version 5 \
    $SWIFT_FILES

# Copy Info.plist
cp "$PROJECT_DIR/MacWinFile/App/Info.plist" "$CONTENTS/Info.plist"

# PkgInfo
echo -n "APPL????" > "$CONTENTS/PkgInfo"

# Generate app icon (.icns from PNGs)
ICON_DIR="$PROJECT_DIR/MacWinFile/Resources/Assets.xcassets/AppIcon.appiconset"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"
cp "$ICON_DIR/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$ICON_DIR/icon_32x32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$ICON_DIR/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$ICON_DIR/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$ICON_DIR/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$ICON_DIR/icon_256x256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$ICON_DIR/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$ICON_DIR/icon_512x512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$ICON_DIR/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$ICON_DIR/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"
iconutil -c icns -o "$RESOURCES/AppIcon.icns" "$ICONSET_DIR"
rm -rf "$ICONSET_DIR"

# Ad-hoc code sign to prevent macOS "unverified developer" prompts on each rebuild
codesign --force --deep --sign - "$APP_BUNDLE"

# Remove quarantine flag if present
xattr -dr com.apple.quarantine "$APP_BUNDLE" 2>/dev/null || true

# Force Finder to refresh the icon
touch "$APP_BUNDLE"
/usr/bin/killall Finder 2>/dev/null || true

echo ""
echo "Build complete: $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"
