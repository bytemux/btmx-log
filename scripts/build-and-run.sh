#!/usr/bin/env bash
# Build the app, install it on a simulator, launch it, take a screenshot.
set -euo pipefail
cd "$(dirname "$0")/.."

SIM="${SIM:-iPhone 17}"
GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
BUNDLE_ID="dev.btmx.BtmxLog"
APP="build/dd/Build/Products/Debug-iphonesimulator/BtmxLog.app"
mkdir -p build

xcrun simctl boot "$SIM" 2>/dev/null || true   # already booted is fine
open -a Simulator

xcodebuild -project BtmxLog.xcodeproj -scheme BtmxLog \
  -destination "platform=iOS Simulator,name=$SIM" \
  -derivedDataPath build/dd GIT_COMMIT="$GIT_COMMIT" -quiet build

xcrun simctl install booted "$APP"
xcrun simctl launch booted "$BUNDLE_ID" -resetStorage
sleep 2
xcrun simctl io booted screenshot build/launch.png
echo "Screenshot: build/launch.png"
