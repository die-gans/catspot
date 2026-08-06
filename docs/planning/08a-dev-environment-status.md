# 08a — Dev Environment Status

Last updated: 2026-08-06

## Goal

Stand up the backend half of a dedicated Catspot **dev** environment that mirrors prod (`catspot-9ee0d`) while keeping prod untouched.

## What got created

| Resource | Prod | Dev (this card) | Notes |
|---|---|---|---|
| Firebase project | `catspot-9ee0d` | `catspot-dev-2026` | `catspot-dev` was already taken globally, so the available ID is `catspot-dev-2026`. |
| Project number | `730762336093` | `805242372266` |  |
| Firestore database | `(default)` in `us-central1` | `(default)` in `us-central1` | Created and rules/indexes deployed. |
| Firestore rules | `firestore.rules` | `firestore.rules` (deployed) | Same rule file as prod. |
| Firestore index | `uid ASC, createdAt DESC` | Same index deployed | `firestore.indexes.json` deployed to dev. |
| Firebase Auth | Apple / Google / Email enabled | API enabled, **providers not configured** | Needs Dan to flip providers in console (see below). |
| Firebase Functions | `seedUser`, `catchKeepsake`, `nameKeepsake`, `listKeepsakes` | **Not deployed yet** | Blocked until Blaze billing is enabled. |
| R2 bucket | `catspot-scans` | `catspot-scans-dev` (created) | Public dev URL still needs to be enabled in the Cloudflare dashboard. |
| FlutterFire config | `firebase_options.dart`, `GoogleService-Info.plist`, `google-services.json` | `firebase_options_dev.dart`, `GoogleService-Info-dev.plist`, `google-services-dev.json` | Additive files only; prod configs untouched. |

## What is live right now

- ✅ Firebase project `catspot-dev-2026` exists.
- ✅ Firestore default database created in `us-central1`.
- ✅ Firestore rules + indexes deployed to dev.
- ✅ Identity Toolkit API enabled (Auth service is ready to accept sign-in once providers are configured).
- ✅ Cloud Functions API enabled.
- ✅ R2 bucket `catspot-scans-dev` created via the existing S3-compatible credentials.
- ✅ Dev Flutter apps registered in Firebase (iOS + Android, same bundle/package `app.catspot.mobile`).
- ✅ Dev FlutterFire artifacts committed additively (see Files changed).
- ✅ `.firebaserc` now has a `dev` alias pointing at `catspot-dev-2026` and a `prod` alias pointing at `catspot-9ee0d`. `default` is set to `dev` so local `firebase deploy` targets the dev project.

## What is blocked / needs Dan to finish manually

### 1. Upgrade to Blaze plan (required before Functions deploy)

The CLI cannot link a billing account headlessly. After enabling Blaze, Functions will deploy to `catspot-dev-2026`.

**Exact click path:**

1. Open <https://console.firebase.google.com/project/catspot-dev-2026/usage/details>.
2. Click **"Upgrade to Blaze"** (or the banner that says **"Upgrade to the Blaze plan"**).
3. In the Google Cloud billing flow that opens:
   - Choose the existing billing account, or click **"Manage billing accounts"** → **"ADD BILLING ACCOUNT"** to add a payment method.
   - Accept the terms and click **"Purchase"** / **"Submit"**.
4. Return to the Firebase console and confirm the project now shows **Blaze plan** in the top-left project selector dropdown.

### 2. Enable Firebase Auth providers

The CLI can create the project but cannot configure the sign-in providers. The Identity Toolkit API is already enabled.

**Exact click path:**

1. Open <https://console.firebase.google.com/project/catspot-dev-2026/authentication>.
2. Click **"Get started"** if prompted, then click the **"Sign-in method"** tab.
3. Enable **Email/Password**:
   - Click **Email/Password** → toggle **Enable** → click **Save**.
4. Enable **Google** (required for iOS Google Sign-In):
   - Click **Google** → toggle **Enable** → select a support email → click **Save**.
   - This will create the OAuth iOS client. After saving, download the updated **GoogleService-Info.plist** from **Project settings → Your apps → iOS app** and replace `apps/mobile/ios/Runner/GoogleService-Info-dev.plist` with it. Also update `iosClientId` in `apps/mobile/lib/firebase_options_dev.dart` if the Dart file currently has a placeholder/missing value.
5. Enable **Apple** (optional but needed for parity with prod):
   - Click **Apple** → toggle **Enable** → enter your Apple Team ID, Key ID, and the private key (p8) from `~/.hermes/profiles/catspot-orchestrator/secrets/AuthKey_5X3P73KZKS.p8`.
   - Click **Save**.

