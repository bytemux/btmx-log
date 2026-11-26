#!/usr/bin/env bash
# Run unit tests and the XCUITest suite on a simulator. Screenshots are kept in the .xcresult bundle.
set -euo pipefail
cd "$(dirname "$0")/.."

SIM="${SIM:-iPhone 17}"
GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
rm -rf build/UITests.xcresult
xcodebuild test -project BtmxLog.xcodeproj -scheme BtmxLog \
  -destination "platform=iOS Simulator,name=$SIM" \
  -derivedDataPath build/dd GIT_COMMIT="$GIT_COMMIT" \
  -resultBundlePath build/UITests.xcresult

# Export test screenshots to build/attachments/
xcrun xcresulttool export attachments \
  --path build/UITests.xcresult --output-path build/attachments 2>/dev/null \
  && echo "Screenshots: build/attachments/" || true
