# Catspot MVP Design System v1

**Status:** Contract for Sprint 1 implementation  
**Date:** 2026-07-29  
**Owner:** Design lane (DSN)  
**Implementer:** Mobile lane (Flutter theme + widgets)  
**Branch:** `feat/design-system-v1`

This document is the **single source of truth** for visual tokens used in the Catspot MVP. Token names defined here are implemented verbatim in `apps/mobile/lib/core/theme/tokens.dart` (task S1.4). If a token cannot be built in Flutter during Sprint 1, it is cut here, not deferred.

---

## 1. Design principles

| # | Principle | What it means in UI | Maps to North Star |
|---|---|---|---|
| 1 | **The camera is the controller.** | Camera controls are thumb-reachable, high-contrast, and respond instantly. No decorative chrome obstructs the viewfinder. | "The catch is sacred." |
| 2 | **Paper first, pixels second.** | Warm cream backgrounds, ink typography, and soft shadows mimic a field journal. Cards feel like stickers with a white die-cut border. | Wholesome, playful, trustworthy brand identity. |
| 3 | **One honest primary action.** | Tabby orange is the only saturated accent. Rarity, status, and economy use reserved semantic palettes. | "Fair by default." |
| 4 | **Never color-only.** | Every rarity tier has a unique icon + label. Every state has an icon or text change, not just a hue shift. | "Trust is a feature" + accessibility. |
| 5 | **Respect the player’s time.** | All transitions are ≤200ms except the card flip. Lists are generous, readable, and fast to parse. | "Never punish collecting." |

### Deviations from ORC direction
- None. All ORC direction is preserved. One refinement: rarity frames add a **pattern/texture accent** (dot grid, leaf, star, crown) in addition to the requested icon + label, so the visual ramp is readable at a glance even in grayscale.

---

## 2. Color tokens

All colors are listed as hex. Contrast ratios are verified against WCAG 2.1 AA normal text (≥4.5:1) or large text (≥3:1). Tokens are prefixed `color.` in code.

### 2.1 Brand

| Token | Hex | Usage | Contrast on `surface.base` | Contrast on white |
|---|---|---|---|---|
| `color.brand.primary` | `#E86A33` | Primary buttons, active states, capture ring, CTA icons | 3.04:1 (AA Large) | 3.21:1 (AA Large) |
| `color.brand.primary.hover` | `#D45A26` | Primary button pressed/hover | 3.75:1 (AA Large) | — |
| `color.brand.primary.pressed` | `#B94A1B` | Primary button deep pressed | — | — |
| `color.brand.secondary` | `#F7B267` | Highlights, decorative warm accents, snack-can labels | — | — |
| `color.brand.primary.surface` | `#FFF0E8` | Subtle primary wash behind cards/hero elements | — | — |

**Contrast note:** Primary buttons use white text (`#FFFFFF`) on `color.brand.primary`. 3.21:1 passes AA Large (bold ≥18pt / 14pt bold). For smaller primary button text, increase background to `color.brand.primary.hover` or use `color.ink.primary` text if the background is a light wash.

### 2.2 Surfaces & ink

| Token | Hex | Usage | Contrast |
|---|---|---|---|
| `color.surface.base` | `#FDF8F0` | App background, bottom sheets, empty states | — |
| `color.surface.paper` | `#FFFDF9` | Cards, panels, inputs | — |
| `color.surface.card` | `#FFFFFF` | Elevated card faces, modals, toasts | — |
| `color.surface.overlay` | `rgba(44, 36, 25, 0.48)` | Camera scrim, modal backdrop | — |
| `color.ink.primary` | `#2C2419` | Headings, body text, icon defaults | 14.46:1 on `surface.base` (AAA) |
| `color.ink.secondary` | `#6B5E4F` | Subheadings, metadata, secondary labels | 5.95:1 on `surface.base` (AA) |
| `color.ink.tertiary` | `#75695A` | Placeholders, disabled text, captions | 5.06:1 on `surface.base` (AA) |
| `color.ink.inverse` | `#FFFFFF` | Text on dark/colored backgrounds | — |
| `color.divider` | `#E8E0D5` | Hairlines, separators | — |
| `color.border` | `#D9CFC0` | Input borders, card frames (common tier) | — |

### 2.3 Rarity ramp

Every tier must be paired with its **icon + label**. The color alone is never the only signal.

