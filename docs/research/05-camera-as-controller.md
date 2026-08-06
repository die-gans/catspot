# Camera as a Controller — Research & Requirements for Catspot

**Date:** 2026-08-06  
**Status:** Research complete → feed into Sprint 3 / PRD F2  
**Question:** What makes a mobile camera-first game feel *great*, and how do we turn those findings into concrete Catspot requirements?

---

## TL;DR — The Verdict

A cat is not a QR code: it moves, it sits at 5 m, it hides in low light. In a camera-first game, the camera is the controller, and the best apps treat it like a physical game input: **fast, forgiving, and juicy**. The incumbent proves the opposite: CatchCat’s #1-2 complaints are detection that fails and a camera that fights the user (no zoom, forced wide lens, no manual fallback, finicky snack-throw). The winners — Cat Scanner, Seek, Pokémon GO, Instagram/Snapchat — share a small set of patterns: **minimal UI, big bottom controls, one-handed zoom/focus, real-time guidance, and a non-blocking fallback when AI is unsure**. Catspot’s camera spec should be upgraded from "has lens and zoom" to "detects, guides, captures, celebrates, and never hard-blocks a real cat."

---

## 1. Why This Research Matters for Catspot

The PRD already names the camera as the #1 risk area:

- `docs/PRD.md §2.4`: CatchCat’s camera UX is hostile — forced wide-angle, no zoom, freezes, no manual capture fallback.
- `docs/PRD.md §4.3`: "Respect the camera" — lens selection, zoom, tap-to-focus, low-light hints.
- `docs/PRD.md §6.5 F2`: current camera acceptance criteria are thin (lens selector, zoom, 30fps, framing hints).
- `docs/PRD.md §8`: "A cat is not a QR code." The camera must be treated as a game controller, not a file picker.

This report upgrades F2 into a concrete, research-backed feature set and anti-pattern list.

---

## 2. Research Findings

### 2.1 Capture UX Patterns in Camera-First Games & Apps

| App / Genre | What it does well | What Catspot should copy | Source |
|-------------|-------------------|--------------------------|--------|
| **CatchCat** (competitor) | Three-step loop is easy to explain; snack-can minigame is memorable | *Nothing* about the camera itself; its complaints are the spec | `docs/PRD.md §2.4`, `docs/PRD.md §2.5`, Google Play reviews |
| **Pokémon GO** | Optional AR; ball-throw minigame with shrinking target, Nice/Great/Excellent feedback, no hard block on a failed throw | Optional AR-lite, skill-based but forgiving capture action, clear feedback | Akendi UX blog, Silph Road / GO community discussions |
| **Cat Scanner** | Reliable breed ID; pinch-to-zoom + tap-to-focus; camera or gallery fallback; fast "analyzing" result screen | Camera-first UI with manual controls, fast feedback, fallback paths when no cat | Cat Scanner website & App Store listing |
| **Instagram / Snapchat** | Borderless full-screen preview, big translucent shutter, one-hand slide-to-zoom, minimal chrome | Shutter dominates; secondary controls stay out of the frame | Snapchat UX review (id3123), Instagram "Instants" UX critique |
| **Seek / iNaturalist** | Real-time CV guidance; confidence builds as you get closer; camera button turns green; conservative IDs | Live framing guidance, "get closer" hints, don’t overclaim when unsure | Bay Nature article, iNaturalist Seek page, iNaturalist forum |

#### 2.1.1 CatchCat: the camera is the controller, and it is broken
CatchCat’s Google Play page and reviews are a direct requirements document of what *not* to do. Top complaints visible on the listing include: "The AI doesn’t seem to detect my cats at all"; "cats were not detected when they were clearly in frame"; "I got the cat food lined up, just didn’t detect the cat"; and the PRD’s own competitive analysis cites "forced wide-angle lens, no zoom, no lens selection, freezes, no manual capture fallback" as a critical pain point. Its own support page tells users to "improve lighting" and "try all three throws" — but there is no explicit fallback for a failed detection. The snack-can minigame then punishes the user after a failed scan: each can gives only three attempts and a missed throw can consume the throttled energy. That converts a failed detection into a lost catch. [^1][^2][^3]

