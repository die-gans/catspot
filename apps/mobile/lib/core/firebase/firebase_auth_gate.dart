import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../convex/catspot_convex_client.dart';
import '../theme/theme.dart';
import 'firebase_token_bridge.dart';

/// Gate that routes signed-out users to the sign-in screen and renders [home]
/// when signed in.
///
/// In addition to the UI gate, this widget keeps the Convex auth token in sync
/// with the Firebase session: when a user signs in, the Firebase ID token is
/// injected into [CatspotConvexClient] and `users:upsertFromFirebase` is called.
class FirebaseAuthGate extends StatefulWidget {
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
  State<FirebaseAuthGate> createState() => _FirebaseAuthGateState();
}

class _FirebaseAuthGateState extends State<FirebaseAuthGate> {
  Stream<User?> _stream() {
    return widget.authStateChanges ?? FirebaseAuth.instance.authStateChanges();
  }

  void _retry() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _stream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AuthErrorShell(error: snapshot.error.toString(), onRetry: _retry);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashShell();
        }
        final user = snapshot.data;
        if (user != null) {
          return _FirebaseConvexAuthSync(user: user, child: widget.home);
        }
        return const _SignInShell();
      },
    );
  }
}

/// Branded splash shown while Firebase auth state is still resolving.
class _SplashShell extends StatelessWidget {
  const _SplashShell();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<CatspotTokens>();
    return Scaffold(
      backgroundColor: tokens?.colors.surfaceBase,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Catspot',
              style: tokens?.typography.displayLarge.copyWith(
                    color: tokens.colors.brandPrimary,
                  ) ??
                  const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: tokens?.colors.brandPrimary,
            ),
          ],
        ),
      ),
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

/// Error shell shown when the auth stream emits an error.
class _AuthErrorShell extends StatelessWidget {
  const _AuthErrorShell({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<CatspotTokens>();
    return Scaffold(
      backgroundColor: tokens?.colors.surfaceBase,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens?.spacing.space4 ?? 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Catspot',
                textAlign: TextAlign.center,
                style: tokens?.typography.displayLarge.copyWith(
                      color: tokens.colors.brandPrimary,
                    ) ??
                    const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
              ),
              SizedBox(height: tokens?.spacing.space4 ?? 24),
              Text(
                'Could not check sign-in status',
                textAlign: TextAlign.center,
                style: tokens?.typography.title ??
                    const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              SizedBox(height: tokens?.spacing.space3 ?? 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: (tokens?.typography.body ?? const TextStyle())
                    .copyWith(color: tokens?.colors.semanticError ?? Colors.red),
              ),
              SizedBox(height: tokens?.spacing.space4 ?? 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
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
