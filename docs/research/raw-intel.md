# CatchCat — Raw Intel Bundle

Compiled for a competitive teardown / PRD. Sources: Google Play Store, catchcat.lol website, privacy policy, press coverage, and community feedback board.

---

## 1. App Identity & Metadata

- **App name:** CatchCat
- **Package ID:** `xyz.catchcat.app`
- **Developer:** Sebastian Seidel (indie, Germany), published under Google Play account `santech`
- **Website:** https://www.catchcat.lol
- **Support email:** help@catchcat.lol
- **Postal address:** Zum Isetal 1, 38518 Gifhorn, Germany
- **Platforms:** Android (live), iOS ("coming soon"), Web3 ("coming soon")
- **Google Play rating:** 3.0 stars (≈2.55K reviews, 100K+ downloads)
- **Content rating:** Everyone / In-Game Purchases
- **Age gate:** 16+ (per website)
- **Updated:** July 28, 2026
- **Launch timeline:** First went live on Sunday, June 21; removed within 48 hours due to server demand / bugs; returned around Wednesday, June 24. Express.co.uk coverage notes 2,000 users on day one and zero marketing.

---

## 2. Concept & Value Proposition

**Tagline:** "Spot real cats. Build your album."

**Elevator pitch:** A real-world cat spotting and collecting game. Players use their phone camera to find real cats, verify the sighting, and turn it into a collectible cat card with a generated name, rarity, stats, and abilities. The game also has a community map of previous sightings, friends, and an upcoming competitive mode ("Alley Clash"). It is often described in press as "Pokémon GO for cats."

**Core emotional hook:** Turns cat-owners and cat-spotters into collectors; gives every random cat you meet a permanent, shareable identity.

**Genres (Google Play):** Adventure / Game Adventure

---

## 3. Core Features & User Flows

### 3.1 Onboarding
- Install app → create account → open field journal (empty album)
- Google Sign-In, Apple Sign-In, or email code login

### 3.2 The Three-Step Scan Loop
1. **Spot:** Open live camera, frame a real cat. On-device detection spots the cat.
2. **Throw:** Drag a retro snack can, release in the green zone of a cardboard box. Each can gives 3 throw attempts.
3. **Collect:** Verified cat becomes a "keepsake" with generated name, serial number, XP, coins, and rarity.

**Key constraints:**
- Live camera only — no gallery import.
- Initial detection/verification runs on-device; confirmed sightings sync to server for moderation, duplicate detection, and album storage.
- One snack can consumed per successful scan (regardless of throws used).

### 3.3 Keepsake / Album
- Sticker-style cat cards with real photo behind them
- Generated names like "Dame Defiant Donut", "Count Royal Stinker", "Loafus Maximus"
- Whiskered stats: **Snack** and **Charm**
- Type: e.g., **Chonky**
- Keyword abilities: e.g., **Guard**, **Copycat**, **Finale** (Alley Clash prep)
- Rarity tiers: **Alley** → **Garden** → **Moonlit** → **Velvet** → **Golden**
- Flip cards to reveal cat underneath
- Profile cat cosmetics: hats, glasses
- Track: sightings logged, rarest find, daily streaks, XP, levels

### 3.4 Community Map
- Shows cat pins logged by other players worldwide
- Proximity requirement: walk close enough to a pin to preview it in a 3D room
- Land snack in box to add a linked keepsake to your album (proximity checked)
- Safety notice: pins are historical community sightings, not live guarantees
- No background location; location only "when in use"

### 3.5 Alley Clash (Coming Soon)
- Competitive mode in the Fight tab
- Keepsakes double as cat cards with stats and abilities
- Friendly matches, tricks, rankings
- Currently a preview only; mechanics being finalized
- Community feedback board has many Alley Clash ideas (see Section 8)

### 3.6 Social
- Add friends
- Compare albums
- Get notified about rare friend finds
- Share favorite keepsakes as stickers and deep links
- Optional contact-search for friend finding (phone numbers hashed locally)

### 3.7 Notifications
- Push notifications via FCM + OneSignal for friend requests, activity, rare finds, updates

---

## 4. Monetization & Economy

### 4.1 Core Currency: Snack Cans
- Each verified scan consumes 1 can and gives 3 throws
- Cans recharge automatically over time
- **CatchCat Pro:** faster recharge + higher can cap
- Bonus cans via rewarded ads
- Bonus cans via store packs (IAP)

### 4.2 Revenue Streams
- **Ads:** Google AdMob (rewarded ads for cans; interstitial/ads in free version)
- **In-app purchases:**
  - CatchCat Pro subscription (premium perks)
  - Snack can packs
  - Cosmetic packs (hats, glasses)
- **Web3:** Mentioned as "Play on Web3 — coming soon" (likely token/NFT integration but not live)

