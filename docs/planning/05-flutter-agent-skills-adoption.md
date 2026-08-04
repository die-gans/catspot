# Flutter/Dart Agent Skills Digest — Catspot Adoption Plan

Source: [docs.flutter.dev/ai/agent-skills](https://docs.flutter.dev/ai/agent-skills) and linked official repositories.

---

## 1. Digest of the Flutter/Dart Agent-Skills Page

### What Agent Skills are
Agent skills are **task-oriented blueprints** for AI agents. They are simple folders with a `SKILL.md` (YAML frontmatter + body), optional `scripts/`, `references/`, and `assets/`. Agents load them via **progressive disclosure** (metadata at startup, full body only when the task matches).

- **Rules files** configure general agent behavior across all tasks.
- **MCP** gives the agent tools.
- **Agent Skills** teach the agent the professional know-how to use those tools correctly.

### Official skill repositories
| Repo | URL | Coverage |
|---|---|---|
| dart-lang/skills | https://github.com/dart-lang/skills | Dart workflows: unit tests, mocks, static analysis, coverage, FFI, pattern matching, CLI apps, package conflict resolution |
| flutter/agent-plugins | https://github.com/flutter/agent-plugins | Flutter workflows: widget tests, responsive layouts, declarative routing, JSON serialization, architecture best practices, localization, HTTP, layout debugging |

### Installing skills (standard `.agents/skills` layout)
For any agent that supports the open Agent Skills format:

```bash
# Flutter skills
npx skills add flutter/agent-plugins --skill '*' --agent universal

# Dart skills
npx skills add dart-lang/skills --skill '*' --agent universal
```

For Claude Code, the Flutter plugin bundles skills + the Dart/Flutter MCP server:

```bash
claude plugin marketplace add flutter/agent-plugins
claude plugin install dart-flutter@dart-flutter
claude plugin marketplace list
```

### Structure of a skill
Example from the fetched files:

```markdown
---
name: flutter-apply-architecture-best-practices
description: Architects a Flutter application using the recommended layered approach (UI, Logic, Data). Use when structuring a new project or refactoring for scalability.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 21 Apr 2026 20:11:20 GMT
---
# Architecting Flutter Applications
...
```

Key style notes:
- `name` is the folder/skill identifier.
- `description` ≤ ~60 chars is what the agent sees during discovery; it should state **when to activate** the skill.
- Body is a numbered workflow/checklist plus examples and pitfalls.

---

## 2. Concrete Adoption Plan for Catspot

### A. Official skills to install/mirror now
Pull all of these into the Catspot repo under `.agents/skills/` using `npx skills add …`:

From **flutter/agent-plugins**:
- `flutter-apply-architecture-best-practices`
- `flutter-setup-declarative-routing` (Catspot uses `go_router`)
- `flutter-add-widget-test`
- `flutter-build-responsive-layout`
- `flutter-implement-json-serialization`
- `flutter-fix-layout-issues`
- `flutter-use-http-package`

From **dart-lang/skills**:
- `dart-run-static-analysis`
- `dart-add-unit-test`
- `dart-generate-test-mocks`
- `dart-collect-coverage`
- `dart-resolve-package-conflicts`

Mirroring recommendation: **clone or subtree** the repos under a `vendor/` folder and run the install command, or schedule a weekly `npx skills update`. This keeps Catspot aligned with upstream bug fixes without hand-copying files.

### B. New skills worth writing for Catspot
Based on the page’s best practices and Catspot’s actual stack, write these three project-specific skills:

#### 1. `catspot-riverpod-state-conventions`
Outline: Enforce Catspot’s state-management rules: UI layer uses Riverpod `StateNotifier`/`AsyncNotifier`, server/cache state is read via generated providers, and no widget holds raw `ConvexClient`. The skill should walk the agent through: identify the state type (UI vs. server), choose `StateProvider`/`FutureProvider`/`StreamProvider`/`AsyncNotifier` as appropriate, keep providers in `lib/features/<name>/providers/`, name providers with a `...Pod` suffix, and write a matching widget test with `ProviderScope` overrides.

#### 2. `catspot-convex-backend-patterns`
Outline: Standardize how Convex functions are authored in `packages/backend/convex/`. The agent must: place queries/mutations/actions in the correct file by domain, validate auth context via `ctx.auth`, never trust the client for rewards/rarity/verification, append every currency/item change to `economyLedger` with an idempotency key, coarsen map coordinates before returning public data, and run `npx convex dev`/`npx convex deploy` with schema checks.

#### 3. `catspot-camera-scan-pipeline`
Outline: Guide implementation of the cat-scan flow without breaking privacy or anti-cheating rules. Steps: request camera permissions via `camera` plugin, strip EXIF before upload, run on-device detection for user feedback only, send the image to the Convex vision pipeline for authoritative verification, store the resulting URL in R2, and keep exact GPS in private `scans` rows while exposing only geohash-6 + jitter to the map.

---

## 3. Fetched Skill Snippets

### `flutter-apply-architecture-best-practices` — core workflow
```markdown
## Workflow: Implementing a New Feature
- [ ] Step 1: Define Domain Models.
- [ ] Step 2: Implement Services.
- [ ] Step 3: Implement Repositories.
- [ ] Step 4: Apply Conditional Logic (Domain Layer).
  - If complex: create a Use Case class.
  - If simple CRUD: skip to Step 5.
- [ ] Step 5: Implement the ViewModel.
- [ ] Step 6: Implement the View.
- [ ] Step 7: Inject Dependencies.
- [ ] Step 8: Run Validator.
```

It also enforces the project layout:
```text
lib/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── domain/
│   ├── models/
│   └── use_cases/
└── ui/
    ├── core/
    └── features/
        └── [feature_name]/
            ├── view_models/
            └── views/
```

### `flutter-setup-declarative-routing` — go_router checklist
```markdown
## Workflow: Initializing the Application and Router
- [ ] Create the Flutter application.
- [ ] Add the `go_router` dependency.
- [ ] Configure the URL strategy for web/deep linking.
- [ ] Implement the `GoRouter` configuration.
- [ ] Bind the router to `MaterialApp.router`.
```

It also provides the native deep-linking configuration snippets for Android (`assetlinks.json`) and iOS (`apple-app-site-association`), plus the `StatefulShellRoute.indexedStack` pattern for bottom-navigation shells.

---

## 4. AGENTS.md Gap Analysis

Catspot has **`docs/AGENTS.md`** but **no root-level `AGENTS.md`**. The existing file already points agents to `.agents/skills/`, which aligns well with the Flutter page. Gaps to close:

| Gap | Recommendation |
|---|---|
| **No root `AGENTS.md`** | Add `/AGENTS.md` that links to `docs/AGENTS.md` or summarizes the agent on-ramping so tools scanning repo roots find it. |
| **No skill install/update instructions** | Document the exact `npx skills add …` commands and a cadence for updating upstream skills. |
| **No skill metadata conventions** | Specify that in-repo skills follow the `SKILL.md` frontmatter format (`name`, `description` ≤ 60 chars). |
| **No mapping of which skills apply to which tasks** | Add a lookup table: e.g. writing a widget test → use `flutter-add-widget-test`; adding routing → use `flutter-setup-declarative-routing`. |
| **No guidance for writing project-specific skills** | Add a short section on when to create a new Catspot skill, where to place it, and how to keep it synced with PRD/tracker changes. |
| **No mention of progressive disclosure / discovery** | Explain that agents only load metadata at startup and why concise `description` fields matter. |
| **No rules-vs-skills-vs-MCP framing** | Briefly clarify the division of labor with `.cursorrules`/`.claude.md`, MCP tools, and Agent Skills. |

---

## 5. Next Steps

1. Run `npx skills add flutter/agent-plugins dart-lang/skills --skill '*' --agent universal` inside Catspot and commit the `.agents/skills` directory (or document the install step).
2. Create `catspot-riverpod-state-conventions`, `catspot-convex-backend-patterns`, and `catspot-camera-scan-pipeline` under `.agents/skills/` (or the orchestrator profile).
3. Patch `docs/AGENTS.md` to close the gaps above and add a root `/AGENTS.md` symlink or summary.
