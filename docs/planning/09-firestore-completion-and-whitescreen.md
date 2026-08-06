# 08 — Firestore Completion + TestFlight White-Screen Fix

**Status:** APPROVED BY DAN 2026-08-05 ("just use firestore — write a plan and send it")
**Author:** ORC
**Supersedes/extends:** `07-convex-to-firebase-migration.md` Phases 2–3

---

## Context

- Migration Phase 1 done: 5 Cloud Functions live (requestScan, verifyScan, requestCutoutUpload, createKeepsake, listKeepsakes), Firestore rules + indexes deployed, `convex_flutter` removed from the app.
- Gemini model swapped to `gemini-3.1-flash-lite` (2.5-flash retired for new keys).
- **Two open problems:** (1) TestFlight builds white-screen on launch while debug builds on Dan's Mac work fine; (2) backend is a hybrid — Convex skeleton still in repo, client talks to Firestore only through callables.

## Phase A — White-screen fix (P0, blocks all field testing)

Debug-works/release-fails means a release-mode-only failure path. Ranked suspects:

1. **Firebase Auth first-emission stall** — `authStateChanges()` in release can behave differently under ATS/network conditions; if the auth gate awaits it before first frame, white screen. Debug on LAN masks it.
2. **Vision/gallery MethodChannel registration** — `FlutterImplicitEngineDelegate` path; a release-only plugin registration failure kills the engine silently.
3. **GoogleService-Info.plist in Release config** — present for archive (build #11+ succeeded) but worth re-verifying runtime read.
4. **Dangling provider post-#21** — something still reading a removed Convex provider throws in a release-only code path (tree-shaken assert differences).

**Steps:**
1. **Repro locally in release:** `fvm flutter run --release -d <Goose>` on Dan's Mac — same AOT build mode as TestFlight. (MOB card, needs the Mac.)
2. **Instrument first frame:** add a post-runApp heartbeat — log each startup milestone (Firebase init, auth first event, first route build) via `debugPrint` + Sentry/crashlytics-free file log; ensure `StartupErrorApp` catches post-runApp errors too (wrap `CatspotApp` in an ErrorWidget.builder + runZonedGuarded).
3. Fix the culprit, verify on release build locally, then TestFlight.
4. **Acceptance:** TestFlight build launches to sign-in on Dan's iPhone, no white screen, twice in a row.

## Phase B — All-in on Firestore (client-direct where sensible)

Dan's call: lean into the Firebase vendor plugins. Target shape:

| Concern | Now | Target |
|---|---|---|
| Keepsake list (collection screen) | `listKeepsakes` callable | **Direct Firestore query** via `cloud_firestore` — rules already owner-only; realtime updates free |
| Keepsake creation | `createKeepsake` callable (Gemini name + serial) | **Stays a function** (secrets + serial integrity server-side) |
| Scan request/verify | callables | **Stay functions** (R2 signing + Gemini keys server-side) |
| Users | nothing (Auth only) | `users/{uid}` doc: onAuthCreate function + client-direct read/write of profile fields |
| Convex skeleton | `packages/backend/convex/` + CI job + `CONVEX_URL` dart-define | **Deleted** |

**Steps:**
1. **BE card:** `onCreate` auth trigger → `users/{uid}` seed doc (displayName, avatar, createdAt, xp/coins stubs). Rules: owner read/write on users, owner read on keepsakes (client-direct). Keep deny-all rest.
2. **MOB card:** add `cloud_firestore`; collection screen swaps `listKeepsakes` callable → Firestore stream (live updates when Catch completes); auth gate writes/reads `users/{uid}`.
3. **INF card (or ORC):** delete `packages/backend/convex/`, the Convex CI job, `CONVEX_URL` from codemagic.yaml + env groups; archive the Convex dev deployment. Update PRD §5 + tracker architecture summary (Backend: Convex → Firebase).
4. Keep `listKeepsakes` function deployed but unused until a TF build proves the direct path; delete in a later cleanup.

**Deliberately NOT doing:** App Check enforcement (spike phase, note for G3), moving R2 → Firebase Storage (R2 egress economics stand), porting unused schema tables early (friendships/economy land when their features do).

## Phase C — Verify + gate

1. TestFlight build with A+B: launch → sign in → scan → verify → Catch → named keepsake appears in Collection **live** (stream, no refresh).
2. That run IS the G1 field test. Record detection recall notes in tracker.

## Sequencing & effort

- Phase A: 1 MOB card + Dan's Mac for release repro (~half day). **Starts now, blocks nothing else.**
- Phase B: 2 worker-cards, can run parallel with A (disjoint lanes; MOB-B touches collection screen, MOB-A touches startup — sequence the two mobile cards, A first).
- Phase C: ORC triggers TF build; Dan field-tests.

**Total: ~2 worker-days. No new vendors, no new cost centres.**
