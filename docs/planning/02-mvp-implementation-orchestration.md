# 02 — MVP Implementation & Agent Orchestration Plan

**Companion to:** `docs/PRD.md`, `docs/ROADMAP.md`, `docs/AGENTS.md`, `docs/PROJECT_TRACKER.md`
**Repo:** https://github.com/die-gans/catspot
**Date:** 2026-07-29
**Scope:** 16-week MVP (Sprints 1–8) + the agent orchestration framework that executes it. No code in this document.

---

## Part I — MVP Implementation Roadmap (8 × 2-week sprints)

### Timeline overview

The 16-week MVP (PRD §5.7) maps to eight 2-week sprints. The ROADMAP's 4-week scan-pipeline spike is folded in as Sprints 1–2 — the spike *is* the start of the MVP, not a separate prelude, because the same codebase and branch conventions apply.

```
Wk  1-2   Sprint 1  Foundations + Detection Baseline        [Phase 0 + Spike Wk1]
Wk  3-4   Sprint 2  Server Verification + Embeddings        [Spike Wk2-4]  → GATE G1
Wk  5-6   Sprint 3  Core Scan Loop I (camera + upload)      [Phase 3a]
Wk  7-8   Sprint 4  Core Scan Loop II (pipeline + cards)    [Phase 3b]     → GATE G2
Wk  9-10  Sprint 5  Collection Management & Polish          [Phase 4]
Wk 11-12  Sprint 6  Economy, Social & Moderation            [Phase 5]      → GATE G3
Wk 13-14  Sprint 7  Map & Proximity Claims                  [Phase 6a]
Wk 15-16  Sprint 8  Launch Readiness                        [Phase 6b]     → GATE G4 (SHIP)
```

Sprint cadence: sprint opens Monday with a plan refresh by the Orchestrator, closes second Friday with a demo build + tracker update + retrospective notes appended to the sprint file.

### Agent owner roster

Owner codes used below (see Part II §2 for how these map to real Hermes profiles / subagent dispatches):

| Code | Role | Owns (code areas) |
|---|---|---|
| **MOB** | Mobile agent | `app/` — screens, camera, components, navigation |
| **ML**  | ML agent | `app/ml/`, `convex/scanPipeline.ts`, model eval, `scripts/eval/` |
| **BE**  | Backend agent | `convex/` — schema, functions, auth, economy, geo |
| **DSN** | Design agent | `app/theme/`, `app/components/`, store assets, `web/` landing |
| **INF** | Infra agent | CI/EAS, R2, `.github/workflows/`, `scripts/`, env config |
| **QA**  | QA/review agent | tests, device matrix, gate reports, `docs/qa/` |
| **ORC** | Orchestrator (planner profile) | docs, tracker, task graph — never writes app code |

Shared/locked areas: `docs/` (ORC only), `convex/schema.ts` (BE only; others request changes via PR), `package.json` / lockfiles (INF merges last).

---

### Sprint 1 (Wk 1–2) — Foundations + Detection Baseline

**Goal:** Repo is a runnable Expo app skeleton with CI, and the ML lane has a working camera + MLKit detection on real devices.

