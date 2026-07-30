# V1/V2 Mobile Wiring — Convex Package Decision

Date: 2026-07-30

## Evaluated options

| Package | Resolves with Flutter 3.44.8? | Notes |
|---|---|---|
| `convex_flutter` 3.0.1 | ✅ Yes | Community package wrapping Convex Rust SDK via `flutter_rust_bridge`. Pub get, `flutter analyze`, and `flutter test` pass on the headless build box. Native builds require Rust toolchain (not exercised here). Web path is pure Dart and does not require Rust. |
| `convex_dart` 0.5.0 | Not tested for V1/V2 spike | Also wraps the Rust SDK. `convex_flutter` resolved first and has the broader install base / higher Pub score, so it was selected as the spike candidate without needing a second install attempt. |
| Own-written HTTP wrapper | Reserved fallback | Documented in `docs/planning/01-mvp-stack-and-scaffold.md` §1. Kept ready if `convex_flutter` fails on-device during the V1 validation gate. |

## Decision

Use **`convex_flutter: ^3.0.1`** for the V1/V2 wiring spike.

## Reasoning

1. **Resolution:** `flutter pub add convex_flutter` succeeded immediately against Flutter 3.44.8 / Dart 3.12.2, alongside `clerk_flutter`, `go_router`, `flutter_riverpod`, and `mocktail`. No dependency conflicts were introduced.
2. **API surface:** It exposes the exact primitives we need: `query`, `mutation`, `action`, `subscribe`, `setAuth`, `setAuthWithRefresh`, `authState`, and `connectionState`.
3. **Web support:** The package ships a pure-Dart web implementation, so web builds do not need the Rust toolchain. The native implementation uses FFI, so physical-device builds will exercise the Rust dependency.
4. **Abstraction:** Our `lib/core/convex/` wrappers hide `convex_flutter` behind the `CatspotConvexClient` interface. If the package fails on-device validation, swapping it for the own-written HTTP wrapper is a one-file change.

## Web limitations

- `convex_flutter` itself supports web (pure Dart). No `kIsWeb` guard is required for the Convex wiring.
- `kIsWeb` guards belong to the camera/MLKit code (scan pipeline), not auth/Convex. Those guards will be added in the Phase 1 scan pipeline card.

## Remaining V1/V2 validation (on-device only)

- [ ] Convex client connects to a live dev deployment and `users:current` returns a row.
- [ ] Authenticated `users:upsertFromClerk` mutation round-trips with a Clerk JWT.
- [ ] Real-time subscription receives updates when `users` row changes from the dashboard.
- [ ] `clerk_flutter` sign-in (email code) works on a physical Android + iOS device.
- [ ] `getToken(template: 'convex')` returns a JWT accepted by Convex `auth.config.ts`.
- [ ] Sign-out / sign-in cycle is clean; token refresh does not strand the Convex client.
- [ ] Native Rust build tooling is available on the build machine for Codemagic / local device builds.
