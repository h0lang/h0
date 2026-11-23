#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out=${1:-build}
mkdir -p "$out"
bundle="$out/stage1.h0"
seed=bootstrap/seed/h0-linux-x64
"$seed" 48 < bootstrap/modules.txt > "$bundle.new"
mv -f "$bundle.new" "$bundle"
"$seed" 1 < "$bundle" > "$out/h0-linux-x64.new"
chmod +x "$out/h0-linux-x64.new"
mv -f "$out/h0-linux-x64.new" "$out/h0-linux-x64"
"$seed" 0 < "$bundle" > "$out/h0-windows-x64.exe.new"
mv -f "$out/h0-windows-x64.exe.new" "$out/h0-windows-x64.exe"
