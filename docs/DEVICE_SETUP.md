# Run on a physical device

The main [setup guide](../READMe.md) uses a simulator and does not require provisioning profiles. Device builds use `--config=device` and Xcode-managed development signing.

The app and widget currently declare the original developer's personal team, `6KR5UHZLG2`, in their `BUILD.bazel` files. For another developer, set both `DEVELOPMENT_TEAM_ID` values to the intended team, choose appropriate bundle identifiers, and update the profile names and script identifiers together. Sign in to that team in Xcode and connect a development-enabled iPhone.

```sh
# Generate the Xcode project and ask Xcode to create/renew device profiles.
./scripts/provision-device.sh

# Build with Bazel, install, and launch on the connected iPhone.
./scripts/run-device.sh
```

Review the scripts before using them with another team/device. Provisioning invokes Xcode with `-allowProvisioningUpdates` and `-allowProvisioningDeviceRegistration`; it can register devices/App IDs and create development signing material. The explicit `CODE_SIGNING_ALLOWED=YES` is needed because the generated project's default disables signing.

`local_provisioning_profile` finds each managed profile by name. `xcode_provisioning_profile` marks it as managed by Xcode. The root `//:ios_device` condition attaches these profiles only during device builds; simulator builds do not need them. The widget needs a separate profile for its bundle identifier.

If the device build reports an absent or expired profile, rerun provisioning with the phone connected. A first installation may require trusting the developer in the phone's Settings → General → VPN & Device Management. The install/launch helper uses `xcrun devicectl` and accepts a CoreDevice identifier when selecting a specific phone.