| # | Task | Owner | Deps | Acceptance criteria |
|---|---|---|---|---|
| S1.1 | Scaffold monorepo: `app/` (Expo SDK 52+, TS), `convex/`, `scripts/`, `.cursorrules`, root `package.json` workspaces | INF | — | `npx expo start` boots; `npx convex dev` connects to a dev deployment |
| S1.2 | CI: GitHub Actions — lint, typecheck, unit tests on PR; EAS dev-build workflow (manual trigger) | INF | S1.1 | PR checks green on a test PR; EAS dev client installable on Android + iOS |
| S1.3 | Branch protection on `main` (require PR + checks), repo secrets (Clerk, Convex, R2, OpenAI, Replicate) | INF | S1.1 | Direct push to `main` rejected; secrets documented in `docs/ops/secrets.md` (names only) |
| S1.4 | Design system v0: color/type tokens, sticker-book card component, dark/light mode | DSN | S1.1 | `app/theme/tokens.ts` + `<KeepsakeCard/>` renders in a Storybook-style sandbox screen |
| S1.5 | Camera shell: vision-camera v4 live preview, permission flow, capture button | MOB | S1.1 | 30fps preview on mid-range device; capture returns full-res JPEG + metadata |
| S1.6 | MLKit object detection frame processor with cat-like filter + bbox overlay | ML | S1.5 | Detection feedback ≤500ms; bbox drawn on detected objects |
| S1.7 | Test set collection: 200+ real cat photos (distance/light/breed/pose matrix), labeled, stored in `scripts/eval/testset/` (LFS or R2) | ML | — | 200 images with `labels.json` (has_cat, distance_band, lighting, pose) |
| S1.8 | PostHog + Sentry wiring (opt-in toggles) | BE | S1.1 | Events/crashes visible in dashboards from a dev build |

**Critical path:** S1.1 → S1.5 → S1.6 (ML lane). S1.7 can start day 1 (no code deps).
**Sprint exit:** detection demo on 2 physical devices; test set committed.

### Sprint 2 (Wk 3–4) — Server Verification + Embeddings → **GATE G1**

| # | Task | Owner | Deps | Acceptance criteria |
|---|---|---|---|---|
| S2.1 | Clerk + Convex auth (Google/Apple/email-code), `users` table, session gating | BE | S1.1 | Sign in/out works on both platforms; `deletedAt` soft-delete flow |
| S2.2 | Convex schema v1: all tables from PRD §5.3 + indexes | BE | S2.1 | `convex/schema.ts` deployed; migration doc in `convex/README.md` |
| S2.3 | R2 upload pipeline: presigned URL → original → thumbnail (Cloudflare Worker) | BE | S2.2 | Image round-trips; EXIF stripped; signed URLs ≤15min TTL |
| S2.4 | `scanPipeline` action: rate-limit + spend can (transactional) → pHash dup rejection → vision-LLM verify (`is_real_cat`, `is_live_photo`, breed, colors, quality, confidence) | BE+ML | S2.3 | Structured verdict JSON; auto verdict ≤5s; cost/scan logged |
| S2.5 | 512-d embeddings (OpenCLIP/MobileCLIP pet-fine-tuned) + `vectors` table + fuzzy duplicate query | ML | S2.3 | Threshold report: precision/recall of dedup on test set |
| S2.6 | Silhouette cutout via Replicate → R2 (`cutoutUrl`) | ML | S2.3 | Transparent PNG produced for 95% of test images |
| S2.7 | Manual fallback flow: "Capture anyway" → queued verification → push notification with verdict | MOB+BE | S2.4 | Manual verdict delivered ≤60s |
| S2.8 | Spike gate eval: run full pipeline on test set, produce `docs/qa/G1-gate-report.md` (first-scan success, recall @≤5m, latency, cost) | QA+ML | S2.4–2.6 | Report contains measured numbers, not estimates |

**GATE G1 (end of Wk 4) — proceed/kill:**
- First-scan success ≥80% on test set; detection recall ≥90% @≤5m; auto verdict ≤5s; manual ≤60s; cost ≤$0.01/scan.
- **FAIL path:** one 2-week remediation sprint (recheck alternate vision model — Gemini Flash fallback; tune on-device filter) OR pivot decision documented in ROADMAP Decision Log. No MVP sprints start red.

**Critical path:** S2.3 → S2.4 → S2.8.

### Sprint 3 (Wk 5–6) — Core Scan Loop I

**Goal:** The camera is a game controller; the client-side catch UX is complete against a stubbed pipeline.

