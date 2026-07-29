# 01 — MVP Tech Stack & Repo Scaffolding Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Lock the final MVP tech stack and scaffold the Catspot monorepo so agents/humans can start coding the scan pipeline immediately.

**Architecture:** pnpm-workspace monorepo with three packages: `apps/mobile` (Expo SDK 54 / React Native 0.81), `packages/backend` (Convex functions + schema), and `apps/web` deferred (landing page placeholder only). TypeScript everywhere, EAS for builds/OTA, GitHub Actions for CI.

**Tech Stack:** Expo SDK 54, React Native 0.81, react-native-vision-camera 4.x, Convex 1.x, Clerk Expo SDK 2.x, Cloudflare R2 (S3 API), OpenAI gpt-4o-mini vision, Replicate (rembg), Vitest + jest-expo, EAS Build/Submit.

**Sources of truth:** `docs/PRD.md` §5 (stack), §5.3 (data model), §5.7 (phases). This plan implements Phase 0.

---

## 1. Final Stack Decisions (locked)

| Layer | Final choice | Version (verify at scaffold) | Rationale / deviation from PRD |
|---|---|---|---|---|
| Expo SDK | **Expo SDK 57** (current stable; pins React Native version automatically) | `expo@^57` (latest 57.0.8) | Use `expo@latest` at scaffold time; do not manually pin RN. PRD said "52+", superseded. |
| Language | TypeScript | current stable | Strict mode, shared types between app and Convex. |
| Package manager | **pnpm** + workspaces | `pnpm@latest` (latest 11.17.0) | Monorepo-native, fast, used by Convex/Expo templates. |
| Node | 22 LTS (`>=22.0`) | `.nvmrc` | Current LTS; verify at scaffold time. |
| Camera | `react-native-vision-camera` | `^5.2.0` (latest) | v5 required for frame processors + lens control. |
| Frame processors | `react-native-worklets-core` | pinned by vision-camera | Required worklet runtime for frame processors. |
| On-device ML (MVP) | `@infinitered/react-native-mlkit-object-detection` | `^5.0.0` (latest) or MLKit config plugin | MLKit wrapper compatible with Expo config plugins; custom TFLite is Phase 2 (spike may accelerate). |
| Backend | **Convex** | `convex@^1.42.3` (latest) | As per PRD. |
| Auth | **Clerk** `@clerk/clerk-expo` + Convex JWT integration | `^2.19.31` (latest) | Official Convex-Clerk template flow. |
| Image storage | **Cloudflare R2** via `@aws-sdk/client-s3` from Convex actions | `^3.700` | Private buckets + signed URLs; EXIF stripped client-side before upload. |
| Server vision | **OpenAI** `gpt-4o-mini` vision | `openai@^7.1.0` (latest) | As per PRD; Gemini Flash kept as env-swappable fallback later. |
| Image cutout | **Replicate** `rembg` (`cjwbw/rembg`) | `replicate@^1.4.0` (latest) | Behind a provider interface from day one (PRD risk #6). |
| Maps | `react-native-maps` | Expo-pinned | Phase 4, installed now to avoid native rebuild churn. |
| Analytics | PostHog `posthog-react-native` + Sentry `sentry-expo` | `^4.61.1 / ^7.2.0` | As per PRD. |
| State/data | Convex React hooks + `zustand` (local UI state only) | `^5.0.14` | No Redux. Server state = Convex. |
| Local queue | `expo-sqlite` | SDK-bundled | Retry-safe scan upload queue. |
| Testing | **Vitest** (unit/logic, shared utils) + **jest-expo** (component smoke tests) + **Maestro** (E2E, Phase 1) | `vitest@latest` / `jest-expo@~57.0.2` | Vitest for Convex-side pure functions; jest-expo minimal. Verify at scaffold. |
| Lint/format | ESLint 9 flat config + Prettier 3 | latest | One config at repo root. |
| CI | **GitHub Actions** (typecheck, lint, test, `npx convex deploy --dry-run` equivalent typecheck) | — | See §6. |
| Builds/OTA | **EAS Build + EAS Update** | `eas-cli@latest` | `eas.json` profiles: development / preview / production. |
| Env/secrets | `.env.local` (gitignored) + `app.config.ts` extra + EAS secrets | — | See §5. |
| Web landing | **Deferred.** Keep `apps/web` out of the MVP workspace; add in Phase 5 as Next.js. | — | YAGNI. |

**Explicitly NOT installed in Phase 0:** RevenueCat, AdMob, OneSignal (Phase 3+). Adding native modules late costs EAS rebuilds; note in PROJECT_TRACKER that Phase 3 requires a new dev-client build.

---

## 2. Monorepo Layout

```
catspot/
├── apps/
│   └── mobile/                  # Expo app
│       ├── app/                 # expo-router file-based routes
│       │   ├── _layout.tsx
│       │   ├── index.tsx        # home / album placeholder
│       │   ├── scan.tsx         # camera screen (Phase 1)
│       │   └── (auth)/          # Clerk sign-in/up routes
│       ├── src/
│       │   ├── components/
│       │   ├── lib/             # convex client, clerk provider, posthog
│       │   ├── hooks/
│       │   └── theme/           # design tokens
│       ├── assets/
│       ├── app.config.ts
│       ├── eas.json
│       ├── metro.config.js      # monorepo-aware
│       ├── babel.config.js
│       ├── package.json
│       └── tsconfig.json        # extends root
├── packages/
│   ├── backend/                 # Convex
│   │   ├── convex/
│   │   │   ├── schema.ts        # PRD §5.3 tables
│   │   │   ├── auth.config.ts   # Clerk JWT
│   │   │   ├── users.ts
│   │   │   ├── scans.ts         # stubs for scanPipeline
│   │   │   ├── http.ts          # webhooks (Clerk) — Phase 0: health only
│   │   │   └── lib/
│   │   │       ├── r2.ts        # S3 client + signed URL helper
│   │   │       └── vision.ts    # OpenAI verify stub (typed interface)
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── shared/                  # @catspot/shared: types, constants, rarity odds
│       ├── src/index.ts
│       └── package.json
├── docs/                        # existing
├── scripts/
│   └── seed-dev.ts              # dev seed via convex run
├── .github/workflows/ci.yml
├── .cursorrules
├── .claude.md
├── .env.example
├── .gitignore
├── .nvmrc
├── package.json                 # workspace root, scripts
├── pnpm-workspace.yaml
├── tsconfig.base.json
├── eslint.config.mjs
└── .prettierrc
```

---

## 3. Environment Variables

`.env.example` (commit this; never commit `.env.local`):

```bash
# --- apps/mobile (EXPO_PUBLIC_* are bundled — public values only) ---
EXPO_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
EXPO_PUBLIC_CONVEX_URL=https://your-deployment.convex.cloud
EXPO_PUBLIC_POSTHOG_KEY=phc_...
EXPO_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com
EXPO_PUBLIC_SENTRY_DSN=

# --- packages/backend (set via `npx convex env set`, NEVER in app bundle) ---
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

Rules: server secrets live only in Convex env (`npx convex env set KEY value`) and GitHub/EAS secrets; mobile gets only `EXPO_PUBLIC_*`.

---

## 4. First 3 Commits (exact)

1. **`chore: monorepo scaffold (pnpm workspaces, tsconfig, lint, ci)`** — root configs, empty package dirs, `.gitignore`, `.nvmrc`, CI workflow, `.cursorrules`, `.claude.md`. Verification: `pnpm install` clean, `pnpm -r typecheck` passes (empty), CI green.
2. **`feat(app): expo app skeleton with expo-router, Clerk + Convex providers`** — Task 2–4 below. Verification: `pnpm dev:app` boots to a sign-in screen; after Clerk login, `convex/users.ts:current` query returns the upserted user row in the Convex dashboard.
3. **`feat(backend): convex schema v1 + users upsert + R2 signed-upload-url action`** — Tasks 5–8. Verification: `npx convex dev` syncs schema; calling `scans:createUploadUrl` from the dashboard returns a working presigned PUT URL that uploads a JPEG to R2 (verify object exists in bucket).

---

## 5. Tasks

### Task 1: Root workspace scaffold

**Objective:** pnpm workspace + tooling that typechecks.

**Files:**
- Create: `pnpm-workspace.yaml`, `package.json`, `tsconfig.base.json`, `.nvmrc`, `.gitignore`, `.prettierrc`, `eslint.config.mjs`

**Step 1:** `.nvmrc` → `20`. `.gitignore`: `node_modules`, `.expo`, `dist`, `.env.local`, `*.tsbuildinfo`, `ios/`, `android/`, `.convex/`.

**Step 2:** `pnpm-workspace.yaml`:
```yaml
packages:
  - "apps/*"
  - "packages/*"
```

**Step 3:** root `package.json`:
```json
{
  "name": "catspot",
  "private": true,
  "packageManager": "pnpm@9.15.0",
  "engines": { "node": ">=20.11" },
  "scripts": {
    "dev:app": "pnpm --filter @catspot/mobile start",
    "dev:convex": "pnpm --filter @catspot/backend convex dev",
    "typecheck": "pnpm -r run typecheck",
    "lint": "eslint .",
    "test": "pnpm -r run test",
    "format": "prettier --write ."
  },
  "devDependencies": {
    "typescript": "~5.9.2",
    "prettier": "^3.4.2",
    "eslint": "^9.17.0"
  }
}
```

**Step 4:** `tsconfig.base.json` — strict, `moduleResolution: "bundler"`, `jsx: "react-jsx"`, path alias `@catspot/shared`.

**Verify:** `nvm use && pnpm install` exits 0.

**Commit:** part of commit 1.

### Task 2: Scaffold Expo app

**Objective:** Create `apps/mobile` from the blank TypeScript template.

**Commands:**
```bash
mkdir -p apps
pnpm create expo-app@latest apps/mobile --template blank-typescript
cd apps/mobile
# rename package to @catspot/mobile in package.json
pnpm add expo-router@~4.0 react-native-safe-area-context react-native-screens expo-linking expo-constants expo-status-bar
npx expo install expo-dev-client
```

**Step 1:** Set `apps/mobile/package.json` `"name": "@catspot/mobile"`, add `"typecheck": "tsc --noEmit"`.

**Step 2:** `metro.config.js` — standard Expo monorepo config (`watchFolders` = repo root, `nodeModulesPaths` for pnpm).

**Step 3:** Delete `App.tsx`; create `app/_layout.tsx` (root Stack) and `app/index.tsx` (hello screen).

**Verify:** `pnpm --filter @catspot/mobile start` → Expo Go / dev-client shows "Catspot" text. `pnpm --filter @catspot/mobile typecheck` passes.

### Task 3: Clerk auth wiring

**Objective:** Sign-in/up routes and token bridge to Convex.

**Files:**
- Create: `apps/mobile/app/(auth)/sign-in.tsx`, `apps/mobile/app/(auth)/sign-up.tsx`, `apps/mobile/src/lib/clerk.ts`
- Modify: `apps/mobile/app/_layout.tsx` (wrap in `ClerkProvider` + `ConvexProviderWithClerk`)

**Commands:**
```bash
cd apps/mobile
pnpm add @clerk/clerk-expo @clerk/clerk-react expo-secure-store convex
```

**Steps:**
1. In Clerk dashboard: create application → enable Google, Apple, Email code → create JWT template named `convex` (default claims).
2. `apps/mobile/src/lib/clerk.ts` — token cache via `expo-secure-store`.
3. `_layout.tsx`: `ClerkProvider publishableKey={process.env.EXPO_PUBLIC_CLERK_PUBLISHABLE_KEY}` → `ConvexProviderWithClerk client={convex} useAuth={useAuth}`.
4. `(auth)` route group with `SignedIn`/`SignedOut` redirect logic.

**Verify:** app shows sign-in when logged out; after email-code login, index renders and `useConvexAuth().isAuthenticated === true` (temporary debug log).

### Task 4: Convex backend package

**Objective:** Convex project initialized inside `packages/backend`.

**Commands:**
```bash
mkdir -p packages/backend && cd packages/backend
pnpm init
pnpm add convex
pnpm pkg set name="@catspot/backend" typecheck="tsc --noEmit" test="vitest run"
npx convex dev --once   # creates convex/_generated, prompts for project
```

**Files:**
- Create: `packages/backend/convex/auth.config.ts`:
```ts
export default {
  providers: [
    { domain: process.env.CLERK_JWT_ISSUER_DOMAIN, applicationID: "convex" },
  ],
};
```
- Create: `packages/backend/convex/users.ts` — `upsertFromClerk` internalMutation + `current` query.

**Verify:** `npx convex dev` syncs; dashboard shows `users` table after Task 5.

### Task 5: Schema v1 (PRD §5.3)

**Objective:** All tables from the PRD, Phase-0-complete.

**File:** `packages/backend/convex/schema.ts` — tables: `users`, `keepsakes`, `scans`, `sightings`, `vectors`, `friendships`, `reports`, `economyLedger`, `moderationQ`, `rolls`, with the indexes listed in PRD §5.3 (`by_owner`, `by_owner_fav`, `by_rarity`, unique `serial`). Use `defineSchema`/`defineTable`, `v.id`, `v.union`, optional fields exactly as specced.

**Verify:** `npx convex dev` reports schema pushed, no validation errors; `npx convex dashboard` shows all 10 tables.

### Task 6: Clerk → users upsert

**Objective:** Every sign-in creates/updates the `users` row keyed by `clerkId`.

**Files:**
- Create: `packages/backend/convex/lib/auth.ts` (`getCurrentUser` helper throwing if unauthenticated)
- Modify: `apps/mobile/src/lib/` — call `upsertFromClerk` via `useMutation` in an `AuthSync` component mounted in `_layout.tsx`.

**Verify:** log in on device → Convex dashboard `users` table contains a row with matching `clerkId`, default `canCount: 10`, `coins: 0`.

### Task 7: R2 signed upload URL action

**Objective:** Client can request a presigned PUT and upload an image privately.

**Files:**
- Create: `packages/backend/convex/lib/r2.ts` — S3 client against `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`, `createPresignedPut(key, contentType)`.
- Create: `packages/backend/convex/scans.ts` — `"use node"` action `createUploadUrl` (rate-limit stub: 30/hour/user), plus mutation `createScanRecord`.

**Commands:** `cd packages/backend && pnpm add @aws-sdk/client-s3 @aws-sdk/s3-request-presigner`, then `npx convex env set R2_ACCOUNT_ID ...` for all 7 R2 vars (create two buckets + API token in Cloudflare first).

**Verify:** from Convex dashboard, run `scans:createUploadUrl` with `{contentType: "image/jpeg"}` → `curl -X PUT -T test.jpg "<url>"` → object appears in `catspot-originals-dev`. Run `scans:createScanRecord` → row in `scans` with status `pending`.

### Task 8: Vision verify stub with typed interface

**Objective:** Provider-abstracted vision interface so the pipeline can be built incrementally.

**Files:**
- Create: `packages/shared/src/index.ts` — `VisionVerdict` type: `{ isRealCat: boolean; isLivePhoto: boolean; breed?: string; colors: string[]; confidence: number; }`.
- Create: `packages/backend/convex/lib/vision.ts` — `verifyScan(imageUrl): Promise<VisionVerdict>` implemented with `openai` gpt-4o-mini structured output (zod → JSON schema), but **not yet called** from a pipeline (Phase 1).

**Verify:** `pnpm --filter @catspot/backend test` runs a Vitest unit test asserting the zod schema accepts/rejects sample payloads.

### Task 9: Testing infra

**Objective:** Vitest at root scope for shared/backend logic; jest-expo for mobile smoke.

**Commands:**
```bash
pnpm add -Dw vitest
pnpm --filter @catspot/mobile add -D jest-expo jest @testing-library/react-native
```

**Files:**
- Create: `packages/backend/test/vision.test.ts` (schema test above)
- Create: `apps/mobile/src/components/__tests__/smoke.test.tsx` — renders index text.

**Verify:** `pnpm test` — all green.

### Task 10: CI workflow

**File:** `.github/workflows/ci.yml`

```yaml
name: ci
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test
      - run: pnpm --filter @catspot/backend exec tsc --noEmit -p convex  # schema typecheck without deploy keys
```

**Verify:** push a branch, CI green. (EAS builds are manual for Phase 0: `eas build --profile development --platform all`; add an `eas-build.yml` triggered on `workflow_dispatch` in Phase 1.)

### Task 11: EAS config

**File:** `apps/mobile/eas.json` — profiles:
- `development`: `developmentClient: true`, `internalDistribution: true`
- `preview`: internal distribution, release build
- `production`: auto-increment

`apps/mobile/app.config.ts` — read `EXPO_PUBLIC_*` into `extra`, set iOS bundle id / Android package (`app.catspot.dev` for dev), camera permission strings, plugins: `expo-router`, `expo-secure-store`, `sentry-expo`, vision-camera + mlkit config plugins (add packages now so Phase 1 needs no native config churn: `pnpm --filter @catspot/mobile add react-native-vision-camera react-native-worklets-core @infinitered/react-native-mlkit-object-detection expo-sqlite zustand react-native-maps posthog-react-native sentry-expo`).

**Verify:** `eas build --profile development --platform android` succeeds; dev client installs and connects to Metro.

---

## 6. `.cursorrules` content (commit at repo root)

```markdown
# Catspot coding rules
- TypeScript strict everywhere. No `any` without a comment.
- Never trust the client: detection, rarity, economy grants are server-authoritative (Convex only).
- All currency/item grants go through economyLedger with an idempotencyKey. Append-only.
- Public geo = geohash-6 + jitter. Exact coords only in private `scans` rows.
- Images live in R2; database stores URLs/keys only, never blobs.
- Strip EXIF before upload. No background location. No facial data.
- No Web3/NFT/token code, strings, or dependencies. Ever.
- Convex functions: queries/mutations in packages/backend/convex/, external API calls in "use node" actions.
- Shared types/constants (rarity odds, VisionVerdict) live in @catspot/shared, imported by both app and backend.
- Tests: Vitest for pure logic (backend/shared), jest-expo for components. Run `pnpm test` before committing.
- Small commits, conventional commit messages (feat/fix/chore/docs).
```

## 7. `.claude.md` content (commit at repo root)

```markdown
# Catspot
Real-world cat spotting → collectible cards. Read docs/PRD.md (product) and docs/AGENTS.md (conventions) before coding.

## Commands
- Install: pnpm install
- App dev: pnpm dev:app
- Backend dev: pnpm dev:convex
- Checks before commit: pnpm lint && pnpm typecheck && pnpm test

## Hard rules
- Server is authoritative for detection verdicts, rarity rolls, and all economy grants (economyLedger + idempotency).
- Never leak exact GPS; geohash-6 + jitter for anything public.
- No Web3, no forced ads, no paywalled cats, no background location.
- Phase 0 scope: scaffold + auth + schema + R2 upload only. Do not implement the scan pipeline yet.

## Layout
apps/mobile (Expo), packages/backend (Convex), packages/shared (types).
```

---

## 8. Definition of Done (Phase 0)

- [ ] `pnpm install && pnpm typecheck && pnpm lint && pnpm test` green locally and in CI
- [ ] App boots, Clerk email-code sign-in works, user row appears in Convex
- [ ] Schema v1 (10 tables) deployed to a dev Convex deployment
- [ ] R2 presigned upload proven end-to-end from the Convex dashboard
- [ ] `.cursorrules`, `.claude.md`, `.env.example` committed
- [ ] EAS development build succeeds on Android
- [ ] `docs/PROJECT_TRACKER.md` updated by the executing agent (status → Phase 0 done)
