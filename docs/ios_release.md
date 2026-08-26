# iOS / App Store release path

VillageGame now treats the iOS App Store as a formal release target. The browser build remains the fastest playtest channel.

## Current iOS baseline
- Godot 4.7.2, GDScript, Compatibility renderer.
- Landscape sensor orientation on mobile (both landscape directions).
- iOS status bar and home indicator are hidden during play.
- Touch controls live inside the native iOS safe area so notches and the home-gesture region do not cover primary controls.
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

## Release automation plan
After the Apple account values exist, keep credentials in GitHub Actions secrets rather than the repository. The release workflow will generate the Xcode project, sign/archive it with the current Xcode toolchain, export an IPA, upload to TestFlight, and later promote approved builds for App Store review.

Do not commit certificates, private keys, provisioning profiles, App Store Connect API private keys, or real signing secrets to this repository.
