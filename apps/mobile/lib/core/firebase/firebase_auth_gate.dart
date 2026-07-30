import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../convex/catspot_convex_client.dart';
import 'firebase_token_bridge.dart';

/// Gate that routes signed-out users to the sign-in screen and renders [home]
/// when signed in.
///
/// In addition to the UI gate, this widget keeps the Convex auth token in sync
/// with the Firebase session: when a user signs in, the Firebase ID token is
/// injected into [CatspotConvexClient] and `users:upsertFromFirebase` is called.
class FirebaseAuthGate extends StatelessWidget {
  /// Construct a [FirebaseAuthGate].
  const FirebaseAuthGate({
    required this.home,
    this.authStateChanges,
    super.key,
  });

  /// Widget to render when the user is signed in.
  final Widget home;

  /// Optional auth-state stream for testing.
  ///
  /// When omitted, the gate listens to [FirebaseAuth.instance.authStateChanges].
  final Stream<User?>? authStateChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authStateChanges ?? FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingShell();
        }
        final user = snapshot.data;
        if (user != null) {
          return _FirebaseConvexAuthSync(user: user, child: home);
        }
        return const _SignInShell();
      },
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

/// Loading shell shown while Firebase auth state is still resolving.
class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Keeps the Convex client authenticated with the Firebase ID token.
///
/// Listens to Firebase auth state and, on sign-in, injects the token bridge and
/// calls `users:upsertFromFirebase`. On sign-out, clears the Convex auth.
class _FirebaseConvexAuthSync extends StatefulWidget {
  const _FirebaseConvexAuthSync({required this.user, required this.child});

  final User user;
  final Widget child;

  @override
  State<_FirebaseConvexAuthSync> createState() =>
      _FirebaseConvexAuthSyncState();
}

class _FirebaseConvexAuthSyncState extends State<_FirebaseConvexAuthSync> {
  ConvexAuthHandle? _authHandle;

  @override
  void initState() {
    super.initState();
    unawaited(_sync());
  }

  @override
  void didUpdateWidget(covariant _FirebaseConvexAuthSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      unawaited(_sync());
    }
  }

  @override
  void dispose() {
    _authHandle?.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    _authHandle?.dispose();
    _authHandle = await CatspotConvexClient.setAuthTokenProvider(
      firebaseTokenBridge(forceRefresh: true),
    );

    try {
      await CatspotConvexClient.mutation('users:upsertFromFirebase', {});
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
