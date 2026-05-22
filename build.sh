#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build/Caticator.app"
BIN="$APP/Contents/MacOS/Caticator"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc "$ROOT/Sources/Caticator.swift" \
  -framework AppKit \
  -framework Carbon \
  -framework ApplicationServices \
  -framework ServiceManagement \
  -o "$BIN"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Caticator</string>
  <key>CFBundleIdentifier</key>
  <string>local.caticator.app</string>
  <key>CFBundleName</key>
  <string>Caticator</string>
  <key>CFBundleDisplayName</key>
  <string>Caticator</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.3.3</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>NSHumanReadableCopyright</key>
  <string>Local utility</string>
</dict>
</plist>
PLIST

# 아이콘 번들에 복사 (Sources 옆에 AppIcon.icns가 있으면 사용)
if [ -f "$ROOT/AppIcon.icns" ]; then
  cp "$ROOT/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

# 고정 인증서로 서명
CERT="HanAIndicator Local"
if security find-certificate -c "$CERT" ~/Library/Keychains/login.keychain-db >/dev/null 2>&1; then
  codesign --force --deep --sign "$CERT" "$APP" 2>/dev/null \
    && echo "Signed: $CERT" \
    || { echo "서명 실패 → ad-hoc 폴백"; codesign --force --deep --sign - "$APP" >/dev/null; }
else
  codesign --force --deep --sign - "$APP" >/dev/null
fi
echo "Built: $APP"
