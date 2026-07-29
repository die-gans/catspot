# packages/backend

Convex backend for Catspot.

## Layout (planned)

```
convex/
├── schema.ts          # PRD §5.3 tables
├── auth.config.ts     # Clerk JWT provider
├── users.ts           # user upsert / current user query
├── scans.ts           # scan pipeline actions & mutations
├── http.ts            # webhooks (Clerk) — Phase 0: health only
└── lib/
    ├── r2.ts          # S3 client + signed URL helper
    └── vision.ts      # OpenAI verify stub (typed interface)
```

## Development

Not initialized yet. A later backend card will run:

```bash
cd packages/backend
pnpm install
npx convex dev
```

Set secrets via `npx convex env set ...` (never commit `.env`).
