#!/bin/bash
# Builds Noty.app for the iOS Simulator with the Swift toolchain, in the same
# spirit as build.sh — swiftc driven directly, no Xcode project.
#
#   ./build-ios.sh            debug build  -> build/ios/Noty.app
#   ./build-ios.sh release    optimised
#   ./build-ios.sh debug run  build, install into the booted simulator, launch
#
# A physical iPhone needs signing and a provisioning profile, which this script
# deliberately does not attempt; that path wants a real Xcode project.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build/ios/Noty.app"
BUNDLE_ID="com.kiranshivaraju.noty"
DEPLOYMENT_TARGET="17.0"

MODE="${1:-debug}"
ACTION="${2:-}"

OPT="-Onone"
[ "$MODE" = "release" ] && OPT="-O"

SDK="$(xcrun --show-sdk-path --sdk iphonesimulator)"
# The simulator on Apple silicon is arm64; the -simulator suffix is what keeps
# this off the device ABI.
TARGET="arm64-apple-ios${DEPLOYMENT_TARGET}-simulator"

echo "→ compiling ($MODE) for $TARGET"
rm -rf "$APP"
mkdir -p "$APP"

SDKROOT="$SDK" swiftc $OPT -parse-as-library -swift-version 5 \
    -target "$TARGET" \
    -sdk "$SDK" \
    "$ROOT"/Sources/Shared/*.swift \
    "$ROOT"/Sources/iOS/*.swift \
    -o "$APP/Noty"

cp "$ROOT/Info-iOS.plist" "$APP/Info.plist"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP/Info.plist"
plutil -replace CFBundleSupportedPlatforms -json '["iPhoneSimulator"]' "$APP/Info.plist"
plutil -replace DTPlatformName -string "iphonesimulator" "$APP/Info.plist"

codesign --force --sign - --timestamp=none "$APP" >/dev/null 2>&1
echo "✓ built $APP"

[ "$ACTION" = "run" ] || exit 0

# Boot a simulator if none is running, preferring an iPhone.
if ! xcrun simctl list devices booted | grep -q iPhone; then
    DEVICE="$(xcrun simctl list devices available \
              | grep -oE 'iPhone [^(]*\([0-9A-F-]{36}\)' \
              | tail -1 | grep -oE '[0-9A-F-]{36}')"
    [ -n "$DEVICE" ] || { echo "no available iPhone simulator"; exit 1; }
    echo "→ booting simulator $DEVICE"
    xcrun simctl boot "$DEVICE"
    open -a Simulator
    # Give SpringBoard a moment before installing into a cold device.
    until xcrun simctl list devices booted | grep -q "$DEVICE"; do sleep 1; done
fi

echo "→ installing"
xcrun simctl install booted "$APP"
echo "→ launching $BUNDLE_ID"
xcrun simctl launch booted "$BUNDLE_ID"