### 4.3 Economy Observations
- Two soft currencies: XP and coins
- Coins appear to have limited use: store sells only IAP items, so coins lack a sink (user complaint: "I don't understand why there are coins or treats")
- Energy mechanic (cans) is the primary throttle

---

## 5. Tech Stack Inference (with evidence)

### 5.1 Mobile App
- **React Native with Expo** — strongly implied by the developer posting in r/expo and the LinkedIn mention of "Expo Convex Flue Agent Framework"
- **Flue Agent Framework** — possibly used for AI agent / image-processing pipeline

### 5.2 Backend
- **Convex** — real-time database, backend functions, sync, user profiles, social graph, map data
- **Cloudflare R2** — image storage (photos, silhouettes)
- **OpenAI** — moderation and possibly image classification / vector generation
- **Replicate** — image processing / silhouette / background removal
- **Vercel** — website hosting (Next.js; `_next/image` URLs throughout)
- **beehiiv** — newsletter/email
- **Resend** — transactional/support email

### 5.3 Auth, Payments, Analytics
- **Google Sign-In / Apple Sign-In / email code login**
- **RevenueCat** — in-app purchases and subscription management
- **Google AdMob** — ads + UMP consent
- **Firebase Cloud Messaging (FCM)** + **OneSignal** — push notifications
- **PostHog** — anonymized product analytics
- **Sentry** — crash/error tracking (with opt-in consent)
- **Google Play / App Store** — distribution

### 5.4 AI / ML Components (inferred)
- **On-device cat detection:** likely a lightweight model (e.g., MobileNet, YOLO, or Expo-friendly TensorFlow Lite model) for real-time bounding box detection
- **Server-side verification:** duplicate fingerprinting using 512-dimensional vectors, breed metadata, silhouette extraction, screen-photo/fake detection
- **Image processing:** silhouette/background separation via Replicate or OpenAI
- **Generation:** generated names, stats, types, abilities; possibly LLM-based or template-based
- **Rarity assignment:** weighted random roll (e.g., 5 tiers with probabilities)

---

## 6. Privacy, Safety, Compliance

### 6.1 Privacy Policy Highlights
- Controller: Sebastian Seidel, Germany
- GDPR-first approach with detailed processing table
- Data collected: email, display name, profile image, precise location (when-in-use), cat photos, silhouettes, 512-d fingerprint vectors, breed metadata, friend links, device tokens, ad ID, crash logs, etc.
- Third-party processors: Vercel, Convex, Cloudflare R2, OpenAI, Replicate, Google, Apple, RevenueCat, AdMob, FCM, OneSignal, PostHog, Sentry, beehiiv, Resend
- Retention: active data kept while account exists; deletion within ~30 days; backups up to 90 days
- No background location; no TrueDepth API; no intentional facial identification
- Children: not directed under 16
- Account deletion: in-app or via https://catchcat.lol/delete-account

### 6.2 Safety Notices
- Map pins are historical sightings, not live cat guarantees
- Users must only scan from where they are, stay aware of surroundings, avoid private/restricted areas
- Proximity checks for community map keepsakes

---

## 7. Public Signals & Traction

- **2,000+ Android downloads on day one** (Express.co.uk, June 2026)
- **Viral on social media** without paid marketing; covered by Express, ICanHasCheezburger, and multiple Instagram/TikTok accounts
- **Server outage on launch day** — removed from Play Store for ~48 hours to fix bugs; returned June 24
- **Google Play:** 100K+ downloads, 3.0★ from ~2.55K reviews (mixed; idea loved, execution criticized)
- **Developer is solo, building in public** — shares progress on X (@ninetofivedude) and Instagram
- **Community feedback board:** 200 ideas, 596 votes at time of extraction
- **iOS and Web3 are listed but not live** — major platform gap

---

## 8. User Feedback & Complaints

### 8.1 Top Google Play Review Themes
- **AI detection fails:** app does not detect cats that are clearly in frame, even high-quality photos; detection works only at very close range; bad lighting handling
- **Camera UX issues:** forced wide-angle lens, poor zoom, no lens selection, difficulty framing moving cats, camera freezes/sluggishness
- **Snack-throwing minigame is finicky:** hard to land, inconsistent, sometimes locks users out
- **Ads disrupt flow:** rewarded ads for cans can be buggy (e.g., watched ad but no can rewarded)
- **Fake/spam content:** community map appears to have fake/duplicate data, photos not always cats, no report button
- **Duplicate management:** no way to delete/release cats, album becomes unwieldy as it grows, album loading slows down
- **Naming/traits:** random generated names can't be edited; users want custom names and explanations of rarity/charm/type logic
- **Performance:** app freezes on first load, sluggish UI, lag on every click
- **Monetization confusion:** coins and treats seem useless because everything is paid with real money
- **Platform availability:** iOS not available in many regions; US App Store not available

