#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root"
mkdir -p release/2.0.0
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
for platform in macOS Windows Linux; do
  godot --headless --path game --export-release "$platform" > "$stage/$platform.log" 2>&1 || { cat "$stage/$platform.log"; exit 1; }
  if grep -E 'SCRIPT ERROR:|^ERROR:' "$stage/$platform.log"; then exit 1; fi
  case "$platform" in
    macOS) binary=Tidepost.app; arch=universal;;
    Windows) binary=Tidepost.exe; arch=x86_64;;
    Linux) binary=Tidepost.x86_64; arch=x86_64;;
  esac
  folder="Tidepost-2.0.0-$platform-$arch"
  mkdir -p "$stage/$folder"
  cp -R "release/2.0.0/$binary" README.md notices "$stage/$folder/"
  (cd "$stage" && COPYFILE_DISABLE=1 zip -q -r -y "$folder.zip" "$folder")
  unzip -tq "$stage/$folder.zip"
  mv "$stage/$folder.zip" release/
done
mkdir "$stage/Tidepost-2.0.0-source"
cp -R game tools notices README.md "$stage/Tidepost-2.0.0-source/"
(cd "$stage" && zip -qr Tidepost-2.0.0-source.zip Tidepost-2.0.0-source -x '*/.godot/*' '*/__pycache__/*' '*/.DS_Store')
mv "$stage/Tidepost-2.0.0-source.zip" release/
(cd release && shasum -a 256 Tidepost-2.0.0-*.zip > SHA256SUMS-2.0.0.txt && shasum -a 256 -c SHA256SUMS-2.0.0.txt)
