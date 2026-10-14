#!/bin/bash
# Build with Bazel, choose an available iPhone, install, and launch.
set -euo pipefail
cd "$(dirname "$0")/.."
BAZEL="${BAZEL:-bazel}"
DEVICE_ID="${1:-}"
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun simctl list devices available --json | python3 -c '
import json, sys
runtimes = json.load(sys.stdin)["devices"]
devices = [d for runtime, group in runtimes.items() if ".iOS-" in runtime for d in group if d.get("isAvailable") and "iPhone" in d["name"]]
booted = [d for d in devices if d["state"] == "Booted"]
if not devices:
    sys.exit("No available iPhone simulator. Install an iOS runtime in Xcode Settings > Components.")
print((booted or devices)[0]["udid"])
')"
fi
"$BAZEL" build --config=simulator //App:HelloWorld
# bootstatus -b boots a shutdown device and waits until it is ready.
xcrun simctl bootstatus "$DEVICE_ID" -b
open -a Simulator
ARCHIVE="$("$BAZEL" cquery --config=simulator //App:HelloWorld --output=files 2>/dev/null | awk '/\.ipa$/ {print; exit}')"
if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
  echo 'Could not find the Bazel application .ipa output.' >&2
  exit 1
fi
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/bazel-hello.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
unzip -q "$ARCHIVE" -d "$STAGING"
APP="$STAGING/Payload/HelloWorld.app"
if [[ ! -d "$APP" ]]; then
  echo "Expected app bundle missing: $APP" >&2
  exit 1
fi
xcrun simctl install "$DEVICE_ID" "$APP"
xcrun simctl launch --terminate-running-process "$DEVICE_ID" com.example.bazelhelloworld
printf 'Launched Hello World on simulator %s\n' "$DEVICE_ID"
