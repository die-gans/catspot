# CatchCat — Full Competitive Breakdown & Build-Ready PRD

**Working title for our build:** *Catspot* (placeholder — pick something you like).  
**Subject:** `xyz.catchcat.app` (CatchCat) — real-world cat spotting & collection game.  
**Date:** 2026-07-29  
**Sources:** Google Play Store, catchcat.lol, privacy policy, press coverage, community feedback board (200 ideas / 596 votes), developer social posts.

---

## TL;DR — The Verdict

**The app sucks, the concept is gold, and the market is wide open.**

CatchCat is a real-world cat-spotting collection game — "Pokémon GO for cats." It went viral on launch: **2,000+ Android downloads on day one with zero marketing**, got press coverage, and now sits at **3.0★ with 100K+ installs**. Every serious complaint is an **execution failure**, not a concept flaw: the AI doesn't detect cats, the camera UX is bad, the app is sluggish, the economy makes no sense, the map is full of junk, and there's no iOS version.

**The winning move:** build a better-executed version of the same thing, on both platforms, with a working camera/detection loop, honest economy, and a social layer that actually ships.

---

## 1. What CatchCat Is

### 1.1 Core Loop
1. **Spot** — open live camera and frame a real cat. On-device detection attempts to find it.
2. **Throw** — drag a retro "snack can" and release it in the green zone of a box. Each can gives 3 attempts.
3. **Collect** — a verified sighting becomes a **keepsake** cat card with a generated name, serial number, rarity tier, stats, and abilities.

### 1.2 Key Features
- **Live camera scan** with real-time cat detection (no gallery import).
- **Five rarity tiers:** Alley → Garden → Moonlit → Velvet → Golden.
- **Album / field journal** with stickers, stats (Snack/Charm), types (e.g., Chonky), and abilities (e.g., Guard, Copycat, Finale).
- **Community map** of historical sightings from other players; proximity required to claim a linked keepsake.
- **Friends & sharing** — compare albums, share cards, activity notifications.
- **Alley Clash** — a promised PvP/card-battle mode, currently "coming soon."
- **Snack can energy system** — throttled recharge, CatchCat Pro subscription for faster regen/higher cap, rewarded ads, and IAP packs.

### 1.3 Platform & Business
- **Platforms:** Android live; iOS "coming soon"; Web3 "coming soon."
- **Downloads:** 100K+ (Google Play).
- **Rating:** 3.0★ (~2.55K reviews).
- **Developer:** Sebastian Seidel, solo indie, Germany.
- **Inferred stack:** Expo + React Native, Convex, Cloudflare R2, OpenAI/Replicate, RevenueCat, AdMob, FCM/OneSignal, PostHog, Sentry.

---

## 2. Product Teardown

### 2.1 Value Proposition Assessment

| Aspect | Verdict | Why |
|---|---|---|
| Hook | ✅ Strong | "Every cat you meet becomes a collectible card" is instantly understandable and viral. |
| Differentiation | ✅ Real | Uses real-world cats instead of licensed creatures — your neighborhood is the content. |
| First-run success | ❌ Broken | The core scan fails too often; a collection game that can't collect loses its value prop immediately. |
| Long-term depth | ⚠️ Shallow | Cards have stats but no real use until Alley Clash ships; album management is missing. |
| Trust | ✅ Good | Strong GDPR/privacy posture; transparent data use is a genuine asset. |

### 2.2 Target Personas & Where CatchCat Fails Them

| Persona | What they want | CatchCat's failure |
|---|---|---|
| **Casual cat lover** | Snap cats on walks, build a cute diary | Detection fails; camera fights them. |
| **Collector/completionist** | Rarity, full sets, stats, serial numbers | No delete/release, no filters, album lags, opaque rarity logic. |
| **Social player** | Friends, trading, duels, leaderboards | No trading, no duels, map is unmoderated. |
| **Location gamer (Pokémon GO crossover)** | Walk-and-collect loop, events, gyms | Static pins, no events, energy has no coin sink. |
| **TCG/battler** | Use card stats & abilities | Abilities are placeholder text; no combat mode. |
| **iOS users** | Play the viral game | App literally doesn't exist on the US App Store. |

