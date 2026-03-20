#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_PNG="${1:-$ROOT_DIR/Web/cover.png}"
TARGET_PNG="$ROOT_DIR/Web/cover.png"
TARGET_JPG="$ROOT_DIR/Web/cover.jpg"
MAX_SIZE="${MAX_SIZE:-1600x1600>}"
JPG_QUALITY="${JPG_QUALITY:-82}"

if ! command -v magick >/dev/null 2>&1; then
	echo "error: ImageMagick 'magick' is required." >&2
	exit 1
fi

if [ ! -f "$SOURCE_PNG" ]; then
	echo "error: source file not found: $SOURCE_PNG" >&2
	exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TMP_PNG="$TMP_DIR/cover.png"
TMP_JPG="$TMP_DIR/cover.jpg"

magick "$SOURCE_PNG" \
	-strip \
	-resize "$MAX_SIZE" \
	-colors 256 \
	PNG8:"$TMP_PNG"

magick "$SOURCE_PNG" \
	-strip \
	-resize "$MAX_SIZE" \
	-sampling-factor 4:2:0 \
	-interlace Plane \
	-quality "$JPG_QUALITY" \
	"$TMP_JPG"

mv "$TMP_PNG" "$TARGET_PNG"
mv "$TMP_JPG" "$TARGET_JPG"

echo "Optimized cover assets:"
ls -lh "$TARGET_PNG" "$TARGET_JPG"
