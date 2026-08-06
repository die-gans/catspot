# Design Sprint 01 — AI UI Generation Brief (Stitch / similar)

Status: DRAFT for Dan's review → feeds GitHub issue #26 (design system & branding).
Purpose: a copy-paste-ready prompt pack for Google Stitch (or Galileo/Uizard/etc.) to generate Catspot's core screens in a coherent visual language.

---

## 1. Brand core (from PRD §7 North Star)

- **Promise:** *"Every cat you meet becomes a friend you keep."*
- **Personality:** wholesome, playful, trustworthy. Sticker-book warmth on the surface, engineering rigor underneath. Explicitly the anti-Web3, anti-dark-pattern alternative.
- **Feel:** a physical sticker album / field journal you carry on a walk. Warm paper, rounded corners, chunky friendly type, cats as die-cut stickers. Pokémon GO's sense of adventure × a stationery shop's charm.
- **Never:** crypto-bro gradients, glassmorphism-over-neon, dark-pattern urgency, sterile fintech minimalism.

## 2. Visual direction seed (v0 — to be validated by the design sprint)

- **Palette:** warm cream paper `#FFF6EC` background · burnt-orange primary `#E86A33` · deep warm charcoal ink `#2E2A26` · soft sage accent `#7FA88B` · golden rarity accent `#E9B44C`
- **Type:** Quicksand (wordmark + headings, rounded geometric), Nunito or similar rounded sans for body
- **Shape language:** big corner radii (16–24px), thick 2px ink outlines on cards/stickers (sticker die-cut look), soft paper-grain shadows, no hard 1px grey lines
- **Illustration/motion cues:** sticker peel, paper flip, paw prints, gentle spring bounces — reward moments should feel like a sticker landing in an album
- **Rarity tiers (5):** Alley (grey) → Garden (green) → Moonlit (indigo) → Velvet (purple) → Golden (gold) — expressed as card frame color + foil shimmer, never paywalled

## 3. Master style preamble (prepend to EVERY screen prompt)

> Design a mobile app screen for "Catspot", a wholesome real-world cat-spotting collection game (like Pokémon GO but for real cats). Visual style: a warm physical sticker album — cream paper background (#FFF6EC), burnt-orange primary color (#E86A33), deep warm charcoal text (#2E2A26), soft sage green accents (#7FA88B). Rounded chunky UI: 20px corner radii, 2px dark outlines giving cards a die-cut sticker look, soft paper shadows. Typography: rounded geometric sans-serif (Quicksand-style), playful but highly legible. Friendly, cozy, kid-safe, zero dark patterns. iOS, iPhone 15 Pro frame, light mode.

## 4. Screen prompts (the screens we actually have today)

### S1 — Sign-in
> [preamble] Screen: welcome/sign-in. Center: the "Catspot" wordmark with a small paw print dotting the 'i' or nestled in the 'o'. Below: a charming illustration of a cat peeking over the bottom edge like a sticker. Three stacked buttons with sticker styling: "Continue with Apple" (black), "Continue with Google" (white with outline), "Continue with Email" (burnt orange). Small print at bottom: privacy note — "We never track you in the background. 🐾". Warm, inviting, zero clutter.

### S2 — Camera / Scan (the core screen — "camera as controller")
> [preamble] Screen: live camera view filling the full frame (show a photo of a real tabby cat sitting in a sunny garden as the viewfinder content). Overlaid UI: a chunky rounded reticle bracket that has snapped around the cat with a springy "locked on" state in sage green, with a small floating label "Cat spotted! 🐾". Bottom center: a large circular shutter/catch button styled like a sticker (burnt orange with 2px ink outline). Top: minimal — close button left, torch toggle right. A small hint pill near the bottom reading "Hold steady…" in friendly type. One-handed reachable, big touch targets, game-like not utility-like.

### S3 — Catch result (the reward moment)
> [preamble] Screen: catch celebration. A cat sticker (die-cut white border, transparent-bg photo cutout of a tabby cat) has just landed on a collectible card at center screen, tilted playfully 3°. The card is cream with a Garden-green rarity frame and a foil shimmer. On the card: generated name "Sir Whiskerton" in big rounded type, serial number "CAT-0042", rarity label "Garden", small stat chips (Snack 🐟 7 · Charm ✨ 4). Around it: a few celebratory paw-print confetti accents, tasteful not noisy. Below: two sticker buttons — "Add to Album" (orange, primary) and "Keep Spotting" (outline). Joyful, collectible, screenshot-worthy.

### S4 — Collection / Album grid
> [preamble] Screen: "My Cats" album. A scrolling grid (2 columns) of cat cards shown as stickers on a warm paper page — each card: die-cut cat photo, name, tiny rarity-colored frame. Top: a chunky search bar and a filter chip row (All · Favorites ⭐ · Garden · Golden). One card in the grid shows a "Naming your cat…" shimmering placeholder state. Bottom nav: two big friendly tabs — Camera (center, orange, primary) and Album. Feels like flipping a sticker book, not browsing a database.

### S5 — Card detail (flip)
> [preamble] Screen: a single cat card large at center, shown mid-flip revealing the back: the original full photo of the cat in the wild with rounded frame, plus details — date caught, location coarsely described ("near your walk in Fitzroy"), stats (Snack/Charm bars), flavor type badge ("Chonky"), and ability text in a friendly italic. Front of card visible as a ghost edge behind. Actions row at bottom: Rename, Favorite ⭐, Release (soft, never scary red — gentle outline button). Sticker-book warmth.

## 5. What we explicitly want Stitch to explore (open questions for the design sprint)

1. Wordmark/logo direction — paw-in-letter vs standalone paw mark vs no mark
2. Card frame language — how rarity reads at a glance without looking pay-to-win
3. Reticle/lock-on visual language for the camera screen (this is our "Pokéball" — needs to be *ours*)
4. Dark mode — is the paper metaphor warm-dark (kraft paper / candlelight) or do we stay light-only for MVP?
5. Icon set — chunky outline icons vs filled sticker-style icons

## 6. Process

1. Dan reviews/edits this brief (especially §2 palette seed and §5 open questions)
2. Generate S1–S5 in Stitch with the preamble
3. Pick 1 direction → refine → export tokens to DESIGN.md (design-md skill exists for the token spec)
4. DSN worker card: implement tokens + restyle screens in Flutter
5. Close issue #26 when DESIGN.md lands in the repo
