#!/bin/bash
set -euo pipefail

# Bundle a compiled binary into a macOS .app bundle

PRODUCT_NAME="VoiceInput"
APP_NAME="Voice Input"
BUILD_DIR=".build"
APP_BUNDLE="${APP_NAME}.app"

echo "📦 Bundling ${APP_NAME}..."

# Find the compiled binary
BINARY="${BUILD_DIR}/${PRODUCT_NAME}"
if [ ! -f "$BINARY" ]; then
    echo "❌ Binary not found at ${BINARY}. Run 'make build' first."
    exit 1
fi

# Clean previous bundle
rm -rf "${APP_BUNDLE}"

# Create .app bundle structure
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BINARY}" "${APP_BUNDLE}/Contents/MacOS/${PRODUCT_NAME}"

# Copy Info.plist
PLIST_SOURCE="Sources/VoiceInput/Resources/Info.plist"
if [ -f "$PLIST_SOURCE" ]; then
    cp "$PLIST_SOURCE" "${APP_BUNDLE}/Contents/Info.plist"
else
    echo "⚠️  Info.plist not found at ${PLIST_SOURCE}"
    exit 1
fi

# Copy app icon
ICON_SOURCE="Sources/VoiceInput/Resources/AppIcon.icns"
if [ -f "$ICON_SOURCE" ]; then
    cp "$ICON_SOURCE" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    echo "🎨 App icon copied"
else
    echo "⚠️  App icon not found at ${ICON_SOURCE}, skipping..."
fi

# Create PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# Ad-hoc code sign
echo "🔏 Signing..."
codesign --force --sign - --deep --timestamp=none "${APP_BUNDLE}"

echo "✅ Bundle created: ${APP_BUNDLE}"
echo "   Run with: open '${APP_BUNDLE}'"
