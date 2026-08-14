#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MouseFlip"
BUILD_APP="$ROOT/build/$APP_NAME.app"
STAGE_DIR="$ROOT/build/release-stage"
ZIP="$ROOT/build/${APP_NAME}.zip"

"$ROOT/build.sh"

if [ ! -d "$BUILD_APP" ]; then
  echo "Brak $BUILD_APP"
  exit 1
fi

echo "→ Czyszczenie atrybutów (quarantine/resource forks)..."
xattr -cr "$BUILD_APP"

echo "→ Podpis ad-hoc..."
codesign --force --deep --sign - "$BUILD_APP"

echo "→ Weryfikacja podpisu..."
codesign --verify --deep "$BUILD_APP"

echo "→ Pakowanie do ZIP (app + INSTALACJA.txt)..."
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
ditto --norsrc "$BUILD_APP" "$STAGE_DIR/$APP_NAME.app"
cp "$ROOT/INSTALACJA.txt" "$STAGE_DIR/"
rm -f "$ZIP"
(
  cd "$STAGE_DIR"
  zip -r -y "$ZIP" "$APP_NAME.app" INSTALACJA.txt
)

echo ""
echo "✓ Gotowe: $ZIP"
echo ""
echo "⚠️  Pobranie z GitHub = macOS zablokuje zwykły dwuklik."
echo "    Pierwsze uruchomienie: klik PRAWY → Otwórz"
echo "    (albo: xattr -d com.apple.quarantine /Applications/MouseFlip.app)"
echo ""
echo "Wrzuć ten ZIP na GitHub Release i dołącz tekst z INSTALACJA.txt do opisu."
