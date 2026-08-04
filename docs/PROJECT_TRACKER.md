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

- [x] **Spike v2 scan pipeline CODE COMPLETE 2026-08-04 (PR #20):** iOS Vision MethodChannel (catspot/vision, VNRecognizeAnimalsRequest), scan debug screen at /debug/scan (bbox overlay, 2-frame capture gate), upload flow (scans:requestScan → R2 presigned PUT → scans:verify w/ Gemini 2.5 Flash structured verdict), scans table. Local verify: analyze clean, 10 tests pass, tsc clean. **NEXT: npx convex deploy to dev deployment (needs Convex access token — device login pending), then TestFlight build → field test G1-G5.**

**❌ BUILD 6a71943397d5b9ed6b314dbf (PR #20 scan pipeline) FAILED 2026-08-04:** All steps green until "Build iOS release IPA" — Swift Compiler Error: `Cannot find 'CatDetectionPlugin' in scope` at `apps/mobile/ios/Runner/AppDelegate.swift:14:4` (Xcode archive otherwise done, 92.7s).

**⏳ BUILD 6a71f2f71830907d56d217f7 (fe2df52 pbxproj re-fix) BUILDING 2026-08-05:** All pre-steps green (fetch, FVM, pods, signing) — currently at "Build iOS release IPA". Last build failed on `Runner/Runner/CatDetectionPlugin.swift`; fe2df52 sets fileRef path `CatDetectionPlugin.swift`. Awaiting archive + publish.


- Detection/AI spike rescoped to a skinny 2-week, no-training, no-dedup plan: `docs/planning/06-detection-spike-v2-skinny.md`.

---

## 📋 Planned (Next 90 Days)

- [ ] Sprint 1 (Wk 1–2): monorepo scaffold, CI, Codemagic dev builds, schema v1, R2 upload
- [ ] Sprint 2 (Wk 3–4): detection/AI spike — server verification, embeddings, cutouts → GO/NO-GO gate G1
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