| Tier | Token (base) | Hex | Badge text (white) | Frame accent | Icon |
|---|---|---|---|---|---|
| Common | `color.rarity.common` | `#666666` | 5.74:1 (AA) | `color.border` | Paw print |
| Uncommon | `color.rarity.uncommon` | `#216944` | 6.63:1 (AAA) | `#3D9A69` | Leaf |
| Rare | `color.rarity.rare` | `#2060B0` | 6.25:1 (AA) | `#4A90E2` | Star |
| Epic | `color.rarity.epic` | `#7A3FBF` | 6.38:1 (AA) | `#A66BE0` | Crown |
| Legendary | `color.rarity.legendary` | `#8A6A00` | 5.07:1 (AA) | `#E8C44D` | Sunburst |

**Light accents** (`rarity.*.light`) are for decorative strokes, glitter textures, and shimmer overlays only; they are not used as text backgrounds. Legendary uses a dark gold base so white text passes AA while the gold sunburst icon still reads as legendary.

### 2.4 Semantic

| Token | Hex | Usage | White text contrast |
|---|---|---|---|
| `color.semantic.success` | `#2E8B57` | Confirmed scans, positive toasts, gained rewards | 4.25:1 (AA Large) |
| `color.semantic.warning` | `#9A6000` | Low energy, retry hints, soft blockers | 5.19:1 (AA) |
| `color.semantic.error` | `#C93E3E` | Failed scans, destructive actions, validation errors | 4.95:1 (AA) |
| `color.semantic.info` | `#2060B0` | Help tips, map pins, neutral alerts | 6.25:1 (AA) |

**Contrast note:** `success` at 4.25:1 only passes AA Large. Use white text on success badges only at ≥14pt bold; for smaller success text, use `color.ink.primary` on `color.semantic.success` surface at 20% opacity.

### 2.5 Dark-mode-ready structure

All tokens use **surface/ink** naming rather than `light`/`dark`. When dark mode is added later, `color.surface.base` becomes a dark value, `color.ink.primary` becomes light, and the brand/rarity/semantic tokens stay unchanged (or gain a dark-mode variant). No token renames are required.

---

## 3. Type scale

Three font families from Google Fonts:

- **Display / Headers:** `Quicksand` — rounded, friendly, sticker-book feel.
- **UI / Body:** `Inter` — legible, neutral, dense information.
- **Mono / Serials:** `Roboto Mono` — fixed-width for serial numbers and stats.

| Token | Font | Size | Weight | Line-height | Letter-spacing | Usage |
|---|---|---|---|---|---|---|
| `type.display.large` | Quicksand | 32px | 700 | 40px | -0.5px | Hero cat name on reveal, album header |
| `type.display.medium` | Quicksand | 28px | 700 | 36px | -0.5px | Sheet title, empty-state headline |
| `type.title` | Quicksand | 24px | 700 | 32px | -0.3px | Screen titles, section headers |
| `type.subtitle` | Quicksand | 20px | 600 | 28px | -0.2px | Card cat name, modal headings |
| `type.body` | Inter | 16px | 400 | 24px | 0px | Default body text, descriptions |
| `type.body.strong` | Inter | 16px | 600 | 24px | 0px | Emphasized body, button labels |
| `type.label` | Inter | 14px | 600 | 20px | 0px | Buttons, chips, badges, tab labels |
| `type.caption` | Inter | 12px | 400 | 16px | 0.2px | Metadata, timestamps, helper text |
| `type.mono` | Roboto Mono | 14px | 500 | 20px | 0px | Serial numbers, stat values |

**Dynamic type:** MVP does not implement dynamic type scaling. All sizes are fixed for Sprint 1. Mark `type.display.large` and `type.title` for large-text accessibility (≥18pt or 14pt bold) so they pass AA Large on primary surfaces.

---

## 4. Spacing, radius, and elevation

### 4.1 Spacing (4pt grid)

| Token | Value | Usage |
|---|---|---|
| `space.0` | 0px | — |
| `space.1` | 4px | Tight icon padding, internal badge gaps |
| `space.2` | 8px | Inline icon+text gap, chip padding |
| `space.3` | 12px | Card internal padding, section gaps |
| `space.4` | 16px | Standard screen padding, button internal padding |
| `space.5` | 20px | Card edge padding, sheet header |
| `space.6` | 24px | Section breaks, bottom sheet inset |
| `space.8` | 32px | Large section gaps, empty-state illustration margin |
| `space.10` | 40px | Hero element margins |
| `space.12` | 48px | Full-screen empty state padding |
| `space.16` | 64px | Extra large illustration spacing |

