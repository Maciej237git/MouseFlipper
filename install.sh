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

echo "→ Uruchamianie razem z macOS (LaunchAgent)..."
USER_ID="$(id -u)"
LABEL="com.maciejcybula.MouseFlip"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/open</string>
    <string>-a</string>
    <string>${TARGET}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF
launchctl bootout "gui/${USER_ID}/${LABEL}" 2>/dev/null || true
if launchctl bootstrap "gui/${USER_ID}" "$PLIST" 2>/dev/null; then
  echo "  LaunchAgent włączony."
else
  echo "  LaunchAgent zapisany — suwak w aplikacji też to obsługuje."
fi

# Usuń stary wpis login items (legacy), jeśli istnieje
osascript <<EOF 2>/dev/null || true
tell application "System Events"
    set targetPath to "$TARGET"
    repeat with li in login items
        if path of li is targetPath then
            delete li
            exit repeat
        end if
    end repeat
end tell
EOF

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
