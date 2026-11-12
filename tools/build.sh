#!/bin/sh
# Build MyCoins for the iOS simulator and print only what went wrong.
#
#   tools/build.sh [derived-data-dir] [Debug|Release]
#
# Release bundles the JavaScript into the app, so it runs without Metro.
# Prints each distinct error once, then the verdict. The full log is left
# beside the derived data as build.log.
set -u
cd "$(dirname "$0")/.."
DD="${1:-${TMPDIR:-/tmp}/mycoins-ios-build}"
CONF="${2:-Release}"
mkdir -p "$DD"
xcodebuild -workspace ios/MyCoins.xcworkspace -scheme MyCoins -configuration "$CONF" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DD" build > "$DD/build.log" 2>&1
grep -E '^/.*: error|^error:|: No such file' "$DD/build.log" | sed "s|^$(pwd)/||" | sort -u
grep -E 'BUILD (SUCCEEDED|FAILED)|xcodebuild: error' "$DD/build.log"