### 2.3 UX Strengths

- **Legible three-step loop:** Spot → Throw → Collect. Easy to TikTok.
- **Charming card design:** sticker-style cards, funny generated names, serial numbers, flip-to-reveal photo.
- **Distinctive snack-can minigame:** more memorable than a simple shutter button.
- **Privacy-first stance:** GDPR-first policy, no background location, easy account deletion — rare for a solo dev.
- **Safety copy on the map:** historical pins, no trespassing — good expectation-setting.

### 2.4 UX Gaps (Brutally Honest)

1. **Core detection is unreliable.** The #1 review theme: cats clearly in frame are not detected, especially at distance or in low light.
2. **Camera UX is hostile.** Forced wide-angle lens, no zoom, no lens selection, freezes, no manual capture fallback.
3. **Snack-throwing minigame is over-tuned.** Hard to land, inconsistent, and can lock players out after a failed scan.
4. **No collection management.** Can't rename, delete, favorite, or filter. Album becomes a laggy pile.
5. **First-run churn trap.** Empty album + broken camera = instant uninstall.
6. **Economy is incoherent.** Coins exist but buy nothing. Everything costs real money. Rewarded ads sometimes don't pay out.
7. **Performance is poor.** First-load freeze, lag on every click, album slows as it grows.
8. **No moderation UX.** Fake/duplicate/non-cat pins on the map; no report button despite being the #3 voted feature.

### 2.5 Pain Point Severity Ranking

| # | Pain Point | Severity | Evidence |
|---|---|---|---|
| 1 | AI detection fails on real cats | 🔴 Critical | Top Play Store theme; works only at close range |
| 2 | Camera UX (lens, zoom, freezes) | 🔴 Critical | Top Play Store theme; +14 feedback votes |
| 3 | Performance (lag, album slowdown) | 🔴 Critical | 3.0★ anchor; +6 votes on album loading |
| 4 | Snack minigame finicky/punishing | 🟠 High | Multiple reviews; "locks users out" |
| 5 | Fake/spam map content, no report | 🟠 High | Reviews; +27 votes (3rd most requested) |
| 6 | No delete/rename/favorites | 🟠 High | +21, +16, +7 votes respectively |
| 7 | Confused economy (coins no sink) | 🟡 Medium | Reviews; +3 votes for coins→cans |
| 8 | No iOS | 🟡 Medium | "Coming soon"; US App Store unavailable |
| 9 | No trading/duels | 🟡 Medium | #1 request: Cat Deck Duel (+78 votes) |
| 10 | Opaque rarity logic | 🟢 Low | Users ask for explanations |

### 2.6 Monetization Critique

CatchCat's model is **ads + IAP + subscription + hinted Web3**. The problem is the throttle gates a broken experience.

| Element | Current state | Problem | What good looks like |
|---|---|---|---|
| Snack cans (energy) | Recharge over time; Pro speeds up | Paying to bypass a timer for a broken scan feels insulting | Energy should gate *delight*, not frustration; generous starting supply |
| Coins | Earned but have no sink | Users ask "why do I have coins?" | Coins buy cans, renames, card frames, basic cosmetics |
| Rewarded ads | Buggy | "Watched ad, got no can" | Server-verified ad rewards; never fail |
| Subscription | More cans, faster | Thin value; feels like a tax | Sell identity: exclusive frames, no interstitials, early mode access |
| Cosmetics | Profile cat only | Attachment is to caught cats, not profile | Cosmetic slots on keepsakes themselves |
| Web3 | "Coming soon" | Red flag for the wholesome audience | Skip entirely; stable serials allow future collectible layer without promising tokens |

