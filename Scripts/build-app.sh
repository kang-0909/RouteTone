#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="RouteTone"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/Resources/AppBundle/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
if [ -f "$ROOT_DIR/Resources/AppBundle/AppIcon.icns" ]; then
  cp "$ROOT_DIR/Resources/AppBundle/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
chmod +x "$MACOS_DIR/$APP_NAME"

# Re-sign the executable and bundle as a coherent ad-hoc app package.
# Without this, Swift's linker-signed binary can produce a bundle that
# Gatekeeper reports as "damaged" after download/quarantine.
codesign --force --sign - "$MACOS_DIR/$APP_NAME"
codesign --force --sign - "$APP_DIR"

echo "Built $APP_DIR"
