# ROADMAP.md — Catspot

Phased build plan and decision gates. This is the execution companion to `docs/PRD.md`.

---

## Philosophy

- **Collection-first, battle-ready.** The MVP must make catching, collecting, and managing cats delightful. Battles, trading, and social depth come after the core loop is proven.
- **Prove the hardest thing first.** The scan pipeline (detection + verification + anti-cheat) is the single biggest risk. It gets a dedicated spike before full MVP scope is committed.
- **No scope creep until the previous gate is green.** Do not start Alley Clash-style PvP until the collection and economy are working and retaining users.

---

## Phase 0 — Repo Setup & Planning (Now → 1 week)

**Goal:** Establish the project home, source of truth, and agent workflow.

- [x] Competitive teardown and PRD
- [x] Local Git repo with README, PRD, ROADMAP, AGENTS, PROJECT_TRACKER
- [ ] GitHub repo live and pushed
- [ ] Finalize project name (Catspot is placeholder)
- [ ] Set up branch protection / basic CI stub (optional)
- [ ] Update PROJECT_TRACKER.md with repo URL and cleared blockers

**Decision Gate:** GitHub repo accessible and team aligned on name.

---

## Phase 1 — Technical Spike: The Scan Pipeline (4 weeks)

**Goal:** Prove we can reliably detect, verify, and turn real-world cat photos into collectible cards.

### Week 1: Detection Baseline
- [ ] Set up Flutter + `camera` plugin + `google_mlkit_object_detection` on Android and iOS test devices; validate web smoke capture only.
- [ ] Build a simple capture flow: live preview → detection feedback → capture → upload to backend.
- [ ] Collect 200+ real-world cat photos across distances, lighting, breeds, and poses for a test set.

### Week 2: Server Verification
- [ ] Set up Convex action endpoint: receive image → pHash duplicate check → vision-LLM (OpenAI/Gemini) verification.
- [ ] Verify output: `is_real_cat`, `is_live_photo` (not screen/print), breed guess, quality score.
- [ ] Build manual fallback flow: "Capture anyway" → async review → notification when verdict is ready.

### Week 3: Embeddings & Cutouts
- [ ] Generate 512-d embeddings for test images using OpenCLIP/MobileCLIP pet-fine-tuned model.
- [ ] Implement duplicate/similarity detection within a user’s album and against recent global sightings.
- [ ] Generate silhouette/cutout via Replicate (rembg/BiRefNet) and store in R2.
- [ ] Decide merge vs. separate-keepsake behavior for ambiguous matches.

### Week 4: Integration & Gate
- [ ] End-to-end flow: camera → detection → capture → server verification → keepsake card → album.
- [ ] Measure real-world first-scan success rate and detection recall at ≤5m.
- [ ] Document cost per scan and latency.
- [ ] **Gate decision:** If first-scan success ≥80% and detection recall ≥90%, proceed to MVP. If not, iterate or pivot.

**Deliverable:** Working spike build + decision report.
**Success Metrics:**
- First-scan success rate ≥80% on test set
- Detection recall ≥90% at ≤5m in normal lighting
- Server verdict latency ≤60s for manual fallback, ≤5s for auto
- Cost per scan ≤$0.01

---

## Phase 2 — MVP Foundations (4 weeks)

**Goal:** Build the app shell, backend, and auth so the core loop can be iterated quickly.

- [ ] Repo structure: `apps/mobile/` (Flutter), `packages/backend/` (Convex), `packages/shared/`, `scripts/`, `.cursorrules` / `.claude.md`.
- [ ] CI: Codemagic/Fastlane build pipeline, Flutter analyze/test, backend lint/typecheck.
- [ ] Clerk/Convex auth: Google, Apple, email-code.
- [ ] Convex schema v1: `users`, `keepsakes`, `scans`, `sightings`, `vectors`, `economyLedger`, `friendships`, `reports`.
- [ ] R2 upload pipeline: original → compressed card → thumbnail → cutout.
- [ ] Design system: sticker-book aesthetic, dark/light modes, card component.
- [ ] PostHog + Sentry wiring (opt-in).

**Decision Gate:** App shell boots, auth works, and a test image can traverse the upload pipeline.

---

