#!/bin/bash
# Runs the shared styling engine against the iOS SDK, in the simulator, to prove
# Sources/Shared behaves the same under UIKit as it does under AppKit.
# Needs a booted simulator; ./build-ios.sh debug run will boot one.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="$(xcrun --show-sdk-path --sdk iphonesimulator)"
OUT="$(mktemp -d "${TMPDIR:-/tmp}/noty-ios-tests.XXXXXX")"
trap 'rm -rf "$OUT"' EXIT

if ! xcrun simctl list devices booted | grep -q Booted; then
    echo "no booted simulator — run ./build-ios.sh debug run first" >&2
    exit 1
fi

SDKROOT="$SDK" swiftc -parse-as-library -swift-version 5 \
    -target arm64-apple-ios17.0-simulator \
    -sdk "$SDK" \
    "$ROOT"/Sources/Shared/*.swift \
    "$ROOT/Tests/IOSEngineSmokeTest.swift" \
    -o "$OUT/IOSEngineSmokeTest"

xcrun simctl spawn booted "$OUT/IOSEngineSmokeTest"
