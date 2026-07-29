# Catspot (Working Title) — PRD & North Star

**Status:** Build-ready draft · **Date:** July 29, 2026 · **Basis:** CatchCat competitive teardown (see `raw-intel.md`)

---

## 1. Problem

CatchCat proved the concept — "Pokémon GO for cats" hit 2,000 downloads day one with zero marketing and went viral. But it holds a **3.0★ rating** because the execution betrays the fantasy:

- **Detection doesn't work.** The #1 complaint: cats clearly in frame aren't detected, detection only works at point-blank range, and bad lighting breaks it. If the core verb of the game fails, nothing else matters.
- **Camera UX fights the user.** Forced wide-angle lens, no zoom control, no lens selection, freezes when framing moving cats.
- **The app is sluggish.** Freezes on first load, lag on every tap, album slows down as it grows.
- **The economy is confusing.** Coins and treats exist but have no sink — everything costs real money, so earned currency feels like a scam.
- **No moderation or anti-cheat.** The community map is polluted with fake/duplicate/non-cat photos and there's no report button. Photos-of-photos pass as catches.
- **No collection management.** No delete/release, no favorites, no filters — albums become unwieldy and slow.
- **Android only.** iOS "coming soon" indefinitely; the US App Store is unavailable — a massive reach gap.

**The opportunity is not inventing a new idea. It's executing the proven one competently.**

## 2. Solution

A real-world cat-spotting and collecting game with the same core loop — **spot → verify → collect** — rebuilt around three commitments CatchCat broke:

1. **Detection that works, with a graceful fallback.** A multi-stage pipeline (on-device detector → server verification → human review queue) plus a **manual capture mode** so a failed auto-detect never blocks a catch. The first scan in onboarding is *guaranteed* to succeed.
2. **A camera built for cats.** Lens selection (ultrawide/1x/tele), zoom, tap-to-focus/exposure, burst capture, and framing guidance tuned for moving animals at realistic distances.
3. **An honest economy and a clean album.** One soft currency with real sinks, a readable energy system, full collection management (release, favorites, filters), and moderation with a report button from day one.

**Differentiation:** We win on reliability, speed, and trust — not novelty. Every design decision is measured against "does this make the first successful catch happen faster and feel better?"

## 3. Target Users

| Segment | Description | What they need |
|---|---|---|
| **Cat owners (primary)** | Want their own cat immortalized as a card; will scan the same cat daily | Forgiving detection indoors, bad lighting support, custom naming |
| **Cat spotters** | See neighborhood/stray cats on walks; the explorer-collector | Detection at distance, zoom, community map they can trust |
| **Casual collectors** | Drawn by virality; Pokémon GO nostalgia | Fast first success, streaks, low friction, no paywall ambush |
| **Social/competitive players** | Want trading, duels, leaderboards | Friends, fair anti-cheat, card game depth (post-MVP) |

**Out of scope for MVP:** children under 16 (age gate, GDPR-first), hardcore TCG players (2.0).

## 4. User Stories

**Core loop**
- As a player, I can point my camera at a cat and get a detection confirmation within 2 seconds, so I don't lose the moment.
- As a player, if auto-detect fails, I can manually capture and submit for verification, so a finicky model never costs me a catch.
- As a player, my first guided catch always succeeds, so I understand the game before I can fail at it.
- As a player, I can choose my lens and zoom, so I can catch shy cats from a respectful distance.

**Collection**
- As a player, I can rename any cat, so "Count Royal Stinker" can become "Mochi."
- As a player, I can release (delete) cats, favorite them, and filter/search my album, so my collection stays manageable at 500+ cards.
- As a player, my album loads instantly regardless of size, so collecting more never punishes me.

**Community & trust**
- As a player, I can report a fake or non-cat map pin, so the map stays trustworthy.
- As a player, I understand exactly what my coins buy, so the economy feels fair.
- As a player, I can catch a community-map cat only when I'm physically near it, so catches are honest.

**Economy**
- As a free player, I can earn everything gameplay-critical through play; money buys time and cosmetics, never exclusive cats.

## 5. MVP Feature List (v0.1) with Acceptance Criteria

### F1 — On-device + server cat detection with manual fallback
- Detect a cat in frame at up to ~5m in normal indoor lighting, ≥90% recall on our test set of 200 real-world cat photos (day/indoor/low-light split).
- Detection feedback (bounding box or glow indicator) appears in ≤500ms on a mid-range device.
- If no detection after 5 seconds, an explicit "Capture anyway" button appears; manual captures queue for server verification (target verdict ≤60s, async with notification).
- Photos-of-screens / photos-of-photos rejected with ≥95% precision (screen-moiré + metadata + vector-duplicate checks).

### F2 — Camera experience
- Lens selector (ultrawide / 1x / telephoto where hardware allows), pinch zoom, tap-to-focus/exposure lock.
- Sustained 30fps preview on 2021+ mid-range devices; no frame freeze >100ms during capture.
- Framing hint ("move closer", "too dark") driven by detector confidence.

### F3 — Collectible cat cards ("Keepsakes")
- Successful catch generates a card: real photo, generated name (user-editable), rarity (5 tiers, published odds), stats, flavor type.
- Card flip animation; serial number; XP + coins awarded.
- **AC:** rename persists; rarity odds documented in-app; duplicate-scan of the same physical cat (vector match) merges rather than duplicates.

### F4 — Album & collection management
- Grid album with: favorites, filters (rarity, date, type), search by name, multi-select release, batch operations.
- Album of 1,000 cards scrolls at 60fps and opens in <1s (virtualized list, server-side pagination).
- Released cats are soft-deleted (recoverable 7 days).

