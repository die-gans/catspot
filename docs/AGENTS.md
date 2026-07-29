# AGENTS.md — How to Work on Catspot

This document is for AI agents (and future humans) who pick up this project. Read it before writing code, modifying docs, or changing scope.

---

## 1. Project Identity

- **Name:** Catspot (working title)
- **Concept:** Real-world cat spotting → collectible keepsake cards → album → social sharing → (later) card battles.
- **Differentiation:** CatchCat proved the idea but shipped a broken experience. We win on **execution**: detection that works, camera that respects the user, honest economy, clean collection management, and iOS+Android parity.
- **Non-negotiables:** No Web3/NFTs, no pay-to-win, no forced ads, no live animal tracking, no facial data collection, no background location.

---

## 2. Repository Structure

```
catspot/
├── README.md                   # One-pager for the repo
├── docs/
│   ├── PRD.md                  # Source of truth for product and technical direction
│   ├── ROADMAP.md              # Phased build plan and decision gates
│   ├── PROJECT_TRACKER.md      # Live status of work
│   ├── AGENTS.md               # This file
│   ├── planning/               # Sprint-level implementation plans
│   │   ├── 01-mvp-stack-and-scaffold.md
│   │   ├── 02-mvp-implementation-orchestration.md
│   │   ├── 03-detection-spike-plan.md
│   │   └── 04-hermes-profiles.md
│   └── research/               # Raw intel, competitive teardown, blueprints
│       ├── raw-intel.md
│       ├── 01-product-teardown.md
│       ├── 02-technical-blueprint.md
│       ├── 03-prd-north-star.md
│       └── CatchCat-Competitive-Analysis-PRD.md
├── apps/
│   └── mobile/                 # Flutter client (iOS, Android, web smoke target)
├── packages/
│   ├── backend/                # Convex backend functions and schema (TypeScript)
│   └── shared/                 # Dart package + JSON-schema contract types
├── scripts/                    # Automation, seeding, one-off scripts, eval harnesses
├── .cursorrules / .claude.md   # Coding style rules (future)
└── .gitignore
```

---

## 3. Source of Truth Hierarchy

When in doubt, consult in this order:

1. **`docs/PRD.md`** — product requirements and North Star.
2. **`docs/ROADMAP.md`** — current phase and milestone gates.
3. **`docs/PROJECT_TRACKER.md`** — what is actually done/in-progress/blocked.
4. **`docs/AGENTS.md`** — conventions and guardrails.
5. **`docs/research/`** — background intel, not action instructions.

---

## 4. Tech Stack (Planned — See PRD Section 5)

| Layer | Choice |
|---|---|
| Mobile app | Flutter stable (Dart 3) — iOS + Android + web smoke target |
| State management | Riverpod (UI state); Convex client (server state) |
| Navigation | `go_router` |
| Camera | `camera` plugin (native); web = manual capture only |
| On-device ML | `google_mlkit_object_detection` (MVP) → custom TFLite via `tflite_flutter` (Phase 2) |
| Backend | Convex (real-time sync, TypeScript functions) |
| Image storage | Cloudflare R2 + CDN |
| Image processing | Replicate (silhouette/cutout) + Cloudflare Workers (thumbnails) |
| Server vision | OpenAI `gpt-4o-mini` / GPT-4.1-mini vision |
| Embeddings | OpenCLIP / MobileCLIP pet-fine-tuned (512-d) |
| Auth | Clerk (`clerk_flutter` beta) + Convex JWT |
| IAP/ads | `purchases_flutter` (RevenueCat) + `google_mobile_ads` |
| Push | `firebase_messaging` + `flutter_local_notifications` (Phase 3+) |
| Analytics | PostHog + Sentry (`posthog_flutter`, `sentry_flutter`) |
| Maps | `google_maps_flutter` / `flutter_map` (Phase 6+) |
| Web landing | Flutter web smoke target; separate landing page deferred |
| CI/Builds | GitHub Actions + Codemagic + Fastlane fallback |

**Do not swap the stack without updating the PRD and explaining the trade-off.**

---

## 5. Coding Conventions (To Be Filled as Code Lands)

- Client: Dart with strict analysis (`analysis_options.yaml`). Backend: TypeScript with `strict`.
- Convex functions live in `packages/backend/convex/` and are the only source of truth for auth, economy, rarity, and verification.
- Flutter client is never authoritative for detection, rewards, or rarity rolls.
- All currency/item grants go through an append-only `economyLedger` with idempotency keys.
- Privacy-first: no background location, no facial data, coarsen public map coordinates, strip EXIF before upload.
- Cross-language contracts (VisionVerdict, rarity tiers, scan status) are authored as JSON Schema in `packages/shared/schema/`, then generated into TS and Dart via `scripts/gen_shared_types.sh`.

---

## 6. Common Pitfalls

- **Never let the client decide if a cat is valid.** The camera/detection is for user feedback and guidance. Server verification (vision-LLM + embeddings) is the authority.
- **Never grant rewards from the client.** Ads, IAP, scans, and quests all result in server-side ledger entries.
- **Do not leak exact coordinates.** Public map pins use geohash-6 + jitter; exact GPS stays in private `scans` rows.
- **Do not store images as database blobs.** Store URLs to R2; keep rows small and paginated.
- **Do not promise Web3 or NFTs.** The project charter explicitly rejects this.
- **Do not skip the technical spike.** The first 4 weeks must prove the scan pipeline works on real cats before full MVP scope is greenlit.

---

## 7. How to Update This Repo

1. **Before coding:** Read `PROJECT_TRACKER.md` and confirm the task is in the current phase.
2. **While coding:** Keep changes focused on one milestone. Update the tracker if scope changes.
3. **After coding:** Update `PROJECT_TRACKER.md` with what was done, what’s next, and any blockers.
4. **For docs/PRD changes:** Propose in a PR or section comment; the PRD is the source of truth and should not be silently overwritten.

---

## 8. Setup Commands (Placeholder — Will Be Updated After Spike)

```bash
# Clone
git clone https://github.com/die-gans/catspot.git
cd catspot

# Flutter client (future)
cd apps/mobile
flutter pub get
flutter run -d <device>

# Backend (future)
cd packages/backend
pnpm install
npx convex dev
```

---

*If something is unclear, update this file so the next agent doesn’t hit the same wall.*
