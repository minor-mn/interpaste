#!/bin/sh
# interpaste をインストールする。
#   curl -fsSL https://raw.githubusercontent.com/minor-mn/interpaste/main/scripts/install.sh | sh
set -eu

app=/Applications/interpaste.app
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "ダウンロードしています…"
curl -fsSL -o "$work/interpaste.zip" https://github.com/minor-mn/interpaste/releases/latest/download/interpaste.zip
ditto -x -k "$work/interpaste.zip" "$work"

pkill -x interpaste 2>/dev/null || true
rm -rf "$app"
cp -R "$work/interpaste.app" "$app"
xattr -dr com.apple.quarantine "$app" 2>/dev/null || true
open "$app"
echo "インストールしました。⌥V で貼り付ける形式を選べます。"