| # | Task | Owner | Deps | Acceptance criteria |
|---|---|---|---|---|
| S3.1 | Lens selector (ultrawide/1x/tele), pinch zoom, tap-to-focus/exposure lock | MOB | S1.5 | All controls work on devices where hardware allows; graceful degradation elsewhere |
| S3.2 | Framing hints + low-light guidance from detector confidence; "move closer / too dark" cues | MOB+ML | S3.1 | Hints fire within 1s of condition change |
| S3.3 | Anti-spoof on-device heuristics: multi-frame parallax + moiré detection flags (sent as metadata, not verdicts) | ML | S1.6 | Flags present in capture payload; screen-photo test set flagged ≥90% |
| S3.4 | Snack-can minigame: drag-and-release into green zone, 3 attempts/can, physics + juice | MOB | S3.1 | Playable on device; tunable difficulty constants in one config file |
| S3.5 | Server-authoritative throw result (attempt consumed, outcome seeded server-side) | BE | S3.4 | Client cannot forge a success; replay/idempotency safe |
| S3.6 | Local queue (expo-sqlite): capture → retry-safe upload with backoff | MOB | S2.3 | Airplane-mode capture syncs on reconnect exactly once |
| S3.7 | Onboarding shell: guided first-catch tutorial with staged/practice cat, pity rule | MOB | S3.4 | First catch cannot fail; skippable after completion |

**Critical path:** S3.1 → S3.4 → S3.5.

### Sprint 4 (Wk 7–8) — Core Scan Loop II → **GATE G2**

| # | Task | Owner | Deps | Acceptance criteria |
|---|---|---|---|---|
| S4.1 | Full async `scanPipeline` wired end-to-end: steps 1–8 from PRD §5.2 (spend can → pHash → vision-LLM → embedding dedup → cutout → rarity roll → name/stats/abilities → moderation queue if uncertain) | BE | S2.4, S2.5, S2.6 | Single keepsake row produced; `rolls` audit trail written; uncertain scans land in `moderationQ` |
| S4.2 | Keepsake card screen: real photo, generated editable name, 5 rarity tiers with documented odds, type, Snack/Charm stats, abilities, flip animation, serial number | MOB+DSN | S4.1, S1.4 | Card renders <1s from push; flip at 60fps |
| S4.3 | Duplicate handling: same physical cat merges into existing keepsake; ambiguous match prompts user | BE+ML | S4.1 | Dedup threshold from S2.5 report applied; merge UX copy reviewed |
| S4.4 | Album v1: virtualized grid, flip-to-reveal, thumbnails via CDN | MOB | S4.2 | 500 mock cards scroll 60fps, open <1s |
| S4.5 | Economy v1: can regen timer + cap, coins, XP/levels — all via append-only `economyLedger` with idempotency keys | BE | S2.2 | Ledger entries for every grant/spend; no balance mutation outside ledger replay |
| S4.6 | Beta build to 20 testers (EAS internal distribution); feedback channel + crash monitoring | INF+QA | S4.1–4.5 | 20 installs; crash-free ≥99% during sprint |

**GATE G2 (end of Wk 8):** 20 beta testers complete first catch unaided; measured first-session catch success ≥80%; crash-free ≥99%.
**FAIL path:** Sprint 4.5 fix window (max 1 week) before Sprint 5 scope starts; no new features during fix window.

**Critical path:** S4.1 → S4.2 → S4.6. This is the longest pole in the MVP — BE gets S4.1 decomposed into sub-tasks at sprint planning (see Part II §5).

### Sprint 5 (Wk 9–10) — Collection Management & Polish

| # | Task | Owner | Deps | Acceptance criteria |
|---|---|---|---|---|
| S5.1 | Rename, favorite, release/delete (soft-delete, recoverable 7 days) | MOB+BE | S4.4 | All mutations ledger-safe; recovery UI works |
| S5.2 | Filters + search: rarity, type, date, name; multi-select release | MOB | S5.1 | Find any card in <10s at 100+ keepsakes |
| S5.3 | Album performance: CDN thumbnails, lazy cutouts, pagination | MOB+BE | S5.1 | p95 album open <1s @500 cards (QA-measured) |
| S5.4 | Streaks, daily quests, XP leveling UI | BE+MOB | S4.5 | Streak at-risk state computed server-side |
| S5.5 | Push notifications: streak at risk, can cap full, rare friend find (OneSignal/Expo Push) | BE | S5.4 | Opt-in; deep links land on correct screen |
| S5.6 | Share card as image + deep link | MOB | S4.2 | Shared image renders card; link opens app or landing fallback |
| S5.7 | Custom TFLite cat model v1 (fine-tuned, hard negatives: dogs/plush/screens) — swap-in behind flag vs MLKit | ML | S1.7 | Recall ≥ MLKit baseline on test set; A/B flag in config |