---

## 3. Competitive Landscape

### 3.1 Feature Matrix

| Feature | CatchCat | Pokémon GO | Cat Scanner | Pikmin Bloom | Google Lens |
|---|---|---|---|---|---|
| Real-world animal/object detection | ✅ (unreliable) | ❌ virtual creatures | ✅ (mature breed ID) | ❌ | ✅ (utility) |
| Collection / album | ✅ cards, rarity | ✅ deep Pokédex | ❌ history only | ✅ light | ❌ |
| Location map gameplay | ⚠️ static pins | ✅ stops/gyms/routes | ❌ | ✅ walking | ❌ |
| PvP / battles | ❌ "coming soon" | ✅ Go Battle League | ❌ | ❌ | ❌ |
| Social / trading | ⚠️ friends only | ✅ friends + trading | ❌ | ⚠️ light | ❌ |
| AR camera layer | ⚠️ detection only | ✅ AR+ | ❌ | ✅ AR-lite | ❌ |
| Capture minigame | ✅ snack throw | ✅ ball throw | ❌ | ❌ | ❌ |
| iOS | ❌ | ✅ | ✅ | ✅ | ✅ |
| Monetization | Confused | Mature F2P | Simple paid/IAP | IAP | Free |

**Key insight:** CatchCat owns a unique intersection — *real-animal detection + collection + minigame* — but it is unexploited because the execution is weak. A new entrant that combines **Cat Scanner-grade detection** with **half of Pokémon GO's game systems** wins the category.

### 3.2 SWOT

| | Helpful | Harmful |
|---|---|---|
| **Internal** | **Strengths:** Proven viral concept; charming card design; novel real-animal collection loop; strong privacy posture; engaged feedback community (200 ideas, 596 votes) | **Weaknesses:** Unreliable detection; poor camera UX; sluggish performance; incoherent economy; no collection management; unmoderated map; solo-dev velocity; 3.0★ rating |
| **External** | **Opportunities:** Huge iOS gap; top-voted community ideas are a free roadmap; modern vision models make detection cheap; no credible #2 | **Threats:** A funded clone could ship in months; Niantic could add real-animal scanning; Web3 pivot could alienate audience; low rating death spiral |

---

## 4. How a New Entrant Wins

1. **Win on detection reliability.** Multi-stage pipeline: on-device detector → server vision-LLM verification → manual fallback. Target ≥90% first-scan success. A failed auto-detect must never hard-block a catch.
2. **Guarantee the first-session win.** Tutorial with a guaranteed staged/practice catch, generous starting cans, and a "pity" rule so early failures still award the card.
3. **Respect the camera.** Lens selection, zoom, tap-to-focus, low-light hints, and a manual capture fallback. The camera is the controller.
4. **Give the collection a brain.** Delete/release, rename, favorites, filters, search, and a fast virtualized album at 500+ cards.
5. **Ship the social game CatchCat only promised.** Cat Deck Duel (turn-based card combat) was the #1 community request (+78 votes). Trading and neighborhood leaderboards turn a solo album into a retention machine.
6. **Launch iOS + Android simultaneously.** CatchCat's biggest unforced error is ceding the US App Store. A cross-platform stack makes this near-free.
7. **Design an honest economy.** One readable soft currency with real sinks, cosmetics on keepsakes (not just profile cat), rewarded ads that always pay out, and a subscription that sells identity — not relief from a timer.

---

## 5. Technical Architecture & Build Blueprint

### 5.1 Recommended Stack