## Phase 3 — Core Scan Loop (4 weeks)

**Goal:** The player can catch a real cat and get a keepsake.

- [ ] Live camera with detection overlay, lens selector, zoom, tap-to-focus, low-light hints.
- [ ] Snack-can minigame: drag-and-release into target zone, 3 attempts per can, server-authoritative result.
- [ ] Async scan pipeline: on-device detection → upload → server verification → duplicate check → rarity roll → generation → keepsake.
- [ ] Keepsake card: real photo, generated name (editable), rarity tier, type, stats (Snack/Charm), abilities.
- [ ] Album: grid, flip-to-reveal, virtualized list, fast at 500+ cards.
- [ ] Economy v1: snack cans (timed recharge, cap), coins, XP, levels.
- [ ] Onboarding: guided first catch that cannot fail.

**Decision Gate:** 20 beta testers can complete first catch and understand their album without support.

---

## Phase 4 — Collection Management & Polish (3 weeks)

**Goal:** Make the album usable and delightful at scale.

- [ ] Rename, favorite, delete/release (soft-delete, recoverable 7 days).
- [ ] Filters and search: rarity, type, date, name.
- [ ] Album performance: virtualized grid, CDN thumbnails, lazy cutouts.
- [ ] Streaks, daily quests, XP leveling.
- [ ] Basic push notifications: streak at risk, can cap full, rare friend finds.
- [ ] Share card as image + deep link.

**Decision Gate:** Users with 100+ keepsakes can find and manage any card in <10 seconds.

---

## Phase 5 — Economy, Social & Moderation (3 weeks)

**Goal:** Trust, monetization, and retention hooks.

- [ ] RevenueCat integration: Pro subscription ($4.99/mo), can packs, cosmetic packs.
- [ ] AdMob rewarded ads with server-verified payouts (SSV); no interstitials in scan loop.
- [ ] Coin sinks: cans, renames, card frames, basic cosmetics.
- [ ] Friends: add by code, compare albums, activity feed.
- [ ] Report button on every pin/card; moderation queue; 48h SLA.
- [ ] Anti-cheat: liveness checks, screen-photo detection, teleport checks, rate limits.

**Decision Gate:** Free players can earn ≥10 catches/day; paid value prop is clear and not pay-to-win.

---

## Phase 6 — Map & Launch Readiness (2 weeks)

**Goal:** Ship on both stores with a trustworthy community map.

- [ ] Geohash-bucketed community map: clusters at low zoom, coarsened pins at high zoom.
- [ ] Proximity claim: collect a linked keepsake from a historical sighting.
- [ ] Safety UX: "historical, not live" notice; no trespassing encouragement.
- [ ] iOS TestFlight + Android internal/closed testing.
- [ ] Load testing for 50K day-one users (CatchCat died at 2K).
- [ ] Store assets, privacy labels, age gate, GDPR consent flows.
- [ ] Play Store launch + iOS TestFlight public link.

**Decision Gate:** Submission ready. Crash-free sessions ≥99.5%, store rating target ≥4.3.

---

## Phase 7 — V1.0: Depth & Trust (Post-MVP, +3 months)

- [ ] Daily quests, streaks, seasonal cat events.
- [ ] Expeditions/missions: send cats on timed tasks for rewards.
- [ ] Trading between friends with anti-dupe safeguards.
- [ ] Localization (Ukrainian, etc.).
- [ ] Web PWA share pages for virality.
- [ ] Moderation dashboard v2 + reputation-weighted reports.

---

## Phase 8 — V2.0: Competition (+6 months)

- [ ] **Cat Deck Duel:** turn-based card combat using real catches as the deck.
- [ ] Ranked ladders, neighborhood leaderboards.
- [ ] Optional walking/fitness XP tie-in.
- [ ] Clan/neighborhood groups.

---

## Decision Log

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-29 | Build collection-first, battles later | Core loop must work before PvP is meaningful; user demand for battles is high but fragmented |
| 2026-07-29 | 4-week technical spike before full MVP | Detection/verification is the highest-risk assumption |
| 2026-07-29 | No Web3/NFTs | Charter rejects; audience is wholesome-casual, not crypto |

---

*Last updated: 2026-07-29*
