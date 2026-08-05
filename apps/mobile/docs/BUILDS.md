# Catspot mobile builds

Build pipelines live in `codemagic.yaml` at the repository root and run on Codemagic's free macOS tier.

## Android debug smoke build (runnable today)

1. Open the Catspot app in the Codemagic dashboard.
2. Choose the **Android Debug APK (smoke test)** workflow.
3. Click **Start new build** > pick branch `main` (or any branch).
4. The runner:
   - Uses FVM and the Flutter version pinned in `.fvmrc` at repo root.
   - Runs `fvm flutter pub get`.
   - Runs `fvm flutter build apk --debug`.
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

## Feature status (as of 2026-08-05)

### Implemented and committed to `main`

| Feature | Status | Notes |
|---|---|---|
| Camera preview + shutter | ✅ | Single-shot; back camera |
| On-device cat detection | ✅ | Apple Vision `VNRecognizeAnimalsRequest` |
| Background removal (sticker) | ✅ | iOS 17+ `VNGenerateForegroundInstanceMaskRequest`; EXIF orientation fix |
| Save sticker to Photos | ✅ | `GalleryPlugin` via `catspot/gallery` channel |
| Keepsake creation | ✅ | R2 upload → Cloud Function → Gemini 2.5 Flash name → Firestore |
| Catch result screen | ✅ | Name + `CAT-NNNN` serial + "Go to Collection" |
| Collection screen | ✅ | 2-col grid, empty state, `FutureProvider` |
| Home screen | ✅ | "Scan for a Cat" + "My Collection" |
| Auth (Firebase) | ✅ | Google, Apple, email sign-in |
| Cloud Functions (keepsakes) | ✅ | Written + pushed; **not yet deployed** — see task below |

### 🔧 TASK FOR NEXT AGENT: Deploy keepsake Cloud Functions

**Status:** Code is merged to `main`. Functions are written but not deployed. The catch flow will stall until this is done.

**Working directory:** `packages/backend/functions/`

**Steps:**

#### 1. Set environment variables in Firebase

Before deploying, the functions need R2 and Gemini credentials. Set them via the Firebase CLI:

```bash
firebase functions:secrets:set R2_ACCOUNT_ID
firebase functions:secrets:set R2_ACCESS_KEY_ID
firebase functions:secrets:set R2_SECRET_ACCESS_KEY
firebase functions:secrets:set R2_BUCKET
firebase functions:secrets:set R2_PUBLIC_URL
firebase functions:secrets:set GEMINI_API_KEY
```

Or set them as environment config if using `.env.local` / Functions config (check how `GEMINI_API_KEY` and R2 vars are set for the existing `requestScan`/`verifyScan` functions — use the same mechanism).

> The existing `requestScan` and `verifyScan` functions already use these same R2 and Gemini vars, so they should already be configured. Confirm with `firebase functions:config:get` or check the Firebase console under Functions → Configuration.

#### 2. Deploy

```bash
cd packages/backend/functions
npm install
firebase deploy --only functions
```

This deploys all four functions: `requestScan`, `verifyScan`, `requestCutoutUpload`, `createKeepsake`, `listKeepsakes`.

#### 3. Create the Firestore composite index

The `listKeepsakes` function queries:
```
collection("keepsakes").where("uid", "==", uid).orderBy("createdAt", "desc")
```

This requires a composite index on `(uid ASC, createdAt DESC)`. On the first call Firebase will log a URL like:
```
https://console.firebase.google.com/project/.../firestore/indexes?create_composite=...
```

Open that URL and click **Create**. Or create it manually in the Firestore console:
- Collection: `keepsakes`
- Fields: `uid` (Ascending), `createdAt` (Descending)
- Query scope: Collection

#### 4. Verify

After deploying, test the catch flow end-to-end on the iOS simulator:
1. Open app → Scan for a Cat → take photo → tap "Catch!"
2. Should show spinner, then the catch result screen with a Gemini-generated name and `CAT-0001` serial
3. Tap "Go to Collection" → should show the keepsake card

If the catch stalls, check Firebase Functions logs:
```bash
firebase functions:log --only requestCutoutUpload,createKeepsake
```

## Notes

- No extra backend URL dart-define is needed; Firebase configuration is bundled at build time via `firebase_options.dart` and Google Services config files.
- Caching is enabled for `$HOME/.pub-cache` and `apps/mobile/.dart_tool` to keep subsequent builds cheap.

## iOS TestFlight (manual trigger)

The **iOS TestFlight** workflow builds a release-signed IPA and publishes it to App Store Connect for TestFlight.

1. Trigger it manually from the Codemagic dashboard, or via the Codemagic API (ORC path).
2. The runner builds with `fvm flutter build ipa --release` and `xcode-project use-profiles`.
3. The `catspot_asc` App Store Connect integration is used for both signing and publishing.
   - Codemagic uses the integration to auto-generate the Apple Distribution certificate and App Store provisioning profile in the Apple Developer Portal.
   - No manually uploaded distribution identities are required.
4. After upload, Codemagic submits the build to TestFlight beta review (`submit_to_testflight: true`).

### Prerequisites

- App Store Connect integration `catspot_asc` is configured in Codemagic.
- Bundle identifier `app.catspot.mobile` is registered in Apple Developer Portal.
- App Store Connect app record exists for the bundle identifier.