| Layer | Choice | Why |
|---|---|---|
| Mobile framework | **Expo SDK 52+ (React Native)** | Single iOS+Android codebase, OTA updates, excellent camera/ML ecosystem. Matches the incumbent's stack but executed properly. |
| Camera | **react-native-vision-camera v4** + frame processors | Real-time frame processing, lens selection, zoom, torch — directly fixes the #2 complaint. |
| On-device ML | **Google MLKit object detection** (MVP) → custom **TFLite YOLOv8n/EfficientDet-Lite0** | MLKit ships day one; custom model fine-tuned on cats closes the accuracy gap. |
| Backend | **Convex** | Real-time sync, TypeScript end-to-end, scheduled jobs, scales from 0. Strong for social/map features. |
| Image storage | **Cloudflare R2** + CDN | Zero egress fees, cheap at image-heavy scale. |
| Image processing | **Replicate** (silhouette/rembg) + **Cloudflare Workers** (thumbnails) | On-demand GPU without managing infra. |
| Server vision | **OpenAI GPT-4.1-mini / GPT-4o-mini vision** | Cheap verification of "real cat vs. screen/print/plush." |
| Embeddings | **OpenCLIP/MobileCLIP pet-fine-tuned** | 512-d vectors for duplicate detection of the same physical cat. |
| Auth | **Clerk** (Expo + Convex integration) | Google/Apple/email-code out of the box. |
| IAP/ads | **RevenueCat** + **AdMob** | Industry standard; handles receipt validation and SSV ad rewards. |
| Push | **Expo Push / FCM + OneSignal** | Segmentation for rare-find alerts, streak reminders. |
| Analytics | **PostHog** + **Sentry** | Privacy-friendly, generous free tiers. |
| Maps | **react-native-maps** (Apple Maps on iOS, Google Maps on Android) | Free Apple Maps; Google Maps has $200/mo credit. |
| Web | **Expo web / Next.js landing** | PWA later for viral share pages. |

### 5.2 System Architecture

```
┌─────────────────────────── CLIENT (Expo) ─────────────────────────────┐
│  Camera (vision-camera)                                                │
│    ├─ Frame processor: on-device cat detector (MLKit/TFLite)           │
│    ├─ Liveness cues: parallax/motion, reflection/moiré detection       │
│    └─ Capture: full-res JPEG + bbox + device metadata                  │
│  Local queue (expo-sqlite) → retry-safe upload                         │
└───────────────┬─────────────────────────────────────────────────────────┘
                │ HTTPS
┌───────────────▼────────────────── BACKEND (Convex) ───────────────────────┐
│  scanPipeline (async action):                                            │
│    1. Rate-limit & spend can (transactional)                             │
│    2. pHash exact-duplicate rejection                                    │
│    3. Vision-LLM verify: real cat? live photo? breed/colors?             │
│    4. 512-d embedding → duplicate detection vs user's/global cats       │
│    5. Silhouette cutout (Replicate) → R2                                  │
│    6. Server-side rarity roll                                             │
│    7. Name/stats/ability generation                                       │
│    8. Moderation queue if uncertain → human review                       │
│  Geo, social, economy, notifications                                     │
└───────────────┬─────────────────────────────────────────────────────────┘
                │
   ┌────────────▼─────┐  ┌──────────────▼───────────┐  ┌──────────────────┐
   │ Cloudflare R2    │  │ AI services              │  │ RevenueCat/AdMob │
   │ originals/cutouts│  │ OpenAI, Replicate        │  │ OneSignal, etc.  │
   └──────────────────┘  └──────────────────────────┘  └──────────────────┘
```

### 5.3 Data Model (Convex sketch)

```
users:        clerkId, displayName, avatar, xp, level, coins, canCount, canCap,
              lastCanRegenAt, proTier, streak, settings, createdAt, deletedAt?

keepsakes:    ownerId, scanId, name, customName?, rarity, type, stats, abilities,
              imageUrl, cutoutUrl, thumbUrl, embeddingId, breed?, colors[], serialNumber,
              released, favorite, createdAt
              indexes: by_owner, by_owner_fav, by_rarity, serial unique

scans:        userId, status, imageUrl, phash, verdict, geo, deviceMeta, rejectionReason?

sightings:    keepsakeId, ownerId, geohash(6), coarseLat, coarseLng, rarity, createdAt
              // Public map data — exact coords never exposed

vectors:      keepsakeId, embedding: float[512]

friendships:  aId, bId, status

reports:      reporterId, targetType, targetId, reason, status

economyLedger: userId, delta, currency, reason, refId, idempotencyKey, createdAt

moderationQ:  scanId, priority, status, reviewerDecision?

rolls:        scanId, raritySeed, rarityRoll, createdAt  // audit trail
```

