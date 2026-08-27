# iOS / App Store release path

VillageGame treats the iOS App Store as the primary commercial release target. The browser build remains the fastest playtest channel.

## Current iOS baseline
- Godot 4.7.2, GDScript, Compatibility renderer.
- Portrait / vertical phone layout is the primary orientation.
- Reference viewport is 720 x 1280 (9:16).
- iOS status bar and home indicator are hidden during play.
- Primary UI is laid out inside the native safe area so notches and the home-gesture region do not cover research controls.
- The UI is puzzle-first and touch-first; free-movement controls are no longer the primary mobile interface.
- The iOS export targets both iPhone and iPad and currently uses iOS 15.0 as the provisional minimum deployment target.
- No camera, Game Center, push notifications, tracking, advertising, accounts, or analytics are enabled in the prototype.

## Unsigned CI validation
`.github/workflows/ios-project-validation.yml` runs on macOS and asks Godot to generate an unsigned Xcode project. It then lets `xcodebuild` parse that project and stores it as a short-lived Actions artifact. This catches iOS exporter regressions before signing credentials exist.

The committed iOS preset deliberately contains these placeholders:
- Team ID: `XXXXXXXXXX`
- Bundle identifier: `com.example.villagegame`

They are not production identities. `application/export_project_only=true` is also deliberate: CI generates an Xcode project but does not attempt to sign an IPA.

## Values needed before TestFlight
1. Active Apple Developer Program membership.
2. Final bundle identifier chosen before creating the App Store Connect app record.
3. Real 10-character Apple Team ID.
4. Distribution certificate / signing setup and an App Store provisioning profile, or an equivalent App Store Connect CI signing setup.
5. App Store Connect app record and API credentials for automated TestFlight upload.
6. Final 1024x1024 App Store icon and launch presentation.
7. App privacy answers reviewed again immediately before submission.
8. Final checks on iPhone safe-area layout, text size, touch targets, and portrait-only/sensor behavior.

## Release automation plan
After the Apple account values exist, keep credentials in GitHub Actions secrets rather than the repository. The release workflow will generate the Xcode project, sign/archive it with the current Xcode toolchain, export an IPA, upload to TestFlight, and later promote approved builds for App Store review.

Do not commit certificates, private keys, provisioning profiles, App Store Connect API private keys, or real signing secrets to this repository.
