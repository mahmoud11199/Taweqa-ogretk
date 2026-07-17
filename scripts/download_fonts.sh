#!/bin/bash
# Download Cairo variable font for the project
set -e

FONT_DIR="$(dirname "$0")/../assets/fonts"
mkdir -p "$FONT_DIR"

URL="https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf"
OUT="$FONT_DIR/Cairo-Variable.ttf"

echo "Downloading Cairo variable font..."
curl -fSL "$URL" -o "$OUT"
echo "Done! Saved to $OUT"
