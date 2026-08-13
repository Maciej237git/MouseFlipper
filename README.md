# MouseFlip

Lokalna aplikacja macOS (menu bar) — automatycznie przełącza kierunek przewijania:

- **Mysz podłączona** → scroll **normalny** (Windows-style)
- **Brak myszy** → scroll **naturalny** (trackpad)

Bez sieci, bez kont, bez App Store. Działa w tle od startu Maca.

---

## Wymagania

- **macOS 13.0** (Ventura) lub nowszy
- Mac **Intel** lub **Apple Silicon**
- Do budowania ze źródeł: **Xcode** albo **Command Line Tools** (`xcode-select --install`)

---

## Szybka instalacja (dla siebie)

```bash
git clone https://github.com/Maciej237git/MouseFlipper.git
cd MouseFlipper
./install.sh
```

Skrypt zbuduje aplikację, skopiuje ją do `/Applications/MouseFlip.app` i uruchomi.

### Po instalacji (ustaw raz)

1. Kliknij **ikonę myszki** w pasku menu (u góry ekranu, obok Wi‑Fi).
2. Sprawdź:
   - **Automatyczne przełączanie** — włączone
   - **Mysz → Normalny**
   - **Trackpad → Naturalny**
   - **Uruchamiaj razem z macOS** — włączone

Od tego momentu aplikacja startuje sama po restarcie Maca i przełącza scroll bez Twojej ingerencji.

> **Uwaga:** MouseFlip nie ma ikony w Docku — to normalne dla narzędzi menu bar. Działa dyskretnie w tle.

---

## Instalacja dla kolegi (z GitHuba)

### Opcja A — klonowanie repozytorium (zalecane)

```bash
git clone https://github.com/Maciej237git/MouseFlipper.git
cd MouseFlipper
./install.sh
```

### Opcja B — gotowy ZIP (bez Gita)

Jeśli ktoś wysłał Ci paczkę:

```bash
./share.sh   # buduje i tworzy build/MouseFlip.zip
```

Albo pobierz release z GitHub (jeśli dodany).

**Kolega robi:**

1. Rozpakowuje ZIP **albo** klonuje repo i uruchamia `./install.sh`
2. Przy **pierwszym uruchomieniu** (gdy macOS blokuje aplikację):  
   **klik prawy** na `MouseFlip.app` → **Otwórz** → **Otwórz**  
   (zwykły dwuklik przy niepodpisanej aplikacji często nie zadziała)
3. W panelu włącza **Uruchamiaj razem z macOS**

### Różne procesory (Intel vs Apple Silicon)

`build.sh` buduje pod architekturę **Twojego** Maca. Jeśli kolega ma inny typ procesora:

```bash
git clone https://github.com/Maciej237git/MouseFlipper.git
cd MouseFlipper
./build.sh    # zbuduje na jego Macu
./install.sh
```

Albo otwórz `MouseFlip.xcodeproj` w Xcode i naciśnij **⌘R**.

---

## Budowanie ręcznie

```bash
./build.sh                              # tylko build → build/MouseFlip.app
open build/MouseFlip.app                # uruchom z folderu projektu

cp -R build/MouseFlip.app /Applications/   # ręczna instalacja
```

### Xcode

1. Otwórz `MouseFlip.xcodeproj`
2. Schemat **MouseFlip** → **My Mac**
3. **⌘R** (Run)
4. Skopiuj `.app` z DerivedData do `/Applications/` albo użyj `./install.sh`

Opcjonalnie: **Signing & Capabilities** → **Automatically manage signing** + Apple ID — ułatwia „Uruchamiaj razem z macOS” i omija ostrzeżenia Gatekeeper.

---

## Jak to działa

| Element | Opis |
|--------|------|
| **Wykrywanie myszy** | I/O Registry (IOKit) — tylko podłączenie/odłączenie, bez Accessibility |
| **Scroll** | Zapis preferencji macOS + prywatne API `PreferencePanesSupport` (patrz `API_DOCUMENTATION.md`) |
| **Auto-start** | `SMAppService` — element logowania (wymaga aplikacji w `/Applications/`) |
| **UI** | SwiftUI `MenuBarExtra`, język polski |

---

## Rozwiązywanie problemów

| Problem | Rozwiązanie |
|--------|-------------|
| macOS nie chce uruchomić aplikacji | Klik prawy → **Otwórz**, albo podpisz w Xcode |
| Nie widać ikony | Szukaj **myszki** w pasku menu u góry, nie w Docku |
| Scroll się nie zmienia | Sprawdź **Mysz = Normalny**; odłącz i podłącz mysz |
| „Uruchamiaj razem z macOS” nie działa | Aplikacja musi być w `/Applications/`; włącz ręcznie w panelu |
| Po restarcie nic nie działa | Włącz auto-start w panelu MouseFlip |

Logi (debug): uruchom z Xcode (**⌘R**) i patrz w konsolę — linie `[MouseFlip]`.

---

## Prywatność

- Brak sieci, analityki, kont
- Brak Accessibility / Input Monitoring / CGEventTap
- Wszystko lokalnie na Twoim Macu

---

## Struktura projektu

```
MouseFlip/
  App/              — punkt wejścia
  Models/           — typy danych
  Services/         — HID, scroll, login, wake
  ViewModels/       — logika UI
  Views/            — SwiftUI
  Utilities/        — ustawienia, logi
build.sh            — build bez Xcode
install.sh          — build + instalacja do /Applications
share.sh            — build + ZIP do wysłania
```

Szczegóły API: [`API_DOCUMENTATION.md`](API_DOCUMENTATION.md)

---

## Licencja

Projekt na własny użytek — możesz klonować, budować i udostępniać znajomym. Bez gwarancji; prywatne API macOS może przestać działać w przyszłych wersjach systemu.
