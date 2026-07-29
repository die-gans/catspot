# 01 — MVP Tech Stack & Repo Scaffolding Plan (Flutter)

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Lock the final MVP tech stack and scaffold the Catspot monorepo so agents/humans can start coding the scan pipeline immediately.

**Architecture:** Simple monorepo with three packages: `apps/mobile` (Flutter 3.x stable, iOS + Android + web from one codebase), `packages/backend` (Convex functions + schema, TypeScript/Node), and `packages/shared` (Dart package + JSON-schema-driven shared contract types). Dart on the client, TypeScript on the backend; **Melos is optional** (a plain directory layout + a few root scripts works fine at this scale — adopt Melos only if/when the Dart package count grows past 3–4). GitHub Actions for CI. Codemagic or GitHub Actions + Fastlane for mobile builds (pick Codemagic free tier for simplicity; Fastlane as backup).

**Pivot note:** This document supersedes the earlier Expo/React Native version of this plan. The client is now **Flutter** for mobile and web. Backend stays **Convex (TypeScript) + Cloudflare R2**. Auth stays **Clerk**. Server vision stays **OpenAI gpt-4o-mini**. Cutouts stay **Replicate (rembg)**. Nothing about the data model, pipeline, or Phase plan changes — only the client framework and its SDK choices.

**Sources of truth:** `docs/PRD.md` §5 (stack), §5.3 (data model), §5.7 (phases). This plan implements Phase 0.

---

## 1. Final Stack Decisions (locked)

