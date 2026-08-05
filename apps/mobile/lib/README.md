# apps/mobile/lib

Catspot Flutter application source.

## Layout

- `main.dart` — entry point.
- `app.dart` — `MaterialApp.router` and theme configuration.
- `router.dart` — `go_router` route definitions.
- `features/` — one folder per vertical feature.
  - `auth/` — Firebase sign-in / sign-up screens (Phase 1).
  - `home/` — Album / collection placeholder.
  - `scan/` — Camera scan flow (Phase 1).
- `core/` — cross-cutting services and design tokens.
  - `functions/` — Backend functions seam (provider-agnostic scan contract).
  - `firebase/` — Firebase Auth provider wrapper and options stub.
  - `theme/` — Design tokens and `ThemeData`.
- `l10n/` — localization / ARB files.
