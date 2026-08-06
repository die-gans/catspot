# PROJECT_TRACKER.md — Catspot

Live project status. Update this file whenever work is completed, blocked, or scope changes.

---

## Project Metadata

- **Name:** Catspot (working title)
- **Repo:** https://github.com/die-gans/catspot ✅
- **Live URL:** None yet
- **Start Date:** 2026-07-29
- **Current Phase:** Phase 0 — Repo setup & planning ✅
- **Next Decision Gate:** Prove scan pipeline technical feasibility in a 4-week spike

---

## Architecture Summary

- **Mobile:** Flutter + Dart (`camera` + `google_mlkit_object_detection` on-device, with `tflite_flutter` as Phase 2 custom model option)
- **ML/AI:** On-device MLKit detection → custom TFLite model → server vision-LLM verification → 512-d embedding duplicate detection → Replicate silhouette cutout
- **Backend:** Convex (real-time sync, social/map, economy ledger)
- **Storage:** Cloudflare R2 for originals, cards, cutouts, thumbnails
- **Auth:** Firebase Auth (Google/Apple/email) — project catspot-9ee0d; Clerk dropped 2026-07-30
- **Monetization:** RevenueCat (`purchases_flutter`) subscriptions + IAP, `google_mobile_ads` rewarded ads, honest coin economy
- **Analytics:** PostHog + Sentry (opt-in)
- **Builds/CI:** GitHub Actions + Codemagic (iOS/Android) + Fastlane fallback

See `docs/PRD.md` for full technical blueprint.

---

## ✅ Done

- [x] Competitive teardown of CatchCat (Google Play, website, privacy policy, press, feedback board)
- [x] Raw intel bundle compiled
- [x] Product teardown + competitive analysis
- [x] Technical architecture + build blueprint
- [x] PRD + North Star document
- [x] Consolidated PRD written
- [x] GitHub repo created and pushed: https://github.com/die-gans/catspot
- [x] K3 swarm planning outputs:
  - [x] MVP tech stack + repo scaffold plan (`docs/planning/01-mvp-stack-and-scaffold.md`) — updated for Flutter pivot
  - [x] MVP implementation roadmap + agent orchestration plan (`docs/planning/02-mvp-implementation-orchestration.md`) — updated for Flutter
  - [x] 4-week detection/AI spike plan (`docs/planning/03-detection-spike-plan.md`) — updated for Flutter test app
  - [x] Hermes agent profile setup plan (`docs/planning/04-hermes-profiles.md`)

---

## ✅ Sprint 1 shipped (PRs #1–16, 2026-07-29 → 2026-08-04)

Design system v1, monorepo scaffold, GitHub Actions CI, theme tokens, Convex + Firebase Auth wiring (Clerk DROPPED — Firebase Auth, project catspot-9ee0d, dev deployment amiable-egret-416 on by_firebaseUid), bundle IDs app.catspot.mobile, FlutterFire configured, Codemagic pipelines (android-debug-apk, ios-dev-ipa, ios-testflight), Apple Developer + capabilities + device registered, iOS runner prep, full iOS signing chain.