#### 2.1.2 Pokémon GO: make the capture action feel fair, not arbitrary
GO’s encounter screen is a camera-first minigame: a shrinking target circle, swipe-to-throw, and visible feedback tiers (Nice/Great/Excellent, Curve Ball). AR is a toggle, not a gate — most players turn it off to save battery and reduce friction. The lesson is not the AR layer; it is the **clear skill expression + visible outcome** that keeps the moment engaging even when the catch is probabilistic. The ball throw never *hard-blocks* the player from a Pokémon; it only changes the odds. [^4][^5]

#### 2.1.3 Cat Scanner: a camera UI that actually works for cats
Cat Scanner is the closest functional analogue to a "cat camera." Its app description explicitly calls out **pinch-to-zoom and tap-to-focus** as first-class features, and its flow is: open camera → frame cat → quick analyzing screen → result. It allows gallery fallback, handles mixed breeds, and even has a humorous fallback when no cat is present (scan yourself). The key takeaway: **reliable cat detection starts with a camera UI that lets the user help the model** — zoom, focus, and a quick confirmation loop. [^6]

#### 2.1.4 Instagram / Snapchat: the shutter is the hero
Both apps maximize the viewfinder and minimize controls. Snapchat offers a borderless view where "you can even see through the camera shutter button." Instagram’s one-hand zoom is triggered by holding the shutter and sliding a thumb. The common pattern: **one big, thumb-reachable primary action; everything else secondary or gesture-based.** This is exactly the posture Catspot should take: the player is holding a phone one-handed while pointing at a cat; the UI must not demand two hands or precise top-of-screen taps. [^7][^8]

#### 2.1.5 Seek / iNaturalist: real-time guidance, not black-box detection
Seek shows a live taxonomy bar that fills as the user gets closer to the subject. When confident, the camera button turns green. Its designers explicitly wanted to avoid the "black box" problem: "The black box gets frustrating when it won’t tell you what you want." The app teaches through use, and it is conservative — it will back up to a broader taxon (e.g., "group: dicot") rather than confidently misidentify. That is the right model for Catspot: **the UI should reveal what the detector sees, not just succeed or fail silently.** [^9][^10]

### 2.2 What "Feels Good" in a Capture Moment

Great camera games compress the moment into an **anticipation → action → reward** loop:

1. **Anticipation:** the detector finds the cat. A bounding box or reticle snaps to the subject and pulses. Audio and haptics build tension as the frame improves (Google’s Pixel Guided Frame uses a musical progression that resolves when the subject is centered). [^11]
2. **Action:** the user presses the shutter. A crisp haptic click (10–20 ms), a screen flash, and a shutter sound confirm the action. [^12][^13]
3. **Reward:** on success, a celebratory haptic pattern, a particle burst, and a smooth transition to the card reveal. The reward must feel proportional to the rarity/stakes.

Google’s Material sound-and-haptics team emphasizes that **the more often an interaction happens, the less intrusive it should be** — but the *important* interactions (capture, first catch, rare catch) should be juicy. Apple’s HIG for game controls says virtual controls should combine visual press states with sound and haptics so the button feels alive even when the thumb is covering it. [^11][^13][^14]

**Juiciness checklist for Catspot:**
- **Lock-on feedback:** reticle/bbox changes color when confidence is stable; a soft haptic tick when the cat is first detected.
- **Shutter feedback:** haptic `click` + white screen flash + subtle shutter sound.
- **Success feedback:** rising haptic pattern, success chime, confetti/particles, card slide/flip.
- **Failure feedback:** no negative buzz; instead a helpful hint ("Move closer") and a fallback path.

### 2.3 Guidance UX — Coach Without Nagging

The best guidance is **binary, progressive, and contextual**.