### 5.4 AI/ML Pipeline

1. **On-device detection (client)**
   - MVP: MLKit object detection with cat-like filter.
   - V1: custom TFLite YOLOv8n/EfficientDet-Lite0 fine-tuned on cats + hard negatives (dogs, plushies, screens).
   - Add guidance UX: "move closer," "too dark," bounding box overlay.
   - Anti-spoof heuristics: multi-frame parallax, moiré pattern detection.

2. **Server verification (async)**
   - pHash → reject exact duplicates instantly.
   - Vision-LLM → `is_real_cat`, `is_live_photo`, breed/colors, quality, confidence.
   - 512-d embedding → fuzzy duplicate detection.
   - Silhouette cutout → transparent PNG for sticker card.
   - Name/stats/ability generation → template + LLM, seeded by rarity/type.
   - Rarity roll → server-side weighted RNG, logged.

3. **Anti-cheat**
   - Server-authoritative verdicts only.
   - Two-layer screen-photo defense: moiré/parallax on device + vision-LLM liveness on server.
   - Location spoofing checks: teleport detection, mock-location flags, accuracy sanity.
   - Rate limits per device/hour.
   - Play Integrity / App Attest for high-value actions.
   - Economy ledger + idempotency keys prevent double-grants.

### 5.5 Security & Privacy

- **GDPR-first:** controller is likely EU-based; maintain a processing register and DPAs with all subprocessors.
- **Data minimization:** precise location only when-in-use; coarsen before public map; no background location; no facial recognition; strip EXIF on upload.
- **Encryption:** TLS everywhere; R2 private buckets + short-lived signed URLs.
- **Account deletion:** in-app + web, 30-day purge, 90-day backup expiry.
- **Moderation:** report button on every pin/card, auto-flag queue, human review console, strikes → shadowban.

### 5.6 Cost Estimates

| Item | Beta (1K DAU) | Launch (20K DAU) | Scale (100K DAU) |
|---|---|---|---|
| Expo/EAS | $29–99 | $99 | $99–250 |
| Convex | $0–25 | $25–100 | $100–500 |
| Cloudflare R2+CDN | ~$1 | $5–20 | $50–150 |
| Vision-LLM (~$0.002/scan) | $20 | $400 | $2K |
| Replicate/fal (~$0.005/scan) | $50 | $1K | $5K |
| OneSignal/PostHog/Sentry | $0 | $0–100 | $100–500 |
| Maps | $0 | $0–50 | $50–200 |
| RevenueCat | $0 | 1% of revenue | 1% |
| **Total infra** | **~$150/mo** | **~$1.5–2K/mo** | **~$8–12K/mo** |

Margin note: AI cost per scan ≈ $0.007. A rewarded ad pays ~$0.01–0.04, and a can pack amortizes to ~$0.07/can — the economy clears AI costs with headroom if verification is one-shot.

### 5.7 Phased Build Plan (16 weeks to MVP)

**Phase 0 — Foundations (weeks 1–2):** repo, CI, EAS dev builds, Clerk/Convex auth, schema v1, R2 upload, PostHog/Sentry, design system.

**Phase 1 — Core scan loop (weeks 3–6):** vision-camera + MLKit, async `scanPipeline`, keepsake card + album, cans/regen/ledger, basic snack-throw minigame. Gate: 20 beta testers, first-scan success ≥80%.

