# Catspot mobile builds

Build pipelines live in `codemagic.yaml` at the repository root and run on Codemagic's free macOS tier.

## Android debug smoke build (runnable today)

1. Open the Catspot app in the Codemagic dashboard.
2. Choose the **Android Debug APK (smoke test)** workflow.
3. Click **Start new build** > pick branch `main` (or any branch).
4. The runner:
   - Uses FVM and the Flutter version pinned in `.fvmrc` at repo root.
   - Runs `fvm flutter pub get`.
   - Runs `fvm flutter build apk --debug --dart-define=CONVEX_URL=...`.
5. When the build finishes, download the APK from:
   - `build/app/outputs/flutter-apk/*.apk` under the build artifacts.

No code signing is required for the debug APK.

## iOS dev IPA (dormant)

The **iOS Dev IPA** workflow is configured but intentionally dormant. Do **not** run it until the checklist below is complete; it will fail because signing credentials are missing.

### iOS go-live checklist

1. Wait for Apple Developer Program to activate (membership is paid but not yet active).
2. Create an App Store Connect API key in `Users and Access > Integrations > App Store Connect API` with **App Manager** rights.
   - Note the **Issuer ID**.
   - Note the **Key ID**.
   - Download the `.p8` private key (it can only be downloaded once).
3. In Codemagic, add an environment group named `app_store_connect` with:
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_PRIVATE_KEY` (the full contents of the `.p8` file)
4. In Codemagic, add an environment group named `certificate_credentials` with:
   - `CERTIFICATE_PRIVATE_KEY` (private key used to generate or match the iOS development certificate; see Codemagic docs for generation instructions).
5. Register the test-device UDIDs in Apple Developer Portal (`Devices > iPhone`).
6. Trigger the **iOS Dev IPA** workflow manually in Codemagic.
7. Install the resulting `.ipa` on the registered device via Diawi, or later via TestFlight once the app is in App Store Connect.

## Notes

- `CONVEX_URL` is passed as a `--dart-define` in both workflows. The value is set in `codemagic.yaml` under `environment.vars`.
- Caching is enabled for `$HOME/.pub-cache` and `apps/mobile/.dart_tool` to keep subsequent builds cheap.