Will Neville’s Advanced Camera Module case study (Invisalign / MyInvisalign) is the most directly applicable source. They tested live guidance in a clinical photo-capture app and learned:
- **Raw confidence scores fail.** Users ignored numbers. They wanted green = good, red = adjust.
- **Progressive disclosure wins.** Show the primary issue (distance/framing) first, then secondary (symmetry), then tertiary (lighting) only if needed. Presenting all feedback at once caused users to chase multiple moving targets.
- **Specific beats generic.** "Hold steady" (88% fix rate) and "Move closer" outperformed generic "photo unclear" messages.
- **Teach through use, not tutorials.** A 5-screen tutorial had a 31% completion rate; moving explanations into contextual tooltips raised completion to 89%.
- **Do not auto-capture on threshold.** Users felt a loss of control when the shutter fired automatically. They wanted the AI to guide, then let them press the button. [^15]

Google’s Pixel Guided Frame uses a similar idea: the phone emits tones and haptics that build as the subject approaches the center, resolving at the sweet spot. The feedback is continuous, not interruptive. [^11]

**For Catspot:** guidance should be one hint at a time, disappear when the condition is fixed, and never use a pre-camera tutorial. Priority order: distance → steadiness → lighting.

### 2.4 Camera Controls on iOS — What the Stack Allows

Apple’s Camera Control documentation shows the controls users expect: exposure, depth, zoom, camera switching, styles, tone, and AE/AF lock. [^16] The Flutter `camera` plugin exposes the primitives we need: `setZoomLevel`, `setFocusPoint`, `setExposurePoint`, and `setFlashMode(FlashMode.torch)`. A LogRocket deep-dive confirms the plugin supports zoom, exposure, and focus on both iOS and Android. [^17] StackOverflow examples show torch mode via `FlashMode.torch`. [^18]

**Control policy for a game context:**
- **Primary:** big shutter, bottom center, always visible.
- **Secondary:** lens toggle (wide/1x) and torch; bottom corners or floating near the shutter, auto-fade after inactivity.
- **Gestures:** pinch to zoom, tap to focus/expose, long-press to lock AE/AF.
- **Do not** show a full manual-mode toolbar. The camera is a controller, not a DSLR.

### 2.5 Failure & Fallback UX — Never Hard-Block a Catch

The PRD already mandates a **"Capture anyway" manual fallback after 5 seconds** (`docs/PRD.md §6.5 F1`). This is the right instinct and is backed by research:

- **Google PAIR guidebook:** "Provide paths forward from failure." AI is probabilistic; the product should give users a way to continue their task and help the AI improve. [^19]
- **Institute of AI PM:** "Never show a blank screen," "Give uncertainty a face," and "The fallback must offer a next step." Dead ends are the most damaging failure state. [^20]
- **Will Neville case study:** auto-capture on quality threshold failed because users felt a loss of control. The fix was to keep manual shutter control and move AI to a supportive role. [^15]
- **Seek / iNaturalist:** when uncertain, the app backs off to a broader ID or says nothing rather than confidently misidentifying. [^9]
- **Cat Scanner:** when no cat is present, it offers a humorous fallback (scan yourself) rather than blocking the user. [^6]

**Catspot failure-state policy:**
1. **0–2 s:** no lock → gentle pulse/scan animation, no text.
2. **2–5 s:** show the single most relevant guidance hint (distance, steadiness, light).
3. **≥5 s:** show the manual **"Capture anyway"** button. Tapping it submits the frame for server verification.
4. **Server uncertain:** do not reject with a scary error. Show a friendly message: *"We’re not 100% sure that’s a real cat, so we’ll take a closer look. You can keep it as a manual catch while we verify."* This preserves the catch and routes to a review queue.

### 2.6 Kid / Casual / One-Handed Considerations

Catspot’s audience includes casual cat lovers, kids, and Pokémon GO-style location gamers. The UI must be one-handed and low-literacy:

- **Apple HIG for game controls:** frequently used controls should be ≥44×44 pt, less-important controls ≥28×28 pt; place buttons near the thumbs; use symbols that represent actions; combine functions into a single control; show/hide controls dynamically. [^14]
- **One-handed mobile design:** the thumb’s safe zone is the lower two-thirds of the screen. Avoid top-left back buttons and top-right primary actions. Place controls where the thumb naturally rests. [^21]
- **Seek is kid-safe:** no registration, no data collection, fuzzed location. [^10]
- **Instagram/Snapchat:** one-hand zoom via slide, shutter is the largest control, secondary controls are tiny or hidden. [^7][^8]

