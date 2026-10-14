#!/bin/bash
# Build for a physical iPhone with Bazel, then install and launch it via devicectl.
# Requires a development signing identity and provisioning profiles that include
# the device; see READMe.md "Run on a physical device".
set -euo pipefail
cd "$(dirname "$0")/.."
BAZEL="${BAZEL:-bazel}"
BUNDLE_ID="com.example.bazelhelloworld"
DEVICE_ID="${1:-}"
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun devicectl list devices --json-output /dev/stdout 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin)
devices = [d for d in data["result"]["devices"]
           if d.get("hardwareProperties", {}).get("reality") == "physical"
           and d.get("hardwareProperties", {}).get("platform") == "iOS"]
connected = [d for d in devices if d.get("connectionProperties", {}).get("tunnelState") == "connected"]
if not devices:
    sys.exit("No paired physical iPhone found. Connect it, unlock it, and trust this Mac.")
print((connected or devices)[0]["identifier"])
')"
fi
"$BAZEL" build --config=device //App:HelloWorld
ARCHIVE="$("$BAZEL" cquery --config=device //App:HelloWorld --output=files 2>/dev/null | awk '/\.ipa$/ {print; exit}')"
if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
  echo 'Could not find the Bazel application .ipa output.' >&2
  exit 1
fi
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/bazel-hello-device.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
unzip -q "$ARCHIVE" -d "$STAGING"
APP="$STAGING/Payload/HelloWorld.app"
if [[ ! -d "$APP" ]]; then
  echo "Expected app bundle missing: $APP" >&2
  exit 1
fi
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"
xcrun devicectl device process launch --device "$DEVICE_ID" --terminate-existing "$BUNDLE_ID"
printf 'Launched Hello World on device %s\n' "$DEVICE_ID"
