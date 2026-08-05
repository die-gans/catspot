# 07 — Convex → Firebase Migration Plan

**Status:** PROPOSED (awaiting Dan GO/NO-GO)
**Date:** 2026-08-05
**Author:** ORC
**Supersedes:** Convex sections of `01-mvp-stack-and-scaffold.md` where conflicted

---

## 1. Why now

The Convex footprint is tiny and pre-production:

- **Backend:** 711 LOC total (`scans.ts` 292, `schema.ts` 177, `users.ts` 84, `lib/r2.ts` 87, `lib/vision.ts` 30, `http.ts` 24, `auth.config.ts` 17)
- **Mobile:** 6 files touch Convex (`catspot_convex_client.dart`, `convex_providers.dart`, `firebase_token_bridge.dart`, `scan_verifier.dart`, `validation_screen.dart`, `main.dart`)
- **Data:** zero production data, dev deployment only
- **Field validation:** G1 spike not yet run — no users, no keepers

This is the cheapest this migration will ever be. Every sprint we delay multiplies the mobile surface area.

## 2. What we actually use Convex for today

| Capability | Current impl | Firebase equivalent |
|---|---|---|
| Scan upload URL + verify action (Gemini) | `scans.ts` Convex action | Cloud Function (callable or HTTPS) — or client-side Firebase AI Logic |
| R2 presigned PUT URLs | `lib/r2.ts` (S3 SDK in action) | Same code in a Cloud Function, or Firebase Storage native upload |
| Users table + Firebase Auth bridge | `auth.config.ts` + `firebase_token_bridge.dart` | **Deleted entirely** — Firestore + Firebase Auth are the same system |
| Schema/tables (11 tables) | `schema.ts` | Firestore collections |
| Realtime sync (future: social, map) | Convex subscriptions | Firestore snapshots listeners (equivalent) |
| Scheduled jobs (can regen — future) | Convex crons | Cloud Scheduler + Functions |

## 3. Target architecture

- **Auth:** Firebase Auth (unchanged — already live)
- **DB:** Cloud Firestore (native vector search via `findNearest` for embeddings when we get there; geohash queries via GeoFlutterFire pattern)
- **Server logic:** Cloud Functions (TypeScript, 2nd gen) — `requestScan`, `verifyScan`, later economy/social mutations
- **AI:** Firebase AI Logic (Vertex AI Gemini) — the "AI gateway" Dan referenced: managed client SDK, App Check enforcement, no raw API key in Convex env
- **Storage decision point:** see §5
- **Push (later):** FCM — comes free in the same ecosystem
- **App Check:** attestation for functions + AI calls — anti-cheat win Convex can't match easily

## 4. Migration phases (each independently shippable)

**Phase 0 — Decide storage (R2 vs Firebase Storage).** Blocks Phase 1.

**Phase 1 — Scan pipeline port (~1 sprint, unblocks G1)**
1. `packages/backend` → Firebase project scaffold: `firebase.json`, `functions/` TS package, Firestore rules + indexes
2. Port `requestScan` + `verifyScan` to callable Functions; verdict contract (snake_case JSON) stays byte-identical — Flutter side doesn't care
3. Firestore `scans` collection; rules: owner-only read/write
4. Mobile: replace `catspot_convex_client` with `cloud_functions` calls; delete `convex_flutter` dep
5. Deploy to Firebase project `catspot-9ee0d`, TestFlight build, re-run G1 field test

**Phase 2 — Users + auth cleanup**
- `users` collection keyed by Firebase UID directly (drop `by_firebaseUid` index indirection)
- Delete `firebase_token_bridge.dart` and Convex auth.config — auth becomes one system
- User doc creation via Auth blocking/on-create function

**Phase 3 — Remaining schema + decommission**
- Port keepsakes, sightings, friendships, economyLedger, moderationQ, rolls as collections land per sprint need (don't port dead tables ahead of need)
- `npx convex` teardown: remove `packages/backend/convex`, CONVEX_URL dart-defines, Codemagic env vars, Cargokit/Rust toolchain from CI + local dev docs
- Update PRD §5 + tracker architecture summary

## 5. Tradeoffs — the honest version

**Firebase wins:**
- **One vendor, one auth.** The Firebase→Convex token bridge is the single jankiest thing in our stack; it disappears.
- **AI gateway.** Firebase AI Logic = managed Gemini path with App Check. No env-var API keys, attestation out of the box.
- **Ecosystem for what's coming:** FCM push, Remote Config, Crashlytics, Analytics — all on the roadmap, all free/cheap, all one SDK.
- **No Rust/Cargokit.** `convex_flutter` drags a Rust toolchain into every iOS build (local + CI). Dropping it deletes a whole failure class.
- **Hiring/docs/AI-assistant familiarity** — Firestore patterns are everywhere.

**What we give up (Convex was genuinely good at):**
- **End-to-end TS types** (schema → client). Firestore + Functions typing is manual or codegen.
- **Transactions & relational-ish queries are nicer in Convex.** Firestore has transactions, but multi-doc economy ledger writes need more care. Mitigation: keep ledger append-only + Cloud Function-side aggregation.
- **Convex crons** for can-regen become Cloud Scheduler (fine, just more moving parts).
- **Realtime DX** — Firestore listeners are good, but Convex's "everything is reactive by default" is smoother. Our realtime needs (social feed, map) are modest.
- **Cost shape flips:** Convex free tier is generous for DB ops; Firebase Blaze is pay-per-op. For a scan-heavy app, Firestore read/write costs need watching. Mitigation: cache aggressively client-side, denormalize counts.

**Storage decision (Phase 0):**
- **Keep R2:** zero egress fees — matters for an image-heavy app at scale; keep existing presign code, Functions just re-sign. Cons: second vendor stays, CORS/keys in Functions env.
- **Move to Firebase Storage:** one vendor, security rules on files, client SDK upload (no presign dance). Cons: GCS egress pricing will bite if the app ever goes viral.
- **ORC recommendation:** keep R2 for originals/cutouts (cost control, Dan's standing preference), use Firebase for everything else. Storage is behind `lib/r2.ts` already — the port is trivial either way.

## 6. Risks

- **Migration churn before G1:** the spike hasn't validated detection accuracy yet. Mitigation: Phase 1 keeps the verify contract identical; G1 gate criteria unchanged. If G1 fails, at least it fails on the stack we'd keep.
- **Firestore query limits** (no joins, composite index management) — schema is simple enough that this won't hurt before MVP.
- **Firebase vendor lock-in** — real, but we're already locked to Firebase Auth; this just admits it.

## 7. Effort estimate

- Phase 1: 2–3 worker-days (BE card) + 1 worker-day (MOB card)
- Phase 2: 1 worker-day
- Phase 3: incremental, per sprint
- ORC overhead: env setup (Blaze plan upgrade, Functions deploy perms), Codemagic env var swap

**Recommendation: GO, starting with Phase 1 immediately — the scan pipeline is the only Convex code that's load-bearing today.**