**Catspot implications:**
- Shutter button at least 72×72 pt (touch target) and visually dominant.
- All capture-time controls in the bottom 40% of the screen or reachable via gestures.
- Icon-only secondary controls with first-use tooltips, not persistent text labels.
- No pre-camera tutorial; teach through animated hints.
- Haptics and sounds provide non-text feedback for kids and low-vision users.

---

## 3. Prioritized "Feels Good" Feature List for Catspot Camera

### P0 — Must ship with the core scan loop (Sprint 3 / MVP)

| # | Feature | Why it matters | Source tie-in |
|---|---------|--------------|---------------|
| 1 | **Manual "Capture anyway" fallback after 5s** | Prevents a failed detection from becoming a lost catch; directly addresses CatchCat’s #1 churn driver | PRD F1, PAIR guide, Neville case study |
| 2 | **Stable detection lock-on feedback** (bbox / reticle, color change when stable) | Lets the user know the camera sees the cat before they press the shutter | Seek, Cat Scanner |
| 3 | **Big, bottom-center shutter button** (≥72×72 pt) | One-handed capture is the baseline for casual/kid users | Apple HIG, Instagram/Snapchat pattern |
| 4 | **Lens selector** (wide/1x, or wide/1x/tele) and **pinch zoom** | CatchCat is punished for forcing a wide lens and offering no zoom | PRD §2.4, Apple Camera Control, Flutter camera plugin |
| 5 | **Tap-to-focus / exposure lock** | Real cats sit at distance, in shade, on windowsills; user needs to help the camera | Cat Scanner, Apple Camera Control, Flutter camera plugin |
| 6 | **30fps preview with no >100ms freeze during capture** | Table stakes; any freeze breaks the moment | PRD F2 |
| 7 | **Shutter feedback triad:** haptic click + screen flash + shutter sound | Confirms the action and makes the camera feel like a physical button | Google Material haptics, Apple HIG |
| 8 | **Single-hint contextual guidance** (distance / hold steady / light) | Coaches the user without nagging; progressive disclosure | Neville case study, Pixel Guided Frame |

### P1 — Should ship before public beta

| # | Feature | Why it matters |
|---|---------|--------------|
| 9 | **Lock-on haptic + sound** when detector is stable for 3+ frames | Builds anticipation and signals the optimal moment |
| 10 | **Torch toggle** + auto-suggest in low light | Indoor/shade cat photos are common; Android haptics principles say haptics must be rich/clear, but the same care applies to lighting |
| 11 | **Best-shot / burst capture** on capture action | Reduces motion blur from live animals |
| 12 | **Success juiciness:** particle burst, rising haptic, card-flip transition | Makes the reward feel proportional to the catch |
| 13 | **Auto-fade secondary controls** after 2s inactivity | Keeps the viewfinder clean and game-like |
| 14 | **First-use contextual tooltips** instead of pre-camera tutorial | Neville: 31% → 89% completion when moving from tutorial to contextual hints |

### P2 — Polish / post-MVP

| # | Feature | Why it matters |
|---|---------|--------------|
| 15 | **Optional AR-lite sticker overlay** once detection is stable | Fun, shareable, but not a core requirement |
| 16 | **Exposure compensation slider** (gesture-based, not a numeric slider) | For advanced users, but hidden by default |
| 17 | **Haptic/sound intensity setting** | Accessibility and player preference |
| 18 | **"Pity" capture:** if a cat is stable for 2s but confidence fluctuates, still allow capture with a server-confidence note | Further reduces false negatives |

---

## 4. Concrete Acceptance Criteria Proposals to Upgrade PRD F2

Replace the current F2 bullets with the following ACs. These are written to be testable on a real iPhone in the field.

### F2.1 — Detection lock-on feedback
- Within 500 ms of the detector seeing a cat in a stable frame, the UI shows a bounding box or reticle.
- If the detector confidence stays above the configured threshold for **3 consecutive frames**, the reticle changes color and emits a short haptic tick.
- The shutter is enabled only after the first frame where a cat is detected (users can still force capture via F2.3).