### 4.2 Radius

| Token | Value | Usage |
|---|---|---|
| `radius.none` | 0px | Full-bleed camera preview, sharp dividers |
| `radius.sm` | 8px | Small buttons, filter chips, input fields |
| `radius.md` | 12px | Badges, snack cans, economy HUD |
| `radius.lg` | 16px | Cards, bottom sheets, toasts |
| `radius.xl` | 20px | Hero cards, large modals, capture button |
| `radius.full` | 9999px | Circular buttons, avatars, capture shutter |

### 4.3 Elevation / shadows

Shadows use `rgba(44, 36, 25, x)` (ink hue) for consistency.

| Token | Value | Usage |
|---|---|---|
| `shadow.0` | none | Flat lists, dividers |
| `shadow.1` | `0 1px 3px rgba(44,36,25,0.08), 0 1px 2px rgba(44,36,25,0.04)` | Filter chips, small badges |
| `shadow.2` | `0 4px 12px rgba(44,36,25,0.10), 0 2px 4px rgba(44,36,25,0.06)` | Keepsake cards (rest), buttons |
| `shadow.3` | `0 12px 24px rgba(44,36,25,0.12), 0 4px 8px rgba(44,36,25,0.08)` | Bottom sheets, floating capture button, picked-up card |
| `shadow.4` | `0 24px 48px rgba(44,36,25,0.16), 0 8px 16px rgba(44,36,25,0.10)` | Full-screen modal, legendary reveal |

---

## 5. Component inventory

### 5.1 KeepsakeCard

**Front state (`KeepsakeCard.front`)**
- White die-cut border: `color.surface.card` with inner `radius.lg` and outer `radius.xl`.
- Cat photo: aspect 4:5, `radius.lg`, top-aligned, with `color.surface.base` placeholder while loading.
- Name: `type.subtitle` in `color.ink.primary`, centered below photo, max 2 lines.
- Rarity badge: top-left, `type.label` + icon, filled with `color.rarity.*` base.
- Type tag: bottom-left (e.g., “Chonky”), `type.caption`, `color.ink.inverse` on `color.ink.primary` pill.
- Serial: bottom-right, `type.mono`, `color.ink.tertiary`.
- Frame: 2px stroke in `color.rarity.*` base; legendary/epic add a subtle inner light accent (`rarity.*.light`) as a 1px inset line.
- Rest shadow: `shadow.2`.
- Pressed state: `shadow.3`, scale 0.98.

**Back state (`KeepsakeCard.back`)**
- Same card shape and frame.
- Header: cat name + rarity badge.
- Stats block: two columns (Snack / Charm) with `type.mono` numbers and `type.caption` labels.
- Abilities list: icon + name + `type.caption` description; divider between items.
- Map pin hint: “Spotted near …” with `type.caption`, `color.ink.tertiary`.
- Flip handle: small grip bar at bottom center, `color.ink.tertiary`, `radius.full`.

**Serial placement rule**
- Format: `CS-XXXX-XX` where `X` is uppercase alphanumeric.
- Position: bottom-right, `space.3` from edges.
- Font: `type.mono`, `color.ink.tertiary`.
- Never overlaps the cat photo; it sits on the bottom gutter below the image.

### 5.2 Buttons

**Primary button (`Button.primary`)**
- Background: `color.brand.primary`; text: `color.ink.inverse`, `type.label`.
- Padding: `space.4` horizontal, `space.3` vertical.
- Radius: `radius.sm`.
- Shadow: `shadow.1` at rest, `shadow.2` on hover/pressed.
- States: default → hover (`color.brand.primary.hover`) → pressed (`color.brand.primary.pressed`) → loading (spinner replaces icon/text) → disabled (`color.ink.tertiary` at 38% opacity, no shadow).
- Minimum width: 88px; touch target 44px.

**Ghost button (`Button.ghost`)**
- Background: transparent; text: `color.brand.primary`; border: 1px `color.brand.primary`.
- Pressed: `color.brand.primary.surface` fill.
- Disabled: `color.ink.tertiary` text and border.

**Destructive button (`Button.destructive`)**
- Background: `color.semantic.error`; text: `color.ink.inverse`.
- Used only for delete/release actions; requires a confirmation sheet.

