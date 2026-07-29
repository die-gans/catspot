# packages/shared

Dart package for cross-language contracts shared between the Catspot Flutter client and the Convex backend.

## Layout (planned)

```
lib/
├── catspot_shared.dart
└── src/
    ├── rarity.dart          # rarity constants / odds
    └── vision_verdict.dart  # codegen'd contract model

schema/
└── vision_verdict.json    # JSON Schema source of truth
```

## Codegen

After editing schema files, run the generator from the repo root:

```bash
./scripts/gen_shared_types.sh
```

This emits TypeScript types into `packages/backend/convex/lib/contracts/` and Dart models into `packages/shared/lib/src/`.

No codegen has been run yet for this scaffold.
