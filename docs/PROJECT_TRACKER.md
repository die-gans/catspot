# PROJECT_TRACKER.md — Catspot

Live project status. Update this file whenever work is completed, blocked, or scope changes.

---

## Project Metadata

- **Name:** Catspot (working title)
- **Repo:** https://github.com/die-gans/catspot ✅
- **Live URL:** None yet
- **Start Date:** 2026-07-29
- **Current Phase:** Phase 0 — Repo setup & planning ✅
- **Next Decision Gate:** Prove scan pipeline technical feasibility in a 4-week spike

---

## Architecture Summary

- **Mobile:** Flutter + Dart (`camera` + `google_mlkit_object_detection` on-device, with `tflite_flutter` as Phase 2 custom model option)
- **ML/AI:** On-device MLKit detection → custom TFLite model → server vision-LLM verification → 512-d embedding duplicate detection → Replicate silhouette cutout
- **Backend:** Convex (real-time sync, social/map, economy ledger)
- **Storage:** Cloudflare R2 for originals, cards, cutouts, thumbnails
- **Auth:** Clerk (Google/Apple/email-code) via `clerk_flutter` (beta — validated in Sprint 1)
- **Monetization:** RevenueCat (`purchases_flutter`) subscriptions + IAP, `google_mobile_ads` rewarded ads, honest coin economy
- **Analytics:** PostHog + Sentry (opt-in)
- **Builds/CI:** GitHub Actions + Codemagic (iOS/Android) + Fastlane fallback

See `docs/PRD.md` for full technical blueprint.

---

## ✅ Done

- [x] Competitive teardown of CatchCat (Google Play, website, privacy policy, press, feedback board)
- [x] Raw intel bundle compiled
- [x] Product teardown + competitive analysis
- [x] Technical architecture + build blueprint
- [x] PRD + North Star document
- [x] Consolidated PRD written
- [x] GitHub repo created and pushed: https://github.com/die-gans/catspot
- [x] K3 swarm planning outputs:
  - [x] MVP tech stack + repo scaffold plan (`docs/planning/01-mvp-stack-and-scaffold.md`) — updated for Flutter pivot
  - [x] MVP implementation roadmap + agent orchestration plan (`docs/planning/02-mvp-implementation-orchestration.md`) — updated for Flutter
  - [x] 4-week detection/AI spike plan (`docs/planning/03-detection-spike-plan.md`) — updated for Flutter test app
  - [x] Hermes agent profile setup plan (`docs/planning/04-hermes-profiles.md`)

---

## 🔄 In Progress

- [x] Pre-flight: create `catspot-*` Hermes profiles (orchestrator + 6 workers, ORC=K3/workers=K2.6, delegation pinned to K2.6) — 2026-07-29
- [x] Pre-flight: install Flutter SDK (via FVM) — 2026-07-29 (FVM 4.1.2, Flutter 3.44.8, Dart 3.12.2; repo pinned via .fvmrc)
- [ ] Pre-flight: role smoke tests for worker profiles
- [ ] Project name finalization (Catspot is a placeholder)
- [ ] **Sprint 1 STARTED 2026-07-29:** ✅ design system v1 (PR #1), ✅ scaffold S1.1 (PR #2), ✅ CI S1.2 (PR #3, green on main), ✅ S1.4 theme tokens (PR #4, CI-gated). In flight: S1.5 backend schema v1 + auth config. Next: V1–V4 validation checklist (Convex/Clerk/camera/MLKit)

---

## 📋 Planned (Next 90 Days)

- [ ] Sprint 1 (Wk 1–2): monorepo scaffold, CI, Codemagic dev builds, Clerk/Convex auth, schema v1, R2 upload
- [ ] Sprint 2 (Wk 3–4): detection/AI spike — server verification, embeddings, cutouts → GO/NO-GO gate G1
- [ ] Sprints 3–8: core scan loop, collection management, economy/social, map, launch readiness
- [ ] Gates G2 (beta), G3 (economy/anti-cheat), G4 (ship)

---

## 🚧 Blockers

None.

---

## 📝 Handoff Notes

- The PRD is the source of truth. If you pick this up, read `docs/PRD.md` next, then the Flutter stack plan in `docs/planning/01-mvp-stack-and-scaffold.md`.
- The biggest risk is **scan detection accuracy** — the spike must prove this before the full MVP is built. The Flutter pivot adds a second risk: **Convex/Clerk Flutter integration** — the 3-day validation checklist in the stack plan must pass before coding depends on it.
- The biggest opportunity is the iOS gap CatchCat left open; plan iOS+Android parity from day one (Flutter supports both; web is a smoke-only target until Phase 5).
- Do not start coding until the GitHub repo is live, the Flutter toolchain is installed, and the technical spike is greenlit.

---

*Last updated: 2026-07-29*
