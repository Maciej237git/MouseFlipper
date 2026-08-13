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

echo "→ Uruchamianie razem z macOS..."
LOGIN_RESULT=$(osascript <<EOF 2>/dev/null || echo "failed"
tell application "System Events"
    set targetPath to "$TARGET"
    repeat with li in login items
        if path of li is targetPath then
            return "already"
        end if
    end repeat
    make login item at end with properties {path:targetPath, hidden:false}
    return "registered"
end tell
EOF
)
case "$LOGIN_RESULT" in
  registered) echo "  Dodano do elementów logowania." ;;
  already)    echo "  Już jest w elementach logowania." ;;
  *)          echo "  Nie udało się dodać automatycznie — włącz ręcznie w panelu MouseFlip." ;;
esac

echo ""
echo "✓ Zainstalowano: $TARGET"
echo ""
echo "Uruchamiam aplikację..."
open "$TARGET"

echo ""
echo "Po pierwszym uruchomieniu:"
echo "  1. Kliknij ikonę myszki w pasku menu (u góry ekranu)"
echo "  2. Sprawdź: Mysz = Normalny, Trackpad = Naturalny, Automatyczne przełączanie = włączone"
echo ""
echo "MouseFlip startuje sam po włączeniu Maca. Nie ma ikony w Docku — to normalne."
