#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="RouteTone"
VERSION="${1:-}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"

if [ -z "$VERSION" ]; then
  echo "Usage: ./Scripts/package-release.sh <version>"
  exit 1
fi

"$ROOT_DIR/Scripts/build-app.sh"

ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"

rm -f "$ZIP_PATH" "$CHECKSUM_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

echo "Packaged $ZIP_PATH"
echo "Checksum $CHECKSUM_PATH"
