#!/bin/bash
# Create or renew the Xcode-managed development profiles for the app and
# widget, using the personal team configured in App/BUILD.bazel and
# Widget/BUILD.bazel. Regenerates the Xcode project, then builds it once for
# the device with automatic signing allowed so Xcode writes the profiles to
# ~/Library/Developer/Xcode/UserData/Provisioning Profiles. Bazel device builds
# (scripts/run-device.sh) then find those profiles by name.
#
# Free personal-team profiles expire after 7 days; rerun this when
# `bazel build --config=device` reports that no profile was found.
set -euo pipefail
cd "$(dirname "$0")/.."
BAZEL="${BAZEL:-bazel}"
DEVICE_UDID="${1:-}"
if [[ -z "$DEVICE_UDID" ]]; then
  DEVICE_UDID="$(xcrun xctrace list devices 2>/dev/null | awk '/^[^=].*\([0-9A-F]{8}-[0-9A-F]{16}\)$/ && !/Simulator/ {gsub(/[()]/, "", $NF); print $NF; exit}')"
fi
if [[ -z "$DEVICE_UDID" ]]; then
  echo 'No connected physical iPhone found. Connect it, unlock it, and trust this Mac.' >&2
  exit 1
fi
"$BAZEL" run //:xcodeproj
# CODE_SIGNING_ALLOWED is NO at the project level in generated projects; it
# must be YES here or Xcode skips provisioning and never creates the profiles.
xcodebuild \
  -project BazelHelloWorld.xcodeproj \
  -scheme HelloWorld \
  -configuration Debug \
  -destination "id=$DEVICE_UDID" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  CODE_SIGNING_ALLOWED=YES \
  build | grep -E "Provisioning Profile:|Signing Identity:|error:|BUILD (SUCCEEDED|FAILED)" || true
ls -1t "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"/*.mobileprovision 2>/dev/null | head -2
