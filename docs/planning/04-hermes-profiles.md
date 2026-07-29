# 04 — Hermes Profile Setup Plan for the Catspot Agent Team

**Companion to:** `02-mvp-implementation-orchestration.md` (Part II)
**Date:** 2026-07-29
**Status:** Plan only — no profiles have been created yet. Every command below was validated against the local `hermes --help` output but should be re-checked before running.

---

## 1. Owner-code → profile mapping

The orchestration plan defines 7 owner codes (ORC, MOB, BE, ML, DSN, INF, QA). Recommended profile names, prefixed `catspot-` so they sort together and never collide with the existing `default`, `coder`, `relationship`, `researcher` profiles:

| Owner code | Profile name | Role summary |
|---|---|---|
| ORC | `catspot-orchestrator` | Planner/coordinator: docs, tracker, task graph, dispatches subagents. Never writes app code. |
| MOB | `catspot-mobile` | `apps/mobile/lib/` — Flutter screens, camera, navigation, components, widgets. |
| BE | `catspot-backend` | `packages/backend/convex/` — schema, functions, auth, economy, geo, R2 pipeline. |
| ML | `catspot-ml` | `apps/mobile/lib/features/scan/ml/`, `packages/backend/convex/scanPipeline.ts`, model eval, `scripts/eval/`. |
| DSN | `catspot-design` | `apps/mobile/lib/core/theme/`, `apps/mobile/lib/features/*/widgets/`, store assets, landing page. |
| INF | `catspot-infra` | CI/Codemagic, R2, `.github/workflows/`, `scripts/`, env config. |
| QA | `catspot-qa` | Tests, device matrix, gate reports, `docs/qa/`. |

**Phased rollout (recommended):** start with a 4-profile subset — `catspot-orchestrator`, `catspot-mobile`, `catspot-backend`, `catspot-ml`. These cover the Sprint 1–2 critical path (scaffold, camera, detection, auth, pipeline). Add `catspot-design`, `catspot-infra`, `catspot-qa` when Sprints 3–4 spin up DSN/QA-heavy work, or immediately if parallel lanes are wanted from day 1.

## 2. Profile creation commands

Clone from `default` (the configured, working profile) so each new profile inherits gateway/auth settings, then specialize. `--clone-from default` implies `--clone` (copies config.yaml, .env, SOUL.md, skills).

```bash
# Core subset (Sprint 1–2)
hermes profile create catspot-orchestrator --clone-from default \
  --description "Catspot orchestrator: sprint planning, task graph, dispatches work to catspot-* worker profiles. Never writes app code."
hermes profile create catspot-mobile --clone-from default \
  --description "Catspot mobile agent: owns apps/mobile/ (Flutter screens, camera, navigation, components, widgets)."
hermes profile create catspot-backend --clone-from default \
  --description "Catspot backend agent: owns packages/backend/convex/ (schema, functions, auth, economy, geo, R2 pipeline)."
hermes profile create catspot-ml --clone-from default \
  --description "Catspot ML/data agent: owns apps/mobile/lib/features/scan/ml/, scanPipeline, embeddings, model eval, scripts/eval/."

# Extended set (add when Sprints 3+ demand them)
hermes profile create catspot-design --clone-from default \
  --description "Catspot design agent: theme tokens, components, store assets, landing page."
hermes profile create catspot-infra --clone-from default \
  --description "Catspot infra agent: CI/Codemagic workflows, R2, scripts/, env/secrets config. Merges lockfiles last."
hermes profile create catspot-qa --clone-from default \
  --description "Catspot QA agent: tests, device matrix, gate reports, docs/qa/. Review-only on app code."
```

Create wrapper aliases (e.g. `hermes-catspot-mobile`) if wanted:

```bash
hermes profile alias catspot-mobile   # repeat per profile, or omit --no-alias at create time
```

## 3. Model / provider recommendations

Available on this machine (per `hermes profile list`): `kimi-k2.6` (current default everywhere except `relationship`), `kimi-k3`. Recommendations:

| Profile | Model | Rationale |
|---|---|---|
| catspot-orchestrator | `kimi-k3` | Long-horizon planning, task decomposition, multi-agent coordination benefits from the stronger model. |
| catspot-ml | `kimi-k3` | Pipeline reasoning, eval analysis, threshold tuning. |
| catspot-mobile | `kimi-k2.6` | Code-heavy implementation; k2.6 is the proven coding model here. Owns Flutter/Dart. |
| catspot-backend | `kimi-k2.6` | Same — Convex functions, schema, transactional logic. |
| catspot-design | `kimi-k2.6` | Component/theme code; mostly code, not planning. |
| catspot-infra | `kimi-k2.6` | YAML/CI scripting. |
| catspot-qa | `kimi-k2.6` | Test writing and review. |

Commands (exact key names may need verification — run `hermes config` with no args to inspect the current schema first):

```bash
hermes -p catspot-orchestrator config set model kimi-k3
hermes -p catspot-ml           config set model kimi-k3
hermes -p catspot-mobile       config set model kimi-k2.6
hermes -p catspot-backend      config set model kimi-k2.6
hermes -p catspot-design       config set model kimi-k2.6
hermes -p catspot-infra        config set model kimi-k2.6
hermes -p catspot-qa           config set model kimi-k2.6
```

Provider keys (e.g. `model.provider` or provider-specific overrides) follow the same `config set <key> <value>` pattern; confirm key names against `default`'s config.yaml before scripting this.

## 4. Toolset recommendations

