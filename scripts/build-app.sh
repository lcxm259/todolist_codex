#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${1:-release}"
APP_DIR="$ROOT/build/todo list.app"
CONTENTS="$APP_DIR/Contents"

swift build --package-path "$ROOT" -c "$CONFIGURATION"

mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$ROOT/.build/$CONFIGURATION/NotchNotes" "$CONTENTS/MacOS/NotchNotes"
cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
