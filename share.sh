#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MouseFlip"
BUILD_APP="$ROOT/build/$APP_NAME.app"
ZIP="$ROOT/build/${APP_NAME}.zip"

"$ROOT/build.sh"

if [ ! -d "$BUILD_APP" ]; then
  echo "Brak $BUILD_APP"
  exit 1
fi

echo "→ Podpis ad-hoc..."
codesign --force --deep --sign - "$BUILD_APP" 2>/dev/null || true

echo "→ Pakowanie do ZIP..."
rm -f "$ZIP"
ditto -c -k --keepParent "$BUILD_APP" "$ZIP"

echo ""
echo "✓ Gotowe do wysłania: $ZIP"
echo ""
echo "Kolega powinien:"
echo "  1. Rozpakować ZIP"
echo "  2. Przeciągnąć MouseFlip.app do folderu Aplikacje"
echo "  3. Pierwsze uruchomienie: klik prawy → Otwórz (nie dwuklik — Gatekeeper)"
echo "  4. W panelu włączyć „Uruchamiaj razem z macOS”"
echo ""
echo "Wymagania: macOS 13 lub nowszy, Mac z Apple Silicon albo Intel."