### Sprint 6 (Wk 11–12) — Economy, Social & Moderation → **GATE G3**

| # | Task | Owner | Deps | Acceptance criteria |
|---|---|---|---|---|
| S6.1 | RevenueCat: Pro subscription ($4.99/mo), can packs, cosmetic packs; receipt validation server-side | BE | S4.5 | Sandbox purchase → ledger entry; entitlements sync |
| S6.2 | AdMob rewarded ads with SSV callbacks; hard daily cap; never in scan loop | BE+MOB | S6.1 | Reward delivery server-verified; "watched but unpaid" path covered by test |
| S6.3 | Coin sinks: cans, renames, card frames, basic cosmetics | BE+DSN | S6.1 | Free player median ≥10 catches/day (simulated + beta telemetry) |
| S6.4 | Friends: add by code, view albums, activity feed | BE+MOB | S2.1 | Friend loop E2E on two devices |
| S6.5 | Report button on every pin/card + reason categories; auto-hide at 3 pending reports | BE+MOB | S6.4 | Report lands in `moderationQ`; auto-hide verified |
| S6.6 | Moderation console v1 (internal web page): queue, approve/reject, strikes → shadowban | BE+INF | S6.5 | Human review <48h SLA measurable; actions logged |
| S6.7 | Anti-cheat hardening: liveness fusion (device flags + vision-LLM), teleport/mock-location checks, per-device rate limits, Play Integrity/App Attest on high-value actions | ML+BE | S3.3, S4.1 | Screen-photo rejection ≥95% precision on test set; spoof tests written |

**GATE G3 (end of Wk 12):** free-player economy ≥10 catches/day; moderation SLA met on seeded reports; anti-cheat test suite green.
**FAIL path:** economy numbers re-tuned (config-only change, 2–3 days) before map work — the map amplifies cheating, so G3 is a hard gate for Sprint 7.

### Sprint 7 (Wk 13–14) — Map & Proximity Claims

| # | Task | Owner | Deps | Acceptance criteria |
|---|---|---|---|---|
| S7.1 | `sightings` writes from completed scans: geohash-6 + jitter, coarse coords only | BE | S4.1 | Exact coords never leave `scans` (private) — verified by API audit test |
| S7.2 | Clustered community map (react-native-maps): clusters at low zoom, pins at high zoom, paginated by geohash bucket | MOB | S7.1 | 10K seeded pins pan/zoom without jank |
| S7.3 | Proximity claim: ≤50m to collect linked keepsake; server-side distance check + anti-teleport | BE+MOB | S7.2 | Claim flow E2E; spoofed GPS rejected in test |
| S7.4 | Safety UX: first-open "historical, not live" notice, no-trespassing copy, no background location audit | MOB+DSN | S7.2 | Location permission only when-in-use; store privacy labels match reality |
| S7.5 | Load test: 50K simulated DAU against scan pipeline + map queries; queue backpressure verified | INF+QA | S4.1, S7.2 | p95 API latency <1s under load; no dropped scans; report in `docs/qa/load-test.md` |

### Sprint 8 (Wk 15–16) — Launch Readiness → **GATE G4**

