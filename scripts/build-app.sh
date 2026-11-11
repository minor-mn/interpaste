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
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/${NAME}" "$APP/Contents/MacOS/${NAME}"

# アイコン。scripts/make-icon.swift で描いた絵から、大きさごとの絵を作って .icns にまとめる。
icons=.build/AppIcon.iconset
rm -rf "$icons"
mkdir -p "$icons"
swift scripts/make-icon.swift .build/AppIcon.png
for n in 16 32 128 256 512; do
  sips -z $n $n .build/AppIcon.png --out "$icons/icon_${n}x${n}.png" >/dev/null
  sips -z $((n * 2)) $((n * 2)) .build/AppIcon.png --out "$icons/icon_${n}x${n}@2x.png" >/dev/null
done
iconutil -c icns "$icons" -o "$APP/Contents/Resources/AppIcon.icns"

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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
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