**✅ TESTFLIGHT LIVE 2026-08-04:** ios-testflight workflow green end-to-end (PRs #15–16 + export-options fix), IPA auto-submits to App Store Connect → TestFlight. Distribution cert `Y64Q7FZRD2` + "Catspot AppStore" profile `B34KP5FBXQ` (ASC API-created, uploaded to Codemagic identities as catspot_dist_cert / catspot_dist_profile). Signing/CI gotchas banked in skill `codemagic-flutter-ios-signing` (profile path mismatch, export-options-plist, exit-0 exports, DER CSRs).

**✅ BUILD 6a713beccf2e79d451ace7f4 VERIFIED 2026-08-04:** ios-testflight green — IPA built clean (26.5MB, no export-options fallback), `UPLOAD SUCCEEDED with no errors` (delivery UUID eb1226c3), confirmed in App Store Connect API: v1.0.0, processing VALID. Remaining for Dan: export compliance + add himself as internal tester (ASC > TestFlight).

**⚠️ BUILD 6a7145177fbdc82d3cc1ff05 (white-screen fix, PR #17) FAILED AT PUBLISHING 2026-08-04:** IPA built clean (no 'Encountered error', no export-options fallback), but App Store Connect rejected upload: `ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE` — "The bundle version must be higher than the previously uploaded version: '1.0.0'" (altool ExitFailure 31). Fix: bump CFBundleVersion (Codemagic `--build-number` not taking effect / re-run reused same number — use $CM_BUILD_NUMBER properly or $BUILD_NUMBER offset), re-trigger ios-testflight. INF card.

**⚠️ BUILD 6a71f2f71830907d56d217f7 (scan pipeline, fe2df52) FAILED AT ARCHIVE 2026-08-04:** pbxproj path fix held (clean through pod install + 239s archive), but Swift compile error: `registrar(forPlugin:)` returns `(any FlutterPluginRegistrar)?` and was passed unwrapped to `CatDetectionPlugin.register(with:)` in AppDelegate.swift. Fixed in dab3b52 (if-let unwrap) → retriggered as build 6a727b14baa34a485ff09663.

**✅ BUILD #14 6a72d2812ecc67a8e60c25c9 (039a7db, Firebase stack + build-number fix) GREEN 2026-08-05:** Full pipeline success. Verified in 'Build iOS release IPA' log: `Using build number: 1050` (bulletproof 1000+CM_BUILD_NUMBER fix working, >1000 ✓). ASC upload clean: `No errors uploading archive` → TestFlight processing. **NEXT for Dan:** ~10-30 min processing → install from TestFlight, sign in (Firebase Auth), /debug/scan, point phone at a cat — end-to-end field test on the Firebase stack.

**✅ BUILD 6a727b14baa34a485ff09663 (dab3b52, scan pipeline) GREEN 2026-08-05:** Full pipeline success — IPA built + `No errors uploading archive` → TestFlight processing. Backend deployed to Convex dev + env vars set. **NEXT for Dan:** ~10-30 min ASC processing → install from TestFlight, open /debug/scan, point phone at a cat, verify scan → upload → Gemini verdict end-to-end.

**❌ BUILD #15 6a72e0c992e037665be136e7 (fea8359, full catch flow) FAILED AT PUBLISHING 2026-08-05:** IPA built clean, but build number regressed — log shows `Using build number: 1050` (required >1050; 1050 already used by build #14). ASC rejected upload: `The provided entity includes an attribute with a value that has already been used` → `Failed to publish catspot_mobile.ipa to App Store Connect`. Root cause: `1000 + $CM_BUILD_NUMBER` did not increment between #14 and #15 (both resolved to 1050 — CM_BUILD_NUMBER is per-workflow/app counter, not monotonic across workflows, or re-run reuse). Fix needed (MOB/INF): make build number strictly monotonic — e.g. git commit count (`git rev-list --count HEAD`) or ASC latest_build_number+1 fetch. Code itself is fine — all 15 steps through archive/export green; just needs a fresh number and retrigger.

**✅ BUILD #16 6a72e68a2c2b4c315ff4292a (full catch flow, PROJECT_BUILD_NUMBER fix v3) GREEN 2026-08-05:** Build-number fix v3 verified in 'Build iOS release IPA' log: `Using build number: 1029 (PROJECT_BUILD_NUMBER=29)` — >1000 ✓, strictly above previous ASC versions ✓. Full pipeline green, ASC upload clean: `No errors uploading archive at '.../catspot_mobile.ipa'` → TestFlight processing. **NEXT for Dan:** ~10-30 min ASC processing → install from TestFlight, sign in, scan a cat, tap **Catch**, check Collection — full catch-flow field test.

**✅ BUILD #17 6a731741add5700b78d83766 (4186268, white-screen hardening + Convex teardown) GREEN 2026-08-05:** Full pipeline green. Verified in 'Build iOS release IPA' log: `Using build number: 1030 (PROJECT_BUILD_NUMBER=30)` — strictly above #16's 1029 ✓ (note: <1050 from the old CM_BUILD_NUMBER scheme, but ASC accepted it — PROJECT_BUILD_NUMBER chain is what's live now). ASC upload clean: `No errors uploading archive` → TestFlight processing. **NEXT for Dan:** ~10-30 min ASC processing → install from TestFlight. App now either launches to sign-in OR shows a VISIBLE error screen (never white) — if an error screen appears, screenshot it and send it.

**✅ BUILD #18 6a731de64e956dbe4d9c4e53 (Plan 08 Phase B — users collection + Firestore-direct live Collection stream, E2E candidate) GREEN 2026-08-05:** Full pipeline green, every step success. Verified in 'Build iOS release IPA' log: `Using build number: 1031 (PROJECT_BUILD_NUMBER=31)` — strictly above #17's 1030 ✓ (PROJECT_BUILD_NUMBER chain live; old >1050 CM_BUILD_NUMBER threshold superseded per #17 note). ASC upload clean: `No errors uploading archive at '.../catspot_mobile.ipa'` → TestFlight processing. seedUser trigger + rules deployed server-side. **NEXT for Dan — FULL E2E FIELD TEST:** ~10-30 min ASC processing → launch (should hit sign-in or a visible error, NEVER white — report any error screen verbatim), sign in, scan a cat, tap **Catch**, watch it appear in Collection LIVE (Firestore stream, no refresh).

- [x] **2026-08-05 PM: Gemini model swap + Plan 08 Phase A + Convex teardown.** gemini-2.5-flash retired for new API keys (404 on createKeepsake/verifyScan) → gemini-3.1-flash-lite, all 5 functions redeployed. PR #23: release white-screen hardening (runZonedGuarded, release-visible error surface, auth gate 10s timeout+retry, defensive iOS plugin registration, startup milestone logs). PR #24: Convex skeleton DELETED (dead since #21, was breaking CI), CONVEX_URL stripped from codemagic.yaml, CI backend job = functions-only. TestFlight build #17 (6a731741add5700b78d83766) triggered on merged main → white screen either fixed or self-diagnosing. Remaining Phase B: users collection + Firestore-direct collection screen.

- [x] **Plan 08 Phase B COMPLETE 2026-08-05 (PR #25):** seedUser auth onCreate trigger live (users/{uid}), rules: keepsakes owner-read direct / users owner-rw, MOB collection screen → Firestore stream (live updates), UserService.ensureUserDoc, cloud_firestore ^6.8.0. 6 functions deployed. Build #18 (6a731de64e956dbe4d9c4e53) = E2E candidate. Gotchas banked: v1 auth provider needed @firebase/app dep for pnpm deploy resolution; npm install in functions/ requires pnpm lockfile re-sync for CI.

## ✅ Also resolved (2026-08-04)

- [x] **White screen on launch** — PR #17 (resilient startup + error surface) + d014b80 (build number from git commit count fixing duplicate bundle version on ASC upload). TestFlight pipeline clean.
- [x] **Project name** — confirmed as **Catspot**
- [x] **Codemagic API / PR-review bot** — resolved

## ✅ Auth screen shipped (2026-08-04)

Apple Sign-In + Google Sign-In + email/password — all three wired via Firebase Auth. Branded sign-in screen uses design tokens (Quicksand wordmark, orange `#E86A33`, warm cream background). `SignInService` isolates all auth logic from the widget. Google Sign-In URL scheme added to Info.plist. CocoaPods integrated into xcconfigs + workspace. Local dev toolchain fully set up: Flutter 3.44.8, CocoaPods 1.17.0, Rust 1.97.1 (Cargokit requirement for convex_flutter), rustup with aarch64-apple-ios + aarch64-apple-ios-sim targets. App runs on physical device "Goose" (iPhone, iOS 26.5.2) and iPhone 17 simulator.

**Local run command:**
```bash
cd apps/mobile
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
flutter run -d 00008140-001C74A01A06801C --dart-define=CONVEX_URL=https://amiable-egret-416.convex.cloud
```

## 🔄 In Progress

- [x] **Keepsake functions DEPLOYED 2026-08-05:** requestCutoutUpload, createKeepsake, listKeepsakes live (us-central1) alongside requestScan/verifyScan — 5 functions total. Composite index (keepsakes: uid ASC, createdAt DESC) added to firestore.indexes.json + deployed. Rules unchanged (keepsakes only touched server-side via admin SDK — deny-all for clients is correct). **RESOLVED 2026-08-05: R2_PUBLIC_URL set (pub-0e6cbb8762ef4bc9.r2.dev public dev URL on catspot-scans) + all 5 functions redeployed. Catch flow fully live.** — plan: `docs/planning/07-convex-to-firebase-migration.md`. Infra: Blaze billing linked, APIs enabled, Firestore `(default)` us-central1. PR #22 (BE): requestScan/verifyScan v2 callables DEPLOYED LIVE (us-central1, nodejs22) + Firestore rules (scans owner-only) + indexes; functions/.env holds secrets (gitignored). PR #21 (MOB): convex_flutter + token bridge + Rust/Cargokit REMOVED, cloud_functions seam (provider-agnostic interface kept), CI green both. Pending: TestFlight build on merged main → G1 field test on Firebase stack. Phase 2 (users collection) + Phase 3 (schema teardown, Convex decommission, codemagic.yaml CONVEX_URL cleanup) pending.

- [x] **Spike v2 scan pipeline CODE COMPLETE 2026-08-04 (PR #20):** iOS Vision MethodChannel (catspot/vision, VNRecognizeAnimalsRequest), scan debug screen at /debug/scan (bbox overlay, 2-frame capture gate), upload flow (scans:requestScan → R2 presigned PUT → scans:verify w/ Gemini 2.5 Flash structured verdict), scans table. Local verify: analyze clean, 10 tests pass, tsc clean. **NEXT: npx convex deploy to dev deployment (needs Convex access token — device login pending), then TestFlight build → field test G1-G5.**

**❌ BUILD 6a71943397d5b9ed6b314dbf (PR #20 scan pipeline) FAILED 2026-08-04:** All steps green until "Build iOS release IPA" — Swift Compiler Error: `Cannot find 'CatDetectionPlugin' in scope` at `apps/mobile/ios/Runner/AppDelegate.swift:14:4` (Xcode archive otherwise done, 92.7s).

**⏳ BUILD 6a71f2f71830907d56d217f7 (fe2df52 pbxproj re-fix) BUILDING 2026-08-05:** All pre-steps green (fetch, FVM, pods, signing) — currently at "Build iOS release IPA". Last build failed on `Runner/Runner/CatDetectionPlugin.swift`; fe2df52 sets fileRef path `CatDetectionPlugin.swift`. Awaiting archive + publish.


- Detection/AI spike rescoped to a skinny 2-week, no-training, no-dedup plan: `docs/planning/06-detection-spike-v2-skinny.md`.

---

## 📋 Planned (Next 90 Days)

- [ ] Sprint 1 (Wk 1–2): monorepo scaffold, CI, Codemagic dev builds, schema v1, R2 upload ✅
- [x] Sprint 1 wrap review (2026-08-06): scan→catch→save flow mapped (4 serial network hops, Gemini naming in critical path); environments plan written (`docs/planning/08-environments.md`, plan-only, 2-env recommendation); design system/branding ticket for Dan → GitHub issue #26
- [x] **Catch-flow optimization SHIPPED 2026-08-06 (PRs #27 BE + #28 MOB):** 3-hop save → single `catchKeepsake({pngBase64})` callable (PNG inline → R2 → Firestore, returns immediately, `name: null` placeholder). Gemini naming moved to `nameKeepsake` Firestore onCreate trigger (async backfill, failure-tolerant). Mobile: Photos save unawaited, nullable name, "Naming your cat…" placeholder, 36/36 tests pass. `requestCutoutUpload`/`createKeepsake` deprecated as shims. All functions deployed live (us-central1) incl. trigger (Eventarc propagation delay needed one retry). Gotcha: parallel workers sharing one repo — mobile worker committed onto the be/ branch; fixed via reset + cherry-pick. Future parallel cards: workers must verify `git branch --show-current` before committing.
- [ ] Sprint 2 (Wk 3–4): catch-flow perf optimization ✅ — TestFlight build 6a740714601e30b03d6dddc4 green (in ASC processing); dead scan-verifier removed (PR #29, anti-cheat descoped by Dan 2026-08-06 — requestScan/verifyScan + deprecated shims deleted from live project; live functions now: catchKeepsake, listKeepsakes, nameKeepsake, seedUser) → then dev/prod environment split (plan 08) + G1 field test
- [x] **Bugfix: fresh scan session on nav (PR #30, 2026-08-06):** camera icon from Collection always starts a new catch session (stale ScanState no longer persists across routes). TestFlight build 6a740ea696eac8365e65d0ce triggered.
- [x] **Camera-as-controller research (PR #31, 2026-08-06):** `docs/research/05-camera-as-controller.md` — P0/P1/P2 camera "feels good" list, F2 rewritten as 10 testable ACs (F2.1–F2.10), anti-patterns with CatchCat evidence. Sprint 3 = requirements-gathering sprint. Open tension: F2.3 manual fallback assumed server verification (descoped 2026-08-06) — leaning provisional-keepsake-no-verify for MVP.
- [x] **Design sprint kickoff (2026-08-06):** Stitch prompt pack at `docs/design/01-stitch-brief.md` (brand preamble + 5 screen prompts + open questions) — tied to issue #26, awaiting Dan's palette/direction review. Codemagic→Discord build notifications live via codemagic-builds webhook on #catspot (watchdog cron retired).
- [ ] Sprints 3–8: core scan loop, collection management, economy/social, map, launch readiness
- [ ] Gates G2 (beta), G3 (economy/anti-cheat), G4 (ship)

---

## 🚧 Blockers

None.

---

## 📝 Handoff Notes

- The PRD is the source of truth. If you pick this up, read `docs/PRD.md` next, then the Flutter stack plan in `docs/planning/01-mvp-stack-and-scaffold.md`.
- The biggest risk is **scan detection accuracy** — the spike must prove this before the full MVP is built. Convex/Firebase auth integration validated; TestFlight pipeline live.
- The biggest opportunity is the iOS gap CatchCat left open; plan iOS+Android parity from day one (Flutter supports both; web is a smoke-only target until Phase 5).
- Do not start coding until the GitHub repo is live, the Flutter toolchain is installed, and the technical spike is greenlit.

---

*Last updated: 2026-08-04*