**Phase 2 — Collection & polish (weeks 7–9):** cutouts, rename, release/delete, favorites/filters, custom TFLite model v1, lens/zoom controls, streaks/XP/levels, notifications.

**Phase 3 — Economy & social (weeks 10–12):** RevenueCat (Pro + packs), AdMob rewarded + SSV, coins sinks, friends + activity feed, report button + moderation console.

**Phase 4 — Map & launch (weeks 13–16):** geohash sightings, clustered map, proximity claims, safety UX, Play Store launch + load testing for 50K day-one users, iOS TestFlight.

**Phase 5+ — Post-launch:** iOS public, PWA, expeditions/missions, Alley Clash-style duels, trading, seasonal events.

### 5.8 Top Technical Risks

| # | Risk | Mitigation |
|---|---|---|
| 1 | On-device detection still underperforms | Graceful degrade to server vision-LLM; manual review queue; custom model with hard-negative training |
| 2 | Vision-LLM cost/latency blowout | Cheapest model that passes eval (Gemini Flash fallback); batch/embed caching; only verify scans that pass on-device gate |
| 3 | Launch-day traffic spike | Async job architecture, queue backpressure, idempotent mutations, load test at 50K DAU |
| 4 | Screen-photo cheating floods map | Two-layer liveness, attestation, report→review, coarsened/jittered pins |
| 5 | Embedding dedup false positives/negatives | Tune threshold on labeled dataset; user prompt on ambiguous matches |
| 6 | Replicate dependency | Abstract provider interface; fal.ai/Modal fallback; async UX |
| 7 | Convex geo/album query limits | Geohash bucketing, pagination, Postgres escape hatch planned |
| 8 | Store review / policy risk | Attestation, accurate privacy labels, UGC moderation ready before launch |
| 9 | Scope creep (trading, duels, Web3) | Phase gates; model abilities/stats now so features are additive later |
| 10 | Ad reward fraud | SSV callbacks, ledger audit, server-authoritative grants |

---

## 6. PRD & North Star

### 6.1 Problem Statement

CatchCat proved the "Pokémon GO for cats" concept but execution failures make it 3.0★. The core verb (detecting and catching a real cat) doesn't work reliably, the camera fights the user, the economy is confusing, and the social layer is missing. A competent rebuild can capture the proven demand.

### 6.2 Solution

A real-world cat-spotting collection game rebuilt around three commitments CatchCat broke:
1. **Detection that works, with graceful fallback.** Multi-stage pipeline + manual capture so a failed auto-detect never blocks a catch.
2. **A camera built for cats.** Lens selection, zoom, tap-to-focus, low-light guidance, burst capture.
3. **An honest economy and a clean album.** Real coin sinks, collection management, and moderation from day one.

### 6.3 Target Users

| Segment | Description | Key needs |
|---|---|---|
| **Cat owners** | Immortalize their own cat as a card | Indoor/bad-light detection, custom naming |
| **Cat spotters** | Explore neighborhood/stray cats | Distance detection, zoom, trustworthy map |
| **Casual collectors** | Viral-curious, Pokémon GO nostalgia | Fast first success, streaks, no paywall ambush |
| **Social/competitive players** | Trading, duels, leaderboards | Friends, fair anti-cheat, card game depth (post-MVP) |

### 6.4 User Stories

- As a player, I can point my camera at a cat and get detection feedback within 2 seconds.
- As a player, if auto-detect fails, I can manually capture and submit for verification.
- As a player, my first guided catch always succeeds.
- As a player, I can choose lens and zoom so I can catch shy cats from a respectful distance.
- As a player, I can rename any cat.
- As a player, I can release/delete, favorite, and filter my cats.
- As a player, I can report a fake or inappropriate map pin.
- As a player, I understand exactly what my coins buy.
- As a free player, I can earn everything gameplay-critical through play.

### 6.5 MVP Feature List (v0.1) with Acceptance Criteria

