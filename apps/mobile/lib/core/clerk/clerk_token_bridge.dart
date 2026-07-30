import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';

import '../convex/auth_token_provider.dart';

/// Bridge that adapts a [ClerkAuthState] to the [AuthTokenProvider] contract
/// expected by [CatspotConvexClient].
///
/// The returned function asks Clerk for a JWT generated from the `convex`
/// template. If there is no active Clerk session or the request fails, it
/// returns `null` so the Convex client treats the user as unauthenticated.
AuthTokenProvider clerkTokenBridge(ClerkAuthState authState) {
  return () async {
    try {
      if (!authState.isSignedIn) {
        return null;
      }
      final token = await authState.sessionToken(templateName: 'convex');
      return token.jwt;
    } on clerk.ClerkError {
      return null;
    } on StateError {
      return null;
    }
  };
}