| # | Task | Owner | Deps | Acceptance criteria |
|---|---|---|---|---|
| S8.1 | iOS TestFlight (public link) + Android closed testing tracks live | INF | all | Install + first catch on 10-device matrix (list in `docs/qa/device-matrix.md`) |
| S8.2 | Store assets: screenshots, listing copy, privacy labels, age gate, GDPR consent + in-app account deletion + web deletion page | DSN+BE+INF | S7.4 | Both listings pass pre-review checklist; deletion flow E2E tested |
| S8.3 | Regression pass on all MVP acceptance criteria (PRD §6.5 F1–F8) | QA | all | `docs/qa/G4-launch-checklist.md` — every F# signed off with evidence |
| S8.4 | Crash/perf hardening: fix all Sentry sev-1/2; album/scan perf budgets re-verified | MOB+BE | S8.1 | Crash-free sessions ≥99.5% over final week |
| S8.5 | Play Store submission + launch runbook (rollback, kill-switches for ads/IAP/pipeline stages, on-call rota) | INF+ORC | S8.3 | Runbook at `docs/ops/launch-runbook.md`; submission approved |
| S8.6 | Post-launch backlog groomed: v1.0 items (quests, expeditions, trading, localization, PWA) ticketed | ORC | — | ROADMAP Phase 7 updated |

**GATE G4 (SHIP):** G3 green + crash-free ≥99.5% + all F1–F8 acceptance criteria evidenced + store approvals. Missing any → fix-forward, do not ship.

---

### Critical path summary

```
S1.1 scaffold → S1.5 camera → S1.6 MLKit → S2.4 scanPipeline → G1
G1 → S3.1 camera UX → S3.5 server-authoritative throw
   → S4.1 full pipeline → S4.2 card → S4.6 beta → G2
G2 → S6.1 RevenueCat → S6.7 anti-cheat → G3
G3 → S7.1 sightings → S7.2 map → S7.5 load test → S8.3 regression → G4
```

**Longest-pole risks (from PRD §5.8):** detection accuracy (G1), pipeline latency/cost (S4.1), launch-day load (S7.5). These get ML/BE pairing and early starts every sprint.

**Parallel lanes:** DSN is never on the critical path after Sprint 1; INF/QA gate work (S2.8, S7.5, S8.x) is scheduled *inside* the sprint, not after it.

---

## Part II — Agent Orchestration Framework

### 1. Execution model: Kanban for cross-agent routing, subagent-driven development for within-task execution

**Decision:** use **Hermes Kanban as the system of record** for sprint tasks, and **subagent-driven-development (SDD)** as the execution pattern inside each task. Kanban alone lacks the per-task review loop; raw SDD (one orchestrator session driving everything) doesn't survive crashes and has no audit trail. The hybrid gives us both.

- **Kanban (cross-agent):** every sprint task (S1.1 … S8.6) is one card. Assignee = the owning profile (MOB/ML/BE/DSN/INF/QA). Dependencies encoded with `parents=[...]` at creation — never prose "wait for X". A card = the atomic unit of *coordination*.
- **SDD (within-agent):** when a worker profile picks up a card, it decomposes the card into 2–5 minute tasks and executes each with the SDD loop: **implementer subagent → spec-compliance reviewer → code-quality reviewer → mark complete**. A card = a *batch* of SDD cycles.
- **ORC profile (orchestrator):** never writes app code. Decomposes sprints into cards, links parents, monitors the board, recovers stuck workers, updates `PROJECT_TRACKER.md`, and owns all gates.

**When NOT to use the board:** a fix under ~30 min touching one file (e.g. copy tweak, config bump) — direct `delegate_task` from ORC with the SDD review loop, noted in the tracker. Everything else gets a card.

### 2. Profile mapping