| Layer | Final choice | Version (verify at scaffold) | Rationale / deviation from PRD |
|---|---|---|---|
| Framework | **Flutter stable** (Dart 3.x) | latest stable; pin in `pubspec.yaml` | PRD said Expo/RN — superseded by the pivot. One codebase for iOS + Android + web. |
| Language (client) | Dart | bundled w/ Flutter | Strict analysis via `flutter_lints` + custom `analysis_options.yaml`. |
| Language (backend) | TypeScript | current stable | Convex functions remain TS. |
| Package manager (client) | `pub` + optional **Melos** | latest | pub workspaces are immature; keep one app + small Dart packages, no forced tooling. |
| Package manager (backend) | **pnpm** | `pnpm@latest` | Convex toolchain is npm-ecosystem. Backend is its own package scope; the repo root is NOT a pnpm workspace anymore. |
| Node | 22 LTS (`>=22.0`) | `.nvmrc` | For Convex CLI / backend tooling only. |
| Flutter SDK pin | `flutter` stable via **FVM** or CI matrix | `.fvmrc` or documented version | Reproducible builds across agents/CI. |
| Camera | **`camera`** plugin | latest | Official first-party plugin: iOS, Android, and (limited) web. Lens selection/zoom/tap-to-focus supported on native; see §1a for web caveats. |
| On-device ML (MVP) | **`google_mlkit_object_detection`** | latest | Matches PRD MVP detector. Custom TFLite cat model is Phase 2 via `tflite_flutter` (official TFLite Flutter plugin exists and is maintained). |
| Frame streaming | `camera` image stream (`CameraImage`, YUV/BGRA) + `google_mlkit_commons` | — | Flutter equivalent of RN frame processors; process every Nth frame to hold 30fps. |
| Backend | **Convex** | `convex@^1.x` (latest) | As per PRD. Functions stay TypeScript. |
| Convex client (Flutter) | **Community package: `convex_flutter` (or `convex_dart`) — UNVERIFIED, spike first** | latest | **No official Convex Flutter SDK exists.** Day-1 validation item (§9). If unusable, fallback plan: thin `convex_dart`-style HTTP/WebSocket wrapper we own (~200 LOC) around Convex's public HTTP query/mutation endpoints + client-generated sync — NOT a backend change. |
| Auth | **Clerk** via **`clerk_flutter`** (beta) + Convex JWT integration | latest | Official-ish Flutter SDK (beta quality — validation item §9). Lower-level `clerk_auth` (Dart-only) is the escape hatch for custom UI. JWT template named `convex` exactly as before; Convex `auth.config.ts` unchanged. |
| Image storage | **Cloudflare R2** via `@aws-sdk/client-s3` from Convex actions | `^3.x` | Unchanged: private buckets + signed URLs; EXIF stripped client-side before upload (`image` package re-encode). |
| Server vision | **OpenAI** `gpt-4o-mini` vision | `openai@^7.x` | Unchanged; runs in Convex Node actions. |
| Image cutout | **Replicate** `rembg` (`cjwbw/rembg`) | `replicate@^1.x` | Unchanged; behind provider interface (PRD risk #6). |
| Maps | `google_maps_flutter` (+ `apple_maps_flutter` optional) | latest | Phase 4, install in Phase 0 to avoid later build churn. |
| Analytics | PostHog `posthog_flutter` + Sentry `sentry_flutter` | latest | As per PRD. |
| State/data | Convex client subscriptions + **Riverpod** (`flutter_riverpod`) for local UI state | `^2.x` | No Bloc ceremony for MVP. Server state = Convex streams; Riverpod for UI state only. |
| Local queue | `drift` (SQLite) or plain `sqflite` | latest | Retry-safe scan upload queue. Drift preferred for typed schema; `sqflite` acceptable for Phase 0. |
| Testing | **flutter_test** (widget/unit) + **mocktail** + **integration_test** (device E2E, Phase 1) + **Vitest** (backend TS) | latest | Dart side: `flutter test`. Backend side: unchanged Vitest. |
| Lint/format | `flutter_lints` + `dart format`; ESLint 9 flat + Prettier for `packages/backend` | latest | Two ecosystems, one CI gate. |
| CI | **GitHub Actions** (flutter analyze, flutter test, dart format check, pnpm lint/typecheck/test for backend) | — | See §6. |
| Builds | **Codemagic** (free tier) or GH Actions + Fastlane | — | `development` (dev client/profile build) / `preview` / `production` profiles. iOS builds need macOS runner — Codemagic includes it. |
| Env/secrets | `.env` (gitignored) + `--dart-define` / `envied` for Flutter; Convex env vars for backend | — | See §3. |
| Web client | **Included from day one as `flutter run -d chrome` smoke target** (not a separate app). Camera + MLKit on web are limited — see §1a. Web is a *validation* target, not a shipping target, until Phase 5. | — | PRD deferred web; pivot makes a web build nearly free, but we do not commit to feature parity. |

**Explicitly NOT installed in Phase 0:** RevenueCat (`purchases_flutter`), AdMob, push (Phase 3+). Adding platform channels late costs rebuilds; note in PROJECT_TRACKER that Phase 3 requires a new dev build.

### 1a. Known platform limitations (web)

| Area | iOS/Android | Flutter Web | Plan |
|---|---|---|---|
| `camera` plugin | Full: lenses, zoom, focus, torch, image streams | Basic preview/capture only; **no `CameraImage` streams**, no lens control, browser permission UX | Web target = manual-capture-only scan flow ("Capture anyway" is the only path). Documented limitation, not a bug. |
| `google_mlkit_object_detection` | Native on-device detection | **Not supported on web** (no implementation) | Web relies on server-side gpt-4o-mini verification. Feature-detect with `kIsWeb` and gate the on-device pipeline. |
| `tflite_flutter` | Native + GPU delegates | WASM variant exists (`tflite_flutter` web support is experimental) | Phase 2 concern; revisit then. |
| Clerk `clerk_flutter` | Native | Supported (beta) | Validate in §9. |
| Real devices | Primary test targets | — | All camera/ML acceptance testing happens on physical devices: 1 mid-range Android (2021+) + 1 iPhone. Emulators/simulators only for UI logic. |

**Contingency (not planned):** If `convex_flutter`/`convex_dart` proves unusable AND writing our own thin Convex client is judged >2 days, the fallback backend is **Supabase** (official `supabase_flutter` SDK). This is a contingency note only — **do not scaffold, abstract, or plan for it.** Convex stays.

---

## 2. Monorepo Layout

```
catspot/
├── apps/
│   └── mobile/                    # Flutter app (iOS + Android + web target)
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart           # MaterialApp.router / theme
│       │   ├── router.dart        # go_router routes
│       │   ├── features/
│       │   │   ├── auth/          # Clerk sign-in/up screens
│       │   │   ├── home/          # album placeholder
│       │   │   └── scan/          # camera screen (Phase 1)
│       │   ├── core/
│       │   │   ├── convex/        # convex client wrapper, auth bridge
│       │   │   ├── clerk/         # clerk provider wrapper
│       │   │   └── theme/         # design tokens
│       │   └── l10n/
│       ├── test/                  # widget/unit tests
│       ├── integration_test/      # device E2E (Phase 1)
│       ├── web/                   # flutter web harness (auto-generated)
│       ├── pubspec.yaml
│       ├── analysis_options.yaml
│       └── codemagic.yaml         # or fastlane/ — build profiles
├── packages/
│   ├── backend/                   # Convex (TypeScript — unchanged from before)
│   │   ├── convex/
│   │   │   ├── schema.ts          # PRD §5.3 tables
│   │   │   ├── auth.config.ts     # Clerk JWT
│   │   │   ├── users.ts
│   │   │   ├── scans.ts           # stubs for scanPipeline
│   │   │   ├── http.ts            # webhooks (Clerk) — Phase 0: health only
│   │   │   └── lib/
│   │   │       ├── r2.ts          # S3 client + signed URL helper
│   │   │       └── vision.ts      # OpenAI verify stub (typed interface)
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── shared/                    # Dart package: shared constants (rarity odds,
│       │                          # VisionVerdict shape) + codegen'd contract types
│       ├── lib/
│       │   ├── catspot_shared.dart
│       │   └── src/
│       │       ├── rarity.dart
│       │       └── vision_verdict.dart
│       ├── schema/                # JSON Schema single source of truth for
│       │   └── vision_verdict.json#   cross-language types (see note below)
│       └── pubspec.yaml
├── docs/                          # existing
├── scripts/
│   ├── seed-dev.ts                # dev seed via convex run (packages/backend)
│   └── gen_shared_types.sh        # JSON-schema → TS + Dart codegen
├── .github/workflows/ci.yml
├── .cursorrules
├── .claude.md
├── .env.example
├── .gitignore
├── .nvmrc
├── melos.yaml                     # OPTIONAL — only if we adopt Melos
├── analysis_options.yaml          # root Dart analysis (applies to apps+packages)
└── README.md                      # quickstart: flutter run, pnpm convex dev
```

**Shared-types strategy (pragmatic):** the TS↔Dart boundary is small — the only cross-language contracts are API payload shapes (`VisionVerdict`, scan status enums, rarity tiers). Source of truth = JSON Schema files in `packages/shared/schema/`; `scripts/gen_shared_types.sh` generates TS (via `json-schema-to-typescript` into `packages/backend/convex/lib/contracts/`) and Dart (via `json_serializable` models into `packages/shared/lib/src/`). Constants that don't need codegen (rarity odds) are authored once in Dart and once in TS with a CI diff-test asserting they match — acceptable duplication at this size.

---

## 3. Environment Variables

`.env.example` (commit this; never commit `.env` / `.env.local`):

```bash
# --- apps/mobile (Flutter: passed via --dart-define or envied; PUBLIC values only) ---
CLERK_PUBLISHABLE_KEY=pk_test_...
CONVEX_URL=https://your-deployment.convex.cloud
POSTHOG_KEY=phc_...
POSTHOG_HOST=https://us.i.posthog.com
SENTRY_DSN=

# --- packages/backend (set via `npx convex env set`, NEVER shipped to client) ---
CLERK_JWT_ISSUER_DOMAIN=https://your-app.clerk.accounts.dev
CLERK_WEBHOOK_SECRET=whsec_...
OPENAI_API_KEY=sk-...
REPLICATE_API_TOKEN=r8_...
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_ORIGINALS=catspot-originals-dev
R2_BUCKET_CUTOUTS=catspot-cutouts-dev
R2_PUBLIC_URL=https://img-dev.catspot.example
```

Rules: server secrets live only in Convex env (`npx convex env set KEY value`) and CI/build secrets. The Flutter client receives only public values, injected via `--dart-define-from-file=.env` (dev) or Codemagic env groups (builds). No `.env` file is ever bundled as an asset.

---

## 4. First 3 Commits (exact)

1. **`chore: monorepo scaffold (flutter app, backend pkg, lint, ci)`** — root configs, `apps/mobile` from `flutter create`, empty `packages/backend` + `packages/shared`, `.gitignore`, `.nvmrc`, CI workflow, `.cursorrules`, `.claude.md`. Verification: `flutter analyze` clean, `flutter test` runs (trivial test), `pnpm -C packages/backend typecheck` passes, CI green.
2. **`feat(app): clerk auth + convex client wiring`** — Tasks 2–4 below. Verification: `flutter run` boots to a sign-in screen on a physical Android device; after Clerk email-code login, the app obtains a `convex`-template JWT and an authenticated Convex query (`users:current`) returns the upserted user row (visible in Convex dashboard).
3. **`feat(backend): convex schema v1 + users upsert + R2 signed-upload-url action`** — Tasks 5–8. Verification: `npx convex dev` syncs schema; calling `scans:createUploadUrl` from the dashboard returns a working presigned PUT URL that uploads a JPEG to R2 (object exists in bucket).

---

## 5. Tasks

### Task 1: Root + Flutter scaffold

**Objective:** Repo layout + tooling that analyzes clean.

**Steps:**
1. `.gitignore`: `build/`, `.dart_tool/`, `.flutter-plugins*`, `node_modules/`, `dist/`, `.env`, `.env.local`, `*.tsbuildinfo`, `.convex/`, `ios/Pods/`, `.idea/`, `.vscode/` (keep shared settings out).
2. `.nvmrc` → `22`.
3. `flutter create --org app.catspot --project-name catspot_mobile --platforms=android,ios,web apps/mobile`. Set app display name "Catspot".
4. Root `analysis_options.yaml` → `include: package:flutter_lints/flutter.yaml` + stricter rules (`prefer_single_quotes`, `require_trailing_commas` via formatter settings). Reference it from `apps/mobile/analysis_options.yaml` and `packages/shared/analysis_options.yaml`.
5. Root `README.md` quickstart.

**Verify:** `cd apps/mobile && flutter pub get && flutter analyze` exits 0; `flutter test` passes the default counter test (replaced in Task 9).

**Commit:** part of commit 1.

### Task 2: App shell + routing

**Objective:** Replace counter app with routed skeleton.

**Commands:**
```bash
cd apps/mobile
flutter pub add go_router flutter_riverpod
```

**Steps:**
1. `lib/router.dart` — routes: `/` (home placeholder), `/sign-in`, `/sign-up`, `/scan` (stub, Phase 1).
2. `lib/app.dart` — `MaterialApp.router`, theme tokens from `core/theme`.
3. Replace default widget test with a smoke test rendering the home route.

**Verify:** `flutter run -d <android-device>` shows "Catspot" home; `flutter test` green.

### Task 3: Clerk auth wiring

**Objective:** Sign-in/up screens and a `convex` JWT available for the Convex client.

**Commands:**
```bash
cd apps/mobile
flutter pub add clerk_flutter   # beta — validate per §9
# escape hatch: clerk_auth (Dart-only) + custom UI
```

**Steps:**
1. Clerk dashboard: application → enable Google, Apple, Email code → JWT template named `convex` (default claims).
2. `lib/core/clerk/` — `ClerkAuthGate` widget: routes signed-out users to `/sign-in`, signed-in users to `/`.
3. Token bridge: `core/convex/convex_auth.dart` — async `getToken({template: 'convex'})` exposed to the Convex client wrapper.
4. Persist session via the SDK's secure storage (no manual token cache unless the beta SDK requires it).

**Verify:** app shows sign-in when logged out; after email-code login, home renders and a debug log prints a non-null `convex` JWT. **This is validation item V2 (§9) — do not proceed to Task 4's client wiring until it passes on a physical device.**

### Task 4: Convex backend package + Flutter client

**Backend (TypeScript — unchanged from previous plan):**
```bash
mkdir -p packages/backend && cd packages/backend
pnpm init && pnpm add convex
pnpm pkg set name="@catspot/backend" typecheck="tsc --noEmit" test="vitest run"
npx convex dev --once   # creates convex/_generated, prompts for project
```
Create `packages/backend/convex/auth.config.ts`:
```ts
export default {
  providers: [
    { domain: process.env.CLERK_JWT_ISSUER_DOMAIN, applicationID: "convex" },
  ],
};
```
Create `packages/backend/convex/users.ts` — `upsertFromClerk` internalMutation + `current` query.

**Flutter client:**
```bash
cd apps/mobile
flutter pub add convex_flutter   # UNVERIFIED community package — validation item V1
```
- `lib/core/convex/convex_client.dart` — wrapper exposing typed `query/mutation/action` + auth-token provider hooking Task 3's bridge.
- `AuthSync` provider (Riverpod): on auth-state change, call `users:upsertFromClerk`.

**Verify:** log in on device → Convex dashboard `users` table gains a row with matching `clerkId`, `canCount: 10`, `coins: 0`. **Validation items V1 + V2.**

### Task 5: Schema v1 (PRD §5.3)

**Objective:** All tables from the PRD, Phase-0-complete.

**File:** `packages/backend/convex/schema.ts` — tables: `users`, `keepsakes`, `scans`, `sightings`, `vectors`, `friendships`, `reports`, `economyLedger`, `moderationQ`, `rolls`, with the indexes listed in PRD §5.3 (`by_owner`, `by_owner_fav`, `by_rarity`, unique `serial`). `defineSchema`/`defineTable`, optional fields exactly as specced.

**Verify:** `npx convex dev` reports schema pushed, no validation errors; dashboard shows all 10 tables.

### Task 6: Clerk → users upsert

**Objective:** Every sign-in creates/updates the `users` row keyed by `clerkId`.

**Files:**
- Create: `packages/backend/convex/lib/auth.ts` (`getCurrentUser` helper throwing if unauthenticated)
- Modify: `apps/mobile/lib/core/convex/` — `AuthSync` triggers `upsertFromClerk` on sign-in (see Task 4).

**Verify:** (same as Task 4 verify.)

### Task 7: R2 signed upload URL action

**Objective:** Client can request a presigned PUT and upload an image privately. **Unchanged from previous plan** — pure backend work.

**Files:**
- Create: `packages/backend/convex/lib/r2.ts` — S3 client against `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`, `createPresignedPut(key, contentType)`.
- Create: `packages/backend/convex/scans.ts` — `"use node"` action `createUploadUrl` (rate-limit stub: 30/hour/user), mutation `createScanRecord`.

**Commands:** `cd packages/backend && pnpm add @aws-sdk/client-s3 @aws-sdk/s3-request-presigner`; `npx convex env set ...` for all 7 R2 vars (create two buckets + API token in Cloudflare first).

**Verify:** from Convex dashboard, run `scans:createUploadUrl` `{contentType: "image/jpeg"}` → `curl -X PUT -T test.jpg "<url>"` → object appears in `catspot-originals-dev`. Run `scans:createScanRecord` → row in `scans` with status `pending`.

### Task 8: Vision verify stub with typed interface

**Objective:** Provider-abstracted vision interface; contract types shared cross-language.

**Files:**
- Create: `packages/shared/schema/vision_verdict.json` — JSON Schema: `{ isRealCat: bool, isLivePhoto: bool, breed?: string, colors: string[], confidence: number }`.
- Run `scripts/gen_shared_types.sh` → generates TS into `packages/backend/convex/lib/contracts/` and Dart `VisionVerdict` model into `packages/shared/lib/src/`.
- Create: `packages/backend/convex/lib/vision.ts` — `verifyScan(imageUrl): Promise<VisionVerdict>` with `openai` gpt-4o-mini structured output; **not yet called** from a pipeline (Phase 1).

**Verify:** `pnpm -C packages/backend test` — Vitest asserts the schema accepts/rejects sample payloads; Dart side: `cd packages/shared && dart test` asserts model round-trips the same JSON fixtures.

### Task 9: Testing infra

**Objective:** `flutter test` for Dart; Vitest for backend; shared JSON fixtures.

**Commands:**
```bash
cd apps/mobile && flutter pub add --dev mocktail
cd packages/shared && dart pub add --dev test
cd packages/backend && pnpm add -D vitest
```

**Files:**
- `apps/mobile/test/smoke_test.dart` — renders home route text.
- `packages/backend/test/vision.test.ts` (schema test above).
- `packages/shared/test/vision_verdict_test.dart` — fixture round-trip (same fixtures as backend test).

**Verify:** `flutter test` (in apps/mobile), `dart test` (shared), `pnpm -C packages/backend test` — all green.

### Task 10: CI workflow

**File:** `.github/workflows/ci.yml` — two jobs:

```yaml
name: ci
on: [push, pull_request]
jobs:
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: stable, cache: true }
      - run: flutter pub get
        working-directory: apps/mobile
      - run: flutter analyze
        working-directory: apps/mobile
      - run: flutter test
        working-directory: apps/mobile
      - run: dart format --set-exit-if-changed .
        working-directory: apps/mobile
      - run: dart pub get && dart test
        working-directory: packages/shared
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: pnpm, cache-dependency-path: packages/backend/pnpm-lock.yaml }
      - run: pnpm install --frozen-lockfile
        working-directory: packages/backend
      - run: pnpm lint && pnpm typecheck && pnpm test
        working-directory: packages/backend
      - run: pnpm exec tsc --noEmit -p convex   # schema typecheck without deploy keys
        working-directory: packages/backend
```

**Verify:** push a branch, both jobs green. (Mobile builds are manual for Phase 0: Codemagic `development` workflow triggered from the dashboard; add `workflow_dispatch` GH Actions + Fastlane alternative in Phase 1.)

### Task 11: Build config + pre-install Phase-1 native deps

**Objective:** Avoid native dependency churn after Phase 0.

**Commands:**
```bash
cd apps/mobile
flutter pub add camera google_mlkit_object_detection google_mlkit_commons \
  google_maps_flutter drift sqlite3_flutter_libs path_provider \
  posthog_flutter sentry_flutter image
```

**Steps:**
1. Android: `minSdkVersion 23` (MLKit requirement), camera permission in `AndroidManifest.xml`, `applicationId app.catspot.dev`.
2. iOS: `NSCameraUsageDescription` in `Info.plist`, bundle id `app.catspot.dev`, deployment target 15.5+.
3. Web: document (in README) that web is manual-capture-only (§1a); add `kIsWeb` guards in scan feature stubs.
4. `codemagic.yaml`: workflows `development` (profile build, Android APK + iOS debug on macOS instance), `preview` (release, internal distribution), `production` (release, auto-increment). PostHog/Sentry keys via Codemagic env groups.

**Verify:** Codemagic `development` Android build succeeds; APK installs on the physical test device and connects to a locally running `flutter run`/backend. iOS debug build compiles (device install optional until Phase 1 — but the §9 camera/MLKit validation requires it, so get a dev cert sorted during Task 11).

---

## 6. `.cursorrules` content (commit at repo root)

```markdown
# Catspot coding rules
- Client is Flutter/Dart (strict analysis, no `dynamic` without a comment). Backend is TypeScript strict. No `any`/`dynamic` without justification.
- Never trust the client: detection, rarity, economy grants are server-authoritative (Convex only).
- All currency/item grants go through economyLedger with an idempotencyKey. Append-only.
- Public geo = geohash-6 + jitter. Exact coords only in private `scans` rows.
- Images live in R2; database stores URLs/keys only, never blobs.
- Strip EXIF before upload (re-encode via `image` package client-side). No background location. No facial data.
- No Web3/NFT/token code, strings, or dependencies. Ever.
- Convex functions: queries/mutations in packages/backend/convex/, external API calls in "use node" actions. Convex functions stay TypeScript — do not port them to Dart.
- Cross-language contract types come from packages/shared/schema/*.json via scripts/gen_shared_types.sh — never hand-edit the generated files; edit the schema and regenerate.
- Flutter: Riverpod for UI state; Convex client for server state; no Bloc, no Redux.
- `kIsWeb` guards around camera-stream and MLKit code — web is manual-capture-only.
- Tests: flutter_test + mocktail (Dart), Vitest (backend TS). Run all suites before committing.
- Small commits, conventional commit messages (feat/fix/chore/docs).
```

## 7. `.claude.md` content (commit at repo root)

```markdown
# Catspot
Real-world cat spotting → collectible cards. Read docs/PRD.md (product) and docs/AGENTS.md (conventions) before coding.

## Stack
Flutter client (apps/mobile, Dart) · Convex backend (packages/backend, TypeScript) · Clerk auth · Cloudflare R2 · OpenAI gpt-4o-mini · Replicate rembg.

## Commands
- App dev: cd apps/mobile && flutter run -d <device>   (physical device for camera/ML)
- App web smoke: flutter run -d chrome   (manual-capture-only; no MLKit)
- Backend dev: cd packages/backend && npx convex dev
- Checks before commit: flutter analyze && flutter test (apps/mobile); dart test (packages/shared); pnpm lint && pnpm typecheck && pnpm test (packages/backend)
- Shared contract types: edit packages/shared/schema/*.json then ./scripts/gen_shared_types.sh

## Hard rules
- Server is authoritative for detection verdicts, rarity rolls, and all economy grants (economyLedger + idempotency).
- Never leak exact GPS; geohash-6 + jitter for anything public.
- No Web3, no forced ads, no paywalled cats, no background location.
- Phase 0 scope: scaffold + auth + schema + R2 upload only. Do not implement the scan pipeline yet.
- convex_flutter / clerk_flutter are community/beta — wrap them behind core/ adapters so swapping them is a one-file change.

## Layout
apps/mobile (Flutter), packages/backend (Convex TS), packages/shared (Dart pkg + JSON-schema contracts).
```

---

## 8. Definition of Done (Phase 0)

- [ ] `flutter analyze` + `flutter test` (apps/mobile), `dart test` (packages/shared), `pnpm lint/typecheck/test` (packages/backend) green locally and in CI
- [ ] App boots on a physical Android device, Clerk email-code sign-in works, user row appears in Convex
- [ ] Schema v1 (10 tables) deployed to a dev Convex deployment
- [ ] R2 presigned upload proven end-to-end from the Convex dashboard
- [ ] `.cursorrules`, `.claude.md`, `.env.example` committed
- [ ] Codemagic `development` Android build succeeds and installs
- [ ] §9 validation checklist completed and results recorded in PROJECT_TRACKER
- [ ] `docs/PROJECT_TRACKER.md` updated by the executing agent (status → Phase 0 done)

---

## 9. Risky-integration validation checklist (3 days, run during/after Tasks 3–4)

> These four integrations carry the pivot's real risk. Timebox: **3 days max**, on physical devices. If V1 or V2 fails hard by end of day 2, escalate before building more on top.

### Day 1 — V1: Convex Flutter client
- [ ] `convex_flutter` (else `convex_dart`) installs and connects to our dev deployment
- [ ] Authenticated query (`users:current`) works with a Clerk `convex` JWT attached
- [ ] Mutation (`users:upsertFromClerk`) round-trips
- [ ] Realtime subscription receives updates when a row changes from the dashboard
- [ ] Works on physical Android **and** iOS; works on web (or is documented as native-only with a graceful `kIsWeb` path)
- [ ] Verdict recorded: **use it / wrap it / write thin own client** (escalate if "write own" looks like >2 days — Supabase contingency conversation happens here, and only here)

### Day 2 — V2: Clerk Flutter → Convex JWT
- [ ] `clerk_flutter` sign-in with email code on physical Android + iOS
- [ ] Session persists across app restart (secure storage)
- [ ] `getToken(template: 'convex')` returns a JWT that Convex accepts (`auth.config.ts` unchanged)
- [ ] Sign-out/sign-in cycle clean; expired-token refresh path doesn't strand the Convex client
- [ ] If `clerk_flutter` beta blocks any of the above: retry same checklist with `clerk_auth` (Dart-only) + custom UI before judging failure

### Day 2–3 — V3: `camera` plugin, Android / iOS / web
- [ ] Preview at 30fps on the mid-range Android test device (2021+)
- [ ] Still capture (JPEG) succeeds; no freeze >100ms at capture
- [ ] `startImageStream` delivers frames (YUV on Android, BGRA on iOS) at usable rate
- [ ] Lens selection / zoom / tap-to-focus work on both native platforms
- [ ] Web (`flutter run -d chrome`): preview + capture work; image stream confirmed **absent** → manual-capture-only path exercised
- [ ] All camera/ML results recorded from **physical devices**; emulators used only to confirm UI doesn't crash

### Day 3 — V4: MLKit object detection
- [ ] `google_mlkit_object_detection` runs on a live `CameraImage` stream on Android + iOS
- [ ] Detection latency ≤500ms/frame on the mid-range Android device
- [ ] Bounding box overlay renders in sync with preview (no coordinate-system mismatch between YUV rotation and widget space — the classic Flutter pitfall; log rotation handling)
- [ ] Confirmed **not available on web**; `kIsWeb` guard in place, server-verification fallback path flagged for Phase 1
- [ ] Notes for Phase 2 captured: `tflite_flutter` model-loading spike plan updated if MLKit integration revealed constraints
