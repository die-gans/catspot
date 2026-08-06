# packages/backend

Firebase backend for Catspot (migrated off Convex 2026-08-05 — see `docs/planning/07-convex-to-firebase-migration.md`).

## Layout

```
functions/
├── src/
│   ├── index.ts       # exported functions: seedUser, catchKeepsake, nameKeepsake, listKeepsakes
│   ├── r2.ts          # R2 (S3-compatible) client + upload helpers
│   └── vision.ts      # Gemini cat-name generation (generateCatName)
├── .env               # secrets (GITIGNORED — sourced from orc profile secrets/firebase_functions.env)
firestore.rules        # security rules
firestore.indexes.json # composite indexes
firebase.json          # deploy config
```

## Live functions (us-central1, nodejs22, project catspot-9ee0d)

| Function | Type | Purpose |
|---|---|---|
| `seedUser` | Auth onCreate trigger | Creates `users/{uid}` doc on first sign-in |
| `catchKeepsake` | Callable | Single-call catch: PNG inline → R2 → Firestore keepsake (name placeholder) |
| `nameKeepsake` | Firestore onCreate trigger | Async Gemini name backfill on new keepsakes (failure-tolerant) |
| `listKeepsakes` | Callable | Keepsake list for the calling user |

## Development

```bash
cd packages/backend/functions
pnpm install
pnpm typecheck   # tsc --noEmit
pnpm build       # tsc
firebase deploy --only functions --project catspot-9ee0d
```

Secrets live in `functions/.env` (never commit). Firestore rules/indexes deploy with `firebase deploy --only firestore`.