Owner codes map to Hermes profiles discovered via `hermes profile list` at kickoff (the kanban-orchestrator skill's Step 0 — **never invent assignee names; unknown assignees silently stall in `ready`**). Recommended setup if profiles don't yet exist:

| Owner | Suggested profile | Model guidance |
|---|---|---|
| ORC | `catspot-orchestrator` | strong planner model |
| MOB | `catspot-mobile` | strong coding model |
| BE | `catspot-backend` | strong coding model |
| ML | `catspot-ml` | coding model w/ long context (eval reports, model configs) |
| DSN | `catspot-design` | any capable coding model |
| INF | `catspot-infra` | strong coding model |
| QA | `catspot-qa` | any capable model |

Single-profile fallback: queue all cards on `default` serially, `parents` still encode order; expect ~1.5× calendar time.

### 3. Branch & PR strategy

**Trunk-based with short-lived task branches.** `main` is always buildable; branch protection requires PR + green CI (S1.3).

**Naming:** `sprint<N>-<task-id>-<slug>-<owner>`
Examples: `s2-s2.4-scan-pipeline-be`, `s4-s4.2-keepsake-card-mob`

**Rules:**
- One card = one branch = one PR. No multi-card branches.
- Branches live < 1 sprint. Rebase on `main` at branch creation and before PR.
- PR title: `[S<N>.<task>] <description>`; body must include: card id, acceptance criteria checklist (copied from the card), evidence (screenshots/logs/test output), tracker line to merge.
- **PR boundaries (conflict avoidance):**
  - `convex/schema.ts` — BE only. Other agents needing schema changes file a sub-card to BE; never edit in a non-BE PR.
  - `package.json`, lockfiles, `app.json`, EAS config — INF merges last; agents note dependency additions in the PR body and INF applies them in a follow-up commit on the same branch before merge.
  - `docs/` — ORC only (agents propose via PR comments).
  - Cross-area cards (e.g. S2.7 MOB+BE) split into two cards sharing a feature branch prefix: `s2-s2.7a-fallback-client-mob`, `s2-s2.7b-fallback-api-be`, BE PR merges first, MOB PR rebases.
- Merge: squash-merge, delete branch. ORC (or INF for infra PRs) merges after QA review + CI.
- Release tags: `gate-g1`, `gate-g2`, `gate-g3`, `v0.1.0` at ship.

### 4. Card anatomy (what ORC puts in every `kanban_create`)

```
title:  [S4.1] Full async scanPipeline (BE)
body:
  SPEC: <full task text from this plan, incl. acceptance criteria — workers must
        not need to read the plan file>
  CONTEXT: <where this fits: deps done, contracts of upstream tasks, file paths>
  CONSTRAINTS: from AGENTS.md §5-6 (server-authoritative, ledger-only grants,
               no exact coords public, no blob storage)
  BRANCH: s4-s4.1-scan-pipeline-be
  DEFINITION OF DONE:
    - [ ] SDD loop completed for each sub-task (implement + 2-stage review)
    - [ ] Acceptance criteria met with evidence in PR body
    - [ ] CI green; tests for new behavior
    - [ ] No files touched outside declared ownership
    - [ ] PROJECT_TRACKER.md update proposed in PR body
parents: [S2.4 card id, S2.5 card id, S2.6 card id]
```

### 5. Review loops

Two nested loops:

1. **SDD loop (inside worker):** per sub-task — implementer subagent (fresh context, full task text inline) → spec reviewer subagent (PASS or gap list) → quality reviewer subagent (APPROVED / REQUEST_CHANGES). Spec review always precedes quality review. No advancing with open critical/important issues.
2. **Cross-agent PR review (at merge):** QA profile reviews every PR against acceptance criteria; a second review from the adjacent owner when the PR crosses an interface (MOB↔BE contract PRs get BE review of client assumptions). Gate sprints (2, 4, 6, 8) add a final integration review subagent across the sprint's full diff.

Failed review → new fix card assigned to the original owner, parented to the review card (never re-run the same card with a sterner prompt).

### 6. Code ownership & conflict avoidance

- Ownership table (Part I) is authoritative; ORC enforces at card-creation time — a card whose scope touches two owned areas gets split.
- **Contract-first interfaces:** before parallel MOB+BE work on a feature, BE writes the Convex function *signature + verdict JSON shape* into `convex/README.md` (or a `.types.ts`) in a small lead PR. MOB codes against the contract with stubs; integration happens at sprint-end demo. This kills the classic "client assumed API shape" conflict.
- **File-claim rule in card bodies:** each card lists the exact paths it will touch. ORC checks the board for overlapping paths among `ready`/`in_progress` cards before promoting; overlap → serialize via `parents`.
- Lockfile/schema merges (INF/BE lanes) are sequenced at sprint close, not mid-sprint.

### 7. Project tracker & docs protocol

- `docs/PROJECT_TRACKER.md` updated by ORC at every: card completion batch (≥ daily), gate decision, blocker raised, scope change. Format stays as-is: Done / In Progress / Planned / Blockers / Handoff Notes.
- Per-sprint status file: `docs/planning/sprints/sprint-<N>.md` — created by ORC at sprint open (cards + owners + dates), appended at close (outcomes, gate metrics, retro notes).
- PRD/ROADMAP changes: proposal PR only, ORC merges after user sign-off. Agents never silently edit source-of-truth docs.
- Every gate report lives in `docs/qa/` and is linked from the tracker and the ROADMAP Decision Log.

### 8. Blocker & dependency protocol

- **Worker blocked (needs info/decision):** `kanban_block()` with a specific question in the comment thread → ORC answers or escalates to the user. Do not guess on product decisions; guessing on PRD-covered items is a review failure.
- **Dependency slip:** if card B (parent of C) will miss its sprint, ORC either (a) re-scopes C to code against B's contract with stubs, or (b) moves C to next sprint and backfills C's owner with a non-critical-path card (DSN polish, QA test-set expansion, ML eval work are the standing backfills).
- **Stuck worker recovery:** dashboard ⚠ → Reclaim → if it recurs, Reassign to another profile or change the profile's model, then Reclaim. Never debug the worker's code in the ORC session (context pollution).
- **Gate failure:** declared by ORC in the tracker + Decision Log with measured numbers; remediation cards created with `parents` = gate card; downstream sprint cards stay in `todo` until remediation passes.
- **Human escalation triggers (stop and ask the user):** any stack swap, any anti-goal tension (PRD §6.6), monetization changes, G1 fail (proceed/pivot is the user's call), store policy rejection.

### 9. Sprint operating rhythm

| When | ORC action |
|---|---|
| Sprint open | Create cards with parents from this plan; verify assignees exist (`hermes profile list`); write sprint file; post plan to user |
| Daily | Board sweep: recover stuck workers, answer blocked cards, update tracker, check path-overlap on ready cards |
| Mid-sprint | Contract check: confirm interface lead PRs landed; re-sequence if slipping |
| Sprint close | Trigger integration review; collect gate metrics (gate sprints); demo build via EAS; close sprint file; retro notes; tracker update; next sprint cards |

### 10. Pre-flight checklist (before Sprint 1 starts)

- [ ] Profiles exist for all owners (or single-profile fallback declared)
- [ ] Repo secrets provisioned (Clerk, Convex, R2, OpenAI, Replicate, PostHog, Sentry)
- [ ] Branch protection live; CI stub green
- [ ] This plan linked from `PROJECT_TRACKER.md`
- [ ] Sprint 1 cards created (S1.1–S1.8) with parents; S1.1 unblocked first
- [ ] User sign-off on G1 gate criteria (80%/90%/≤5s/≤60s/≤$0.01)

### 11. Anti-patterns (hard rules)

1. ORC never implements — route, don't execute.
2. No card without acceptance criteria copied into its body.
3. No dependent cards without `parents`; no "wait for" prose.
4. No cross-ownership file edits; schema/lockfile lanes are exclusive.
5. No skipping the two-stage SDD review to save time — that's how gate metrics get lied to.
6. No starting a sprint's work while the previous gate is red.
7. No invented profile names on the board.
8. No client-authoritative verdicts, rewards, or coordinates — ever (AGENTS.md §6).

---

*Next: `03-` documents (per-sprint detail files) are generated by ORC at each sprint open, not ahead of time — this plan plus the PRD is sufficient context to spawn Sprint 1 today.*
