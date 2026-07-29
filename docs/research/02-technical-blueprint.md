# CatchCat-Style App — Technical Architecture & Build Blueprint

*Working title: "CatDex" (placeholder). Document 02 in the CatchCat project series. Based on intel in `raw-intel.md`. No code here — architecture, data model, and build plan only.*

---

## 1. Executive Summary

We're building a real-world cat-spotting collection game ("Pokémon GO for cats") that beats the incumbent (CatchCat, 3.0★, 100K+ downloads) on **execution**, not concept. The incumbent's failures are all technical and fixable: bad on-device detection, bad camera UX, no anti-cheat, no album management, slow backend, confused economy.

**Design principles:**

1. **First-scan success is the whole game.** If a new user's first real cat doesn't scan, they churn. The pipeline must degrade gracefully (on-device → server verification → manual review) instead of failing hard.
2. **Trust the client as little as possible.** All verification, duplicate detection, rarity rolls, and currency grants happen server-side.
3. **Boring, proven stack.** Solo/small team, fast iteration: Expo + Convex (matching the incumbent's stack, but executed properly), with managed services for everything non-differentiating.
4. **Privacy as a feature.** GDPR-first, no background location, no facial recognition, transparent AI moderation.

---

## 2. MVP Stack Recommendation

### 2.1 Recommended: Expo (React Native) + Convex

| Layer | Choice | Why | Alternatives considered |
|---|---|---|---|
| Mobile framework | **Expo SDK 52+ (React Native)** | Single codebase iOS+Android, OTA updates (EAS Update), excellent camera/ML ecosystem via config plugins, dev builds allow native modules | Flutter (weaker on-device ML camera pipeline), native (2× cost, no) |
| Camera | **react-native-vision-camera v4** + frame processors | Runs TFLite/MLKit inference on the JS→native bridge at 30fps with zero-copy frames; supports lens selection, zoom, torch — directly fixes incumbent's #2 complaint | Expo Camera (too limited for frame processing) |
| On-device ML | **Google MLKit object detection** (default) → custom **TFLite YOLOv8n / EfficientDet-Lite0 cat model** via vision-camera frame processor | MLKit works out-of-box; custom model trained/fine-tuned on cat datasets closes the accuracy gap | MediaPipe Tasks; CoreML on iOS via ExecuTorch |
| Backend / DB / realtime | **Convex** | Realtime sync for map/social for free, TypeScript functions end-to-end, scheduled jobs, file storage escape hatch, scales from 0. Matches incumbent's stack but with proper schema design | Supabase (Postgres + Realtime + Edge Functions) — strong alternative if relational queries dominate; Firebase (more ops glue) |
| Image storage | **Cloudflare R2** (S3-compatible, zero egress fees) | Cheap at image-heavy scale; serve via Cloudflare CDN with signed URLs | Convex file storage (fine for MVP, migrate later); S3+CloudFront (egress costs) |
| Image processing | **Replicate** (background removal/silhouette via `rembg`/BiRefNet) + **Cloudflare Images/Workers** for resize/thumbnails | On-demand GPU without managing infra | fal.ai (cheaper for some models) |
| Server-side vision | **OpenAI GPT-4.1-mini vision** (or GPT-4o-mini) for verification: "is this a real live cat, not a screen/print?" + breed/color metadata | Multimodal LLM verification is now cheap (~$0.001–0.01/scan) and crushes custom classifiers for anti-spoof nuance | Gemini 2.0 Flash (cheaper); Claude Haiku vision |
| Embeddings (dedup) | **OpenCLIP / MobileCLIP fine-tuned on pets, or `imagebind`-style pet embeddings** via Replicate/fal; store 512-d vectors | Perceptual dedup of the same physical cat | pHash for cheap exact-duplicate rejection + embeddings for fuzzy match |
| Auth | **Clerk** (Expo + Convex native integration) or Convex Auth | Google/Apple/email-code out of box, Convex integration is first-class | Supabase Auth |
| IAP/subscriptions | **RevenueCat** | Industry standard, handles StoreKit/Play Billing receipt validation, entitlements sync to Convex via webhook | — |
| Ads | **AdMob** via `react-native-google-mobile-ads`, UMP consent | Incumbent uses it; rewarded ads for cans is the core ad loop | LevelPlay mediation later |
| Push | **Expo Push / FCM + OneSignal** | OneSignal for segmentation (rare-find alerts, streak reminders) | — |
| Analytics | **PostHog** (product) + **Sentry** (crash) | Matches intel; both have generous free tiers, privacy-friendly config | — |
| Maps | **react-native-maps** (Google Maps on Android, Apple Maps on iOS) + server-side geohash tiling | Free Apple Maps on iOS; Google Maps has $200/mo credit | Mapbox (nicer styling, costs) |
| Web | **Expo web / Next.js landing** + later PWA | Web PWA is a viral-growth gap in the incumbent | — |

**Verdict:** Expo + Convex is correct for MVP. The differentiating engineering is in the ML pipeline and camera UX, not in reinventing infra.

### 2.2 When to deviate
- If relational/geo queries (PostGIS `ST_DWithin`, complex album filters) become painful in Convex → migrate read-heavy geo/album queries to **Supabase/Postgres**, keep Convex for realtime presence/social. Don't start there.
- If Replicate latency hurts silhouette UX → move background removal to a dedicated GPU endpoint on fal.ai or Modal.

---

## 3. System Architecture

```
┌────────────────────────────── CLIENT (Expo) ──────────────────────────────┐
│  Camera screen (vision-camera)                                            │
│    ├─ Frame processor: on-device cat detector (MLKit/TFLite YOLO)         │
│    ├─ Liveness cues: parallax/multi-frame motion check, flash/reflection  │
│    └─ Capture: full-res JPEG + detection bbox + device metadata           │
│  Local queue (expo-sqlite) → retry-safe upload                            │
└───────────────┬───────────────────────────────────────────────────────────┘
                │ HTTPS (Convex actions/mutations, R2 presigned uploads)
┌───────────────▼────────────────── BACKEND (Convex) ───────────────────────┐
│  scanPipeline (action, async job):                                        │
│    1. Rate-limit & can-spend auth (mutation, transactional)               │
│    2. pHash exact-dup reject                                              │
│    3. Vision-LLM verify: real cat? live photo vs screen? breed/colors     │
│    4. Embedding (512-d) → vector dedup vs user's + global recent sightings│
│    5. Silhouette cutout (Replicate BiRefNet) → R2                         │
│    6. Rarity roll (server RNG, seeded + logged)                           │
│    7. Name/stats/ability generation (LLM template + constraints)          │
│    8. Moderation queue flag if uncertain → human review                   │
│  Geo: sightings table w/ geohash index; map tiles endpoint                │
│  Social: friends, feed, notifications fan-out (OneSignal)                 │
│  Economy: cans ledger, XP/coins, RevenueCat webhook, AdMob SSV callbacks  │
└───────────────┬───────────────────────────────────────────────────────────┘
                │
   ┌────────────▼─────┐  ┌──────────────▼───────────┐  ┌───────────────────┐
   │ Cloudflare R2    │  │ AI services              │  │ RevenueCat / AdMob│
   │ originals +      │  │ OpenAI vision, Replicate │  │ OneSignal, PostHog│
   │ cutouts + thumbs │  │ (bg-removal, embeddings) │  │ Sentry            │
   └──────────────────┘  └──────────────────────────┘  └───────────────────┘
```

**Key architectural decisions:**

- **Scans are async jobs, not request/response.** Client uploads image → gets `scanId` → subscribes to Convex realtime doc for result. Snack-throwing minigame plays *while* verification runs, hiding latency (the incumbent's perceived sluggishness partly comes from blocking UI).
- **Optimistic can spend, server-authoritative.** Can is deducted in the same Convex mutation that creates the scan; refunded automatically if the pipeline hard-fails server-side (never for "no cat found" — that's gameplay).
- **All randomness server-side.** Rarity rolls use server RNG with a logged seed; client never sees probabilities it can manipulate.
- **Idempotency keys** on every mutation that grants currency/items (scan, ad reward, IAP) — retry storms after launch-day outages must not double-grant.

---

## 4. Data Model (Convex schema sketch)

```
users:        { clerkId, displayName, avatarUrl, xp, level, coins,
                canCount, canCap, lastCanRegenAt, proTier, streak,
                settings: {units, privacy}, createdAt, deletedAt? }
keepsakes:    { ownerId, scanId, name, customName?, rarity, type,
                stats: {snack, charm}, abilities[], imageUrl, cutoutUrl,
                thumbUrl, embeddingId, breed?, colors[], serialNumber,
                released: bool, favorite: bool, createdAt }
                indexes: by_owner, by_owner_fav, by_rarity, serial unique
scans:        { userId, status: queued|verifying|complete|failed|flagged,
                imageUrl, phash, verdict: {isCat, isLive, confidence, breed},
                geo: {geohash, lat, lng, accuracy}, deviceMeta, rejectionReason? }
sightings:    { keepsakeId, ownerId, geohash(6), coarseLat, coarseLng,  // coarsened!
                rarity, createdAt }   // public map data — never exact coords
vectors:      { keepsakeId, embedding: float[512] }  // or external vector DB at scale
friendships:  { aId, bId, status }  // canonical ordered pair
reports:      { reporterId, targetType, targetId, reason, status }
economyLedger:{ userId, delta, currency, reason, refId, idempotencyKey, createdAt }
moderationQ:  { scanId, priority, status, reviewerDecision? }
rolls:        { scanId, raritySeed, rarityRoll, createdAt }  // audit trail
```

Notes:
- **Public map stores only coarsened coordinates** (~geohash-6, ±610m) plus a jitter; exact location never leaves the `scans` table, which is private to the owner.
- `economyLedger` is append-only; balances are derived/cached — makes dupes and exploits auditable.
- Album performance fix (incumbent complaint): keep `keepsakes` rows small (URLs not blobs), paginate by cursor, thumbnails via CDN, denormalize album counts onto `users`.

---

## 5. AI/ML Pipeline

### 5.1 Stage 1 — On-device detection (client)
- **MVP:** MLKit Object Detection (stream mode) + simple "cat-like" filter. Ships day one, zero training.
- **V1:** Custom **YOLOv8n-cat or EfficientDet-Lite0**, fine-tuned on Oxford-IIIT Pet + OpenImages cat classes + negative hard cases (dogs, stuffed animals, screens), exported to TFLite, run in a vision-camera frame processor with SKL/NNAPI/GPU delegate. Target: ≥90% recall on in-frame cats at 15fps on a 2020 mid-range Android.
- **Guidance UX (fixes #1 complaint):** don't just binary-detect — show distance/lighting hints ("move closer", "more light") derived from bbox size and luma. Show the detection box so users trust it.
- **Lens & zoom control:** expose ultra-wide/wide/tele selection and pinch zoom via vision-camera — direct response to top user complaint.
- **Anti-spoof on-device heuristics:** require ≥N consecutive frames with micro-motion/parallax (bbox jitter consistent with a live animal, not a static screen), reject moiré patterns (FFT spike detection on the crop).

### 5.2 Stage 2 — Server verification (per scan, async)
1. **pHash** → reject exact duplicates (screenshots of own album, re-uploads) in <5ms.
2. **Vision-LLM check** (GPT-4.1-mini or Gemini Flash, structured JSON output):
   - `is_real_cat` (vs. plush, drawing, human in costume)
   - `is_live_photo` (vs. photo-of-screen / photo-of-print — look for bezels, moiré, glare, perspective)
   - breed guess, coat colors, pose, image quality
   - confidence; anything <threshold → moderation queue, user gets "verifying…" state, not a hard fail.
3. **Duplicate fingerprinting:** 512-d embedding (pet-fine-tuned CLIP). Cosine similarity vs (a) the same user's existing keepsakes → "you already caught this cat!" (merge + bonus instead of dupe), (b) recent global sightings in same geohash → multi-user same-cat is *allowed and celebrated* ("3 trainers spotted Whiskers") but flagged if same device cluster.
4. **Silhouette/cutout:** BiRefNet/rembg on Replicate → transparent PNG for the sticker card. Async; card shows photo first, cutout pops in later.
5. **Generation:** name via template + LLM with constrained vocabulary (seeded by rarity/type/colors), stats derived from rarity roll + breed traits, abilities from a fixed keyword pool. **Allow renaming (paid/free)** — top-10 user request the incumbent ignores.
6. **Rarity:** server roll, weighted tiers (e.g. Alley 55% / Garden 25% / Moonlit 12% / Velvet 6% / Golden 2%), pity timer for streak protection, all rolls logged.

### 5.3 Anti-cheat / integrity
- **Server-side only verdicts**; client detection is UX, never authority.
- **Screen-photo defense:** on-device moiré/parallax + server vision-LLM liveness — two independent layers.
- **Location spoofing:** plausibility checks (teleport detection via last-sighting distance/time, mock-location flags from Android API, accuracy radius sanity). Community-map claims require being within ~100m of pin with GPS accuracy <50m.
- **Rate limits:** max scans/hour/device + per-IP anomaly detection; device attestation (Play Integrity / App Attest) on scan submission for high-value actions.
- **Economy:** ledger + idempotency keys + RevenueCat server receipt validation + AdMob server-side verification (SSV) callbacks before granting cans — fixes "watched ad, got nothing" *and* ad-reward farming.
- **Moderation:** report button (top-3 voted feature), auto-flag queue from low-confidence verdicts, human review console (simple internal Next.js page), strikes → shadowban from map.

---

## 6. Image Storage & Processing

| Asset | Store | Notes |
|---|---|---|
| Original capture | R2 `orig/` (private) | Presigned PUT from client; lifecycle: delete after 90d unless keepsake'd |
| Card photo (compressed) | R2 `cards/` + CF CDN | 1080px WebP, signed URL for non-public |
| Cutout PNG/WebP | R2 `cutouts/` + CDN | Generated async |
| Thumbnail | R2 `thumbs/` + CDN | 256px WebP, public-ish — powers album lists fast |
| Embeddings | Convex `vectors` table (MVP) → pgvector/Qdrant if >1M | Brute-force per-user compare is fine; global search needs ANN later |

Costs kept near zero by R2's no-egress-fee model and generating derivatives via a Cloudflare Worker on upload.

---

## 7. Map & Social Features

- **Community map:** geohash-bucketed sightings; map endpoint returns aggregated clusters at low zoom, individual coarsened pins at high zoom. Only sightings older than 24h and from non-deleted, non-banned accounts appear. "Historical, not live" disclaimer in UX (safety + expectation-setting, per intel §6.2).
- **Proximity claim:** client must be within radius; verified server-side against reported GPS + accuracy; claim triggers a lightweight re-verification (no new can needed).
- **Friends/social:** friend codes + deep links first; contact-discovery opt-in with locally-hashed phone numbers (matches incumbent's privacy posture). Activity feed (friend caught X rarity), album compare, sticker/deep-link sharing.
- **Notifications:** OneSignal segments — rare friend find, streak at risk, can cap full, map pin near you (batch, not realtime, to avoid creep factor).
- **Deferred to post-MVP:** trading, Alley Clash duels, expeditions — design the data model (abilities, stats on keepsakes) so they're additive, not schema-breaking.

---

## 8. Monetization & Economy

- **Cans (energy):** regen 1 per 20 min (free, cap 10) — Pro: 2× regen, cap 25. Rewarded ad = +2 cans. Store packs: 15/40/100 cans. **Also: cans purchasable with coins** — gives coins the sink users demand.
- **Coins sink:** rename cards, buy basic cosmetics, extra throws, can packs — fixes the #1 economy complaint.
- **Pro subscription** ($4.99/mo): regen/cap, no interstitials, exclusive cosmetics, extra album slots, rename free.
- **Cosmetics IAP:** hats/glasses packs ($0.99–2.99).
- **Ads:** rewarded (opt-in) primary; one interstitial max per session for free users, never after a failed scan (emotional timing matters).
- **Web3:** explicitly out of scope for MVP. Design keepsakes with stable serials so a future collectible layer is possible, but don't promise it.

---

## 9. Security & Privacy

- **GDPR-first** (controller likely EU-based): processing register, DPAs with every sub-processor (Convex, Cloudflare, OpenAI, Replicate/fal, RevenueCat, Google, OneSignal, PostHog, Sentry), consent gating for ads (UMP) and analytics/Sentry (opt-in), 16+ age gate.
- **Data minimization:** precise location used when-in-use only, coarsened before any public storage; no background location; no facial recognition; strip EXIF on upload server-side.
- **Encryption:** TLS everywhere; R2 private buckets + short-lived signed URLs; embeddings not reversible to images but treated as personal data.
- **Account deletion:** in-app + web, 30-day purge, 90-day backup expiry — mirror incumbent's policy (it's a good baseline).
- **Abuse:** report → queue → action SLAs; rate limits; attestation; content-hash blocklist for removed images.
- **Secrets:** all API keys server-side (Convex env vars); client has zero third-party secrets except public keys.

---

## 10. Cost Estimates (monthly, per phase)

| Item | Beta (1K DAU) | Launch (20K DAU) | Scale (100K DAU) |
|---|---|---|---|
| Expo/EAS (builds+updates) | $29–99 | $99 | $99–250 |
| Convex | $0–25 | $25–100 | $100–500 |
| Cloudflare R2+CDN | ~$1 | $5–20 | $50–150 |
| Vision-LLM verify (~$0.002/scan avg) | $20 (10K scans) | $400 (200K scans) | $2K (1M scans) |
| Replicate/fal (cutout+embed, ~$0.005/scan) | $50 | $1K | $5K |
| OneSignal/PostHog/Sentry | $0 | $0–100 | $100–500 |
| Maps (Google/Apple) | $0 | $0–50 | $50–200 |
| RevenueCat | $0 (<$2.5K MTR) | 1% of revenue | 1% |
| **Total infra** | **~$150/mo** | **~$1.5–2K/mo** | **~$8–12K/mo** |

Margin note: AI cost per successful scan ≈ $0.007; a rewarded ad pays ~$0.01–0.04 and a can pack amortizes to ~$0.07/can — the economy clears AI costs with headroom, *as long as* verification is one-shot per scan (no retry loops). Biggest variable is Replicate GPU latency/cost — cache cutouts, batch embeddings.

---

## 11. Phased Implementation Plan

**Phase 0 — Foundations (weeks 1–2)**
Repo + CI, EAS dev builds, Clerk/Convex auth, schema v1, R2 upload path, PostHog/Sentry wiring, design system skeleton.

**Phase 1 — Core scan loop (weeks 3–6)**
Vision-camera + MLKit detection, capture → upload → async `scanPipeline` (pHash → vision-LLM → embedding → rarity → generation), keepsake card + album, cans/regen/ledger, basic snack-throw minigame. **Gate: 20 beta testers, first-scan success rate ≥80%.**

**Phase 2 — Collection & polish (weeks 7–9)**
Cutouts, rename, release/delete, favorites/filters, custom TFLite model v1, lens/zoom controls, streaks/XP/levels, notification basics.

**Phase 3 — Economy & social (weeks 10–12)**
RevenueCat (Pro + packs), AdMob rewarded + SSV, coins sinks, friends + activity feed, report button + moderation console.

**Phase 4 — Map & launch (weeks 13–16)**
Geohash sightings, clustered map, proximity claims, safety UX, Play Store launch + load testing (target 10× day-one incumbent traffic; the incumbent died at 2K users — we plan for 50K day one), iOS TestFlight.

**Phase 5+ — Post-launch:** iOS public, PWA, expeditions/missions, Alley Clash duels, trading, seasonal events.

---

## 12. Top Technical Risks

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| 1 | **On-device detection still underperforms** in low light/distance | Fatal — the core promise | Graceful degrade to server vision-LLM verify ("we'll check this one"); guidance UI; custom model with hard-negative training; manual review queue instead of hard fail |
| 2 | **Vision-LLM cost/latency blowout** at scale | Margin + UX | Cheapest model that passes eval (Gemini Flash fallback), batch/embed caching, only verify scans that pass on-device gate |
| 3 | **Launch-day traffic spike** (viral cat content) | Incumbent literally died to this | Async job architecture, queue backpressure, idempotent mutations, load test at 50K DAU, feature-flag kill switches |
| 4 | **Screen-photo cheating floods the map** | Trust collapse (incumbent's map is spammy) | Two-layer liveness, attestation, report→review pipeline, coarsened/jittered pins |
| 5 | **Embedding dedup false positives/negatives** (same cat marked new / different cats merged) | Collection integrity | Tune threshold on labeled pet-pair dataset; "merge or keep both" user prompt on ambiguous matches instead of silent decisions |
| 6 | **Replicate dependency** (latency, price changes) | Card-gen delays | Abstract behind provider interface; fal.ai/Modal fallback; async so UX never blocks |
| 7 | **Convex query limits on geo/album scale** | Perf regressions | Geohash pre-bucketing, pagination discipline, Postgres escape hatch planned (§2.2) |
| 8 | **Store review / policy risk** (camera+location app, 16+, UGC) | Delist/delay | Attestation, privacy nutrition labels accurate, UGC moderation tooling ready before launch |
| 9 | **Solo/small-team scope creep** (trading, duels, web3) | Never shipping | Phase gates above are contractual with ourselves; abilities/stats modeled now so features are additive |
| 10 | **Ad reward fraud / economy exploits** | Revenue leak | SSV callbacks, ledger audit, server-authoritative grants, anomaly alerts |

---

## 13. What We Do Differently From the Incumbent (one-line each)

1. Async scan pipeline + minigame-as-loading → no perceived lag.
2. Server vision-LLM verification → detection that actually works.
3. Two-layer anti-spoof + report button → a map users trust.
4. Release/rename/favorites → an album users can manage.
5. Coins with real sinks → an economy users understand.
6. Lens selection + zoom + guidance → camera users can aim.
7. Load-tested async backend → we survive our own launch day.
8. iOS at launch → double the market the incumbent is missing.