Manage with `hermes -p <name> tools enable|disable <toolset>` (built-in toolsets use plain names: `web`, `memory`, etc.; MCP tools use `server:tool`). Since profiles are cloned from `default`, start from that baseline and prune.

| Profile | Enable | Consider disabling |
|---|---|---|
| catspot-orchestrator | terminal, file ops, web, memory, session_search | image_generation, text_to_speech, heavy code-execution |
| catspot-mobile | terminal, file ops, web (Flutter/camera/MLKit docs), browser (for component previews) | image_generation, TTS |
| catspot-backend | terminal, file ops, web (Convex/Clerk/R2 docs) | image_generation, TTS, browser |
| catspot-ml | terminal, file ops, web, code execution (Python eval scripts, threshold reports) | image_generation (uses Replicate via scripts instead), TTS |
| catspot-design | terminal, file ops, web, browser, image_generation (asset mockups) | — |
| catspot-infra | terminal, file ops, web | image_generation, TTS, browser |
| catspot-qa | terminal, file ops, web, browser (device-matrix sim testing) | image_generation, TTS |

Example:

```bash
hermes -p catspot-mobile tools disable image_generation
hermes -p catspot-mobile tools disable text_to_speech
hermes -p catspot-ml     tools enable  code_execution
hermes -p catspot-qa     tools enable  browser
```

Verify tool names with `hermes -p <name> tools list` before disabling — names are version-dependent.

## 5. Skills to attach

Skills live per-profile under `~/.hermes/profiles/<name>/skills/`; cloning from `default` copies `default`'s set. After creation, copy or symlink additional skills from the shared skill library, or use `hermes profile export/import` to move bundles.

| Profile | Skills |
|---|---|---|
| catspot-orchestrator | `subagent-driven-development`, `writing-plans`, `kanban-orchestrator`, `plan` |
| catspot-mobile | `test-driven-development`, `systematic-debugging`, `github-pr-workflow`, `requesting-code-review` |
| catspot-backend | `test-driven-development`, `systematic-debugging`, `github-pr-workflow`, `requesting-code-review` |
| catspot-ml | `test-driven-development`, `jupyter-live-kernel`, `huggingface-hub`, `github-pr-workflow` |
| catspot-design | `github-pr-workflow`, `sketch`, `popular-web-designs` |
| catspot-infra | `docker-first-deployment`, `github-pr-workflow`, `systematic-debugging` |
| catspot-qa | `test-driven-development`, `github-code-review`, `dogfood` (exploratory QA), `systematic-debugging` |

INF scope: CI/Codemagic, R2, scripts, env/secrets.

(These skills exist in this machine's shared library; copying them into a profile is a file operation under `~/.hermes/profiles/<name>/skills/`.)

## 6. Setup order & verification

**Order:**

1. `hermes profile list` — confirm baseline (default, coder, relationship, researcher).
2. Create the 4 core profiles (§2, first block).
3. Set models per §3; verify with `hermes -p <name> config set model` (read) or `hermes -p <name> profile show`.
4. Tune toolsets per §4 (`hermes -p <name> tools list` first).
5. Attach skills per §5.
6. Create aliases if desired: `hermes profile alias catspot-orchestrator` etc.
7. Only when Sprints 3+ require them: create the extended 3 profiles and repeat steps 3–5.

**Verification:**

```bash
hermes profile list                                    # all catspot-* profiles present
hermes -p catspot-orchestrator profile show            # model/description correct
hermes -p catspot-mobile tools list                    # toolset as intended
# Smoke-test each profile with a role-appropriate query:
hermes -p catspot-orchestrator chat "Summarize the Sprint 1 critical path from docs/planning/02-mvp-implementation-orchestration.md"
hermes -p catspot-mobile chat "What files would own the Flutter camera capture shell in apps/mobile?"
hermes -p catspot-backend chat "Sketch a Convex schema for users + keepsakes."
hermes -p catspot-ml chat "How would you evaluate pHash dedup precision/recall on a 200-image test set using Python?"
```

Each smoke test should return a coherent answer and show the profile's configured model in its output/logs.

## 7. Single-profile fallback (no new profiles)

If 7 profiles is too much overhead, map all owner codes onto the existing profiles and serialize work via queues instead of parallel lanes:

| Owner codes | Existing profile | Why |
|---|---|---|
| ORC (+ INF) | `researcher` | Planning/docs/coordination; INF's YAML/CI work fits the generalist lane. Switch its model to `kimi-k3` if it becomes the permanent orchestrator. |
| MOB, BE, ML (+ DSN) | `coder` | All implementation lanes share one coding profile; k2.6 already configured. |
| QA | `default` | Review/gate reports, kept separate from the coding profile so reviews aren't self-graded. |

Mechanics under the fallback:

- **Serial queues:** instead of parallel per-owner profiles, the orchestrator dispatches one task at a time to `coder` (or `researcher`), with the owner code passed in the task prompt (e.g. "Act as MOB; own apps/mobile/…"). Use the kanban skills (`kanban-orchestrator`, `kanban-worker`) for queue discipline.
- **No ownership enforcement by profile:** locked areas (`docs/` ORC-only, `convex/schema.ts` BE-only, lockfiles INF-last) must be enforced in prompts + PR review, since the profile boundary no longer does it.
- **Cost:** losing lane isolation means context bleed between MOB/BE/ML work in shared history; mitigate with fresh sessions per task and explicit role preamble.

The dedicated-profile setup (§1–6) remains the recommendation — it matches the orchestration plan's owner-boundary model and lets the kanban decomposer route by profile description (§2 `--description`).
