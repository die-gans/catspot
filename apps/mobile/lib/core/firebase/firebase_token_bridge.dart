import 'package:firebase_auth/firebase_auth.dart';

import '../convex/auth_token_provider.dart';

/// Bridge that adapts Firebase Auth to the [AuthTokenProvider] contract
/// expected by [CatspotConvexClient].
///
/// The returned function asks the current Firebase user for an ID token. If
/// there is no signed-in user or the request fails, it returns `null` so the
/// Convex client treats the user as unauthenticated.
///
/// [forceRefresh] is forwarded to [User.getIdToken] so callers can force a
/// token refresh when needed (for example, after sign-in).
AuthTokenProvider firebaseTokenBridge({bool forceRefresh = false}) {
  return () async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }
      return await user.getIdToken(forceRefresh);
    } on FirebaseAuthException {
      return null;
    } on StateError {
      return null;
    }
  };
}