#### F1 — On-device + server detection with manual fallback
- Detect a cat in frame at up to ~5m in normal indoor lighting, ≥90% recall on a 200-image test set.
- Detection feedback ≤500ms on mid-range device.
- If no detection after 5s, show "Capture anyway" button; manual captures queued for server verification (≤60s).
- Reject photos-of-screens with ≥95% precision.

#### F2 — Camera experience
- Lens selector (ultrawide/1x/tele where hardware allows), pinch zoom, tap-to-focus/exposure lock.
- 30fps preview on 2021+ mid-range devices; no freeze >100ms during capture.
- Framing hints based on detector confidence.

#### F3 — Collectible cat cards ("Keepsakes")
- Real photo, generated name (editable), rarity (5 tiers with documented odds), stats, flavor type.
- Card flip animation; serial number; XP + coins awarded.
- Duplicate scan of the same physical cat merges rather than duplicates.

#### F4 — Album & collection management
- Grid album with favorites, filters (rarity/date/type), search by name, multi-select release.
- 1,000 cards scroll at 60fps and open in <1s.
- Released cats soft-deleted (recoverable 7 days).

#### F5 — Community map with moderation
- Map of historical sighting pins; proximity claim ≤50m to collect a linked keepsake.
- Report button on every pin and card with reason categories.
- Auto-hide at 3 pending reports; human moderation SLA <48h.
- Safety notice on first map open; no background location.

#### F6 — Economy
- One energy unit (Snack Cans): 1 per catch, timed recharge, cap. Free tier: ≥10 catches/day.
- One soft currency (Coins): earnable from catches/quests; spendable on cans, cosmetics, renames.
- No interstitial ads in MVP. Rewarded ads optional for bonus cans; server-verified delivery.

#### F7 — Accounts, friends, onboarding
- Google / Apple / email-code sign-in; in-app account deletion (GDPR).
- Guided first-catch tutorial that cannot fail.
- Add friends, view albums, share card as image/deep link.

#### F8 — Platforms
- Android + iOS at parity from launch.

### 6.6 Anti-Goals

- **No Web3/NFTs/tokens** — ever.
- **No pay-to-win or paid-exclusive cats.** Rarity is earned in the world, not bought.
- **No forced/ interstitial ads** in the core scan loop.
- **No live cat tracking.** Pins are historical.
- **No facial recognition or human data collection.** Faces auto-blurred.
- **No PvP/TCG in MVP.** Alley-Clash-style mode waits for 2.0.
- **No background location tracking.**
- **No gallery import** in MVP (preserves the "real world" contract).

### 6.7 Monetization Plan

| Stream | Detail |
|---|---|
| **Subscription "Pro" (~$4.99/mo)** | Faster can recharge, higher cap, exclusive cosmetics, advanced album stats, no interstitials. No exclusive cats. |
| **IAP** | Can packs, cosmetic packs (keepsake frames, hats, glasses), name-change tokens beyond free allowance. |
| **Rewarded ads (opt-in)** | Bonus cans; hard daily cap; server-verified delivery. |
| **Seasonal passes (1.0+)** | Themed events, limited cosmetics — only after core retention is proven. |

### 6.8 Roadmap

**v0.1 — MVP (4 months)**
Everything in Section 6.5. Android + iOS. Goal: prove the core loop is delightful and reliable. Gate: first-session catch success ≥80%.

