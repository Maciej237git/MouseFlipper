#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MouseFlip"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"

SDK="$(xcrun --show-sdk-path --sdk macosx)"
ARCH="$(uname -m)"
TARGET="$ARCH-apple-macos13.0"

echo "→ Budowanie $APP_NAME..."
echo "  SDK:    $SDK"
echo "  Target: $TARGET"

mkdir -p "$MACOS_DIR"

SOURCES=(
  "$ROOT/MouseFlip/Models/ScrollDirection.swift"
  "$ROOT/MouseFlip/Models/HIDMouseDevice.swift"
  "$ROOT/MouseFlip/Utilities/MouseFlipLogger.swift"
  "$ROOT/MouseFlip/Utilities/Color+MouseFlip.swift"
  "$ROOT/MouseFlip/Utilities/MouseFlipSettings.swift"
  "$ROOT/MouseFlip/Services/ScrollDirectionManager.swift"
  "$ROOT/MouseFlip/Services/HIDMouseMonitor.swift"
  "$ROOT/MouseFlip/Services/LaunchAtLoginManager.swift"
  "$ROOT/MouseFlip/Services/WakeMonitor.swift"
  "$ROOT/MouseFlip/ViewModels/MouseFlipViewModel.swift"
  "$ROOT/MouseFlip/Views/MenuBarView.swift"
  "$ROOT/MouseFlip/Views/MenuBarPanelSizeFixer.swift"
  "$ROOT/MouseFlip/Views/StatusCard.swift"
  "$ROOT/MouseFlip/Views/ScrollSettingsCard.swift"
  "$ROOT/MouseFlip/Views/StartupSettingsCard.swift"
  "$ROOT/MouseFlip/Views/PrivacyFooter.swift"
  "$ROOT/MouseFlip/App/MouseFlipApp.swift"
)

swiftc \
  -sdk "$SDK" \
  -target "$TARGET" \
  -parse-as-library \
  -O \
  -framework SwiftUI \
  -framework AppKit \
  -framework IOKit \
  -framework ServiceManagement \
  -framework Combine \
  -framework CoreFoundation \
  "${SOURCES[@]}" \
  -o "$MACOS_DIR/$APP_NAME"

cat > "$CONTENTS/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>pl</string>
  <key>CFBundleExecutable</key>
  <string>MouseFlip</string>
  <key>CFBundleIdentifier</key>
  <string>com.maciejcybula.MouseFlip</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>MouseFlip</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
EOF

echo ""
echo "✓ Gotowe: $APP_DIR"
echo ""
echo "Uruchom:"
echo "  open \"$APP_DIR\""
echo ""
echo "Albo skopiuj do Aplikacji:"
echo "  cp -R \"$APP_DIR\" /Applications/"
