import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

const _startupTag = '[catspot-startup]';
const _authTimeout = Duration(seconds: 10);

/// Gate that routes signed-out users to the sign-in screen and renders [home]
/// when signed in.
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
  Timer? _timeoutTimer;
  bool _timedOut = false;

  Stream<User?> _stream() {
    return widget.authStateChanges ?? FirebaseAuth.instance.authStateChanges();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_authTimeout, () {
      if (mounted) {
        setState(() => _timedOut = true);
      }
    });
  }

  void _retry() {
    setState(() {
      _timedOut = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  @override
  void didUpdateWidget(covariant FirebaseAuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset timeout when the stream identity changes (e.g. retry).
    if (oldWidget.authStateChanges != widget.authStateChanges) {
      _startTimeout();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _stream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _timeoutTimer?.cancel();
          return _AuthErrorShell(
            error: snapshot.error.toString(),
            onRetry: _retry,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_timedOut) {
            return _AuthTimeoutShell(onRetry: _retry);
          }
          return const _SplashShell();
        }

        // First real auth event received.
        _timeoutTimer?.cancel();
        final user = snapshot.data;
        debugPrint('$_startupTag auth first event: ${user != null ? 'signed-in' : 'signed-out'}');

        if (user != null) {
          return widget.home;
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
              style:
                  tokens?.typography.displayLarge.copyWith(
                    color: tokens.colors.brandPrimary,
                  ) ??
                  const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: tokens?.colors.brandPrimary),
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
                style:
                    tokens?.typography.displayLarge.copyWith(
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
                style:
                    tokens?.typography.title ??
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: tokens?.spacing.space3 ?? 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: (tokens?.typography.body ?? const TextStyle()).copyWith(
                  color: tokens?.colors.semanticError ?? Colors.red,
                ),
              ),
              SizedBox(height: tokens?.spacing.space4 ?? 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Timeout shell shown when auth state takes too long to resolve.
class _AuthTimeoutShell extends StatelessWidget {
  const _AuthTimeoutShell({required this.onRetry});

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
                style:
                    tokens?.typography.displayLarge.copyWith(
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
                'Sign-in check is taking too long',
                textAlign: TextAlign.center,
                style:
                    tokens?.typography.title ??
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: tokens?.spacing.space3 ?? 12),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: tokens?.typography.body ?? const TextStyle(),
              ),
              SizedBox(height: tokens?.spacing.space4 ?? 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
