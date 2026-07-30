/// Provider signature for an async auth token that can be injected into the
/// Convex client wrapper, so Clerk (or a mock) can be swapped without touching
/// [CatspotConvexClient].
///
/// Returns `null` when the user is signed out or a token cannot be produced.
typedef AuthTokenProvider = Future<String?> Function();
