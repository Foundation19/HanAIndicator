#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build/HanAIndicator.app"
BIN="$APP/Contents/MacOS/HanAIndicator"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc "$ROOT/Sources/HanAIndicator.swift" \
  -framework AppKit \
  -framework Carbon \
  -framework ApplicationServices \
  -o "$BIN"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>HanAIndicator</string>
  <key>CFBundleIdentifier</key>
  <string>local.caticator.app</string>
  <key>CFBundleName</key>
  <string>Caticator</string>
  <key>CFBundleDisplayName</key>
  <string>Caticator</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.3.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Local utility</string>
</dict>
</plist>
PLIST

# 고정 인증서로 서명 — 빌드마다 해시가 바뀌지 않아 AX 권한 유지됨
CERT="HanAIndicator Local"
if security find-certificate -c "$CERT" ~/Library/Keychains/login.keychain-db >/dev/null 2>&1; then
  codesign --force --deep --sign "$CERT" "$APP" 2>/dev/null \
    && echo "Signed: $CERT" \
    || { echo "서명 실패 → ad-hoc 폴백"; codesign --force --deep --sign - "$APP" >/dev/null; }
else
  codesign --force --deep --sign - "$APP" >/dev/null
fi
echo "Built: $APP"
