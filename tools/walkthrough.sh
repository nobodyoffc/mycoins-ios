#!/bin/sh
# Run the UI walkthrough on a simulator and collect its screenshots.
#
#   tools/walkthrough.sh <simulator-udid> <shots-dir> [derived-data-dir] [only-testing]
#
# It starts from a fresh install: the app is removed from the simulator first.
set -u
cd "$(dirname "$0")/.."
DEV="$1"; SHOTS="$2"; DD="${3:-${TMPDIR:-/tmp}/mycoins-ios-build}"
ONLY="${4:-MyCoinsUITests/WalkthroughTests}"
mkdir -p "$SHOTS" "$DD"
xcrun simctl uninstall "$DEV" com.mycoins.wallet.ios 2>/dev/null
TEST_RUNNER_SHOTS_DIR="$SHOTS" xcodebuild -workspace ios/MyCoins.xcworkspace -scheme MyCoins \
    -destination "platform=iOS Simulator,id=$DEV" \
    -derivedDataPath "$DD" -only-testing:"$ONLY" test > "$DD/test.log" 2>&1
grep -E '^/.*: error|error: -\[|XCTAssert|Test Case .*(passed|failed)|\*\* TEST' "$DD/test.log" | sed "s|^$(pwd)/||" | sort -u
ls "$SHOTS"