### 3. Enable R2 public dev URL for `catspot-scans-dev`

The bucket was created headlessly, but R2 bucket-level public access cannot be toggled via the S3 API.

**Exact click path:**

1. Open <https://dash.cloudflare.com/> and select the account that owns the R2 credentials in `secrets/firebase_functions.env`.
2. Go to **R2** → **Buckets** → click **catspot-scans-dev**.
3. Click the **Settings** tab.
4. Under **Public access**, toggle **Allow public access** to **On** (or click **Add** under **R2.dev subdomain** if Cloudflare presents that option).
5. Copy the displayed **r2.dev URL** (it looks like `https://pub-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.r2.dev`).
6. Update the deployed function env:
   - Open <https://console.firebase.google.com/project/catspot-dev-2026/functions>.
   - Click the three-dot menu on the `catchKeepsake` function (or any function) → **"Edit environment variables"**.
   - Set `R2_PUBLIC_URL` to the copied URL (no trailing slash).
   - Save and redeploy functions, OR edit `packages/backend/functions/.env` locally and run `firebase deploy --only functions`.

## How to finish the backend deployment once Blaze is enabled

```bash
cd /home/dan/Projects/catspot
firebase deploy --only functions
```

Or, if you want to target dev explicitly:

```bash
firebase deploy --project catspot-dev-2026 --only functions
```

The local `.env` in `packages/backend/functions/.env` already points at the dev bucket (`catspot-scans-dev`) and the same R2 credentials as prod. **Remember to replace `R2_PUBLIC_URL=__DEV_R2_PUBLIC_URL_PLACEHOLDER__` with the real r2.dev URL before the final deploy.**

## Dev environment details

- **Firebase project ID:** `catspot-dev-2026`
- **Firebase project number:** `805242372266`
- **Firestore database:** `(default)` in `us-central1`
- **Cloud Functions region:** `us-central1` (Node 22, v2 callables + v1 auth trigger + v2 Firestore trigger)
- **R2 dev bucket:** `catspot-scans-dev`
- **Functions base URL after deploy:** `https://us-central1-catspot-dev-2026.cloudfunctions.net`
- **Expected functions after deploy:** `seedUser`, `catchKeepsake`, `nameKeepsake`, `listKeepsakes`

## Environment variables that differ from prod

| Var | Prod | Dev | Notes |
|---|---|---|---|
| `FIREBASE_PROJECT_ID` | `catspot-9ee0d` | `catspot-dev-2026` | Removed from `.env` entirely per Functions dotenv reserved-prefix rules; project comes from `.firebaserc`. |
| `R2_BUCKET` | `catspot-scans` | `catspot-scans-dev` |  |
| `R2_PUBLIC_URL` | `https://pub-0e6cbb8762ef4bc9a34349d00b3bf562.r2.dev` | `__DEV_R2_PUBLIC_URL_PLACEHOLDER__` | Set after enabling public access on the dev bucket. |

All other function env vars (`GEMINI_API_KEY`, `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`) are intentionally the same as prod.

## Flutter config artifacts

Committed additively; prod files untouched:

- `apps/mobile/lib/firebase_options_dev.dart`
- `apps/mobile/ios/Runner/GoogleService-Info-dev.plist`
- `apps/mobile/android/app/google-services-dev.json`

`firebase_options_dev.dart` uses the newly registered dev app IDs and project ID. The CLI-generated `GoogleService-Info-dev.plist` does **not** contain a `CLIENT_ID` until Google Sign-In is enabled in the console; download the full plist after that step (see Auth provider section above).

## Known issues / gotchas

- `catspot-dev` was unavailable as a project ID, so the dev environment runs under `catspot-dev-2026`. This is purely a naming limitation; the mobile worker should use `catspot-dev-2026` in any hardcoded project references.
- Functions deployment is the only piece blocked by billing. Once Blaze is active, the deploy command above should succeed and create the four functions.
- The first v2 Firestore trigger deployment (`nameKeepsake`) may fail with an Eventarc Service Agent permission error. If that happens, wait 2–3 minutes and rerun `firebase deploy --only functions`, or grant `roles/eventarc.serviceAgent` to `service-805242372266@gcp-sa-eventarc.iam.gserviceaccount.com`.
- Local `packages/backend/functions/.env` now targets dev. If you need to deploy prod manually, switch the file back to the `.env.prod` backup or use CI (which should read the prod secrets from a CI secret store, not from `.env`).