### F2.2 — Shutter action
- The shutter button is at least 72×72 pt, centered in the bottom safe area.
- On tap: a 10–20 ms haptic click, a white screen flash (≤100 ms), and a shutter sound (respecting mute switch).
- After capture, the preview freezes cleanly and transitions to the capture-review / card-reveal screen within 1 s.

### F2.3 — Manual fallback
- If no cat is detected for **5 seconds**, a "Capture anyway" button appears in the primary thumb zone.
- Tapping it captures the current frame and submits it for server verification.
- The user sees a progress state ("Checking with our cat experts…") and receives an async notification with the verdict within 60 s.
- A manual capture is never rejected with a blocking error; uncertain results are queued for human review and added to the album as a provisional keepsake.

### F2.4 — Lens & zoom
- The UI exposes at most 2 on-screen lens toggles (wide/1x) when the device has multiple lenses; pinch-to-zoom is always available.
- Zoom is continuous between the native magnifications of the selected lenses.
- Zoom does not drop the preview frame rate below 30 fps on a 2021+ mid-range iPhone.

### F2.5 — Focus & exposure
- A single tap on the preview sets focus and exposure to that point and shows a 1s focus animation.
- A long-press locks AE/AF until the user taps elsewhere, captures, or leaves the screen.
- Focus and exposure lock are visually distinct (e.g., yellow "AF/AE Lock" badge).

### F2.6 — Torch
- A torch toggle is available in the bottom-left or bottom-right corner.
- Torch is auto-suggested (gentle icon pulse) when the average luminance of the preview stream is below a calibrated threshold.
- Torch turns off automatically after capture or when the user leaves the scan screen.

### F2.7 — Guidance hints
- Only one hint is visible at a time.
- Priority: distance > steadiness > lighting.
- Each hint appears with a subtle animation and disappears within 2 s after the condition is resolved.
- Hints are text + icon, but text is ≤4 words and can be read at a glance.
- No pre-camera tutorial is required; first-time users see a contextual tooltip the first time each hint appears.

### F2.8 — Control visibility & one-handed posture
- All capture-time controls are reachable in the bottom 40% of the screen or via gestures.
- Secondary controls (lens, torch, zoom) fade to 60% opacity after 2 s of inactivity and restore to 100% on any tap or gesture.
- No more than two lines of instructional text are on screen at any time.

### F2.9 — Success juiciness
- On a confirmed catch: a short rising haptic pattern + success sound + particle/confetti burst around the shutter.
- The transition from capture to card reveal is ≤1 s and includes a smooth flip or slide animation.
- Rarity is revealed with escalating juiciness (common = subtle; rare = stronger haptic + sound + visual flourish).

### F2.10 — Failure UX
- If server verification is uncertain, the app shows a friendly, non-blocking explanation and offers to keep the catch as a manual catch.
- The screen never shows a blank spinner, a raw confidence score, or an "AI error" message.
- The user can always retry immediately from the same screen.

---

## 5. Anti-Patterns to Avoid (With CatchCat Evidence)

| Anti-pattern | Why it hurts | CatchCat evidence |
|--------------|--------------|-------------------|
| **Forced wide-angle lens with no zoom or lens choice** | Cats are often at 3–5 m; the user cannot frame them naturally | PRD §2.4: "forced wide-angle lens, no zoom, no lens selection" [^1] |
| **No manual capture fallback** | A failed detection becomes a hard failure and churns the user | Google Play review: "cats were not detected when they were clearly in frame" [^2] |
| **Punishing minigame after a failed detection** | Energy is wasted on a broken controller, turning frustration into rage | PRD §2.4: snack minigame is over-tuned and "locks users out" [^1] |
| **Auto-capture on model confidence** | Users feel a loss of control; the camera fires at the wrong moment | Neville case study: auto-capture failed in user testing [^15] |
| **Raw confidence scores or technical error messages** | Users ignore or distrust numbers; generic errors kill trust | Neville case study: users ignored numbers; PAIR guide says give uncertainty a face [^15][^19] |
| **Tutorial-before-camera** | Completion rates collapse; users learn by doing | Neville case study: 31% completion for tutorial-first vs. 89% for contextual hints [^15] |
| **Multiple simultaneous guidance hints** | Users chase moving targets; overload erodes confidence | Neville case study: single comprehensive overlay failed [^15] |
| **No haptic or visual shutter feedback** | The camera feels laggy and unresponsive; the action is unclear | Google / Apple haptics guidelines [^11][^13] |