**Icon button (`Button.icon`)**
- Circular, 44px × 44px touch target, `radius.full`.
- Background: `color.surface.card` with `shadow.2`; pressed `shadow.3`.
- Used in camera overlay, sheet headers, economy HUD.

### 5.3 Filter chip (`FilterChip`)
- Height 36px, `radius.sm`, `shadow.1`.
- Inactive: `color.surface.card`, `color.ink.secondary` text, 1px `color.border`.
- Active: `color.brand.primary.surface` fill, `color.brand.primary` text, 1px `color.brand.primary`.
- Touch target: 44px vertically (expand hit area beyond visual height).
- Trailing close icon when removable.

### 5.4 Rarity badge (`RarityBadge`)
- Height 28px, `radius.sm`.
- Filled background with `color.rarity.*` base; white icon + label.
- Icon size 16px; label `type.label`.
- Always includes the tier name (“Common”, “Uncommon”, etc.) and icon; never color-only.
- Legendary badge adds a subtle shimmer overlay (decorative, not required for accessibility).

### 5.5 Economy HUD (`EconomyHud`)
- Fixed bar or inline cluster showing snack cans + coins.
- Snack can: 32px icon, count in `type.label`, `color.ink.primary`. Empty/low state turns `color.semantic.warning`.
- Coins: 24px icon, count in `type.label`, `color.brand.secondary` (amber) icon with `color.ink.primary` number.
- Add-buttons (+) use `Button.icon` at 40px, tap to bottom sheet for store/ads.
- Progress: recharge timer shown as a thin bar under cans, `color.ink.tertiary`.

### 5.6 Camera overlay

**Focus ring (`CameraFocusRing`)**
- 80px × 80px rounded square, 2px stroke `color.brand.primary`, `radius.md`.
- Animated pulse when cat is detected; collapses to a solid ring when locked.
- Corner accents: 4 corner ticks, 12px long, same color.

**Framing hint (`CameraFramingHint`)**
- Text label at top of safe area, `type.caption`, `color.ink.inverse` on `color.surface.overlay` pill.
- Messages: “Frame one cat”, “Hold steady”, “Too far”, “Too dark”, “Tap to focus”.
- Icon leading each message.

**Capture button (`CaptureButton`)**
- 72px circular shutter, `radius.full`, `color.surface.card` with `shadow.3`.
- Inner ring: 56px, `color.brand.primary`, stroke 3px; fill animates to solid when ready.
- Disabled state: inner ring `color.ink.tertiary`, no shadow.
- Long-press not required in MVP; tap to capture or throw.

### 5.7 Bottom sheet (`BottomSheet`)
- Background: `color.surface.card`.
- Top radius: `radius.lg` (20px); bottom radius: `radius.none`.
- Handle: 36px × 4px, `color.ink.tertiary`, `radius.full`, centered at top.
- Header: `type.title` + optional close icon button.
- Content padding: `space.5` horizontal, `space.4` vertical.
- Backdrop: `color.surface.overlay`.
- Entry motion: `motion.slide.up` 200ms; exit: `motion.slide.down` 150ms.

### 5.8 Empty state (`EmptyState`)
- Illustration: 120px placeholder/vector, `color.ink.tertiary` at 20%.
- Headline: `type.display.medium`, `color.ink.primary`.
- Body: `type.body`, `color.ink.secondary`.
- CTA: `Button.primary` or `Button.ghost`.
- Vertically and horizontally centered with `space.12` padding.

### 5.9 Toast (`Toast`)
- Background: `color.ink.primary`; text: `color.ink.inverse`.
- Radius: `radius.lg`.
- Padding: `space.4` horizontal, `space.3` vertical.
- Max width: 320px, centered horizontally, 16px from bottom safe area.
- Leading icon for semantic intent (success, warning, error, info).
- Motion: `motion.fade` + `motion.slide.up` 150ms; auto-dismiss 3s.

---

## 6. Motion tokens

All motion tokens are prefixed `motion.`. Durations are in milliseconds.

