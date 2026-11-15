#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1
flutter build macos --release
app='build/macos/Build/Products/Release/Receipts & Payments Manager.app'
# Flutter incremental builds can update App.framework after Xcode has sealed
# the parent bundle. Refresh only local ad-hoc signatures, then fail packaging
# if any nested framework or resource fails verification.
signature_details="$(codesign -dv "$app" 2>&1)"
if [[ "$signature_details" == *'Signature=adhoc'* ]]; then
  codesign --force --sign - --entitlements macos/Runner/Release.entitlements "$app"
fi
codesign --verify --deep --strict "$app"
mkdir -p dist
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/Receipts & Payments Manager.app"
ln -s /Applications "$stage/Applications"
hdiutil create -volname 'Receipts & Payments Manager' -srcfolder "$stage" -ov -format UDZO dist/RPM-macOS.dmg
(cd dist && shasum -a 256 RPM-macOS.dmg > RPM-macOS.dmg.sha256)
lipo -archs "$app/Contents/MacOS/Receipts & Payments Manager"
echo 'Local release packaged. Public distribution requires Developer ID signing and Apple notarization.'
