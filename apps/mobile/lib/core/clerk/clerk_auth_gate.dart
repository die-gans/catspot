import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import '../convex/catspot_convex_client.dart';
import 'clerk_token_bridge.dart';

/// Gate that routes signed-out users to the Clerk authentication UI and
/// renders [home] when signed in.
///
/// In addition to the UI gate, this widget keeps the Convex auth token in sync
/// with the Clerk session: when a user signs in, the Clerk `convex` JWT is
/// injected into [CatspotConvexClient] and `users:upsertFromClerk` is called.
class ClerkAuthGate extends StatelessWidget {
  /// Construct a [ClerkAuthGate].
  const ClerkAuthGate({required this.home, super.key});

  /// Widget to render when the user is signed in.
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ClerkAuthBuilder(
      signedInBuilder: (context, authState) =>
          _ClerkConvexAuthSync(authState: authState, child: home),
      signedOutBuilder: (context, authState) => const _SignInShell(),
    );
  }
}

/// Lightweight shell shown while the router redirects to `/sign-in`.
class _SignInShell extends StatelessWidget {
  const _SignInShell();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Keeps the Convex client authenticated with the Clerk `convex` JWT.
///
/// Listens to [ClerkAuthState] and, on sign-in, injects the token bridge and
/// calls `users:upsertFromClerk`. On sign-out, clears the Convex auth.
class _ClerkConvexAuthSync extends StatefulWidget {
  const _ClerkConvexAuthSync({required this.authState, required this.child});

  final ClerkAuthState authState;
  final Widget child;

  @override
  State<_ClerkConvexAuthSync> createState() => _ClerkConvexAuthSyncState();
}

class _ClerkConvexAuthSyncState extends State<_ClerkConvexAuthSync> {
  ConvexAuthHandle? _authHandle;

  @override
  void initState() {
    super.initState();
    widget.authState.addListener(_onAuthChanged);
    unawaited(_sync());
  }

  @override
  void didUpdateWidget(covariant _ClerkConvexAuthSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authState != widget.authState) {
      oldWidget.authState.removeListener(_onAuthChanged);
      widget.authState.addListener(_onAuthChanged);
      unawaited(_sync());
    }
  }

  @override
  void dispose() {
    widget.authState.removeListener(_onAuthChanged);
    _authHandle?.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    unawaited(_sync());
  }

  Future<void> _sync() async {
    if (!widget.authState.isSignedIn) {
      _authHandle?.dispose();
      _authHandle = null;
      await CatspotConvexClient.clearAuth();
      return;
    }

    _authHandle = await CatspotConvexClient.setAuthTokenProvider(
      clerkTokenBridge(widget.authState),
    );

    try {
      await CatspotConvexClient.mutation('users:upsertFromClerk', {});
    } on Exception {
      // Best-effort upsert; real errors will be surfaced by the validation
      // screen and on-device testing.
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