| Token | Duration | Curve (Flutter name) | Usage |
|---|---|---|---|
| `motion.flip` | 400ms | `easeInOut` (slow-in, slow-out) | Hero card flip front ↔ back. **This is the only >200ms transition.** |
| `motion.snap` | 100ms | `easeOut` | Button taps, chip toggles, focus ring lock |
| `motion.fade` | 150ms | `easeInOut` | Toast, backdrop, placeholder swaps |
| `motion.slide.up` | 200ms | `easeOut` | Bottom sheet enter, economy HUD reveal |
| `motion.slide.down` | 150ms | `easeIn` | Bottom sheet exit, toast dismiss |
| `motion.bounce` | 200ms | `easeOut` with slight overshoot | Rarity badge pop, reward reveal, capture button ready pulse |
| `motion.ease` | 200ms | `easeInOut` | Default for all other transitions (opacity, position, color) |

**Curves mapping (Flutter Material):**
- `easeInOut` → `Curves.easeInOut`
- `easeOut` → `Curves.easeOut`
- `easeIn` → `Curves.easeIn`
- Overshoot curve for `motion.bounce` → `Curves.easeOutBack` (only when scale is safe; no layout shifts).

---

## 7. Accessibility rules

1. **Touch targets:** every interactive element is at least **44×44 logical pixels** (Material `kMinInteractiveDimension`). Chips and icon buttons may look smaller but expand their `Material` hit area.
2. **Contrast:** all text/background pairs listed above meet WCAG 2.1 AA. Decorative shimmer and light rarity accents do not carry information.
3. **Rarity is never color-only:** each tier badge shows its icon + full label. Card frames vary by stroke color **and** texture accent. In album list view, tier is also expressed by the badge text.
4. **Focus and action states:** every button has a visible pressed state (color + shadow change). Loading and disabled states are communicated by icon change and opacity, not color alone.
5. **Motion respect:** the card flip is the only long animation. All other motion is ≤200ms. No auto-playing motion that cannot be paused (shimmer is decorative and brief).
6. **Camera hints:** all camera guidance uses text + icon; never color alone. Low-light warnings use the warning icon and a text message.
7. **Screen reader labels:** component specs above imply labels for buttons and badges. Implementer adds `Semantics` wrappers in Flutter for icon buttons, capture button, and rarity badges.

---

## 8. Flutter mapping

This section names the ThemeData and ThemeExtension classes that consume the tokens above. No Dart code is included here; that is the mobile lane’s implementation.

### 8.1 ThemeData integration
- `ThemeData` is created with `colorScheme` built from the semantic color tokens (`color.brand.primary`, `color.surface.*`, `color.semantic.*`).
- `textTheme` is overridden using `GoogleFonts.quicksandTextTheme()` for display/title and `GoogleFonts.interTextTheme()` for body/caption, then mapped to the named tokens above.
- `elevatedButtonTheme`, `outlinedButtonTheme`, `textButtonTheme` are configured to match `Button.primary`, `Button.ghost`, and `Button.destructive`.

### 8.2 ThemeExtension classes
All custom tokens live in ThemeExtension classes under `apps/mobile/lib/core/theme/`:

- `CatspotColors` — holds every `color.*` token.
- `CatspotType` — holds every `type.*` TextStyle token.
- `CatspotSpacing` — holds every `space.*` double.
- `CatspotRadius` — holds every `radius.*` double.
- `CatspotShadows` — holds every `shadow.*` BoxShadow list.
- `CatspotMotion` — holds every `motion.*` duration and curve.
- `CatspotTokens` — convenience aggregate that exposes all extensions via `Theme.of(context).extension<CatspotTokens>()` or a helper `CatspotTheme.of(context)`.

### 8.3 Widget token consumption
- `apps/mobile/lib/core/widgets/keepsake_card.dart` consumes `CatspotColors`, `CatspotRadius`, `CatspotShadows`, `CatspotType`, and `CatspotMotion` for the flip.
- `apps/mobile/lib/core/widgets/buttons.dart`, `filter_chip.dart`, `rarity_badge.dart`, `economy_hud.dart`, `camera_overlay.dart`, `bottom_sheet.dart`, `empty_state.dart`, and `toast.dart` consume the corresponding token classes.

### 8.4 Implementation note for Sprint 1
- Do not implement dark mode variants in Sprint 1. Structure the tokens with surface/ink naming so dark mode is an additive change later.
- Google Fonts packages to add: `google_fonts` (Quicksand, Inter, Roboto Mono).
- Add a `tokens.dart` barrel file that exports constants for every token, matching the names in this document exactly.

---

## 9. Change log

| Version | Date | Notes |
|---|---|---|
| v1.0 | 2026-07-29 | Initial contract for Sprint 1. |

---

*End of document. Any visual change in Sprint 1 must update this spec first.*
