# apps/mobile/lib

Catspot Flutter application source.

## Layout

- `main.dart` — entry point.
- `app.dart` — `MaterialApp.router` and theme configuration.
- `router.dart` — `go_router` route definitions.
- `features/` — one folder per vertical feature.
  - `auth/` — Clerk sign-in / sign-up screens.
  - `home/` — Album / collection placeholder.
  - `scan/` — Camera scan flow (Phase 1).
- `core/` — cross-cutting services and design tokens.
  - `convex/` — Convex client wrapper and auth bridge.
  - `clerk/` — Clerk auth provider wrapper.
  - `theme/` — Design tokens and `ThemeData`.
- `l10n/` — localization / ARB files.
