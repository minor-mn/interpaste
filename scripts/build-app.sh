#!/bin/bash
# interpaste.app を作って署名する。
# 同じ証明書で署名するので、再ビルドしてもアクセシビリティの許可は維持される。
set -euo pipefail
cd "$(dirname "$0")/.."

IDENTITY="9F3711F021D370C579E162E3A02F715657032042"  # 自己署名 "Dr.Nitrovic"
NAME="interpaste"
BUNDLE_ID="biz.umr.interpaste"
APP="build/${NAME}.app"
VERSION="${VERSION:-0.1}"
KEYCHAIN="${KEYCHAIN:-}"

swift build -c release --product "$NAME"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp ".build/release/${NAME}" "$APP/Contents/MacOS/${NAME}"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

keychain_args=()
[ -n "$KEYCHAIN" ] && keychain_args=(--keychain "$KEYCHAIN")
codesign --force ${keychain_args[@]+"${keychain_args[@]}"} --sign "$IDENTITY" "$APP"
echo "built: $APP"
