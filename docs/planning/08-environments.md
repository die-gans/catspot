# 08 — Environments Plan (dev / prod)

Status: **PLAN ONLY** — no infra changes yet. Written 2026-08-06 after Sprint 1.

## Problem

Today everything runs against one Firebase project (`catspot-9ee0d`) and one R2 bucket (`catspot-scans`). TestFlight builds point at the same backend as local dev. That means a bad deploy, a rules experiment, or test junk can hit the build real users (well, Dan) are running.

## Recommendation: two environments, not three

Early days — three environments is overhead we don't need. Preprod only earns its keep once we have real users and need a staging gate before prod.

| Env | Firebase project | R2 bucket | Who uses it |
|---|---|---|---|
| **dev** | `catspot-dev` (new) | `catspot-scans-dev` | Local dev, debug builds, experiments |
| **prod** | `catspot-9ee0d` (existing) | `catspot-scans` | TestFlight + App Store builds |

- Dev = wild west. Break rules, wipe data, redeploy at will.
- Prod = what TestFlight points at. Deploys via CI only, no console surgery.

## What changes when we implement (Sprint 2 card, not now)

1. **Firebase**: create `catspot-dev` project; copy Blaze plan, enable Auth (Apple/Google/email), Firestore `(default)` us-central1, Functions.
2. **Flutter**: two FlutterFire configs. Simplest path is Flutter flavors (`--flavor dev` / `--flavor prod`) with per-flavor `GoogleService-Info.plist` / `firebase_options_dev.dart`. Fallback: `--dart-define=ENV=dev` selecting between two generated option files.
3. **Codemagic**: `ios-testflight` / release workflows build `--flavor prod`; add a dev workflow building `--flavor dev` for internal dogfood builds.
4. **R2**: `catspot-scans-dev` bucket + separate API token; function env vars per project.
5. **Gemini key**: shared is fine (quota is per-key, not per-project).
6. **Deploys**: `firebase deploy` defaults to dev via `.firebaserc` alias; prod deploys only from CI on `main` merge (or manual with a typed confirmation).

## Deferred

- **preprod**: revisit at G2 (beta). A third project is a copy-paste of this pattern.
- **Data seeding scripts** for dev (fake users/keepsakes) — card when dev env exists.
- **Remote Config / feature flags** — not yet, YAGNI.