### 8.2 Top-Voted Feedback Board Ideas (as of extraction)
1. **Cat Deck Duel** (+78) — turn-based cat-card combat using real catches as deck
2. **Cat missions and expeditions** (+46) — send cats on timed expeditions for rewards
3. **Report button / filter only cat photos** (+27) — content moderation
4. **Delete/release cat button** (+21) — collection management
5. **Ukrainian language** (+21) — localization
6. **Anti fake-catching system** (+17) — prevent scanning photos of photos
7. **Change cat names** (+16) — personalization
8. **Bowl Blitz** (+16) — 3-cat squad race to fill a food bowl
9. **Random loot boxes of cans/coins** (+15) — economy rewards
10. **Camera improvements / lens selection** (+14) — better camera UX
11. **Trading Cat** (+13) — peer-to-peer trading
12. **Purchasable cans for coins** (+3) — give coins a sink
13. **Favorites category** (+7) — album organization
14. **Album loading optimization** (+6) — performance
15. **Walking/running XP / Garmin integration** (+5) — fitness tie-in

### 8.3 Community Sentiment Summary
- **Love the concept** — universally praised as clever, wholesome, viral-worthy
- **Frustrated by execution** — AI detection, camera, performance, and monetization feel rushed
- **Want more control** — naming, deleting, favorite filters, camera settings
- **Want social/trading** — trading, duels, missions are highly requested
- **Skeptical of fake content** — moderation and anti-cheat are top concerns

---

## 9. Competitive Landscape

### 9.1 Direct Competitors (cat-focused)
- **Cat Scanner (siwalusoftware)** — breed identification, not collection; mature, 4.5M+ installs
- **Cat Breed Identifier / Pet Scan** — breed identification
- **Google Lens / Apple Visual Look Up** — can identify cat breeds but not a game
- **Various cat photo diary apps** — manual albums, not AI/AR collectibles

### 9.2 Adjacent / Inspiration Games
- **Pokémon GO** — location-based AR collecting, real-world exploration, energy/premium economy, PvP (Go Battle League)
- **Pikmin Bloom** — walk-and-collect, daily journaling, AR-lite
- **Jurassic World Alive / Harry Potter: Wizards Unite** — map-based creature collection
- **Trading card games (Pokémon TCG, Hearthstone)** — deck building, stats, keywords, rarity

### 9.3 Market Gap
- No polished, well-executed "real-world cat collection" game
- Cat content is highly viral and has massive organic reach
- The core mechanic (camera + AI + collection) can be cloned and improved quickly with modern AI/ML APIs
- Biggest weakness of current market leader (CatchCat) is execution, not concept

---

## 10. Opportunities & Gaps

1. **AI detection accuracy** — the biggest blocker. A better model or multi-stage verification would immediately win users.
2. **Camera UX** — lens selection, zoom, exposure, manual capture fallback, better framing guidance.
3. **Onboarding & first-scan success** — if the first scan fails, users churn. A tutorial + fallback/manual verification can rescue this.
4. **Collection management** — delete/release, favorites, filters, search, album organization, batch operations.
5. **Monetization clarity** — give coins a real sink, simplify the economy, reduce ad friction.
6. **Moderation & anti-cheat** — screen-photo detection, report button, human-in-the-loop review.
7. **Social depth** — trading, duels, leaderboards, clans, neighborhood leaderboards.
8. **iOS & web** — major platform gap; web PWA could unlock virality.
9. **Gamification beyond collection** — daily quests, streaks, cat missions, walking challenges, seasonal events.
10. **Ethical/privacy moat** — transparent data use, no facial data, clear moderation, community-first safety.

---

## 11. Raw Sources

- Google Play Store: https://play.google.com/store/apps/details?id=xyz.catchcat.app
- Website: https://www.catchcat.lol
- How it works: https://www.catchcat.lol/how-catchcat-works
- Community map: https://www.catchcat.lol/features/community-map
- Cat cards: https://www.catchcat.lol/features/cat-cards
- Alley Clash: https://www.catchcat.lol/alley-clash
- Rarity tiers: https://www.catchcat.lol/guides/rarity-tiers
- Snack cans: https://www.catchcat.lol/guides/snack-cans
- Support: https://www.catchcat.lol/support
- Feedback board: https://www.catchcat.lol/feedback (full cache at `/home/dan/.hermes/cache/web/www.catchcat.lol-282edaba70.md`)
- Privacy policy: https://www.catchcat.lol/legal/privacy
- Press: Express.co.uk (June 24, 2026) — "Pokemon Go for cats" article
- Developer social: @ninetofivedude (X), Instagram posts by Sebastian Seidel
- Reddit: r/expo posts by developer about Expo/CatchCat

---

*Compiled for teardown — not an official product document.*
