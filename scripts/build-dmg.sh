#!/bin/bash
# Builds a Release HandyBar.app and packages it as a DMG in build/.
#
# Environment:
#   HANDYBAR_SIGN_IDENTITY  Code signing identity (name or SHA-1). Defaults to ad-hoc ("-").
#                           Releases must use the stable self-signed certificate so macOS
#                           keeps granted permissions across updates.
#   HANDYBAR_KEYCHAIN       Keychain containing the identity. Optional.
#   HANDYBAR_VERSION        Marketing version, e.g. 0.1.0. Defaults to the project's value.
#   HANDYBAR_BUILD_NUMBER   Build number. Defaults to the project's value.
set -euo pipefail

cd "$(dirname "$0")/.."
identity="${HANDYBAR_SIGN_IDENTITY:--}"
derived_data="build/DerivedData"
app="$derived_data/Build/Products/Release/HandyBar.app"

settings=()
[[ -n "${HANDYBAR_VERSION:-}" ]] && settings+=("MARKETING_VERSION=$HANDYBAR_VERSION")
[[ -n "${HANDYBAR_BUILD_NUMBER:-}" ]] && settings+=("CURRENT_PROJECT_VERSION=$HANDYBAR_BUILD_NUMBER")

xcodebuild \
    -project HandyBar.xcodeproj \
    -scheme HandyBar \
    -configuration Release \
    -derivedDataPath "$derived_data" \
    ${settings[@]+"${settings[@]}"} \
    build

keychain_args=()
[[ -n "${HANDYBAR_KEYCHAIN:-}" ]] && keychain_args+=(--keychain "$HANDYBAR_KEYCHAIN")

codesign --force --options runtime --timestamp=none \
    --entitlements App/HandyBar.entitlements \
    --sign "$identity" ${keychain_args[@]+"${keychain_args[@]}"} \
    "$app"
codesign --verify --strict --verbose=2 "$app"

version="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app/Contents/Info.plist")"
dmg="build/HandyBar-$version.dmg"
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

cp -R "$app" "$staging/"
ln -s /Applications "$staging/Applications"
rm -f "$dmg"
hdiutil create -volname HandyBar -srcfolder "$staging" -fs HFS+ -format UDZO -ov "$dmg"
codesign --force --timestamp=none --sign "$identity" ${keychain_args[@]+"${keychain_args[@]}"} "$dmg"

if [[ "$identity" == "-" ]]; then
    echo "warning: ad-hoc signed; macOS will not keep permissions across updates." >&2
fi
echo "$dmg"
