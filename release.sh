#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ZIP="$ROOT/build/MouseFlip.zip"
TAG="${1:-v1.0.0}"
TITLE="${2:-MouseFlip 1.0.0}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Brak gh — zainstaluj: brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "→ Logowanie do GitHub (otworzy się przeglądarka)..."
  gh auth login --hostname github.com --git-protocol ssh --web
fi

echo "→ Budowanie ZIP..."
"$ROOT/share.sh"

BODY="$(cat <<'EOF'
## MouseFlip — auto scroll mysz / trackpad

- Mysz podłączona → scroll **normalny** (Windows-style)
- Mysz odłączona → scroll **naturalny** (trackpad)
- macOS 13+, Intel lub Apple Silicon
- 100% lokalnie, bez sieci

### Instalacja

1. Pobierz **MouseFlip.zip** poniżej
2. Rozpakuj → przeciągnij `MouseFlip.app` do folderu **Aplikacje**
3. **Pierwsze uruchomienie:** klik **prawy** na aplikację → **Otwórz** → **Otwórz**  
   (macOS blokuje niepodpisane aplikacje pobrane z internetu — to nie wirus)
4. Kliknij ikonę myszki w pasku menu → włącz **Uruchamiaj razem z macOS**

Alternatywa w terminalu:
```bash
xattr -d com.apple.quarantine /Applications/MouseFlip.app
open /Applications/MouseFlip.app
```

Szczegóły też w pliku `INSTALACJA.txt` w ZIP-ie.
EOF
)"

echo "→ Tworzenie / aktualizacja release $TAG..."
if gh release view "$TAG" >/dev/null 2>&1; then
  gh release upload "$TAG" "$ZIP" --clobber
  gh release edit "$TAG" --title "$TITLE" --notes "$BODY"
  echo "✓ Zaktualizowano release $TAG"
else
  gh release create "$TAG" "$ZIP" --title "$TITLE" --notes "$BODY"
  echo "✓ Utworzono release $TAG"
fi

gh release view "$TAG" --web 2>/dev/null || gh release view "$TAG"
