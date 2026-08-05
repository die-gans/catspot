import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/firebase/firebase_auth_gate.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/debug/validation_screen.dart';
import 'features/home/home_screen.dart';
import 'features/scan/scan_screen.dart';

const _startupTag = '[catspot-startup]';

/// Notifies [GoRouter] when Firebase auth state changes so redirects re-evaluate.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier([Stream<bool?>? stream]) {
    if (stream != null) setStream(stream);
  }

  StreamSubscription<bool?>? _sub;

  void setStream(Stream<bool?> stream) {
    _sub?.cancel();
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Auth-state notifier used by the router.
///
/// The stream is wired to [FirebaseAuth.instance.authStateChanges] in
/// [main.dart] once Firebase is initialized. Until then the router treats the
/// user as signed out, which is safe for test environments without Firebase.
final _authNotifier = _AuthNotifier();

/// Wire the router auth notifier to the live Firebase auth stream.
///
/// This is called from [main.dart] only when Firebase is initialized. It is a
/// no-op if the notifier already has a stream.
void bindFirebaseAuthNotifier() {
  try {
    final stream = FirebaseAuth.instance.authStateChanges().map(
      (user) => user != null,
    );
    _authNotifier.setStream(stream);
  } on Exception {
    // Keep the router in the signed-out fallback when Firebase is unavailable.
  }
}

/// Logs the first route that is actually built/pushed so we can verify the
/// router reached a frame in release logs.
class _StartupRouteObserver extends NavigatorObserver {
  bool _firstRouteLogged = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (!_firstRouteLogged) {
      _firstRouteLogged = true;
      debugPrint('$_startupTag first route built: ${route.settings.name ?? route.toString()}');
    }
  }
}

/// App router.
///
/// Redirects enforce the Firebase auth gate: signed-out users land on
/// `/sign-in`, signed-in users are kept away from the auth route.
final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authNotifier,
  observers: [_StartupRouteObserver()],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const FirebaseAuthGate(home: HomeScreen()),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/collection',
      builder: (context, state) => const CollectionScreen(),
    ),
    GoRoute(
      path: '/debug/validation',
      builder: (context, state) => const ValidationScreen(),
    ),
    GoRoute(
      path: '/debug/scan',
      builder: (context, state) => const ScanScreen(),
    ),
  ],
  redirect: (context, state) {
    final isSignedIn = _firebaseSignedIn();
    final location = state.matchedLocation;

    final isAuthRoute = location == '/sign-in';

    if (!isSignedIn && !isAuthRoute) {
      return '/sign-in';
    }
    if (isSignedIn && isAuthRoute) {
      return '/';
    }
    return null;
  },
);

bool _firebaseSignedIn() {
  try {
    return FirebaseAuth.instance.currentUser != null;
  } on Exception {
    // Firebase is not initialized (e.g. test environment). Treat as signed out.
    return false;
  }
}
