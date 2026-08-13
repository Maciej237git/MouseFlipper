#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MouseFlip"
SOURCE_APP="$ROOT/build/$APP_NAME.app"
TARGET="/Applications/$APP_NAME.app"

echo "→ Budowanie $APP_NAME..."
"$ROOT/build.sh"

echo ""
echo "→ Instalacja do /Applications..."
if [ -d "$TARGET" ]; then
  rm -rf "$TARGET"
fi
cp -R "$SOURCE_APP" "$TARGET"

echo "→ Podpis ad-hoc (Gatekeeper)..."
codesign --force --deep --sign - "$TARGET" 2>/dev/null || {
  echo "  (pominięto — brak codesign; na własnym Macu zwykle OK)"
}

echo ""
echo "✓ Zainstalowano: $TARGET"
echo ""
echo "Uruchamiam aplikację..."
open "$TARGET"

echo ""
echo "Po pierwszym uruchomieniu:"
echo "  1. Kliknij ikonę myszki w pasku menu (u góry ekranu)"
echo "  2. Włącz „Uruchamiaj razem z macOS” (jeśli nie włączyło się samo)"
echo "  3. Ustaw: Mysz = Normalny, Trackpad = Naturalny — raz i zapomnij"
echo ""
echo "Aplikacja działa w tle. Nie ma ikony w Docku — to normalne dla narzędzi menu bar."
