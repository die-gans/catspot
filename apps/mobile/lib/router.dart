import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/clerk/clerk_auth_gate.dart';
import 'features/debug/validation_screen.dart';

/// Dart-define for the Clerk publishable key.
const String _kClerkPublishableKey = String.fromEnvironment(
  'CLERK_PUBLISHABLE_KEY',
);

/// Build the [ClerkAuthConfig] from the dart-define.
///
/// The default session token template is `convex` so the Clerk SDK returns the
/// correct JWT for Convex authentication out of the box.
ClerkAuthConfig buildClerkAuthConfig() {
  if (_kClerkPublishableKey.isEmpty) {
    throw ArgumentError(
      'CLERK_PUBLISHABLE_KEY is not set. '
      'Pass --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_...',
    );
  }
  return ClerkAuthConfig(
    publishableKey: _kClerkPublishableKey,
    defaultSessionTokenTemplate: 'convex',
  );
}

/// App router.
///
/// Redirects enforce the Clerk auth gate: signed-out users land on
/// `/sign-in`, signed-in users are kept away from the auth routes.
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const ClerkAuthGate(home: _HomePlaceholder()),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const _SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const _SignUpScreen(),
    ),
    GoRoute(
      path: '/debug/validation',
      builder: (context, state) => const ValidationScreen(),
    ),
  ],
  redirect: (context, state) {
    final auth = ClerkAuth.of(context, listen: false);
    final isSignedIn = auth.isSignedIn;
    final location = state.matchedLocation;

    final isAuthRoute = location == '/sign-in' || location == '/sign-up';

    if (!isSignedIn && !isAuthRoute) {
      return '/sign-in';
    }
    if (isSignedIn && isAuthRoute) {
      return '/';
    }
    return null;
  },
);

/// Home placeholder shown once the user is authenticated.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catspot')),
      body: const Center(child: Text('Home')),
    );
  }
}

/// Sign-in screen rendered by the `/sign-in` route.
///
/// Uses the Clerk Flutter SDK's built-in authentication flow. The router
/// redirects unauthenticated users here and authenticated users away.
class _SignInScreen extends StatelessWidget {
  const _SignInScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: ClerkAuthentication()));
  }
}

/// Sign-up screen rendered by the `/sign-up` route.
///
/// Reuses the Clerk authentication widget; the SDK handles the sign-up flow.
class _SignUpScreen extends StatelessWidget {
  const _SignUpScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: ClerkAuthentication()));
  }
}