**v1.0 — Depth & Trust (+3 months)**
- Daily quests, streaks, seasonal events.
- Expeditions/missions (send cats on timed tasks — #2 community request).
- Trading between friends with anti-dupe safeguards.
- Localization (including Ukrainian — top community ask).
- Web PWA share pages for virality.
- Moderation dashboard v2.

**v2.0 — Competition (+6 months)**
- **Cat Deck Duel:** turn-based card combat using real catches as the deck (#1 request, +78 votes).
- Ranked ladders, neighborhood leaderboards.
- Optional walking/fitness XP tie-in.
- Clan/neighborhood groups.

### 6.9 Success Metrics

| Metric | v0.1 target | Why |
|---|---|---|
| First-session catch success rate | ≥80% | CatchCat's biggest churn point |
| Detection recall (field telemetry) | ≥90% at ≤5m | Core verb must work |
| D1 / D7 retention | 45% / 20% | Concept retention once execution is fixed |
| Time-to-first-catch | <3 min | Onboarding quality |
| Store rating | ≥4.3 | Execution credibility |
| Report resolution SLA | <48h, 95% | Community trust |
| Album p95 load time @ 500 cards | <1s | Collection longevity |
| Free-player catches/day | ≥10 median | Economy fairness |
| Crash-free sessions | ≥99.5% | Table stakes CatchCat missed |

### 6.10 North Star

**Brand promise:** *"Every cat you meet becomes a friend you keep."*

Wholesome, playful, trustworthy. We are the cat-spotting game that *works* — the technology disappears and the moment stays. Sticker-book warmth in the art; engineering rigor underneath. We are explicitly the anti-Web3, anti-dark-pattern, pro-privacy alternative in a genre the incumbent left broken.

**Principles:**
1. **The catch is sacred.** Detection reliability and camera quality outrank everything.
2. **Never punish collecting.** More cats must always mean more joy, never a slower app or a messier album.
3. **Fair by default.** One readable economy; money buys time and style, never power or exclusives.
4. **Trust is a feature.** Moderation, anti-cheat, honest map pins, and transparent data use are shipped as product, not policy PDFs.
5. **Real world, real respect.** Historical pins only, no live tracking, no trespassing, faces blurred, kids protected.

**What we will not compromise:**
- No crypto, NFTs, or tokens — regardless of market fashion.
- No forced ads in the core loop, at any revenue pressure.
- No paywalled cats or rarity — the world is not for sale.
- No background location or human facial data — even if it makes features easier.
- No shipping a detection regression — recall gates every release.

---

## 7. Decision Gate / Recommendation

**Should we build this?** Yes — but only if we can commit to the detection and camera quality as the #1 investment. The concept is already validated; the risk is execution, not market.

**Recommended next step:** a **4-week technical spike** to prove the scan pipeline works on real cats in real conditions (on-device detector + server vision-LLM + manual fallback) and to hit the ≥80% first-scan success gate. If the spike passes, move into the 16-week MVP plan.

**Biggest risk:** underestimating the camera UX. A cat is not a QR code — it moves, it's at distance, lighting varies. The camera must be treated like a game controller, not a file picker.

**Biggest opportunity:** the incumbent's community literally wrote the roadmap. Ship the top 5 feedback-board features (detection, camera, collection management, moderation, duels) and you inherit CatchCat's dissatisfied users.

---

## Appendix: Sources

- Google Play Store: https://play.google.com/store/apps/details?id=xyz.catchcat.app
- Website: https://www.catchcat.lol
- How it works: https://www.catchcat.lol/how-catchcat-works
- Community map: https://www.catchcat.lol/features/community-map
- Cat cards: https://www.catchcat.lol/features/cat-cards
- Alley Clash: https://www.catchcat.lol/alley-clash
- Rarity tiers: https://www.catchcat.lol/guides/rarity-tiers
- Snack cans: https://www.catchcat.lol/guides/snack-cans
- Support: https://www.catchcat.lol/support
- Feedback board: https://www.catchcat.lol/feedback
- Privacy policy: https://www.catchcat.lol/legal/privacy
- Press: Express.co.uk (June 24, 2026) — "'Pokemon Go for cats' game CatchCat returns after take down"
- Developer social: @ninetofivedude (X)

---

*Prepared by the K3 swarm + consolidation. Raw intel and subagent outputs live in `/home/dan/Projects/CatchCat/`.*
