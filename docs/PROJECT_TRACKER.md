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

- **Mobile:** Expo + React Native (`react-native-vision-camera` for frame processing)
- **ML/AI:** On-device MLKit detection → custom TFLite model → server vision-LLM verification → 512-d embedding duplicate detection → Replicate silhouette cutout
- **Backend:** Convex (real-time sync, social/map, economy ledger)
- **Storage:** Cloudflare R2 for originals, cards, cutouts, thumbnails
- **Auth:** Clerk (Google/Apple/email-code)
- **Monetization:** RevenueCat subscriptions + IAP, AdMob rewarded ads, honest coin economy
- **Analytics:** PostHog + Sentry (opt-in)

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
  - [x] MVP tech stack + repo scaffold plan (`docs/planning/01-mvp-stack-and-scaffold.md`)
  - [x] MVP implementation roadmap + agent orchestration plan (`docs/planning/02-mvp-implementation-orchestration.md`)
  - [x] 4-week detection/AI spike plan (`docs/planning/03-detection-spike-plan.md`)

---

## 🔄 In Progress

- [ ] Pre-flight: confirm agent profiles or single-profile fallback
- [ ] Project name finalization (Catspot is a placeholder)

---

## 📋 Planned (Next 90 Days)

- [ ] Sprint 1 (Wk 1–2): monorepo scaffold, CI, EAS dev builds, Clerk/Convex auth, schema v1, R2 upload
- [ ] Sprint 2 (Wk 3–4): detection/AI spike — server verification, embeddings, cutouts → GO/NO-GO gate G1
- [ ] Sprints 3–8: core scan loop, collection management, economy/social, map, launch readiness
- [ ] Gates G2 (beta), G3 (economy/anti-cheat), G4 (ship)

---

## 🚧 Blockers

None.

---

## 📝 Handoff Notes

- The PRD is the source of truth. If you pick this up, read `docs/PRD.md` next.
- The biggest risk is **scan detection accuracy** — the spike must prove this before the full MVP is built.
- The biggest opportunity is the iOS gap CatchCat left open; plan iOS+Android parity from day one.
- Do not start coding until the GitHub repo is live and the technical spike is greenlit.

---

*Last updated: 2026-07-29*
