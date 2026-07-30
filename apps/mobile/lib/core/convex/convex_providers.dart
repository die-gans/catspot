import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catspot_convex_client.dart';

/// Initialization state of the Catspot Convex client.
///
/// This is intentionally a [FutureProvider] so the UI can show a loading state
/// while the singleton is being initialized.
final convexClientProvider = FutureProvider<void>((ref) async {
  if (!CatspotConvexClient.isInitialized) {
    await CatspotConvexClient.initialize();
  }
});

/// Synchronous status of the Convex client, suitable for widgets that just
/// need a yes/no initialized indicator.
final convexClientStatusProvider = Provider<bool>((ref) {
  return CatspotConvexClient.isInitialized;
});

/// Stream of whether the Convex client considers the user authenticated.
final convexAuthStateProvider = StreamProvider<bool>((ref) {
  return CatspotConvexClient.authState;
});