---

## 6. Open Questions for Follow-Up

1. **Hardware coverage:** Do we need a separate Android camera UX research pass, or can we treat iOS as the design target and adapt controls on Android?
2. **Accessibility:** Should we add a VoiceOver label for the live guidance hints and a high-contrast reticle mode?
3. **AR-lite scope:** Is a sticker overlay a P2 nice-to-have or a marketing requirement for shareability?
4. **Sound policy:** Should the capture sound respect the mute switch and offer a silent mode for shy cats?
5. **Haptic intensity:** Should we vary haptics by device capability (e.g., Taptic Engine vs. olderERM motors) or ship one default pattern?

---

## 7. References

[^1]: Catspot PRD, §2.4 and §2.5 — `docs/PRD.md`
[^2]: CatchCat Google Play Store listing and reviews — https://play.google.com/store/apps/details?id=xyz.catchcat.app
[^3]: CatchCat support / how it works — https://www.catchcat.lol/how-catchcat-works and https://www.catchcat.lol/support
[^4]: Akendi UX blog, "Pokémon Go: Fun but Not Augmented Reality" — https://www.akendi.com/blog/pokemon-go-fun-but-not-augmented-reality/
[^5]: r/TheSilphRoad / r/pokemongo community discussions on throw mechanics and feedback
[^6]: Cat Scanner website and App Store listing — https://siwalusoftware.com/cat-scanner/ and https://apps.apple.com/us/app/cat-scanner/id1447491786
[^7]: Snapchat UX review, "P1 – Snapchat Review" — https://id3123.wordpress.com/2016/08/28/p1-snapchat-review-ching-soon-tiac/
[^8]: Instagram UX critique (one-hand shutter zoom) — https://www.instagram.com/reel/DYYp8alIXQu/
[^9]: Bay Nature, "An App to Identify (Almost) Anything (Almost) Anywhere" — https://baynature.org/2019/06/24/science-nature/botany/an-update-to-the-app-to-identify-almost-anything-almost-anywhere/
[^10]: iNaturalist Seek app page — https://www.inaturalist.org/pages/seek_app
[^11]: Google Design, "Sound & Touch: Design Beyond the Screen" — https://design.google/library/ux-sound-haptic-material-design
[^12]: Android Developers, "Haptics design principles" — https://developer.android.com/develop/ui/views/haptics/haptics-principles
[^13]: Apple, "Playing haptics" — https://developer.apple.com/design/human-interface-guidelines/playing-haptics
[^14]: Apple, "Game controls" — https://developer.apple.com/design/human-interface-guidelines/game-controls
[^15]: Will Neville, "Advanced Camera Module — AI capture & quality checks" — https://willcneville.com/case-studies/advanced-camera-module.html
[^16]: Apple Support, "Use the Camera Control on iPhone" — https://support.apple.com/guide/iphone/use-the-camera-control-iph0c397b154/ios
[^17]: LogRocket, "Flutter camera plugin: A deep dive with examples" — https://blog.logrocket.com/flutter-camera-plugin-deep-dive-with-examples/
[^18]: StackOverflow, "How to turn on camera flash in flutter?" — https://stackoverflow.com/questions/58204794/how-to-turn-on-camera-flash-in-flutter
[^19]: Google PAIR, "Errors + Graceful Failure" — https://pair.withgoogle.com/chapter/errors-failing/
[^20]: Institute of AI PM, "Designing for AI Failure: Error States, Fallbacks, and Graceful Degradation" — https://www.institutepm.com/knowledge-hub/designing-for-ai-failure
[^21]: Aaron Cheng, "Mobile UI Design for One-handed Use" — https://medium.com/@aaroncheng/design-for-one-handed-use-a3b28c986a89