### F5 — Community map with moderation
- Map of historical sighting pins; proximity check (≤50m) to collect a linked keepsake.
- **Report button on every pin and card**, with reason categories (not a cat / fake / inappropriate / location unsafe).
- Report queue: auto-hide at 3 reports pending review; human moderation SLA <48h.
- Safety notice surfaced on first map open; no background location, "when in use" only.

### F6 — Economy
- **One energy unit (Snack Cans):** 1 per catch, timed recharge, cap. Free tier is genuinely playable (≥10 catches/day).
- **One soft currency (Coins):** earnable from catches/quests; spendable on cans, cosmetics, and card cosmetics — a real, documented sink.
- No interstitial ads in MVP. Rewarded ads optional for bonus cans; ad reward delivery verified client+server (no "watched ad, got nothing").

### F7 — Accounts, friends, onboarding
- Google / Apple / email-code sign-in; account deletion in-app (GDPR).
- Guided first-catch tutorial that cannot fail (assisted detection + fallback).
- Add friends, view friend albums, share a card as image/deep link.

### F8 — Platforms
- Android + iOS at parity from launch (React Native/Expo single codebase).

## 6. Anti-Goals

- **No Web3/NFT/token mechanics.** Ever. (CatchCat flirts with it; we plant a flag against.)
- **No pay-to-win or paid-exclusive cats.** Rarity is earned in the world, not bought.
- **No interstitial/forced ads** in the core scan loop.
- **No live cat tracking.** Pins are historical; we never imply a live animal's location.
- **No facial recognition or human data collection.** Cat photos only; faces auto-blurred before upload.
- **No PvP/TCG in MVP.** Alley-Clash-style mode waits for 2.0.
- **No background location tracking.**
- **No gallery import** in MVP (preserves the "real world" contract; reconsider post-1.0 with strict anti-fake).

## 7. Monetization Plan

| Stream | Detail |
|---|---|
| **Subscription ("Pro", ~$4.99/mo)** | Faster can recharge, higher cap, exclusive cosmetics, advanced album stats. No gameplay-exclusive cats. |
| **IAP** | Can packs, cosmetic packs (hats, glasses, card frames), name-change tokens beyond the free allowance. |
| **Rewarded ads (opt-in only)** | Bonus cans; hard daily cap; verified delivery. |
| **Seasonal passes (1.0+)** | Themed events, limited cosmetics — only after core retention is proven. |

**Principles:** the free game is complete; coins always have a sink; every price is understandable in 5 seconds; no dark patterns (no disguised buttons, no countdown-pressure fake scarcity).

## 8. Roadmap

### v0.1 — MVP (target: 4 months)
Everything in Section 5. Android + iOS. Goal: **prove the core loop is delightful and reliable.** North-star gate: first-session catch success ≥80%.

### v1.0 — Depth & Trust (+3 months)
- Daily quests, streaks, seasonal cat events
- Expeditions/missions (send cats on timed tasks — #2 community request)
- Trading between friends (with anti-dupe safeguards)
- Localization (incl. Ukrainian — top community ask)
- Performance hardening; web PWA share pages for virality
- Moderation dashboard v2 (reputation-weighted reports)

### v2.0 — Competition (+6 months)
- **Cat Deck Duel:** turn-based card combat using your real catches as the deck (the #1 community request, 78 votes)
- Ranked ladders, neighborhood leaderboards
- Optional walking/fitness XP tie-in
- Clan/neighborhood groups

## 9. Success Metrics

| Metric | v0.1 target | Why |
|---|---|---|
| **First-session catch success rate** | ≥80% | CatchCat's biggest churn point |
| **Detection recall (field telemetry)** | ≥90% at ≤5m | The core verb must work |
| **D1 / D7 retention** | 45% / 20% | Concept retention once execution is fixed |
| **Time-to-first-catch** | <3 min | Onboarding quality |
| **Play Store / App Store rating** | ≥4.3 | Execution credibility |
| **Report resolution SLA** | <48h, 95% | Community trust |
| **Album p95 load time @ 500 cards** | <1s | Collection longevity |
| **Free-player catches/day** | ≥10 median | Economy fairness |
| **Crash-free sessions** | ≥99.5% | Table stakes CatchCat missed |

## 10. North Star

### Brand Identity
**"Every cat you meet becomes a friend you keep."**
Wholesome, playful, trustworthy. We are the cat-spotting game that *works* — the one where the technology disappears and the moment stays. Sticker-book warmth in the art; engineering rigor underneath. We are explicitly the anti-Web3, anti-dark-pattern, pro-privacy alternative in a genre the incumbent left broken.

### Principles
1. **The catch is sacred.** Detection reliability and camera quality outrank every other investment. A missed cat is a lost player.
2. **Never punish collecting.** More cats must always mean more joy, never a slower app or a messier album.
3. **Fair by default.** One readable economy; money buys time and style, never power or exclusives.
4. **Trust is a feature.** Moderation, anti-cheat, honest map pins, and transparent data use are shipped as product, not policy PDFs.
5. **Real world, real respect.** Historical pins only, no live tracking, no trespassing encouragement, faces blurred, kids protected.

### What We Will Not Compromise
- **No crypto, NFTs, or tokens** — regardless of market fashion.
- **No forced ads** in the core loop, at any revenue pressure.
- **No paywalled cats or rarity** — the world is not for sale.
- **No background location or human facial data** — even if it would make features easier.
- **No shipping a detection regression** — recall gates every release, like a unit test for the game's soul.
